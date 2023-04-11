import Foundation
import HeapSwiftCoreInterfaces

@objc
public class Heap: NSObject, HeapProtocol {

    internal let consumer: any HeapProtocol
    internal let uploader: any UploaderProtocol

    private static let heapDirectory: URL = {
        let fileManager = FileManager.default
        var url = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!
        url.appendPathComponent("HeapSwiftCore", isDirectory: true)
        url.appendPathComponent(ApplicationInfo.current.identifier, isDirectory: true)
        try! fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
    
    @objc(sharedInstance)
    public static var shared: Heap = {
        let stateStore = FileBasedStateStore(directoryUrl: heapDirectory)
        let dataStore = SqliteDataStore(databaseUrl: heapDirectory.appendingPathComponent("DataStore.db"))
        let consumer = EventConsumer(stateStore: stateStore, dataStore: dataStore)
        let uploader = Uploader(dataStore: dataStore, activeSessionProvider: consumer)

        return Heap(consumer: consumer, uploader: uploader)
    }()

    private init(consumer: any HeapProtocol, uploader: any UploaderProtocol) {
        self.consumer = consumer
        self.uploader = uploader
    }

    @objc(startRecording:withOptions:)
    public func startRecording(_ environmentId: String, with options: [Option: Any] = [:]) {
        // Reminder: any change in the logic here should also be applied to startRecording in HeapBridgeSupport.swift
        let sanitizedOptions = options.sanitizedCopy()
        consumer.startRecording(environmentId, with: sanitizedOptions)
        uploader.startScheduledUploads(with: .init(with: sanitizedOptions))
    }

    @objc
    public func stopRecording() {
        consumer.stopRecording()
    }

    public func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) {
        consumer.track(event, properties: properties, timestamp: timestamp, sourceInfo: sourceInfo, pageview: pageview)
    }
    
    public func trackPageview(_ properties: PageviewProperties, timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, bridge: RuntimeBridge? = nil, userInfo: Any? = nil) -> Pageview? {
        consumer.trackPageview(properties, timestamp: timestamp, sourceInfo: sourceInfo, bridge: bridge, userInfo: userInfo)
    }
    
    public func uncommittedInteractionEvent(timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) -> InteractionEventProtocol? {
        return consumer.uncommittedInteractionEvent(timestamp: timestamp, sourceInfo: sourceInfo, pageview: pageview)
    }
    
    public func trackInteraction(interaction: Interaction, nodes: [InteractionNode], callbackName: String? = nil, timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) {
        consumer.trackInteraction(interaction: interaction, nodes: nodes, callbackName: callbackName, timestamp: timestamp, sourceInfo: sourceInfo, pageview: pageview)
    }

    @objc
    public func identify(_ identity: String) {
        consumer.identify(identity)
    }

    @objc
    public func resetIdentity() {
        consumer.resetIdentity()
    }

    public func addUserProperties(_ properties: [String: HeapPropertyValue]) {
        consumer.addUserProperties(properties)
    }

    public func addEventProperties(_ properties: [String: HeapPropertyValue]) {
        consumer.addEventProperties(properties)
    }

    @objc
    public func removeEventProperty(_ name: String) {
        consumer.removeEventProperty(name)
    }

    @objc
    public func clearEventProperties() {
        consumer.clearEventProperties()
    }

    @objc
    public var userId: String? {
        consumer.userId
    }

    @objc
    public var identity: String? {
        consumer.identity
    }

    @objc
    public var sessionId: String? {
        consumer.sessionId
    }
    
    @objc
    public func fetchSessionId() -> String? {
        consumer.fetchSessionId()
    }
    
    public func addSource(_ source: Source, isDefault: Bool = false) {
        consumer.addSource(source, isDefault: isDefault)
    }
    
    public func removeSource(_ name: String) {
        consumer.removeSource(name)
    }
    
    public func addRuntimeBridge(_ bridge: RuntimeBridge) {
        consumer.addRuntimeBridge(bridge)
    }
    
    public func removeRuntimeBridge(_ bridge: RuntimeBridge) {
        consumer.removeRuntimeBridge(bridge)
    }
    
    /// The level of logging to be performed by the HeapLogger.
    @objc
    public var logLevel: LogLevel {
       get { HeapLogger.shared.logLevel }
       set { HeapLogger.shared.logLevel = newValue }
    }
    
    /// The logging channel to route all logs
    public var logChannel: LogChannel {
       get { HeapLogger.shared.logChannel }
       set { HeapLogger.shared.logChannel = newValue }
    }
}
