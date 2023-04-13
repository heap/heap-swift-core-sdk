//
//  AppDelegate.swift
//  InterfacesReleaseTester

import UIKit
import HeapSwiftCoreInterfaces

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        HeapLogger.shared.logLevel = .debug
        return true
    }
}

