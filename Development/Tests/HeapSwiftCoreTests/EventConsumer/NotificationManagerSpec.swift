import XCTest
import Quick
import Nimble
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class NotificationManagerSpec: HeapSpec {
    
    override func spec() {
        
        var delegateManager: DelegateManager!
        var notificationManager: NotificationManager!
        var sourceA1: CountingSource!
        var bridge1: CountingRuntimeBridge!
       
        beforeEach {
            
            delegateManager = DelegateManager()
            notificationManager = NotificationManager(delegateManager)
            notificationManager.addForegroundAndBackgroundObservers()
            
            sourceA1 = CountingSource(name: "A", version: "1")
            bridge1 = CountingRuntimeBridge()
            
            let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
            delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: currentState)
            delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: currentState)
            
            sourceA1.calls.removeAll()
            bridge1.calls.removeAll()
            
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
            notificationManager.removeForegroundAndBackgroundObservers()
        }

        
        context("listeners have been added") {
                
            it("calls applicationDidEnterForeground on UIApplication.willEnterForegroundNotification post") {
                
#if canImport(UIKit) && !os(watchOS)
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
#elseif canImport(AppKit)
                NotificationCenter.default.post(name: NSApplication.willBecomeActiveNotification, object: nil)
#elseif os(watchOS)
                NotificationCenter.default.post(name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
#endif
                
                expect(sourceA1.calls).toEventually(equal([
                    .applicationDidEnterForeground,
                ]))
                
                expect(bridge1.calls).toEventually(equal([
                    .applicationDidEnterForeground,
                ]))
            }
            
            it("calls applicationDidEnterBackground on UIApplication.didEnterBackgroundNotification post") {
                
#if canImport(UIKit) && !os(watchOS)
                NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
#elseif canImport(AppKit)
                NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)
#elseif os(watchOS)
                NotificationCenter.default.post(name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
#endif
                
                expect(sourceA1.calls).to(equal([
                    .applicationDidEnterBackground,
                ]))
                
                expect(bridge1.calls).to(equal([
                    .applicationDidEnterBackground,
                ]))
            }
            
#if canImport(UIKit)
            if #available(iOS 13.0, *) {
                
                // UIWindowScene lacks initializers necessary to mock it
                // TODO: Use integration tests to cover UIScene.didEnterBackgroundNotification
                xit("calls windowSceneDidEnterForeground on UIScene.willEnterForegroundNotification post") {

                    expect(sourceA1.calls).to(equal([
                        .windowSceneDidEnterForeground,
                    ]))
                    
                    expect(bridge1.calls).to(equal([
                        .windowSceneDidEnterForeground,
                    ]))
                }
                
                // UIWindowScene lacks initializers necessary to mock it
                // TODO: Use integration tests to cover UIScene.didEnterBackgroundNotification
                xit("calls windowSceneDidEnterBackground on UIScene.didEnterBackgroundNotification post") {
                          
                    expect(sourceA1.calls).to(equal([
                        .windowSceneDidEnterBackground,
                    ]))
                    
                    expect(bridge1.calls).to(equal([
                        .windowSceneDidEnterBackground,
                    ]))
                }
            }
#elseif canImport(AppKit)
            
            it("calls windowSceneDidEnterBackground on NSWindow.didBecomeMainNotification post") {
                
                NotificationCenter.default.post(name: NSWindow.didBecomeMainNotification, object: NSWindow())
                
                expect(sourceA1.calls).to(equal([
                    .windowDidBecomeMain,
                ]))
                
                expect(bridge1.calls).to(equal([
                    .windowDidBecomeMain,
                ]))
            }
            
            it("calls windowDidResignMain on NSWindow.didResignMainNotification post") {
                
                NotificationCenter.default.post(name: NSWindow.didResignMainNotification, object: NSWindow())
                
                expect(sourceA1.calls).to(equal([
                    .windowDidResignMain,
                ]))
                
                expect(bridge1.calls).to(equal([
                    .windowDidResignMain,
                ]))
            }
#endif

        }
        
        context("listeners have been added and removed") {
            
            it("does not make foreground or background calls when observers are removed") {
                
                notificationManager.removeForegroundAndBackgroundObservers()
                
#if canImport(UIKit) && !os(watchOS)
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
#elseif canImport(AppKit)
                NotificationCenter.default.post(name: NSApplication.willBecomeActiveNotification, object: nil)
                NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: nil)
#elseif os(watchOS)
                NotificationCenter.default.post(name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
                NotificationCenter.default.post(name: WKExtension.applicationDidEnterBackgroundNotification, object: nil)
#endif

                expect(sourceA1.calls).to(beEmpty())
                expect(bridge1.calls).to(beEmpty())
            }
        }
        
        context("addForegroundAndBackgroundObservers has been called twice") {
            
            it("does not add multiple observers") {
                
                notificationManager.addForegroundAndBackgroundObservers()
                
#if canImport(UIKit) && !os(watchOS)
                NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
#elseif canImport(AppKit)
                NotificationCenter.default.post(name: NSApplication.willBecomeActiveNotification, object: nil)
#elseif os(watchOS)
                NotificationCenter.default.post(name: WKExtension.applicationWillEnterForegroundNotification, object: nil)
#endif

                expect(sourceA1.calls).toEventually(equal([
                    .applicationDidEnterForeground
                ]))
                
                expect(bridge1.calls).toEventually(equal([
                    .applicationDidEnterForeground
                ]))
            }
        }
    }
}
