import CoreGraphics
import HeapSwiftCoreInterfaces

class InteractionEvent: InteractionEventProtocol {
    
    private var _lock = DispatchSemaphore(value: 1)
    
    private let pendingEvent: PendingEvent
    private let fieldSettings: FieldSettings
    
    private var _needsNodes: Bool = true

    private var _kind: Interaction?
    private var _callbackName: String? = nil
    private var _nodes: [InteractionNode] = []
    private var _sourceProperties: [String: String] = [:]
    
    init(pendingEvent: PendingEvent, fieldSettings: FieldSettings) {
        self.pendingEvent = pendingEvent
        self.fieldSettings = fieldSettings
    }
    
    public var kind: Interaction? {
        get {
            _lock.wait()
            defer { _lock.signal() }
            return _kind
        }

        set {
            _lock.wait()
            defer { _lock.signal() }
            _kind = newValue
        }
    }
    
    public var callbackName: String? {
        get {
            _lock.wait()
            defer { _lock.signal() }
            return _callbackName
        }

        set {
            _lock.wait()
            defer { _lock.signal() }
            _callbackName = newValue
        }
    }
    
    public var nodes: [InteractionNode] {
        get {
            _lock.wait()
            defer { _lock.signal() }
            return _nodes
        }

        set {
            _lock.wait()
            defer { _lock.signal() }
            _nodes = newValue
            _needsNodes = false
        }
    }
    
    public var sourceProperties: [String: HeapPropertyValue] {
        get {
            _lock.wait()
            defer { _lock.signal() }
            return _sourceProperties
        }

        set {
            _lock.wait()
            defer { _lock.signal() }
            _sourceProperties = newValue.sanitized(methodName: "InteractionEvent.sourceProperties")
        }
    }
    
    func commit() {

        let kind: Interaction
        let nodes: [InteractionNode]
        
        do {
            _lock.wait()
            defer { _lock.signal() }
            guard let unwrappedKind = _kind, !_needsNodes else { return }
            kind = unwrappedKind
            nodes = _nodes
        }
        
        pendingEvent.setKind(.interaction(.with({
            $0.kind = kind.kind
            $0.nodes = nodes
                .prefix(fieldSettings.maxInteractionNodeCount)
                .map({ $0.node(with: fieldSettings) })
            $0.setIfNotNil(\.callbackName, callbackName)
            $0.sourceProperties = sourceProperties.mapValues(\.protoValue)
        })))
        
        if let firstNode = nodes.first {
            HeapLogger.shared.debug("Tracked \(kind) interaction event on node \(firstNode.nodeName).")
        } else {
            HeapLogger.shared.debug("Tracked \(kind) interaction event with no nodes.")
        }
    }
}

extension Interaction {

    var kind: EventInteraction.OneOf_Kind {
        switch self {
        case .custom(let name): return .custom(name)
        case .unspecified: return .builtin(.unspecified)
        case .click: return .builtin(.click)
        case .touch: return .builtin(.touch)
        case .change: return .builtin(.change)
        case .submit: return .builtin(.submit)
        case .builtin(let value): return .builtin(.UNRECOGNIZED(value))
            
        @unknown default:
            // This is not technically possible since we always link to the same or older versions, but we'll apply a safe default.
            return .builtin(.unspecified)
        }
    }
}

extension Interaction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .custom(let name): return "\(name) (custom)"
        case .unspecified: return "unspecified"
        case .click: return "click"
        case .touch: return "touch"
        case .change: return "change"
        case .submit: return "submit"
        case .builtin(let value): return "\(value) (unknown built-in)"
            
        @unknown default:
            // This is not technically possible since we always link to the same or older versions, but we'll apply a safe default.
            return "unknown type"
        }
    }
}

extension InteractionNode {

    func node(with fieldSettings: FieldSettings) -> ElementNode {
        .with {
            $0.nodeName = nodeName
            $0.setIfNotNil(\.nodeText, nodeText?.trimmed?.truncated(toUtf16Count: 64).result.trimmed, andTrue: fieldSettings.captureInteractionText)
            $0.setIfNotNil(\.nodeID, nodeId)
            $0.setIfNotNil(\.nodeHtmlClass, nodeHtmlClass)
            $0.setIfNotNil(\.href, href)
            $0.setIfNotNil(\.accessibilityLabel, accessibilityLabel?.trimmed?.truncated(toUtf16Count: 64).result.trimmed, andTrue: fieldSettings.captureInteractionAccessibilityLabel)
            $0.setIfNotNil(\.referencingPropertyName, referencingPropertyName, andTrue: fieldSettings.captureInteractionReferencingProperty)
            $0.attributes = attributes.mapValues(\.protoValue)
        }
    }
}
