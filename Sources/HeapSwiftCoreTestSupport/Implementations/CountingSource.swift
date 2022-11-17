import Foundation
import HeapSwiftCore
import Nimble

#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum DelegateCall: Equatable {
    case didStartRecording
    case didStopRecording
    case sessionDidStart
    case applicationDidEnterForeground
    case applicationDidEnterBackground
    case windowSceneDidEnterForeground
    case windowSceneDidEnterBackground
    case windowDidBecomeMain
    case windowDidResignMain
    case activePageview
    case reissuePageview

}

class CountingSource: NSObject, Source {
    
    let name: String
    let version: String
    
    var calls: [DelegateCall] = []
    
    init(name: String, version: String) {
        self.name = name
        self.version = version
    }
    
    
    func didStartRecording(options: [HeapSwiftCore.Option : Any], complete: @escaping () -> Void) {
        calls.append(.didStartRecording)
        complete()
    }
    
    func didStopRecording(complete: @escaping () -> Void) {
        calls.append(.didStopRecording)
        complete()
    }
    
    func sessionDidStart(sessionId: String, timestamp: Date, foregrounded: Bool, complete: @escaping () -> Void) {
        calls.append(.sessionDidStart)
        complete()
    }
    
    func applicationDidEnterForeground(timestamp: Date, complete: @escaping () -> Void) {
        calls.append(.applicationDidEnterForeground)
        complete()
    }
    
    func applicationDidEnterBackground(timestamp: Date, complete: @escaping () -> Void) {
        calls.append(.applicationDidEnterBackground)
        complete()
    }
    
#if canImport(UIKit) && !os(watchOS)
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterForeground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void) {
        calls.append(.windowSceneDidEnterForeground)
        complete()
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    func windowSceneDidEnterBackground(scene: UIWindowScene, timestamp: Date, complete: @escaping () -> Void) {
        calls.append(.windowSceneDidEnterBackground)
        complete()
    }
#elseif canImport(AppKit)
    func windowDidBecomeMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void) {
        calls.append(.windowDidBecomeMain)
        complete()
    }
    
    func windowDidResignMain(window: NSWindow, timestamp: Date, complete: @escaping () -> Void) {
        calls.append(.windowDidResignMain)
        complete()
    }
#endif
    
    func activePageview(sessionId: String, timestamp: Date, complete: @escaping (HeapSwiftCore.Pageview?) -> Void) {
        calls.append(.activePageview)

        expect(self.activePageviewCallback).to(beNil(), description: "activePageview was called while a pending call was waiting.  Resolve this with activePageviewCallback.")
        
        activePageviewCallback?(nil)
        activePageviewCallback = complete
    }
    
    private var activePageviewCallback: ((Pageview?) -> Void)?
    
    func resolveActivePageview(_ pageview: Pageview?) {
        expect(self.activePageviewCallback).notTo(beNil(), description: "activePageviewCallback was called even though it wasn't requested with activePageview.")
        
        activePageviewCallback?(pageview)
        activePageviewCallback = nil
    }
    
    func reissuePageview(_ pageview: HeapSwiftCore.Pageview, sessionId: String, timestamp: Date, complete: @escaping (HeapSwiftCore.Pageview?) -> Void) {
        calls.append(.reissuePageview)
        
        expect(self.reissuePageviewCallback).to(beNil(), description: "reissuePageview was called while a pending call was waiting.  Resolve this with resolveReissuePageview.")
        
        reissuePageviewCallback?(nil)
        reissuePageviewCallback = complete
    }
    
    private var reissuePageviewCallback: ((Pageview?) -> Void)?
    
    func resolveReissuePageview(_ pageview: Pageview?) {
        expect(self.reissuePageviewCallback).notTo(beNil(), description: "resolveReissuePageview was called even though it wasn't requested with reissuePageview.")
        
        reissuePageviewCallback?(pageview)
        reissuePageviewCallback = nil
    }
}
