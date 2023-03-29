@testable import HeapSwiftCore

extension Pageview {
    
    // Swift does not want to resolve properties with the same name from a superclass.
    
    var _sessionInfo: SessionInfo? { (self as! ConcretePageview).sessionInfo }
    var _pageviewInfo: PageviewInfo { (self as! ConcretePageview).pageviewInfo }
    var _sourceLibrary: LibraryInfo? { (self as! ConcretePageview).sourceLibrary }
    var _bridge: RuntimeBridge? { (self as! ConcretePageview).bridge }
    var _isFromBridge: Bool { (self as! ConcretePageview).isFromBridge }
}
