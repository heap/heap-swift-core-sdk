import Foundation

extension HeapBridgeSupport {

    public struct InvocationResult: Encodable {
        let type: String = "result"
        let callbackId: String
        var data: JSON?
        var error: String?
    }
    
    public struct Invocation: Encodable {
        let type: String = "invocation"
        var method: String
        var arguments: [String: JSON]?
        var callbackId: String?
    }
}
