import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

class NotificationManager {
    
    let delegateManager: DelegateManager
    
    init(_ delegateManager: DelegateManager) {
        self.delegateManager = delegateManager
    }
    
    func addForegroundAndBackgroundObservers() {
        
        // Prevent addition of multiple observers when startRecording is called multiple times.
        removeForegroundAndBackgroundObservers()
        
        let notificationCenter = NotificationCenter.default
        
#if canImport(UIKit) && !os(watchOS)
        
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)),
                                       name: UIApplication.willEnterForegroundNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)),
                                       name: UIApplication.didEnterBackgroundNotification, object: nil)

        if #available(iOS 13.0, tvOS 13.0, *) {
            
            notificationCenter.addObserver(self, selector: #selector(windowSceneDidEnterForeground(_:)),
                name: UIScene.willEnterForegroundNotification, object: nil)
            
            notificationCenter.addObserver(self, selector: #selector(windowSceneDidEnterBackground(_:)),
                name: UIScene.didEnterBackgroundNotification, object: nil)
        }
                
#elseif canImport(AppKit)
        
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)),
                                       name: NSApplication.willBecomeActiveNotification, object: nil)
            
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)),
                                       name: NSApplication.didResignActiveNotification, object: nil)
        
        
        notificationCenter.addObserver(self, selector: #selector(windowDidBecomeMain(_:)),
                                       name: NSWindow.didBecomeMainNotification, object: nil)
            
        notificationCenter.addObserver(self, selector: #selector(windowDidResignMain(_:)),
                                       name: NSWindow.didResignMainNotification, object: nil)
        

#elseif os(watchOS)
        
        if #available(watchOS 7.0, *) {
            
            notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)),
                                           name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
            
            notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)),
                                           name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
            
        }
#else
#warning ("Unsupported platform will not have foreground/background notification.")
#endif
    }
    
    func removeForegroundAndBackgroundObservers() {
        
        let notificationCenter = NotificationCenter.default
        
#if canImport(UIKit) && !os(watchOS)
        
        notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)

        if #available(iOS 13.0, tvOS 13.0, *) {
            notificationCenter.removeObserver(self, name: UIScene.willEnterForegroundNotification, object: nil)
            notificationCenter.removeObserver(self, name: UIScene.didEnterBackgroundNotification, object: nil)
        }
                
#elseif canImport(AppKit)
        
        notificationCenter.removeObserver(self, name: NSApplication.willBecomeActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        
        notificationCenter.removeObserver(self, name: NSWindow.didBecomeMainNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSWindow.didResignMainNotification, object: nil)
          
#elseif os(watchOS)
        
        if #available(watchOS 7.0, *) {
            
            notificationCenter.removeObserver(self, name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
            notificationCenter.removeObserver(self, name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
        }
        
#endif
    }
    
    
    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        
        HeapLogger.shared.logDebug("applicationWillEnterForeground")
        
        let (sources, _, bridges) = delegateManager.current
        let timestamp = Date()
        for (sourceName, source) in sources {
            source.applicationDidEnterForeground(timestamp: timestamp) {
                HeapLogger.shared.logDebug("Source [\(sourceName)] has completed all work related to the applicationDidEnterForeground notification.")
            }
        }

        for bridge in bridges {
            bridge.applicationDidEnterForeground(timestamp: timestamp) {
                HeapLogger.shared.logDebug("Bridge of type [\(type(of: bridge))] has completed all work related to the applicationDidEnterForeground notification.")
            }
        }
    }
    
    @objc func applicationDidEnterBackground(_ notification: NSNotification) {
        
        HeapLogger.shared.logDebug("applicationDidEnterBackground")

        let (sources, _, bridges) = delegateManager.current
        let timestamp = Date()
        for (sourceName, source) in sources {
            source.applicationDidEnterBackground(timestamp: timestamp) {
                HeapLogger.shared.logDebug("Source [\(sourceName)] has completed all work related to the applicationDidEnterBackground notification.")
            }
        }
        
        for bridge in bridges {
            bridge.applicationDidEnterBackground(timestamp: timestamp) {
                HeapLogger.shared.logDebug("Bridge of type [\(type(of: bridge))] has completed all work related to the applicationDidEnterBackground notification.")
            }
        }
    }
    
#if canImport(UIKit) && !os(watchOS)
    @available(iOS 13.0, tvOS 13.0, *)
    @objc func windowSceneDidEnterForeground(_ notification: NSNotification) {
        
        guard let scene = notification.object as? UIWindowScene else { return }
        HeapLogger.shared.logDebug("windowSceneDidEnterForeground: \(scene)")
        
        let (sources, _, bridges) = delegateManager.current
        let timestamp = Date()
        for (sourceName, source) in sources {
            source.windowSceneDidEnterForeground(scene: scene, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Source [\(sourceName)] has completed all work related to the windowSceneDidEnterForeground notification.")
            }
        }
        
        for bridge in bridges {
            bridge.windowSceneDidEnterForeground(scene: scene, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Bridge of type [\(type(of: bridge))] has completed all work related to the windowSceneDidEnterForeground notification.")
            }
        }
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    @objc func windowSceneDidEnterBackground(_ notification: NSNotification) {
        
        guard let scene = notification.object as? UIWindowScene else { return }
        HeapLogger.shared.logDebug("windowSceneDidEnterBackground: \(scene)")
        
        let (sources, _, bridges) = delegateManager.current
        let timestamp = Date()
        for (sourceName, source) in sources {
            source.windowSceneDidEnterBackground(scene: scene, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Source [\(sourceName)] has completed all work related to the windowSceneDidEnterBackground notification.")
            }
        }
        
        for bridge in bridges {
            bridge.windowSceneDidEnterBackground(scene: scene, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Bridge of type [\(type(of: bridge))] has completed all work related to the windowSceneDidEnterBackground notification.")
            }
        }
    }
#elseif canImport(AppKit)
    
    @objc func windowDidBecomeMain(_ notification: NSNotification) {
        
        guard let window = notification.object as? NSWindow else { return }
        HeapLogger.shared.logDebug("Window Become Main: [\(window)]")
            
        let (sources, _, bridges) = delegateManager.current
        let timestamp = Date()
        for (sourceName, source) in sources {
            source.windowDidBecomeMain(window: window, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Source [\(sourceName)] has completed all work related to the windowDidBecomeMain notification.")
            }
        }
        
        for bridge in bridges {
            bridge.windowDidBecomeMain(window: window, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Bridge of type [\(type(of: bridge))] has completed all work related to the windowDidBecomeMain notification.")
            }
        }
    }
    
    @objc func windowDidResignMain(_ notification: NSNotification) {
        
        guard let window = notification.object as? NSWindow else { return }
        HeapLogger.shared.logDebug("Window Resigned Main: [\(window)]")
        
        let (sources, _, bridges) = delegateManager.current
        let timestamp = Date()
        for (sourceName, source) in sources {
            source.windowDidResignMain(window: window, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Source [\(sourceName)] has completed all work related to the windowDidResignMain notification.")
            }
        }
        
        for bridge in bridges {
            bridge.windowDidResignMain(window: window, timestamp: timestamp) {
                HeapLogger.shared.logDebug("Bridge of type [\(type(of: bridge))] has completed all work related to the windowDidResignMain notification.")
            }
        }
    }
    
#endif
}
    
