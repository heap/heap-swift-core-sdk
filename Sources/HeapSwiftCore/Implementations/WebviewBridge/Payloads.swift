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

// From https://github.com/iwill/generic-json-swift/blob/master/GenericJSON/JSON.swift

public enum JSON: Equatable {
    case string(String)
    case number(Double)
    case object([String:JSON])
    case array([JSON])
    case bool(Bool)
    case null
}

extension JSON: Encodable {

    public func encode(to encoder: Encoder) throws {

        var container = encoder.singleValueContainer()

        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }
}
