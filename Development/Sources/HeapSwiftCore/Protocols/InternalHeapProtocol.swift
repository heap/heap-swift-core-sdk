import Foundation
import HeapSwiftCoreInterfaces

protocol InternalHeapProtocol: HeapProtocol {
    func extendSession(sessionId: String, preferredExpirationDate: Date)
    func fetchSession() -> State?
}

let HeapStateForHeapJSChangedNotification = NSNotification.Name("HeapStateForHeapJSChangedNotification")
