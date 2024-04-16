import HeapSwiftCoreInterfaces

protocol InternalHeapProtocol: HeapProtocol, AnyObject {
    func extendSession(sessionId: String, preferredExpirationDate: Date)
    func fetchSession() -> State?
    var contentsquareIntegration: _ContentsquareIntegration? { get set }
}

let HeapStateForHeapJSChangedNotification = NSNotification.Name("HeapStateForHeapJSChangedNotification")
