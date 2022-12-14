import Foundation

public enum Interaction {
    case custom(String)
    case click, touch, change
}

public struct InteractionNode {

    /// The element or component name for DOM elements, or the class name for views.
    public var nodeName: String
    
    /// The on-screen text within the element, truncated to 1024 UTF-16 code-units.
    public var nodeText: String?
    
    /// Traits that are applied to the element that can be used for filtering
    /// (e.g., individual class names on the web).
    public var nodeTraits: [String] = []

    /// The unique ID for the node in its context.
    public var id: String?

    /// The developer-defined accessibility or testing identifier.
    public var accessibilityIdentifier: String?
    
    /// The developer-defined accessibility label, truncated to 1024 UTF-16 code-units.
    public var accessibilityLabel: String?
    
    /// The name of a variable containing the node in the owning controller, if
    /// available.
    public var referencingPropertyName: String?

    /// Source-specific properties of the node that do not map to an above category.
    /// Keys limited to 512 UTF-16 code units.  Values limited to 1024 UTF-16 code units.
    public var sourceProperties: [String: HeapPropertyValue] = [:]

    /// Developer-defined attributes.
    public var attributes: [String: HeapPropertyValue] = [:]

    /// An optional representation of the bounding box with the origin in the top-left
    /// corner of the screen.
    public var boundingBox: CGRect?

    public init(nodeName: String) {
        self.nodeName = nodeName
    }
}

public protocol InteractionEventProtocol: AnyObject {

    /// The type of interaction that has taken place.
    ///
    /// This must be set for the event to be committed.
    var kind: Interaction? { get set }

    /// An optional name of the callback that was evoked by the
    /// interaction.
    var callbackName: String? { get set }

    /// The elements that are included in the autocaptured event, starting with the inner-most
    /// element.
    ///
    /// This must be set for the event to be committed.
    var nodes: [InteractionNode] { get set }

    /// Commits the event so it can be uploaded.
    ///
    /// This has no effect if the event is missing required data or has already been committed
    func commit()
}
