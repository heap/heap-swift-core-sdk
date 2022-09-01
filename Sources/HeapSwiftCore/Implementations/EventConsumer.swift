import Foundation

class EventConsumer<DataStore: DataStoreProtocol>: EventConsumerProtocol, ActiveSessionProvider {

    let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore;
    }

    func startRecording(_ environmentId: String, with options: [Option: Any] = [:], timestamp: Date = Date()) {
    }

    func stopRecording(timestamp: Date = Date()) {
    }

    func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil) {
    }

    func identify(_ identity: String, timestamp: Date = Date()) {
    }

    func resetIdentity(timestamp: Date = Date()) {
    }

    func addUserProperties(_ properties: [String: HeapPropertyValue]) {
    }

    func addEventProperties(_ properties: [String: HeapPropertyValue]) {
    }

    func removeEventProperty(_ name: String) {
    }

    func clearEventProperties() {
    }

    var userId: String? {
        return "1"
    }

    var identity: String? {
        return "2"
    }

    var eventProperties: [String: Value] {
        return [:]
    }

    func getSessionId(timestamp: Date = Date()) -> String? {
        return "3"
    }

    var activeSession: ActiveSession? {
        return nil
    }


    /// For testing, returns the last set session ID without attempting to extend the session.
    var activeOrExpiredSessionId: String? {
        return "4"
    }

    /// For testing, returns the last set session expiration time without attempting to extend the session.
    var sessionExpirationTime: Date? {
        return Date()
    }
}
