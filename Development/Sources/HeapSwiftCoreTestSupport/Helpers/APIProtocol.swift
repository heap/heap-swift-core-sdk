import Foundation
@testable import HeapSwiftCore

enum APIRequest {
    case addUserProperties(Result<UserProperties, Error>, URLRequest)
    case identify(Result<UserIdentification, Error>, URLRequest)
    case track(Result<MessageBatch, Error>, URLRequest)
    
    enum Simplified: Equatable {
        case addUserProperties(Bool)
        case identify(Bool)
        case track(Bool)
    }
}

extension APIRequest {
    var simplified: Simplified {
        switch self {
        case .addUserProperties(.success, _):
            return .addUserProperties(true)
        case .addUserProperties:
            return .addUserProperties(false)
        case .identify(.success, _):
            return .identify(true)
        case .identify:
            return .identify(false)
        case .track(.success, _):
            return .track(true)
        case .track:
            return .track(false)
        }
    }
    
    var rawRequest: URLRequest {
        switch self {
        case .addUserProperties(_, let request):
            return request
        case .identify(_, let request):
            return request
        case .track(_, let request):
            return request
        }
    }
}

/// Possible responses to emit when processing a request
enum APIResponse {
    
    /// A 200 response
    case success
    
    /// A 400 response
    case badRequest
    
    /// A 503 response, representing some response that the server is unintentionally sending.
    case serviceUnavailable
    
    /// The request ends not with a HTTPURLResponse but with a URLError.
    case networkFailure
}

class APIProtocol: URLProtocol {
    
    static var baseUrlOverride: URL? = nil
    
    var baseUrl: URL { APIProtocol.baseUrlOverride ?? URL(string: "https://heapanalytics.com/")! }
    
    static var requests: [APIRequest] = []
    
    static var addUserPropertiesResponse: APIResponse = .success
    static var identifyResponse: APIResponse = .success
    static var trackResponse: APIResponse = .success
    
    static func reset() {
        requests = []
        addUserPropertiesResponse = .success
        identifyResponse = .success
        trackResponse = .success
        baseUrlOverride = nil
    }
    
    static var ephemeralUrlSessionConfig: URLSessionConfiguration {
        
#if os(watchOS)
        preconditionFailure("watchOS does not appear to support URLProtocol")
#else
        let urlSessionConfig = URLSessionConfiguration.heapUploader
        urlSessionConfig.protocolClasses = [APIProtocol.self]
        return urlSessionConfig
#endif
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        // Take all requests.
        return task.currentRequest?.url != nil
    }
    
    override func startLoading() {
        guard let url = request.url
        else {
            complete(with: 400)
            return
        }
        
        guard request.httpMethod == "POST"
        else {
            complete(with: 404)
            return
        }
        
        guard let httpBodyStream = request.httpBodyStream,
              let httpBody = try? Data(reading: httpBodyStream)
        else {
            complete(with: 400)
            return
        }
        
        let response: APIResponse
        
        if url.matches(path: "api/capture/v2/add_user_properties", baseUrl: baseUrl) {
            response = APIProtocol.addUserPropertiesResponse
            do {
                APIProtocol.requests.append(.addUserProperties(.success(try UserProperties(serializedData: httpBody)), request))
            } catch {
                APIProtocol.requests.append(.addUserProperties(.failure(error), request))
            }
        } else if url.matches(path: "api/capture/v2/identify", baseUrl: baseUrl) {
            response = APIProtocol.identifyResponse
            do {
                APIProtocol.requests.append(.identify(.success(try UserIdentification(serializedData: httpBody)), request))
            } catch {
                APIProtocol.requests.append(.identify(.failure(error), request))
            }
        } else if url.matches(path: "api/capture/v2/track", baseUrl: baseUrl) {
            response = APIProtocol.trackResponse
            do {
                APIProtocol.requests.append(.track(.success(try MessageBatch(serializedData: httpBody)), request))
            } catch {
                APIProtocol.requests.append(.track(.failure(error), request))
            }
        } else {
            complete(with: 404)
            return
        }
        
        switch response {
        case .success:
            complete(with: 200)
        case .badRequest:
            complete(with: 400)
        case .serviceUnavailable:
            complete(with: 503)
        case .networkFailure:
            fail()
        }
    }
    
    override func stopLoading() {
    }
    
    func complete(with statusCode: Int) {
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: "OK".data(using: .utf8)!)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    func fail() {
        client?.urlProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost))
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    static var addUserPropertyPayloads: [UserProperties] {
        requests.compactMap { request in
            guard case .addUserProperties(.success(let payload), _) = request else { return nil }
            return payload
        }
    }
    
    static var identifyPayloads: [UserIdentification] {
        requests.compactMap { request in
            guard case .identify(.success(let payload), _) = request else { return nil }
            return payload
        }
    }
    
    static var trackPayloads: [MessageBatch] {
        requests.compactMap { request in
            guard case .track(.success(let payload), _) = request else { return nil }
            return payload
        }
    }
}

extension Data {
    
    init(reading input: InputStream) throws {
        self.init()
        
        input.open()
        defer { input.close() }
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let bytesRead = input.read(buffer, maxLength: 1024)
            if let streamError = input.streamError {
                throw streamError
            }
            
            if bytesRead >= 0 {
                append(buffer, count: bytesRead)
            } else {
                break
            }
        }
    }
}

extension URL {
    func matches(path: String, baseUrl: URL) -> Bool {
        let target = URL(string: path, relativeTo: baseUrl)
        return target?.scheme == absoluteURL.scheme && target?.host == absoluteURL.host && target?.path == absoluteURL.path
    }
}
