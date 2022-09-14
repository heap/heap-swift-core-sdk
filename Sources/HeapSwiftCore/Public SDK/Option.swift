import Foundation

public enum OptionType: Equatable, Hashable {
    case string
    case boolean
    case timeInterval
    case integer
    case url
    case data
    case object
}

public struct Option: Equatable, Hashable {

    public let name: String
    public let type: OptionType

    public init(name: String, type: OptionType) {
        self.name = name
        self.type = type
    }
}

public extension Option {
    static let debug = Option(name: "debug", type: .boolean)
    static let uploadInterval = Option(name: "uploadInterval", type: .timeInterval)
    static let baseUrl = Option(name: "baseUrl", type: .url)
    static let messageBatchByteLimit = Option(name: "messageBatchByteLimit", type: .integer)
    static let messageBatchMessageLimit = Option(name: "messageBatchMessageLimit", type: .integer)
}

extension Dictionary where Key == Option, Value == Any {

    func string(at key: Option) -> String? {
        self[key] as? String
    }

    func boolean(at key: Option) -> Bool? {
        self[key] as? Bool
    }

    func timeInterval(at key: Option) -> TimeInterval? {
        self[key] as? TimeInterval
    }

    func integer(at key: Option) -> Int? {
        self[key] as? Int
    }

    func url(at key: Option) -> URL? {
        if let url = self[key] as? URL {
            return url.absoluteURL
        }

        if let urlString = string(at: key),
           let url = URL(string: urlString),
           url.scheme != nil && url.host != nil {
            return url
        }

        return nil
    }

    func data(at key: Option) -> Data? {
        self[key] as? Data
    }

    func object(at key: Option) -> NSObject? {
        self[key] as? NSObject
    }

    func sanitizedValue(at key: Option) -> Any? {
        switch key.type {
            case .string: return string(at: key)
            case .boolean: return boolean(at: key)
            case .timeInterval: return timeInterval(at: key)
            case .integer: return integer(at: key)
            case .url: return url(at: key)
            case .data: return data(at: key)
            case .object: return object(at: key)
        }
    }

    func sanitizedCopy() -> [Option: Any] {
        return [Option: Any](uniqueKeysWithValues: self.keys.compactMap({ key in
            guard let value = sanitizedValue(at: key) else { return nil }
            return (key, value)
        }))
    }

    func matches(_ other: [Option: Any], at key: Key) -> Bool {
        switch key.type {
            case .string: return string(at: key) == other.string(at: key)
            case .boolean: return boolean(at: key) == other.boolean(at: key)
            case .timeInterval: return timeInterval(at: key) == other.timeInterval(at: key)
            case .integer: return integer(at: key) == other.integer(at: key)
            case .url: return url(at: key) == other.url(at: key)
            case .data: return data(at: key) == other.data(at: key)
            case .object: return object(at: key) == other.object(at: key)
        }
    }

    func matches(_ other: [Option: Any]) -> Bool {
        keys == other.keys && keys.allSatisfy({ matches(other, at: $0) })
    }
}
