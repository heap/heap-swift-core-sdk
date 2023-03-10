import Foundation

/// An operation to upload data to Heap.
final class UploadOperation: AsynchronousOperation {
    
    private static let baseUrl = URL(string: "https://c.us.heap-api.com/")
    
    private var callback: ((UploadResult) -> Void)?
    private var task: URLSessionDataTask?
    public private(set) var result: UploadResult?
    
    /// Creates a new operation to upload the provided request and evaluate a callback on completion.
    ///
    /// - Parameters:
    ///   - request: The request to send to Heap.
    ///   - urlSession: The URL session in which to perform the request.
    ///   - complete: A callback to execute while prior to the completion of the operation.
    init(request: URLRequest, in urlSession: URLSession, complete: @escaping(UploadResult) -> Void) {
        super.init()
        self.task = urlSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            if let self = self {
                self.result = self.taskResult(data: data, response: response, error: error)
                self.finish()
            }
        })
        self.result = nil
        self.callback = complete
    }
    
    init(result: UploadResult, complete: @escaping(UploadResult) -> Void) {
        super.init()
        self.task = nil
        self.result = result
        self.callback = complete
    }
    
    override func cancelAsync() {
        task?.cancel()
    }
    
    override func startAsync() {
        if let task = task {
            task.resume()
        } else {
            finish()
        }
    }
    
    override func finish() {
        if !isCancelled, let result = result {
            callback?(result)
        }
        task = nil
        callback = nil
        super.finish()
    }
    
    private func taskResult(data: Data?, response: URLResponse?, error: Error?) -> UploadResult {
        guard let response = response as? HTTPURLResponse, error == nil
        else { return .failure(.networkFailure) }
        
        switch response.statusCode {
        case 200:
            return .success(())
        case 400:
            HeapLogger.shared.trace("Bad Request when posting to <\(response.url?.absoluteString ?? "unknown url")>.")
            return .failure(.badRequest)
        default:
            HeapLogger.shared.trace("Unexpected status code \(response.statusCode) when posting to <\(response.url?.absoluteString ?? "unknown url")>.")
            return .failure(.unexpectedServerResponse)
        }
    }
}

extension UploadOperation {
    
    /// Creates an operation to upload the provided user properties.
    ///
    /// - Parameters:
    ///   - userProperties: The user properties to upload.
    ///   - configuration: The configuration for this operation.
    ///   - complete: A callback to execute while prior to the completion of the operation.
    convenience init(userProperties: UserProperties, configuration: Configuration, complete: @escaping (UploadResult) -> Void) {
        HeapLogger.shared.trace("Building add_user_properties request for:\n\(userProperties)")
        self.init(
            path: "api/capture/v2/add_user_properties",
            bodyBuilder: { try userProperties.serializedData() },
            configuration: configuration,
            complete: complete)
    }
    
    /// Creates an operation to upload the provided user identification.
    ///
    /// - Parameters:
    ///   - userIdentification: The user identification to upload.
    ///   - configuration: The configuration for this operation.
    ///   - complete: A callback to execute while prior to the completion of the operation.
    convenience init(userIdentification: UserIdentification, configuration: Configuration, complete: @escaping (UploadResult) -> Void) {
        HeapLogger.shared.trace("Building identify request for:\n\(userIdentification)")
        self.init(
            path: "api/capture/v2/identify",
            bodyBuilder: { try userIdentification.serializedData() },
            configuration: configuration,
            complete: complete)
    }
    
    /// Creates an operation to upload the provided encoded messages.
    ///
    /// - Parameters:
    ///   - encodedMessages: An array of encoded message protobufs.
    ///   - configuration: The configuration for this operation.
    ///   - complete: A callback to execute while prior to the completion of the operation.
    convenience init(encodedMessages: [Data], configuration: Configuration, complete: @escaping (UploadResult) -> Void) {
        HeapLogger.shared.trace("Building track request for \(encodedMessages.count) messages (contents previously logged).")
        self.init(
            path: "api/capture/v2/track",
            bodyBuilder: {
                try MessageBatch.with {
                    $0.events = try encodedMessages.map({ try Message(serializedData: $0) })
                }.serializedData()
            },
            configuration: configuration,
            complete: complete)
    }
    
    private convenience init(path: String, bodyBuilder: () throws -> Data, configuration: Configuration, complete: @escaping (UploadResult) -> Void) {
        
        do {
            let request = try configuration.request(path: path, bodyBuilder: bodyBuilder)
            
            if let url = request.url,
               let body = request.httpBody {
                if body.count < 2048 {
                    HeapLogger.shared.trace("Sending serialized data to <\(url.absoluteString)>:\n\(body.base64EncodedString())")
                } else {
                    HeapLogger.shared.trace("Sending serialized data of length \(body.count) to <\(url.absoluteString)>.")
                }
            }
            
            self.init(request: request, in: configuration.urlSession, complete: complete)
        } catch {
            self.init(result: .failure(.badRequest), complete: complete)
        }
    }
    
    struct Configuration {
        
        static let allowedQueryCharacters: CharacterSet = .urlQueryAllowed.subtracting(.init(charactersIn: "&+"))
        
        let user: UserToUpload
        let activeSession: ActiveSession
        let urlSession: URLSession
        let settings: UploaderSettings
        
        func encode(_ string: String?) -> String {
            string?.addingPercentEncoding(withAllowedCharacters: Configuration.allowedQueryCharacters) ?? ""
        }
        
        func url(path: String) throws -> URL {
            
            // Apply a query string with properties to support log troubleshooting.
            let relativeString = "\(path)?b=\(encode(activeSession.sdkInfo.libraryInfo.name))&i=\(encode(user.identity))&u=\(encode(user.userId))&a=\(encode(user.environmentId))"
            
            guard
                let baseUrl = settings.baseUrl,
                let url = URL(string: relativeString, relativeTo: baseUrl)
            else {
                HeapLogger.shared.trace("Could not generate url with relative string: \(relativeString) and base url: \(String(describing: settings.baseUrl))")
                throw UploadError.badRequest
            }
            
            return url
        }
        
        func request(path: String, bodyBuilder: () throws -> Data) throws -> URLRequest {
            let url = try url(path: path)
            let body = try bodyBuilder()

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.setValue(user.environmentId, forHTTPHeaderField: "X-Heap-Env-Id")
            return request
        }
        
        var isUserActive: Bool {
            user.isActive(in: activeSession)
        }
        
        var messageLimit: Int { settings.messageBatchMessageLimit }
        var byteLimit: Int { settings.messageBatchByteLimit }
    }
}
