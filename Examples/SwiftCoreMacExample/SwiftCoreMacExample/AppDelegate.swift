//
//  AppDelegate.swift
//  SwiftCoreMacExample
//
//  Created by Jerry Jones on 9/13/22.
//

import Cocoa
import HeapSwiftCore

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        HeapLogger.shared.logLevel = .debug
        Heap.shared.startRecording("11")
    }
}

