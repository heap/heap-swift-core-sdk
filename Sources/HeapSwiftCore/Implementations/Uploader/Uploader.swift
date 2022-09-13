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
    
    func uploadAll(activeSession: ActiveSession, options: [Option : Any], complete: @escaping (UploadResult) -> Void) {
        
        func finish(_ result: UploadResult) { OperationQueue.uploadQueue.addOperation { complete(result) } }
        
        // TODO: Add reachability test
        
        var users = dataStore.usersToUpload().filter({ !rejectedUsers.contains(.init($0)) })
        guard users.count > 0 else {
            finish(.success(()))
            return
        }
        
        // Move the active user to the front of the list.
        _ = users.partition(by: { !$0.isActive(in: activeSession) })
        
        func uploadNextUser() {
            let user = users.removeFirst()
            
            uploadUser(user, activeSession: activeSession, options: options) { result in
                
                // If uploading the user failed, stop uploading.
                guard case .success = result else {
                    finish(result)
                    return
                }
                
                if users.isEmpty {
                    finish(.success(()))
                } else {
                    uploadNextUser()
                }
            }
        }
        
        uploadNextUser()
    }
    
    func uploadUser(_ user: UserToUpload, activeSession: ActiveSession, options: [Option : Any], complete: @escaping (UploadResult) -> Void) {
        
        func finish(_ result: UploadResult, reject: Bool = false) {
            OperationQueue.uploadQueue.addOperation {
                if reject {
                    self.rejectedUsers.insert(.init(user))
                }
                complete(result)
            }
        }
        
        func handleFailure(_ error: UploadError) {
            
            let reject: Bool
            
            switch error {
            case .normalError where user.isActive(in: activeSession):
                reject = true
            case .normalError:
                dataStore.deleteUser(environmentId: user.environmentId, userId: user.userId)
                reject = false
            default:
                reject = false
            }
            
            finish(.failure(error), reject: reject)
        }

        func processUserDetails() {
            finish(.success(()))
        }
        
        if user.needsInitialUpload {
            
            upload(userProperties: .init(withInitialPayloadFor: user), options: options) { [self] result in
                
                switch result {
                case .success(_):
                    dataStore.setHasSentInitialUser(environmentId: user.environmentId, userId: user.userId)
                    processUserDetails()
                case .failure(let error):
                    handleFailure(error)
                }
            }
            
        } else {
            processUserDetails()
        }
    }
    
    func uploadSession(with sessionId: String, activeSession: ActiveSession, options: [Option : Any], complete: @escaping (UploadResult) -> Void) {
    }
    
    private func upload(userProperties: UserProperties, options: [Option : Any], complete: @escaping (UploadResult) -> Void) {
        
        func finish(_ result: UploadResult) { OperationQueue.uploadQueue.addOperation { complete(result) } }

        guard let url = URL(string: "https://heapanalytics.com/api/integrations/capture/2/add-user-properties") else {
            finish(.failure(.normalError))
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try userProperties.serializedData()
            urlSession.dataTask(with: request, completionHandler: urlCompletionHandler(wrapping: complete)).resume()
        } catch {
            finish(.failure(.normalError))
        }
    }
    
    private func urlCompletionHandler(wrapping complete: @escaping(UploadResult) -> Void) -> TaskCompletionHandler {
        
        return { data, response, error in
            
            let result: UploadResult
            
            if let response = response as? HTTPURLResponse, error == nil {
                switch response.statusCode {
                case 200:
                    result = .success(())
                case 400:
                    result = .failure(.normalError)
                default:
                    result = .failure(.unknownError)
                }
            } else {
                result = .failure(.networkError)
            }
            
            OperationQueue.uploadQueue.addOperation {
                complete(result)
            }
        }
    }
}

extension UserToUpload {
    func isActive(in activeSession: ActiveSession) -> Bool {
        userId == activeSession.userId && environmentId == activeSession.environmentId
    }
}
