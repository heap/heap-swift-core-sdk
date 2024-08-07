import Foundation

public protocol HeapProtocol {
    
    func startRecording(_ environmentId: String, with options: [Option: Any])
    
    func stopRecording()
    
    func stopRecording(deleteUser: Bool)
    
    func track(_ event: String, properties: [String: HeapPropertyValue], timestamp: Date, sourceInfo: SourceInfo?, pageview: Pageview?)
    
    func trackPageview(_ properties: PageviewProperties, timestamp: Date, sourceInfo: SourceInfo?, bridge: RuntimeBridge?, userInfo: Any?) -> Pageview?
    
    func uncommittedInteractionEvent(timestamp: Date, sourceInfo: SourceInfo?, pageview: Pageview?) -> InteractionEventProtocol?
    
    @available(*, deprecated, renamed: "trackInteraction(interaction:nodes:callbackName:timestamp:sourceInfo:sourceProperties:pageview:)")
    func trackInteraction(interaction: Interaction, nodes: [InteractionNode], callbackName: String?, timestamp: Date, sourceInfo: SourceInfo?, pageview: Pageview?)
    
    func trackInteraction(interaction: Interaction, nodes: [InteractionNode], callbackName: String?, timestamp: Date, sourceInfo: SourceInfo?, sourceProperties: [String: HeapPropertyValue], pageview: Pageview?)
    
    func trackNotificationInteraction(properties: NotificationInteractionProperties, timestamp: Date, sourceInfo: SourceInfo?)
    
    func identify(_ identity: String)
    
    func resetIdentity()
    
    func addUserProperties(_ properties: [String: HeapPropertyValue])
    
    func addEventProperties(_ properties: [String: HeapPropertyValue])
    
    func removeEventProperty(_ name: String)
    
    func clearEventProperties()
    
    var environmentId: String? { get }
    
    var userId: String? { get }
    
    var identity: String? { get }
    
    var sessionId: String? { get }
    
    func fetchSessionId() -> String?
    
    func addSource(_ source: Source, isDefault: Bool)
    
    func removeSource(_ name: String)
    
    func addRuntimeBridge(_ bridge: RuntimeBridge)
    
    func removeRuntimeBridge(_ bridge: RuntimeBridge)
    
    func addTransformer(_ transformer: Transformer)
}
