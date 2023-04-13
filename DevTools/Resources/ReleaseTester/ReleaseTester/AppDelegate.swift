//
//  AppDelegate.swift
//  ReleaseTester

import UIKit
import HeapSwiftCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Heap.shared.startRecording("11")
        return true
    }


}

