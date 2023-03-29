import Foundation
import HeapSwiftCoreInterfaces

protocol ActiveSessionProvider {
    var activeSession: ActiveSession? { get }
}

extension DispatchQueue {
    @nonobjc static let upload = DispatchQueue(label: "io.heap.Uploader")
}

extension OperationQueue {
    
    private static func createUploaderQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "io.heap.Uploader"
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = .upload
        return queue
    }
    
    /// An operation queue for performing upload operations.
    @nonobjc static let upload = createUploaderQueue()
}

fileprivate typealias TaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void

fileprivate struct RejectedUser: Equatable, Hashable {
    let environmentId: String
    let userId: String
    
    init(_ user: UserToUpload) {
        environmentId = user.environmentId
        userId = user.userId
    }
}

fileprivate struct RejectedSession: Equatable, Hashable {
    let environmentId: String
    let userId: String
    let sessionId: String
    
    init(_ user: UserToUpload, sessionId: String) {
        environmentId = user.environmentId
        userId = user.userId
        self.sessionId = sessionId
    }
}

extension URLSessionConfiguration {
    
    /// A network configuration that does not cache data and is in a low priority state.
    static var heapUploader: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true // Don't make requests until the network is reachable.
        configuration.networkServiceType = .background // Mark that our requests don't need immediate network access.
        return configuration
    }
}

class Uploader<DataStore: DataStoreProtocol, SessionProvider: ActiveSessionProvider>: UploaderProtocol {
    
    let dataStore: DataStore
    let activeSessionProvider: SessionProvider
    let urlSession: URLSession
    
    /// An set of users who received a 400 response during their initial upload.
    ///
    /// Although these users may continue to exist in the data store, they should not be uploaded
    /// again because they are active.
    fileprivate var rejectedUsers: Set<RejectedUser> = []
    
    /// A set of sessions which have recieved a 400 response.
    ///
    /// Although these sessions may continue to exist in the data store, they should not be
    /// uploaded again because they are active.
    fileprivate var rejectedSessions: Set<RejectedSession> = []
    
    var nextScheduledUploadDate: Date = Date()
    fileprivate var scheduledUploadSettings: UploaderSettings = .default
    fileprivate var nextUploadTimer: HeapTimer? = nil
    fileprivate var shouldScheduleUploads = false
    fileprivate var isPerformingScheduledUpload = false

    init(dataStore: DataStore, activeSessionProvider: SessionProvider, urlSessionConfiguration: URLSessionConfiguration = .heapUploader) {
        self.dataStore = dataStore
        self.activeSessionProvider = activeSessionProvider
        self.urlSession = URLSession(configuration: urlSessionConfiguration)
    }

    func startScheduledUploads(with settings: UploaderSettings) {
        OperationQueue.upload.addOperation { [self] in
            shouldScheduleUploads = true
            nextUploadTimer?.cancel()
            scheduledUploadSettings = settings
            repeatedlyPerformScheduledUploads()
        }
    }

    func stopScheduledUploads() {
        OperationQueue.upload.addOperation { [self] in
            shouldScheduleUploads = false
            nextUploadTimer?.cancel()
            nextUploadTimer = nil
        }
    }
    
    /// Calls `performScheduledUpload` and schedules the next upload, so long as
    /// `shouldScheduleUploads` is true.
    func repeatedlyPerformScheduledUploads() {
        guard shouldScheduleUploads else { return }
        
        performScheduledUpload { [weak self] nextScheduledUploadDate in
            self?.nextUploadTimer?.cancel()
            self?.nextUploadTimer = HeapTimer.schedule(in: OperationQueue.upload, at: nextScheduledUploadDate) { [weak self] in
                self?.repeatedlyPerformScheduledUploads()
            }
        }
    }
    
    /// Performs a single scheduled upload if conditions are met.
    ///
    /// This method is safe to call at any point. In order to upload data:
    ///
    /// - The next upload date must be in the past.
    /// - There must be (or must have been) an active session.
    /// - This method must not be currently uploading data.
    ///
    /// If those conditions are not met, the method will return the next time it should be called
    /// again.
    ///
    /// - Parameter complete: A completion block containing the next time that the uploader should
    ///                       run.  Executes in the upload queue.
    func performScheduledUpload(complete: @escaping (Date) -> Void) {
        OperationQueue.upload.addOperation { [self] in
            guard Date() >= nextScheduledUploadDate
            else {
                complete(nextScheduledUploadDate)
                return
            }
            
            guard let activeSession = activeSessionProvider.activeSession,
                  !isPerformingScheduledUpload
            else {
                nextScheduledUploadDate = calculateNextScheduledUploadDate(with: .success(()), settings: scheduledUploadSettings)
                complete(nextScheduledUploadDate)
                return
            }
            
            isPerformingScheduledUpload = true
            
            uploadAll(activeSession: activeSession, settings: scheduledUploadSettings) { [weak self] result in
                if let self = self {
                    self.nextScheduledUploadDate = self.calculateNextScheduledUploadDate(with: result, settings: self.scheduledUploadSettings)
                    complete(self.nextScheduledUploadDate)
                    self.isPerformingScheduledUpload = false
                }
            }
        }
    }
    
    /// Determines the next time the uploader should run, based on previous run results and the
    /// option dictionary.
    ///
    /// - Parameters:
    ///   - result: The result of the last upload attempt.
    ///   - settings: Any settings passed while starting the scheduled upload.
    /// - Returns: The next time the uploader should run.
    private func calculateNextScheduledUploadDate(with result: UploadResult, settings: UploaderSettings) -> Date {
        
        if result.canContinueUploading {
            return Date().addingTimeInterval(settings.uploadInterval)
        } else {
            return Date().addingTimeInterval(settings.uploadInterval * 4)
        }
    }
    
    /// Attempts to upload all queued data to the server.
    ///
    /// - Parameters:
    ///   - activeSession: Information about the active session.
    ///   - settings: Any settings passed while starting the scheduled upload.
    ///   - complete: A completion block that fires when the upload process completes.
    func uploadAll(activeSession: ActiveSession, settings: UploaderSettings, complete: @escaping (UploadResult) -> Void) {
        
        var users: [UserToUpload] = []
        var result: UploadResult = .success(())
        var operationCount = 0
        
        // This method calls `doNextOperation()` repeatedly on the upload queue until there are no
        // more upload operations or an operation has failed.  When an operation complete
        // `completionOperation` will process the result and queue up the next batch.
        
        func doNextOperation() {
            guard result.canContinueUploading,
                  let uploadOperation = nextOperation(for: &users, activeSession: activeSession, settings: settings)
            else {
                switch result {
                case .failure(.networkFailure):
                    HeapLogger.shared.warn("A network error occurred while uploading data and Heap will try again later.")
                case .failure(.unexpectedServerResponse):
                    HeapLogger.shared.warn("A server issue was encountered while uploading and Heap will try again later.")
                case .failure(.badRequest):
                    HeapLogger.shared.warn("All pending data has been uploaded but some invalid data was discarded.")
                case .success(()) where operationCount > 0:
                    HeapLogger.shared.info("All pending data has been uploaded.")
                case .success(()):
                    break // Don't log if nothing happened.
                }
                
                HeapLogger.shared.debug("A total of \(operationCount) requests were made.")
                
                complete(result)
                return
            }
            
            OperationQueue.upload.addOperation(uploadOperation)
            
            let completionOperation = BlockOperation {
                result = uploadOperation.result ?? .failure(.badRequest)
                operationCount += 1
                doNextOperation()
            }
            
            completionOperation.addDependency(uploadOperation)
            OperationQueue.upload.addOperation(completionOperation)
        }
        
        OperationQueue.upload.addOperation {
            users = self.dataStore.usersToUpload()
            users.remove(rejectedUsers: self.rejectedUsers, rejectedSessions: self.rejectedSessions)
            users.moveActiveSessionToTheFront(using: activeSession)
            doNextOperation()
        }
    }
    
    /// Creates an operation to with the next piece of information that can be sent for the
    /// provided users or `nil` if all information has been sent.
    ///
    /// During execution of this method or the operation, the `users` array and properties of the
    /// users may be modified to advance its state.  When all data has been consumed and the
    /// function returns `nil`, `users` will be an empty array.
    ///
    /// - Parameters:
    ///   - users: A mutable array of users to upload.
    ///   - activeSession: Information about the active session.
    ///   - settings: Any settings passed while starting the scheduled upload.
    /// - Returns: The next upload operation for the list of users, or `nil` if all data has been
    ///            sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload
    ///              queue.
    func nextOperation(for users: inout [UserToUpload], activeSession: ActiveSession, settings: UploaderSettings) -> UploadOperation? {
        while let user = users.first {
            if let operation = nextOperation(for: user, activeSession: activeSession, settings: settings) {
                return operation
            } else {
                users.removeFirst()
            }
        }
        
        return nil
    }
    
    /// Creates an operation to with the next piece of information that can be sent for the user or
    /// `nil` if the user doesn't have any information to send.
    ///
    /// During execution of this method or the operation, properties of `user` may be modified to
    /// advance its state.
    ///
    /// - Parameters:
    ///   - user: The user to upload.
    ///   - activeSession: Information about the active session.
    ///   - settings: Any settings passed while starting the scheduled upload.
    /// - Returns: The next upload operation for the user, or `nil` if all data has been sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload
    ///              queue.
    func nextOperation(for user: UserToUpload, activeSession: ActiveSession, settings: UploaderSettings) -> UploadOperation? {
        
        let configuration = UploadOperation.Configuration(user: user, activeSession: activeSession, urlSession: urlSession, settings: settings)
        
        if let operation = initialUserUploadOperation(configuration: configuration) {
            return operation
        }
        
        if let operation = identityUploadOperation(configuration: configuration) {
            return operation
        }
        
        if let operation = addUserPropertiesUploadOperation(configuration: configuration) {
            return operation
        }
        
        if let operation = addMessageBatchUploadOperation(configuration: configuration) {
            return operation
        }
        
        return nil
    }
    
    /// Creates an operation to upload the initial data for a user if it has not yet been uploaded.
    ///
    /// Once the operation completes, in success or failure, `needsInitialUpload` will be set to
    /// `false` to prevent future uploads.  This reflects the change in this upload cycle and may
    /// not represent the persisted state.
    ///
    /// - Parameters:
    ///   - configuration: The configuration for this operation.
    /// - Returns: An operation to upload the initial user data, or `nil` if it has already been
    ///            sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload
    ///              queue.
    func initialUserUploadOperation(configuration: UploadOperation.Configuration) -> UploadOperation? {
        let user = configuration.user
        let sdkInfo = configuration.activeSession.sdkInfo
        
        guard user.needsInitialUpload
        else { return nil }
        
        return UploadOperation(userProperties: .init(withInitialPayloadFor: user, sdkInfo: sdkInfo), configuration: configuration) { result in
            
            user.needsInitialUpload = false
            
            switch result {
            case .failure(.badRequest) where configuration.isUserActive:
                self.rejectedUsers.insert(.init(user))
                user.markAsDone()
            case .failure(.badRequest):
                self.dataStore.deleteUser(environmentId: user.environmentId, userId: user.userId)
                user.markAsDone()
            case .success(()):
                self.dataStore.setHasSentInitialUser(environmentId: user.environmentId, userId: user.userId)
            default:
                break
            }
        }
    }
    
    /// Creates an operation to upload the identity for a user if it has not yet been uploaded.
    ///
    /// Once the operation completes, in success or failure, `needsIdentityUpload` will be set to
    /// `false` to prevent future uploads.  This reflects the change in this upload cycle and may
    /// not represent the persisted state.
    ///
    /// - Parameters:
    ///   - configuration: The configuration for this operation.
    /// - Returns: An operation to upload the user pending user properties, or `nil` if it has
    ///            there are no pending properties.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload
    ///              queue.
    func identityUploadOperation(configuration: UploadOperation.Configuration) -> UploadOperation? {
        let user = configuration.user
        let sdkInfo = configuration.activeSession.sdkInfo
        
        guard user.needsIdentityUpload,
              let userIdentification = UserIdentification(forIdentificationOf: user, at: Date(), sdkInfo: sdkInfo)
        else { return nil }
        
        return UploadOperation(userIdentification: userIdentification, configuration: configuration) { result in
            
            user.needsIdentityUpload = false
            
            switch result {
            case .failure(.badRequest), .success(()):
                self.dataStore.setHasSentIdentity(environmentId: user.environmentId, userId: user.userId)
            default:
                break
            }
        }
    }
    
    /// Creates an operation to add user properties to a user.
    ///
    /// Once the operation completes, in success or failure, `pendingUserProperties` will be
    /// cleared to prevent future uploads.  This reflects the change in this upload cycle and may
    /// not represent the persisted state.
    ///
    /// - Parameters:
    ///   - configuration: The configuration for this operation.
    /// - Returns: An operation to upload the user identity data, or `nil` if it has already been
    ///            sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload
    ///              queue.
    func addUserPropertiesUploadOperation(configuration: UploadOperation.Configuration) -> UploadOperation? {
        let user = configuration.user
        let activeSession = configuration.activeSession
        let sdkInfo = activeSession.sdkInfo
        let properties = user.pendingUserProperties
        
        guard !properties.isEmpty
        else { return nil }
        
        return UploadOperation(userProperties: .init(withUserPropertiesFor: user, sdkInfo: sdkInfo), configuration: configuration) { result in
            
            user.pendingUserProperties.removeAll()
            
            switch result {
            case .failure(.badRequest), .success(()):
                for (name, value) in properties {
                    self.dataStore.setHasSentUserProperty(environmentId: user.environmentId, userId: user.userId, name: name, value: value)
                }
            default:
                break
            }
        }
    }
    
    func addMessageBatchUploadOperation(configuration: UploadOperation.Configuration) -> UploadOperation? {
        let user = configuration.user
        let activeSession = configuration.activeSession
        let messageLimit = configuration.messageLimit
        let byteLimit = configuration.byteLimit
        
        let (messageBatch, sessionId) = nextMessageBatch(user, activeSession: activeSession, messageLimit: messageLimit, byteLimit: byteLimit)
        
        guard !messageBatch.isEmpty
        else { return nil }
        
        return UploadOperation(encodedMessages: messageBatch.map(\.1), configuration: configuration) { result in
            
            switch result {
            case .failure(.badRequest) where configuration.isUserActive && sessionId == activeSession.sessionId:
                self.rejectedSessions.insert(.init(user, sessionId: sessionId))
                user.removeSession(withId: sessionId)
            case .failure(.badRequest):
                self.dataStore.deleteSession(environmentId: user.environmentId, userId: user.userId, sessionId: sessionId)
                user.removeSession(withId: sessionId)
            case .success(()):
                self.dataStore.deleteSentMessages(Set(messageBatch.map(\.0)))
            default:
                break
            }
        }
    }
    
    func nextMessageBatch(_ user: UserToUpload, activeSession: ActiveSession, messageLimit: Int, byteLimit: Int) -> ([(identifier: MessageIdentifier, payload: Data)], String) {
        guard let sessionId = user.sessionIds.first else { return ([], "") }
        
        let messages = dataStore.getPendingEncodedMessages(environmentId: user.environmentId, userId: user.userId, sessionId: sessionId, messageLimit: messageLimit, byteLimit: byteLimit)
        
        if !messages.isEmpty {
            return (messages, sessionId)
        }
        
        user.sessionIds.removeFirst()
        
        if !user.isActive(in: activeSession) || sessionId != activeSession.sessionId {
            dataStore.deleteSession(environmentId: user.environmentId, userId: user.userId, sessionId: sessionId)
        }
        
        return nextMessageBatch(user, activeSession: activeSession, messageLimit: messageLimit, byteLimit: byteLimit)
    }
}

extension UserToUpload {
    
    /// Checks if the user owns the active session.
    func isActive(in activeSession: ActiveSession) -> Bool {
        userId == activeSession.userId && environmentId == activeSession.environmentId
    }
    
    /// Marks all properties on the user as uploaded so `nextOperation(for:, activeSession:, settings:)` will return `nil`.
    func markAsDone() {
        self.needsInitialUpload = false
        self.needsIdentityUpload = false
        self.pendingUserProperties = [:]
        self.sessionIds = []
    }
    
    func removeSession(withId sessionId: String) {
        sessionIds.removeAll(where: { $0 == sessionId })
    }
}

fileprivate extension Array where Element == UserToUpload {
    
    /// Rearranges the users and sessions so that the active user and session are at the front of the queue.
    /// - Parameter activeSession: Information about the active session.
    mutating func moveActiveSessionToTheFront(using activeSession: ActiveSession) {
        
        // Move the active user to the front of the list.
        _ = partition(by: { !$0.isActive(in: activeSession) })
        
        // Move the active session to the front of the list.
        if !isEmpty && self[0].isActive(in: activeSession) {
            _ = self[0].sessionIds.partition(by: { $0 != activeSession.sessionId })
        }
    }
    
    mutating func remove(rejectedUsers: Set<RejectedUser>, rejectedSessions: Set<RejectedSession>) {
        if !rejectedUsers.isEmpty {
            self = self.filter({ !rejectedUsers.contains(.init($0)) })
        }
        
        for user in self {
            let sessionsIdsToReject = rejectedSessions.sessionIds(for: user)
            if !sessionsIdsToReject.isEmpty {
                user.sessionIds = user.sessionIds.filter({ !sessionsIdsToReject.contains($0) })
            }
        }
    }
}

extension Set where Element == RejectedSession {
    
    func sessionIds(for user: UserToUpload) -> Set<String> {
        return Set<String>(compactMap({ $0.environmentId == user.environmentId && $0.userId == user.userId ? $0.sessionId : nil }))
    }
}

extension UploadResult {
    
    /// Returns whether or not the result should stop the upload process.
    ///
    /// We allow uploading to proceed for success and bad request payloads. In cases where a bad
    /// request prevents part of the upload from continuing, the source operation must mark the
    /// appropriate data as unuploadable rather than stopping the whole process.
    var canContinueUploading: Bool {
        switch self {
        case .success(()), .failure(.badRequest):
            return true
        case .failure(.networkFailure), .failure(.unexpectedServerResponse):
            return false
        }
    }
}
