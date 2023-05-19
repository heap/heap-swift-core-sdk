import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A runtime bridge delegate, allowing non-native runtimes to forward events to Source SDK
/// implementations that they manage.
public protocol RuntimeBridge: AnyObject {
    
    /// Notifies the runtime bridge that recording has started.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that recording has started.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - options:  The sanitized list of options passed into `Heap.startRecording`.
    ///   - complete: A callback indicating that the all sources have completed all work related to
    ///               the notification.
    func didStartRecording(options: [Option: Any], complete: @escaping () -> Void)
    
    /// Notifies the runtime bridge that recording has stopped.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that recording has stopped.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameter complete: A callback indicating that the source has completed all work related
    ///                       to the notification.
    func didStopRecording(complete: @escaping () -> Void)
    
    /// Notifies the runtime bridge that a new session has started.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that a session has started.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - sessionId:    The `sessionId` that will be sent to Heap alongside all messages.
    ///   - timestamp:    The date at which the session started.
    ///   - foregrounded: A boolean indicating whether or not the app is foregrounded.
    ///   - complete:     A callback indicating that the all sources have completed all work
    ///                   related to the notification.
    func sessionDidStart(sessionId: String, timestamp: Date, foregrounded: Bool, complete: @escaping () -> Void)
    
    /// Notifies the runtime bridge that the application has entered the foreground.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that the application has entered the foreground.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - timestamp:    The date at which the application entered the foreground.
    ///   - complete:     A callback indicating that the all sources have completed all work
    ///                   related to the notification.
    func applicationDidEnterForeground(timestamp: Date, complete: @escaping () -> Void)
    
    /// Notifies the runtime bridge that the application has entered the background.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that the application has entered the background.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - timestamp:    The date at which the application entered the background.
    ///   - complete:     A callback indicating that the all sources have completed all work
    ///                   related to the notification.
    func applicationDidEnterBackground(timestamp: Date, complete: @escaping () -> Void)
    
#if canImport(UIKit) && !os(watchOS)
    /// Notifies the runtime bridge that a window scene has entered the foreground.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that the window scene has entered the foreground.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - scene:        The window scene that entered the foreground.
    ///   - timestamp:    The date at which the window scene entered the foreground.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterForeground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void)
    
    /// Notifies the runtime bridge that a window scene has entered the background.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that the window scene has entered the background.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - scene:        The window scene that entered the background.
    ///   - timestamp:    The date at which the window scene entered the background.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterBackground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void)

#elseif canImport(AppKit)
    
    /// Notifies the runtime bridge that an NSWindow did become main.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that an NSWindow has become main.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - window:       The window scene that entered the background.
    ///   - timestamp:    The date at which the window scene entered the background.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func windowDidBecomeMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void)
    
    /// Notifies the runtime bridge that an NSWindow did resign main.
    ///
    /// The runtime bridge should use this notification to notify any of its `Source`
    /// implementations that an NSWindow has resigned main.
    ///
    /// When all `Source` implementations have called their `complete` callbacks, this method
    /// must call `complete` so the Heap SDK is aware that the source is running.
    ///
    /// - Parameters:
    ///   - window:        The window scene that entered the background.
    ///   - timestamp:    The date at which the window scene entered the background.
    ///   - complete:     A callback indicating that the source has completed all work related to
    ///                   the notification.
    func windowDidResignMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void)
#endif

    /// Requests a new instance of pageview from the runtime bridge, for use in an event that is
    /// being tracked.
    ///
    /// This method will be called if an event is being tracked with a pageview that originated
    /// from the bridge, but the pageview was created in a previous, expired session.  This can
    /// happen if an app has sat idle for a period of time and an interaction has issued a
    /// pageview.
    ///
    /// The runtime bridge should use information stored in `pageview.userInfo` to identify the
    /// pageview that exists in the bridge runtime.  When found, it should request a pageview from
    /// that source. If the pageview or source cannot be found in the bridge runtime, it must call
    /// `complete` so the Heap SDK can send its event.
    ///
    /// - Parameters:
    ///   - pageview:     The pageview that was passed to the event being tracked, resulting in
    ///                   this notification.
    ///   - sessionId:    The sessionId for the current session.
    ///   - timestamp:    The date at which the event was being tracked, resulting in this
    ///                   notification.
    ///   - complete:     A callback for asynchronously providing the resulting pageview.  This may
    ///                   be called from any thread.
    func reissuePageview(_ pageview: Pageview, sessionId: String, timestamp: Date, complete: @escaping (_ pageview: Pageview?) -> Void)
}

// Default implementations of platform-specific methods to make it optional.
#if canImport(UIKit) && !os(watchOS)
public extension RuntimeBridge {
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
public extension RuntimeBridge {
    func windowDidBecomeMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void) {
        complete()
    }
    
    func windowDidResignMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void) {
        complete()
    }
}
#endif
