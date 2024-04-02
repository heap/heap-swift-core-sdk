import XCTest
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

/// This performance test shows the overhead of writing to the state store.  The overhead is the
/// difference between `testFileWrites` and `testInMemoryWrites`.
final class StateStorePerformanceTests: XCTestCase {
    
    func testFileWrites() throws {
        
        let dataStore = InMemoryDataStore()
        let stateStore = FileBasedStateStore(directoryUrl: FileManager.default.temporaryDirectory)
        let consumer = EventConsumer(stateStore: stateStore, dataStore: dataStore)
        
        HeapLogger.shared.logLevel = .none
        consumer.startRecording("11")

        self.measure {
            for _ in 1...1000 {
                consumer.track("event")
            }
        }
    }
    
    func testInMemoryWrites() throws {
        
        let dataStore = InMemoryDataStore()
        let consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
        
        HeapLogger.shared.logLevel = .none
        consumer.startRecording("11")

        self.measure {
            for _ in 1...1000 {
                consumer.track("event")
            }
        }
    }
}
