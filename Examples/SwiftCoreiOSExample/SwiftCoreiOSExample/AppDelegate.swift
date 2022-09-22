//
//  AppDelegate.swift
//  SwiftCoreiOSExample
//
//  Created by Bryan Mitchell on 9/19/22.
//

import UIKit
import HeapSwiftCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Heap.shared.startRecording("11")
        return true
    }
}
