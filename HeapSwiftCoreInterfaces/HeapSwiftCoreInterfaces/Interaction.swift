import Foundation

public enum Interaction {
    case custom(String)
    case unspecified, click, touch, change, submit
    case builtin(Int)
}

public struct InteractionNode {

    /// The element or component name for DOM elements, or the class name for views.
    public var nodeName: String
    
    /// The on-screen text within the element, truncated to 1024 UTF-16 code-units.
    public var nodeText: String?
    
    /// A space-separated list of HTML classes, e.g. HtmlElement.className on the web.
    public var nodeHtmlClass: String?

    /// The unique ID for the node in its context.
    public var nodeId: String?
    
    /// The URL that the interacted element links to, e.g. HtmlAnchorElement.href on the
    /// web.
    public var href: String?
    
    /// The developer-defined accessibility label, truncated to 1024 UTF-16 code-units.
    public var accessibilityLabel: String?
    
    /// The name of a variable containing the node in the owning controller, if
    /// available.
    public var referencingPropertyName: String?

    /// Developer-defined attributes.
    public var attributes: [String: HeapPropertyValue] = [:]

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
    
    /// Additional source properties for the event.
    ///
    /// Property values are sanitized to strings on write to prevent unexpected mutation.
    var sourceProperties: [String: HeapPropertyValue] { get set }

    /// Commits the event so it can be uploaded.
    ///
    /// This has no effect if the event is missing required data or has already been committed
    func commit()
}
