import HeapSwiftCoreInterfaces

protocol InternalHeapProtocol: HeapProtocol {
    func extendSession(sessionId: String, preferredExpirationDate: Date)
    func fetchSession() -> State?
    
    // TODO: Move the below two entries to HeapSwiftCoreInterfaces.
    var environmentId: String? { get }
    func addTransformer(_ transformer: any Transformer)
}

let HeapStateForHeapJSChangedNotification = NSNotification.Name("HeapStateForHeapJSChangedNotification")
