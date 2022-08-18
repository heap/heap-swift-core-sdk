import Foundation

protocol EventConsumerProtocol {
    func startRecording(_ environmentId: String, with options: [Option: Any], timestamp: Date)
    func stopRecording()
    func track(_ event: String, properties: [String: HeapPropertyValue], timestamp: Date, sourceInfo: SourceInfo?)
    func identify(_ identity: String, timestamp: Date)
    func resetIdentity(timestamp: Date)
    func addUserProperties(_ properties: [String: HeapPropertyValue], timestamp: Date)
    func addEventProperties(_ properties: [String: HeapPropertyValue])
    func removeEventProperty(_ name: String)
    func clearEventProperties()
    var userId: String? { get }
    var identity: String? { get }
    func getSessionId(timestamp: Date) -> String?
}
