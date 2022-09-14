import Foundation

/// An operation to upload data to Heap.
final class UploadOperation: AsynchronousOperation {
    
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
            return .failure(.badRequest)
        default:
            return .failure(.unexpectedServerResponse)
        }
    }
}

extension UploadOperation {
    
    /// Creates an operation to upload the provided user properties.
    ///
    /// - Parameters:
    ///   - userProperties: The user properties to upload.
    ///   - options: Any options passed while starting the scheduled upload.
    ///   - urlSession: The URL session in which to perform the request.
    ///   - complete: A callback to execute while prior to the completion of the operation.
    convenience init(userProperties: UserProperties, options: [Option : Any], in urlSession: URLSession, complete: @escaping (UploadResult) -> Void) {
        self.init(
            urlString: "https://heapanalytics.com/api/integrations/capture/2/add-user-properties",
            bodyBuilder: { try userProperties.serializedData() },
            options: options,
            in: urlSession,
            complete: complete)
    }
    
    /// Creates an operation to upload the provided user identification.
    ///
    /// - Parameters:
    ///   - userIdentification: The user identification to upload.
    ///   - options: Any options passed while starting the scheduled upload.
    ///   - urlSession: The URL session in which to perform the request.
    ///   - complete: A callback to execute while prior to the completion of the operation.
    convenience init(userIdentification: UserIdentification, options: [Option : Any], in urlSession: URLSession, complete: @escaping (UploadResult) -> Void) {
        self.init(
            urlString: "https://heapanalytics.com/api/integrations/capture/2/identify",
            bodyBuilder: { try userIdentification.serializedData() },
            options: options,
            in: urlSession,
            complete: complete)
    }
    
    convenience init(encodedMessages: [Data], options: [Option : Any], in urlSession: URLSession, complete: @escaping (UploadResult) -> Void) {
        self.init(
            urlString: "https://heapanalytics.com/api/integrations/capture/2/track",
            bodyBuilder: {
                try MessageBatch.with {
                    $0.events = try encodedMessages.map({ try Message(serializedData: $0) })
                }.serializedData()
            },
            options: options,
            in: urlSession,
            complete: complete)
    }
    
    private convenience init(urlString: String, bodyBuilder: () throws -> Data, options: [Option : Any], in urlSession: URLSession, complete: @escaping (UploadResult) -> Void) {
        
        guard let url = URL(string: urlString) else {
            self.init(result: .failure(.badRequest), complete: complete)
            return
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try bodyBuilder()
            self.init(request: request, in: urlSession, complete: complete)
        } catch {
            self.init(result: .failure(.badRequest), complete: complete)
        }
    }
}
