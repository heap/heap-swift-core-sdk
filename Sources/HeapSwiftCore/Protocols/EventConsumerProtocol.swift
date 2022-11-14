import Foundation

protocol EventConsumerProtocol {
    func startRecording(_ environmentId: String, with options: [Option: Any], timestamp: Date)
    func stopRecording(timestamp: Date)
    func track(_ event: String, properties: [String: HeapPropertyValue], timestamp: Date, sourceInfo: SourceInfo?, pageview: Pageview?)
    func trackPageview(_ properties: PageviewProperties, timestamp: Date, sourceInfo: SourceInfo?, bridge: RuntimeBridge?, userInfo: Any?) -> Pageview?
    func identify(_ identity: String, timestamp: Date)
    func resetIdentity(timestamp: Date)
    func addUserProperties(_ properties: [String: HeapPropertyValue])
    func addEventProperties(_ properties: [String: HeapPropertyValue])
    func removeEventProperty(_ name: String)
    func clearEventProperties()
    var userId: String? { get }
    var identity: String? { get }
    func getSessionId(timestamp: Date) -> String?
    
    func addSource(_ source: Source, isDefault: Bool, timestamp: Date)
    func removeSource(_ name: String)
    
    func addRuntimeBridge(_ bridge: RuntimeBridge, timestamp: Date)
    func removeRuntimeBridge(_ bridge: RuntimeBridge)
}
