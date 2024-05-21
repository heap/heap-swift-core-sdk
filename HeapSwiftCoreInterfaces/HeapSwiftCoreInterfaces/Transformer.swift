import Foundation

public enum TransformPhase: Int {
    case early = 0
}

public protocol Transformable { }

public struct TransformableEvent: Transformable, Equatable {
    
    public struct ContentsquareProperties: Equatable {
        public let cspid: String
        public let csuu: String
        public let cssn: String
        public let cspvid: String
        public let csts: String
        
        public init(cspid: String, csuu: String, cssn: String, cspvid: String, csts: String) {
            self.cspid = cspid
            self.csuu = csuu
            self.cssn = cssn
            self.cspvid = cspvid
            self.csts = csts
        }
    }
    
    public let environmentId: String
    public let userId: String
    public let sessionId: String
    public let timestamp: Date
    
    public var sessionReplays: [String] = []
    public var contentsquareProperties: ContentsquareProperties? = nil
    
    public init(environmentId: String, userId: String, sessionId: String, timestamp: Date) {
        self.environmentId = environmentId
        self.userId = userId
        self.sessionId = sessionId
        self.timestamp = timestamp
    }
}

public enum TransformResult<T: Transformable> {
    case `continue`(T)
}

public protocol Transformer {
    var name: String { get }
    var timeout: TimeInterval { get }
    var phase: TransformPhase { get }
    func transform(_ event: TransformableEvent, complete: @escaping (_ result: TransformResult<TransformableEvent>) -> Void)
}

public extension Transformer {
    func transform(_ event: TransformableEvent, complete: @escaping (_ result: TransformResult<TransformableEvent>) -> Void) {
        complete(.continue(event))
    }
}
