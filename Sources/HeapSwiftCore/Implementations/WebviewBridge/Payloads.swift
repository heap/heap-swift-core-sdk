import Foundation

struct HeapSDKInvocationResult: Encodable {
    let type: String = "result"
    let callbackId: String
    var data: JSON?
    var error: String?
}

struct HeapSDKInvocation: Encodable {
    let type: String = "invocation"
    var method: String
    var callbackId: String?
    var arguments: [String: JSON]?
}
