import Foundation

public struct _ContentsquareSessionProperties: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let createdByContentsquare = _ContentsquareSessionProperties(rawValue: 1 << 0)
    public static let createdByContentsquareScreenView = _ContentsquareSessionProperties(rawValue: (1 << 0) | (1 << 1)) // Implicitly created by CS.
    public static let previousSessionHadDifferentUser = _ContentsquareSessionProperties(rawValue: 1 << 2)
}

public enum _ContentsquareSessionExtensionSource {
    case screenview
    case appStartOrShow
    case other
}

public struct _AdvanceOrExtendSessionResults {
    public var environmentId: String?
    public var userId: String?
    public var sessionId: String?
    
    public var newSessionCreated: Bool = false
    public init() {}
}

public protocol _ContentsquareMethods: AnyObject {
    func advanceOrExtendSession(source: _ContentsquareSessionExtensionSource) -> _AdvanceOrExtendSessionResults
    var currentSessionProperties: _ContentsquareSessionProperties { get }
}

public protocol _ContentsquareIntegration: AnyObject {
    var sessionTimeoutDuration: TimeInterval { get }
    func didTrackHeapPageview(_ pageview: Pageview)
    func setContentsquareMethods(_ methods: _ContentsquareMethods)
}
