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

class Uploader<DataStore: DataStoreProtocol, SessionProvider: ActiveSessionProvider>: UploaderProtocol {
    
    let dataStore: DataStore
    let activeSessionProvider: SessionProvider
    let urlSession: URLSession

    init(dataStore: DataStore, activeSessionProvider: SessionProvider, urlSessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.dataStore = dataStore
        self.activeSessionProvider = activeSessionProvider
        self.urlSession = URLSession(configuration: urlSessionConfiguration)
    }

    func startScheduledUploads(with options: [Option : Any]) {
    }

    func stopScheduledUploads() {
    }

    var nextScheduledUploadDate: Date {
        Date()
    }
    
    func uploadAll(activeSession: ActiveSession, options: [Option : Any], complete: @escaping (UploadResult) -> Void) {
        
        func finish(_ result: UploadResult) { OperationQueue.uploadQueue.addOperation { complete(result) } }
        
        // TODO: Add reachability test
        
        var users = dataStore.usersToUpload()
        guard users.count > 0 else {
            finish(.success(()))
            return
        }
        
        // Move the active user to the front of the list.
        _ = users.partition(by: { $0.environmentId != activeSession.environmentId || $0.userId != activeSession.userId })
        
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
        
        func finish(_ result: UploadResult) { OperationQueue.uploadQueue.addOperation { complete(result) } }

        func processUserDetails() {
            finish(.success(()))
        }
        
        if user.needsInitialUpload {
            
            upload(userProperties: .init(withInitialPayloadFor: user), options: options) { [self] result in
                
                // If uploading the user failed, stop uploading.
                guard case .success = result else {
                    finish(result)
                    return
                }
                
                dataStore.setHasSentInitialUser(environmentId: user.environmentId, userId: user.userId)
                
                processUserDetails()
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
