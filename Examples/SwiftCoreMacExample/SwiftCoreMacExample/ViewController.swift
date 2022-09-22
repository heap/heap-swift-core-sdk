//
//  ViewController.swift
//  SwiftCoreMacExample
//
//  Created by Jerry Jones on 9/13/22.
//

import Cocoa
import HeapSwiftCore

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Heap.shared.startRecording("11")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func butonClicked(_ sender: Any?) {
        print("👍 Button was clicked, and tracked")
        Heap.shared.track("Button Clicked")
    }
}

