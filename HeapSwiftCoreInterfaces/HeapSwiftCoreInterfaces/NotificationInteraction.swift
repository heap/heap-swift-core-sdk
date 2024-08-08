import Foundation

public enum NotificationInteractionSource {
    case unknown
    case pushService
    case geofence
    case interval
    case calendar
}

public struct NotificationInteractionProperties {
    
    /// The notification source.
    public var source: NotificationInteractionSource = .unknown
    
    /// The title text for the notification.
    public var titleText: String? = nil
    
    /// The body text for the notification.
    public var bodyText: String? = nil
    
    /// The category or channel for the notification.
    public var category: String? = nil
    
    /// The action the user tapped, if any.
    public var action: String? = nil
    
    /// The component that responded to the notification, if known.
    public var componentOrClassName: String? = nil
    
    /// Creates an empty `NotificationInteractionProperties`.
    public init() {}
    
    /// A shorthand constructor for `NotificationInteractionProperties`.
    ///
    /// This can be used with a closure to configure a pageview inline with `trackNotificationInteraction`:
    ///
    /// ```
    /// Heap.shared.trackNotificationInteraction(.with({
    ///     $0.category = request.content.categoryIdentifier
    ///     $0.action = response.actionIdentifier
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
