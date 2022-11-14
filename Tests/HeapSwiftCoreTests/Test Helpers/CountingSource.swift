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

enum DelegateCall: Equatable {
    case didStartRecording
    case didStopRecording
    case sessionDidStart
    case applicationDidEnterForeground
    case applicationDidEnterBackground
    case windowSceneDidEnterForeground
    case windowSceneDidEnterBackground
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
#endif
    
    func activePageview(sessionId: String, timestamp: Date, complete: @escaping (HeapSwiftCore.Pageview?) -> Void) {
        calls.append(.activePageview)
        complete(nil)
    }
    
    func reissuePageview(_ pageview: HeapSwiftCore.Pageview, sessionId: String, timestamp: Date, complete: @escaping (HeapSwiftCore.Pageview?) -> Void) {
        calls.append(.reissuePageview)
        complete(nil)
    }
}
