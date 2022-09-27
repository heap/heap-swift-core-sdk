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
    }
    
    @IBAction func butonClicked(_ sender: Any?) {
        print("👍 Button was clicked, and tracked")
        Heap.shared.track("Button Clicked")
    }
}

