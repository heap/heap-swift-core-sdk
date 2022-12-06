import CoreGraphics

class InteractionEvent: InteractionEventProtocol {
    
    private var _lock = DispatchSemaphore(value: 1)
    
    private let pendingEvent: PendingEvent
    private var _needsNodes: Bool = true

    private var _kind: Interaction?
    private var _callbackName: String? = nil
    private var _nodes: [InteractionNode] = []
    
    init(pendingEvent: PendingEvent) {
        self.pendingEvent = pendingEvent
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
    
    func commit() {

            let kind: Interaction
            do {
                _lock.wait()
                defer { _lock.signal() }
                guard let unwrappedKind = _kind, !_needsNodes else { return }
                kind = unwrappedKind
            }

            pendingEvent.setKind(.interaction(.with({
                $0.kind = kind.kind
                $0.nodes = _nodes.map(\.node)
                $0.setIfNotNil(\.callbackName, callbackName)
            })))
        }
}

extension Interaction {

    var kind: Event.Interaction.OneOf_Kind {

        switch self {
        case .custom(let name): return .custom(name)
        case .click: return .builtin(.click)
        case .touch: return .builtin(.touch)
        case .change: return .builtin(.change)
        }
    }
}

extension InteractionNode {

    var node: Node {
        .with {
            $0.nodeName = nodeName
            $0.setIfNotNil(\.nodeText, nodeText)
            $0.setIfNotNil(\.id, id)
            $0.setIfNotNil(\.accessibilityIdentifier, accessibilityIdentifier)
            $0.setIfNotNil(\.accessibilityLabel, accessibilityLabel)
            $0.sourceProperties = sourceProperties.mapValues(\.protoValue)
            $0.attributes = attributes.mapValues(\.protoValue)
            if let boundingBox = boundingBox {
                $0.boundingBox = boundingBox.boundingBox
            }
        }
    }
}

extension CGRect {
    var boundingBox: BoundingBox {
        var boundingBox = BoundingBox()
        boundingBox.position.x = Int32(self.minX)
        boundingBox.position.y = Int32(self.minY)
        boundingBox.size.width = UInt32(self.width)
        boundingBox.size.height = UInt32(self.height)
        return boundingBox
    }
}

