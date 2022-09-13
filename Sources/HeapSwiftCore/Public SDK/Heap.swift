import Foundation

@objc
public class Heap: NSObject {

    private var consumer: any EventConsumerProtocol
    private var uploader: any UploaderProtocol

    @objc(sharedInstance)
    public static var shared: Heap = {
        let dataStore = SqliteDataStore()
        let consumer = EventConsumer(dataStore: dataStore)
        let uploader = Uploader(dataStore: dataStore, activeSessionProvider: consumer, connectivityTester: ReachabilityConnectivityTester())

        return Heap(consumer: consumer, uploader: uploader)
    }()

    private init(consumer: any EventConsumerProtocol, uploader: any UploaderProtocol) {
        self.consumer = consumer
        self.uploader = uploader
    }

    public func startRecording(_ environmentId: String, with options: [Option: Any] = [:]) {
        let sanitizedOptions = options.sanitizedCopy()
        consumer.startRecording(environmentId, with: sanitizedOptions, timestamp: Date())
        uploader.startScheduledUploads(with: sanitizedOptions)
    }

    public func stopRecording() {
        consumer.stopRecording(timestamp: Date())
    }

    public func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil) {
        consumer.track(event, properties: properties, timestamp: timestamp, sourceInfo: sourceInfo)
    }

    public func identify(_ identity: String) {
        consumer.identify(identity, timestamp: Date())
    }

    public func resetIdentity() {
        consumer.resetIdentity(timestamp: Date())
    }

    public func addUserProperties(_ properties: [String: HeapPropertyValue]) {
        consumer.addUserProperties(properties)
    }

    public func addEventProperties(_ properties: [String: HeapPropertyValue]) {
        consumer.addEventProperties(properties)
    }

    public func removeEventProperty(_ name: String) {
        consumer.removeEventProperty(name)
    }

    public func clearEventProperties() {
        consumer.clearEventProperties()
    }

    public var userId: String? {
        consumer.userId
    }

    public var identity: String? {
        consumer.identity
    }

    public var sessionId: String? {
        consumer.getSessionId(timestamp: Date())
    }
}
