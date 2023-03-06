@testable import HeapSwiftCore

public typealias StateRestorer = () -> Void

func prepareEventConsumerWithCountingDelegates() -> (InMemoryDataStore, EventConsumer<InMemoryDataStore, InMemoryDataStore>, CountingRuntimeBridge, CountingSource, StateRestorer) {
    
    let previousLogLevel = HeapLogger.shared.logLevel
    
    let dataStore = InMemoryDataStore()
    let consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
    let bridge = CountingRuntimeBridge()
    let source = CountingSource(name: "A", version: "1")
        
    consumer.addRuntimeBridge(bridge)
    consumer.addSource(source, isDefault: false)
    HeapLogger.shared.logLevel = .trace
    
    func restoreState() {
        consumer.stopRecording()
        HeapLogger.shared.logLevel = previousLogLevel
    }
    
    return (dataStore, consumer, bridge, source, restoreState)
}
