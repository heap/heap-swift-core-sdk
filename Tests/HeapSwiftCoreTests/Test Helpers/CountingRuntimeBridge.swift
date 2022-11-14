//
//  File.swift
//  
//
//  Created by Brian Nickel on 11/8/22.
//

import Foundation
import HeapSwiftCore

#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

class CountingRuntimeBridge: NSObject, RuntimeBridge {
    
    var calls: [DelegateCall] = []

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
#endif
    
    func reissuePageview(_ pageview: HeapSwiftCore.Pageview, sessionId: String, timestamp: Date, complete: @escaping (Pageview?) -> Void) {
        calls.append(.reissuePageview)
        complete(nil)
    }
}
