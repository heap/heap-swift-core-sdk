import Foundation

@objc
public enum OptionType: Int {
    case string
    case boolean
    case timeInterval
    case integer
    case url
    case data
    case object
}

extension OptionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string: return "string"
        case .boolean: return "boolean"
        case .timeInterval: return "timeInterval"
        case .integer: return "integer"
        case .url: return "url"
        case .data: return "data"
        case .object: return "object"
        }
    }
}

@objc(HeapOption)
public class Option: NSObject {
    
    public let name: String
    public let type: OptionType

    private init(name: String, type: OptionType) {
        self.name = name
        self.type = type
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Option else { return false }
        return (name, type) == (other.name, other.type)
    }
    
    public override var hash: Int {
        self.name.hashValue
    }
    
    private static var registeredOptions: [String: Option] = [:]
    
    @objc
    public static func register(name: String, type: OptionType) -> Option {
        let option = Option(name: name, type: type)
        if let existing = registeredOptions[name] {
            
            if existing != option {
                HeapLogger.shared.error("Attempted to overwrite option \(name) of type \(existing.type) with \(option.type). This may result in unexpected behavior as options of the wrong type are ignored.")
            }
            
            return existing
        }
        
        registeredOptions[name] = option
        return option
    }
    
    @objc
    public static func named(_ name: String) -> Option? {
        registeredOptions[name]
    }
}

// Expose NSCopying to enable use as an NSDictionary key.
@objc
extension Option: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

@objc
public extension Option {
    static let uploadInterval = register(name: "uploadInterval", type: .timeInterval)
    static let baseUrl = register(name: "baseUrl", type: .url)
    static let messageBatchByteLimit = register(name: "messageBatchByteLimit", type: .integer)
    static let messageBatchMessageLimit = register(name: "messageBatchMessageLimit", type: .integer)
    static let captureAdvertiserId = register(name: "captureAdvertiserId", type: .boolean)
}

@objc
public extension Option {
    static let disablePageviewAutocapture = register(name: "disablePageviewAutocapture", type: .boolean)
    static let disablePageviewTitleCapture = register(name: "disablePageviewTitleCapture", type: .boolean)
    static let disableInteractionAutocapture = register(name: "disableInteractionAutocapture", type: .boolean)
    static let disableInteractionTextCapture = register(name: "disableInteractionTextCapture", type: .boolean)
    static let disableInteractionAccessibilityLabelCapture = register(name: "disableInteractionAccessibilityLabelCapture", type: .boolean)
    static let disableInteractionReferencingPropertyCapture = register(name: "disableInteractionReferencingPropertyCapture", type: .boolean)
    static let interactionHierarchyCaptureLimit = register(name: "interactionHierarchyCaptureLimit", type: .integer)
}

public extension Dictionary where Key == Option, Value == Any {

    func string(at key: Option) -> String? {
        self[key] as? String
    }

    func boolean(at key: Option) -> Bool? {
        self[key] as? Bool
    }

    func timeInterval(at key: Option) -> TimeInterval? {
        self[key] as? TimeInterval ?? integer(at: key).map(TimeInterval.init(_:))
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

struct UploaderSettings {
    var uploadInterval: TimeInterval
    var baseUrl: URL?
    var messageBatchByteLimit: Int
    var messageBatchMessageLimit: Int
    
    static let `default` = UploaderSettings(
        uploadInterval: 15,
        baseUrl: URL(string: "https://heapanalytics.com/"),
        messageBatchByteLimit: 1_000_000,
        messageBatchMessageLimit: 200
    )
}

extension UploaderSettings {
    
    init(with options: [Option: Any]) {
        
        let base = Self.default
        
        self.init(
            uploadInterval: options.timeInterval(at: .uploadInterval) ?? base.uploadInterval,
            baseUrl: options.url(at: .baseUrl) ?? base.baseUrl,
            messageBatchByteLimit: options.integer(at: .messageBatchByteLimit) ?? base.messageBatchByteLimit,
            messageBatchMessageLimit: options.integer(at: .messageBatchMessageLimit) ?? base.messageBatchMessageLimit
        )
    }
    
    static func with(_ config: (_ settings: inout Self) -> Void) -> Self {
        var instance = Self.default
        config(&instance)
        return instance
    }
}

struct FieldSettings {
    var captureAdvertiserId: Bool
    var capturePageviewTitle: Bool
    var captureInteractionText: Bool
    var captureInteractionAccessibilityLabel: Bool
    var captureInteractionReferencingProperty: Bool
    var maxInteractionNodeCount: Int
    
    static let `default` = FieldSettings(
        captureAdvertiserId: false,
        capturePageviewTitle: true,
        captureInteractionText: true,
        captureInteractionAccessibilityLabel: true,
        captureInteractionReferencingProperty: true,
        maxInteractionNodeCount: 30
    )
}

extension FieldSettings {
    
    init(with options: [Option: Any]) {
        
        let base = Self.default
        
        func negated(_ option: Option) -> Bool? {
            options.boolean(at: option).map({ !$0 })
        }
        
        self.init(
            captureAdvertiserId: options.boolean(at: .captureAdvertiserId) ?? base.captureAdvertiserId,
            capturePageviewTitle: negated(.disablePageviewTitleCapture) ?? base.capturePageviewTitle,
            captureInteractionText: negated(.disableInteractionTextCapture) ?? base.captureInteractionText,
            captureInteractionAccessibilityLabel: negated(.disableInteractionAccessibilityLabelCapture) ?? base.captureInteractionAccessibilityLabel,
            captureInteractionReferencingProperty: negated(.disableInteractionReferencingPropertyCapture) ?? base.captureInteractionReferencingProperty,
            maxInteractionNodeCount: options.integer(at: .interactionHierarchyCaptureLimit) ?? base.maxInteractionNodeCount
        )
    }
    
    static func with(_ config: (_ settings: inout Self) -> Void) -> Self {
        var instance = Self.default
        config(&instance)
        return instance
    }
}
