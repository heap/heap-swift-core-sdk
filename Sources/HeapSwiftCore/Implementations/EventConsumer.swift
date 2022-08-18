import Foundation

class EventConsumer<DataStore: DataStoreProtocol>: EventConsumerProtocol, ActiveSessionProvider {

    let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore;
    }

    func startRecording(_ environmentId: String, with options: [Option: Any] = [:], timestamp: Date = Date()) {
    }

    func stopRecording() {
    }

    func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil) {
    }

    func identify(_ identity: String, timestamp: Date = Date()) {
    }

    func resetIdentity(timestamp: Date = Date()) {
    }

    func addUserProperties(_ properties: [String: HeapPropertyValue], timestamp: Date = Date()) {
    }

    func addEventProperties(_ properties: [String: HeapPropertyValue]) {
    }

    func removeEventProperty(_ name: String) {
    }

    func clearEventProperties() {
    }

    var userId: String? {
        return nil
    }

    var identity: String? {
        return nil
    }

    func getSessionId(timestamp: Date = Date()) -> String? {
        return nil
    }

    var sessionExpirationTime: Date? {
        return nil
    }

    var activeSession: ActiveSession? {
        return nil
    }
}
