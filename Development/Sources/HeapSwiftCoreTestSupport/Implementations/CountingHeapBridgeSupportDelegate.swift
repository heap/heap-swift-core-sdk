import Foundation
import HeapSwiftCore
import Nimble

class CountingHeapBridgeSupportDelegate: NSObject, HeapBridgeSupportDelegate {
    
    var invocations: [HeapBridgeSupport.Invocation] = []
    
    func sendInvocation(_ invocation: HeapBridgeSupport.Invocation) {
        invocations.append(invocation)
    }
}
