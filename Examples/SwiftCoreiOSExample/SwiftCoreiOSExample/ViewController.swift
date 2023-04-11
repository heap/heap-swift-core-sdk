//
//  ViewController.swift
//  SwiftCoreiOSExample
//
//  Created by Bryan Mitchell on 9/19/22.
//
import UIKit
import HeapSwiftCore

class ViewController: UIViewController {
    
    @IBAction func butonClicked(_ sender: Any?) {
        
        print("👍 Button was clicked, and tracked")
        Heap.shared.track("Button Clicked")
    }
}
