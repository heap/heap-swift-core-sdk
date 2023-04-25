import Foundation

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

public protocol JSONEncodable
{
    func _toHeapJSON() -> JSON
}

public extension JSONEncodable {
    func toJSONData() throws -> Data
    {
        try JSONEncoder().encode(_toHeapJSON())
    }
    
    func toJSONString(encoding: String.Encoding = .utf8) throws -> String?
    {
        String(data: try toJSONData(), encoding: encoding)
    }
}

extension String: JSONEncodable
{
    public func _toHeapJSON() -> JSON { JSON.string(self) }
}

extension Double: JSONEncodable
{
    public func _toHeapJSON() -> JSON { JSON.number(self) }
}

extension Int: JSONEncodable
{
    public func _toHeapJSON() -> JSON { JSON.number(Double(self)) }
}

extension Dictionary: JSONEncodable where Key == String, Value: JSONEncodable
{
    public func _toHeapJSON() -> JSON { JSON.object(self.mapValues({ $0._toHeapJSON() })) }
}

extension Array: JSONEncodable where Element: JSONEncodable
{
    public func _toHeapJSON() -> JSON { JSON.array(self.map({ $0._toHeapJSON() })) }
}

extension Bool: JSONEncodable
{
    public func _toHeapJSON() -> JSON { JSON.bool(self) }
}

extension Optional: JSONEncodable where Wrapped: JSONEncodable
{
    public func _toHeapJSON() -> JSON { self.map({ $0._toHeapJSON() }) ?? JSON.null }
}

struct AnyJSONEncodable: JSONEncodable {
    let wrapped: JSONEncodable
    
    func _toHeapJSON() -> JSON {
        return wrapped._toHeapJSON()
    }
}
