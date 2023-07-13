//
//  ContentView.swift
//  SwiftCoreVisionOSExample
//
//  Created by Brian Nickel on 7/13/23.
//

import SwiftUI
import RealityKit
import RealityKitContent
import HeapSwiftCore

struct ContentView: View {
    
    static let initHeap: Bool = {
        Heap.shared.logLevel = .trace
        Heap.shared.startRecording("1501760456")
        return true
    }()
    
    var body: some View {
        NavigationSplitView {
            List {
                Text("Item")
            }
            .navigationTitle("Sidebar")
        } detail: {
            VStack {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)

                Text("Hello, world!")
                
                Button("Track event") {
                    _ = ContentView.initHeap
                    Heap.shared.track("Vision Event")
                }
            }
            .navigationTitle("Content")
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
