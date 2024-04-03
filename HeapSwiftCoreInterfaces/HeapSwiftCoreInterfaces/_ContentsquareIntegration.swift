import Foundation

public struct _ContentsquareSessionProperties {
    public var createdByContentsquareScreenView: Bool = false
    public var previousSessionHadDifferentUser: Bool = false
    
    public init() {}
}

public protocol _ContentsquareMethods: AnyObject {
    func advanceOrExtendSession(fromContentsquareScreenView: Bool) -> (environmentId: String, userId: String, sessionId: String)?
    var currentSessionProperties: _ContentsquareSessionProperties { get }
}

public protocol _ContentsquareIntegration: AnyObject {
    var sessionTimeoutDuration: TimeInterval { get }
    func didTrackHeapPageview(_ pageview: Pageview)
    func setContentsquareMethods(_ methods: _ContentsquareMethods)
}
