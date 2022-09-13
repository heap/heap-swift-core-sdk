import Foundation

protocol ActiveSessionProvider {
    var activeSession: ActiveSession? { get }
}

extension OperationQueue {
    
    private static func createUploaderQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "io.heap.Uploader"
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    static let uploadQueue = createUploaderQueue()
}

fileprivate typealias TaskCompletionHandler = (Data?, URLResponse?, Error?) -> Void

fileprivate struct RejectedUsers: Equatable, Hashable {
    let environmentId: String
    let userId: String
    
    init(_ user: UserToUpload) {
        environmentId = user.environmentId
        userId = user.userId
    }
}

class Uploader<DataStore: DataStoreProtocol, SessionProvider: ActiveSessionProvider, ConnectivityTester: ConnectivityTesterProtocol>: UploaderProtocol {
    
    let dataStore: DataStore
    let activeSessionProvider: SessionProvider
    let connectivityTester: ConnectivityTester
    let urlSession: URLSession
    
    /// An set of users who received a 400 response during their initial upload.
    fileprivate var rejectedUsers: Set<RejectedUsers> = []

    init(dataStore: DataStore, activeSessionProvider: SessionProvider, connectivityTester: ConnectivityTester, urlSessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.dataStore = dataStore
        self.activeSessionProvider = activeSessionProvider
        self.connectivityTester = connectivityTester
        self.urlSession = URLSession(configuration: urlSessionConfiguration)
    }

    func startScheduledUploads(with options: [Option : Any]) {
    }

    func stopScheduledUploads() {
    }

    var nextScheduledUploadDate: Date {
        Date()
    }
    
    func performScheduledUpload(complete: @escaping (Date) -> Void) {
        complete(nextScheduledUploadDate)
    }
    
    /// Attempts to upload all queued data to the server.
    ///
    /// - Parameters:
    ///   - activeSession: Information about the active session.
    ///   - options: Any options passed while starting the scheduled upload.
    ///   - complete: A completion block that fires when the upload process completes.
    func uploadAll(activeSession: ActiveSession, options: [Option : Any], complete: @escaping (UploadResult) -> Void) {
        
        var users: [UserToUpload] = []
        var result: UploadResult = .success(())
        
        // This method calls `doNextOperation()` repeatedly on the upload queue until there are no more upload operations
        // or an operation has failed.  When an operation complete `completionOperation` will process the result and queue
        // up the next batch.
        
        func doNextOperation() {
            guard case .success(()) = result,
                let uploadOperation = nextOperation(for: &users, activeSession: activeSession, options: options) else {
                complete(result)
                return
            }
            
            OperationQueue.uploadQueue.addOperation(uploadOperation)
            
            let completionOperation = BlockOperation {
                result = uploadOperation.result ?? .failure(.badRequest)
                doNextOperation()
            }
            
            completionOperation.addDependency(uploadOperation)
            OperationQueue.uploadQueue.addOperation(completionOperation)
        }
        
        OperationQueue.uploadQueue.addOperation {
            users = self.dataStore.usersToUpload().filter({ !self.rejectedUsers.contains(.init($0)) })
            users.moveActiveSessionToTheFront(using: activeSession)
            doNextOperation()
        }
    }
    
    /// Creates an operation to with the next piece of information that can be sent for the provided users or `nil` if all information has been sent.
    ///
    /// During execution of this method or the operation, the `users` array and properties of the users may be modified to advance its state.  When all data has been consumed and the function returns `nil`, `users` will be an empty array.
    ///
    /// - Parameters:
    ///   - users: A mutable array of users to upload.
    ///   - activeSession: Information about the active session.
    ///   - options: Any options passed while starting the scheduled upload.
    /// - Returns: An operation to upload the initial user data, or nil if it has already been sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload queue.
    func nextOperation(for users: inout [UserToUpload], activeSession: ActiveSession, options: [Option : Any]) -> UploadOperation? {
        while let user = users.first {
            if let operation = nextOperation(for: user, activeSession: activeSession, options: options) {
                return operation
            } else {
                users.removeFirst()
            }
        }
        
        return nil
    }
    
    /// Creates an operation to with the next piece of information that can be sent for the user or `nil` if the user doesn't have any information to send.
    ///
    /// During execution of this method or the operation, properties of `user` may be modified to advance its state.
    ///
    /// - Parameters:
    ///   - user: The user to upload.
    ///   - activeSession: Information about the active session.
    ///   - options: Any options passed while starting the scheduled upload.
    /// - Returns: The next upload operation for the user, or `nil` if all data has been sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload queue.
    func nextOperation(for user: UserToUpload, activeSession: ActiveSession, options: [Option : Any]) -> UploadOperation? {
        
        if let operation = initialUserUploadOperation(user, activeSession: activeSession, options: options) {
            return operation
        }
        
        if let operation = identityUploadOperation(user, activeSession: activeSession, options: options) {
            return operation
        }
        
        return nil
    }
    
    /// Creates an operation to upload the initial data for a user if it has not yet been uploaded.
    ///
    /// Once the operation completes, in success or failure, `needsInitialUpload` will be set to `false` to prevent future uploads.  This reflects the change in this upload cycle and may not represent the persisted state.
    ///
    /// - Parameters:
    ///   - user: The user to upload.
    ///   - activeSession: Information about the active session.
    ///   - options: Any options passed while starting the scheduled upload.
    /// - Returns: An operation to upload the initial user data, or `nil` if it has already been sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload queue.
    func initialUserUploadOperation(_ user: UserToUpload, activeSession: ActiveSession, options: [Option : Any]) -> UploadOperation? {
        
        guard user.needsInitialUpload
        else { return nil }
        
        return UploadOperation(userProperties: .init(withInitialPayloadFor: user), options: options, in: urlSession) { result in
            
            user.needsInitialUpload = false
            
            switch result {
            case .failure(.badRequest) where user.isActive(in: activeSession):
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
    /// Once the operation completes, in success or failure, `needsIdentityUpload` will be set to `false` to prevent future uploads.  This reflects the change in this upload cycle and may not represent the persisted state.
    ///
    /// - Parameters:
    ///   - user: The user to upload.
    ///   - activeSession: Information about the active session.
    ///   - options: Any options passed while starting the scheduled upload.
    /// - Returns: An operation to upload the user identity data, or `nil` if it has already been sent.
    ///
    /// - Important: This method and the returned operation **MUST** only be executed on the upload queue.
    func identityUploadOperation(_ user: UserToUpload, activeSession: ActiveSession, options: [Option : Any]) -> UploadOperation? {
        
        guard user.needsIdentityUpload,
              let userIdentification = UserIdentification(forIdentificationOf: user, at: Date())
        else { return nil }
        
        return UploadOperation(userIdentification: userIdentification, options: options, in: urlSession) { result in
            
            user.needsIdentityUpload = false
            
            switch result {
            case .failure(.badRequest), .success(()):
                self.dataStore.setHasSentIdentity(environmentId: user.environmentId, userId: user.userId)
            default:
                break
            }
        }
    }
}

extension UserToUpload {
    
    /// Checks if the user owns the active session.
    func isActive(in activeSession: ActiveSession) -> Bool {
        userId == activeSession.userId && environmentId == activeSession.environmentId
    }
    
    /// Marks all properties on the user as uploaded so `nextOperation(for:, activeSession:, options:)` will return `nil`.
    func markAsDone() {
        self.needsInitialUpload = false
        self.needsIdentityUpload = false
        self.pendingUserProperties = [:]
        self.sessionIds = []
    }
}

extension Array where Element == UserToUpload {
    
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
}
