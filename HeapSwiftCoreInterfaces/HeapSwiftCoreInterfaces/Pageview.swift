import Foundation

/// An object representing a pageview returned by `Heap.trackPageview`.
///
/// This object can be passed in to `track` and `trackInteraction` to attribute that event to a
/// specific pageview.  It is also used in `Source` and `RuntimeBridge` delegate methods to resolve
/// pageviews from a active source or to reissue pageviews from expired sessions.
open class Pageview {
    
    /// A special case for `Pageview.none`, indicating that an event should not be associated with
    /// any tracked pageviews.
    public let isNone: Bool

    /// A unique string representing the session that the pageview originated in.
    public let sessionId: String
    
    /// The properties provided in the `trackPageview` call.
    ///
    /// These properties are passed to the server and available for analysis in Heap.
    public let properties: PageviewProperties
    
    /// The timestamp of the pageview or `nil` if `isNone` is true.
    public let timestamp: Date?
    
    /// The source info provided in the `trackPageview` call.
    public let sourceInfo: SourceInfo?
    
    /// An arbitrary object used to contain local information about the pageview.
    ///
    /// One usecase for this object would be to store a weak reference to the `UIViewController`
    /// that generated the pageview.  When the source that provided the pageview receives a
    /// `reissuePageview` call, it could look at `userInfo` for the pageview and use that to
    /// issue or a new one.
    ///
    /// For example:
    ///
    /// ```
    /// struct UserInfo {
    ///     weak var viewController: UIViewController?
    /// }
    ///
    /// let pageview = Heap.shared.trackPageview(
    ///     properties,
    ///     userInfo: UserInfo(viewController: self)
    /// )
    ///
    /// ...
    ///
    /// if let viewController = (pageview.userInfo as? UserInfo)?.viewController {
    ///     ...
    /// }
    /// ```
    public let userInfo: Any?
    
    private init() {
        isNone = true
        sessionId = ""
        properties = .init()
        timestamp = nil
        sourceInfo = nil
        userInfo = nil
    }
    
    @available(*, deprecated, renamed: "init(sessionId:properties:timestamp:sourceInfo:userInfo:)", message: "More properties have been added to this type. Use the new initializer.")
    public init(sessionId: String, properties: PageviewProperties, userInfo: Any?) {
        isNone = false
        self.sessionId = sessionId
        self.properties = properties
        self.timestamp = nil
        self.sourceInfo = nil
        self.userInfo = userInfo
    }
    
    /// Initializes a new Pageview.
    ///
    /// This method should not be called directly and pageviews created with this initializer will
    /// be ignored.  Instead, use `Heap.trackPageview` to create a pageview.
    public init(sessionId: String, properties: PageviewProperties, timestamp: Date, sourceInfo: SourceInfo?, userInfo: Any?) {
        isNone = false
        self.sessionId = sessionId
        self.properties = properties
        self.timestamp = timestamp
        self.sourceInfo = sourceInfo
        self.userInfo = userInfo
    }
    
    /// A singleton `Pageview` indicating that the event should not be attributed to a pageview.
    ///
    /// When passed into `track` or `trackInteraction`, the SDK will resolve this to an empty
    /// "unattributed" pageview that occurred at the start of the session.
    public static let none: Pageview = .init()
}

public struct PageviewProperties {
    
    /// The fixed name of the component or class that generated this object, if one exists.
    ///
    /// In MVC applications, this would typically be the class name of the controller, e.g., a
    /// `UIViewController` or an Android `Activity`.  On platforms like React Native, this could be
    /// the `displayName` of the React Navigation screen.  On web app, it could be the server-side
    /// route name, were one provided.
    public var componentOrClassName: String? = nil
    
    /// The user-visible title of the page, if one exists.
    ///
    /// This will typically be the title that appears at the top of the page in the navigation bar.
    /// On iOS, this could be `navigationItem.title`.  On the web, it could be `document.title`.
    public var title: String? = nil
    
    /// The URL that corresponds to the pageview, if one exists.
    ///
    /// This is typically a web-only feature, corresponding to the URL of the page in the browser.
    /// It could, however, also refer to the URL of an active `NSUserActivity` or `Intent` for apps
    /// that have them.
    public var url: URL? = nil
    
    /// A dictionary of other non-schematized properties of the pageview, generated by the source
    /// SDK.
    ///
    /// This could be used for properties that are specific to a single platform or have been
    /// recently introduced but not added as first-class properties.
    public var sourceProperties: [String: HeapPropertyValue] = [:]
    
    /// A dictionary of custom properties attached to the pageview.
    ///
    /// The source SDK is responsible for determining a mechanism for setting these properties.
    public var properties: [String: HeapPropertyValue] = [:]
    
    /// Creates an empty `Pageview`.
    init() {}
    
    /// A shorthand constructor for `Pageview`.
    ///
    /// This can be used with a closure to configure a pageview inline with `trackPageview`:
    ///
    /// ```
    /// Heap.shared.trackPageview(.with({
    ///     $0.componentOrClassName = String(describing: type(of: self))
    ///     $0.title = self.navigationItem.title
    /// }))
    /// ```
    public static func with(
      _ populator: (inout Self) throws -> ()
    ) rethrows -> Self {
      var message = Self()
      try populator(&message)
      return message
    }
}
