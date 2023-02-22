import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A Source SDK delegate, allowing autocapture SDKs to respond to Heap SDK events.
public protocol Source: AnyObject {
    
    /// The name of the Source SDK as exposed in `sourceInfo` parameters.
    ///
    /// This value should be consistent across releases of the source SDK.
    var name: String { get }
    
    /// The version of the source SDK as exposed in `sourceInfo` parameters.
    var version: String { get }
    
    /// Notifies the Source SDK that recording has started.
    ///
    /// The Source SDK should perform any configuration that is appropriate given the supplied
    /// `options`, in preparation for whatever work it may be conducting.  Once configuration is
    /// complete, it must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - options:  The sanitized list of options passed into `Heap.startRecording`.
    ///   - complete: A callback indicating that the source has completed all work related to the
    ///               notification.
    func didStartRecording(options: [Option: Any], complete: @escaping () -> Void)
    
    /// Notifies the Source SDK that recording has stopped.
    ///
    /// This method only fires if `Heap.stopRecording` has been called. The Source SDK should alter
    /// its behavior to minimize the amount of work it's performing and should stop sending
    /// autocaptured events if applicable.
    ///
    /// - Parameter complete: A callback indicating that the source has completed all work related
    ///                       to the notification.
    func didStopRecording(complete: @escaping () -> Void)
    
    /// Notifies the Source SDK that a new session has started.
    ///
    /// The Source SDK should perform any appropriate cleanup of data from the previous session.
    /// If the app is foregrounded, the Source SDK should issue pageviews as appropriate for
    /// visible page contexts.
    ///
    /// - Parameters:
    ///   - sessionId:    The `sessionId` that will be sent to Heap alongside all messages.  This
    ///                   can be used to validate if existing `Pageview` objects are part of the
    ///                   current session.
    ///   - timestamp:    The date at which the session started.  If events are generated as a
    ///                   result of the session starting, this timestamp may be used in generating
    ///                   them.
    ///   - foregrounded: A boolean indicating whether or not the app is foregrounded. If true, the
    ///                   session started after the app had foregrounded and there will not be
    ///                   subsequent `applicationDidEnterForeground` or
    ///                   `windowSceneDidEnterForeground` notifications.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func sessionDidStart(sessionId: String, timestamp: Date, foregrounded: Bool, complete: @escaping () -> Void)
    
    /// Notifies the Source SDK that the application has entered the foreground.
    ///
    /// The Source SDK may choose to respond by issuing new pageviews for pages that are visible,
    /// or by starting up pageview reporting.
    ///
    /// - Parameters:
    ///   - timestamp:    The date at which the application entered the foreground.  If events are
    ///                   generated as a result of the scene becoming visibile, this timestamp may
    ///                   be used in generating them.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func applicationDidEnterForeground(timestamp: Date, complete: @escaping () -> Void)
    
    /// Notifies the Source SDK that the application has entered the foreground.
    ///
    /// The Source SDK may choose to respond by suspending pageview tracking.
    ///
    /// - Parameters:
    ///   - timestamp:    The date at which the application entered the background.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func applicationDidEnterBackground(timestamp: Date, complete: @escaping () -> Void)
    
#if canImport(UIKit) && !os(watchOS)
    /// Notifies the Source SDK that a window scene has entered the foreground.
    ///
    /// The Source SDK may choose to respond by issuing new pageviews for pages that are visible,
    /// or by starting up pageview reporting for the scene.
    ///
    /// - Parameters:
    ///   - scene:        The window scene that entered the foreground.
    ///   - timestamp:    The date at which the window scene entered the foreground.  If events are
    ///                   generated as a result of the scene becoming visibile, this timestamp may
    ///                   be used in generating them.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterForeground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void)
    
    /// Notifies the Source SDK that the a window scene has entered the foreground.
    ///
    /// The Source SDK may choose to respond by suspending pageview tracking for that scene.
    ///
    /// - Parameters:
    ///   - scene:        The window scene that entered the background.
    ///   - timestamp:    The date at which the window scene entered the background.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterBackground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void)
    
#elseif canImport(AppKit)
    /// Notifies the Source SDK that an NSWindow did become main.
    ///
    /// The Source SDK may choose to respond by issuing new pageviews for pages that are visible,
    /// or by starting up pageview reporting for the scene.
    ///
    /// - Parameters:
    ///   - window:       The NSWindow that became main.
    ///   - timestamp:    The date at which the window scene entered the foreground.  If events are
    ///                   generated as a result of the scene becoming visibile, this timestamp may
    ///                   be used in generating them.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func windowDidBecomeMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void)
    
    /// Notifies the Source SDK that an NSWindow did resign main.
    ///
    /// The Source SDK may choose to respond by suspending pageview tracking for that scene.
    ///
    /// - Parameters:
    ///   - window:       The NSWindow that resigned main.
    ///   - timestamp:    The date at which the window scene entered the background.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func windowDidResignMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void)
#endif
    
    /// Requests the active pageview from the Source SDK, for use in an event that is being
    /// tracked.
    ///
    /// This method will be called if an event originates from the Source SDK and doesn't provide
    /// a pageview, or if the Source SDK is the default source and the event didn't provide a
    /// pageview.
    ///
    /// The Source SDK should attempt to find an active pageview based on what is active on the
    /// display, in the context of the Source SDK.  If an appropriate pageview if found and in the
    /// same session as provided, that pageview shouldb e returned.  If the pageview not found or
    /// is from a different session, the source may use `trackPageview` to create a new pageview
    /// and send that to the completion callback.  Otherwise, replying with `nil` wil allow the
    /// Heap SDK to assign a fallback pageview.
    ///
    /// - Parameters:
    ///   - sessionId:    The sessionId for the current session.
    ///   - timestamp:    The date at which the event was being tracked, resulting in this
    ///                   notification.  If a pageview is tracked as a result of this call, this
    ///                   value should be used for its timestamp.
    ///   - complete:     A callback for asynchronously providing the resulting pageview.  This may
    ///                   be called from any thread.
    func activePageview(sessionId: String, timestamp: Date, complete: @escaping (_ pageview: Pageview?) -> Void)
    
    /// Requests a new instance of pageview from the Source SDK, for use in an event that is being
    /// tracked.
    ///
    /// This method will be called if an event is being tracked with a pageview that originated
    /// from the source, but the pageview was created in a previous, expired session.  This can
    /// happen if an app has sat idle for a period of time and an interaction has issued a
    /// pageview.
    ///
    /// It is possible that the pageview will have already been reissued as a result of a
    /// `sessionDidStart` notification.  If so, the previously reissued pageview should be reused
    /// in this call, rather than through a second reissuing.
    ///
    /// The expected behavior is that the Source Library will use `pageview.userInfo` to find the
    /// original source of the pageview, e.g. a `UIViewController`.  If that source has a
    /// `pageview` associated with it with the same session ID as provided, it should be used.
    /// Otherwise, the source should use `trackPageview` to create a new pageview, and send that to
    /// the completion callback.
    ///
    /// - Parameters:
    ///   - pageview:     The pageview that was passed to the event being tracked, resulting in
    ///                   this notification.
    ///   - sessionId:    The sessionId for the current session.
    ///   - timestamp:    The date at which the event was being tracked, resulting in this
    ///                   notification.  If a pageview is tracked as a result of this call, this
    ///                   value should be used for its timestamp.
    ///   - complete:     A callback for asynchronously providing the resulting pageview.  This may
    ///                   be called from any thread.
    func reissuePageview(_ pageview: Pageview, sessionId: String, timestamp: Date, complete: @escaping (_ pageview: Pageview?) -> Void)
}

// Default implementations of platform-specific methods to make it optional.
#if canImport(UIKit) && !os(watchOS)
public extension Source {
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterForeground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void) {
        complete()
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterBackground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void) {
        complete()
    }
}
#elseif canImport(AppKit)
public extension Source {
    func windowDidBecomeMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void) {
        complete()
    }
    
    func windowDidResignMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void) {
        complete()
    }
}
#endif
