import HeapSwiftCoreInterfaces

protocol InternalHeapProtocol: HeapProtocol {
    func extendSession(sessionId: String, preferredExpirationDate: Date)
    func fetchSession() -> State?
    var environmentId: String? { get }
}

let HeapStateForHeapJSChangedNotification = NSNotification.Name("HeapStateForHeapJSChangedNotification")
