import Foundation
import Quick
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

class DataStoreSpec: HeapSpec {

    final override func spec() {
        
        context("InMemoryDataStore") {
            var dataStore: InMemoryDataStore! = nil
            
            beforeEach {
                dataStore = InMemoryDataStore(settings: .init(
                    messageByteLimit: 20_000
                ))
            }
            
            spec(dataStore: { dataStore })
        }
        
        context("SqliteDataStore") {
            
            var dataStore: SqliteDataStore! = nil
            
            beforeEach {
                dataStore = .temporary()
            }
            
            afterEach {
                dataStore.deleteDatabase(complete: { _ in })
            }
            
            spec(dataStore: { dataStore })
            sqliteSpec(dataStore: { dataStore })
        }
    }
    
    open func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol { }
    
    open func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) { }
}

extension SqliteDataStore {
    class func temporary() -> SqliteDataStore {
        let databaseUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return .init(databaseUrl: databaseUrl, settings: .init(
            messageByteLimit: 20_000
        ))
    }
}
