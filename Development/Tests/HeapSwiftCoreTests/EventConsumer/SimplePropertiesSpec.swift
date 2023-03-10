import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_SimplePropertiesSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }

        describe("EventConsumer.userId") {
            
            it("returns nil before `startRecording` is called") {
                expect(consumer.userId).to(beNil())
            }

            it("returns nil after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                expect(consumer.userId).to(beNil())
            }

            it("returns a value when Heap is recording") {
                consumer.startRecording("11")
                expect(consumer.userId).notTo(beNil())
            }
        }

        describe("EventConsumer.identity") {
            
            it("returns nil before `startRecording` is called") {
                _ = dataStore.applyIdentifiedState(to: "11")
                expect(consumer.identity).to(beNil())
            }

            it("returns nil after `stopRecording` is called") {
                _ = dataStore.applyIdentifiedState(to: "11")
                consumer.startRecording("11")
                consumer.stopRecording()
                expect(consumer.identity).to(beNil())
            }

            it("returns nil when unidentified and Heap is recording") {
                _ = dataStore.applyUnidentifiedState(to: "11")
                consumer.startRecording("11")
                expect(consumer.identity).to(beNil())
            }

            it("returns a value when identified and Heap is recording") {
                _ = dataStore.applyIdentifiedState(to: "11")
                consumer.startRecording("11")
                expect(consumer.identity).notTo(beNil())
            }
        }
        
        describe("EventConsumer.getSessionId") {
            
            it("returns nil before `startRecording` is called") {
                _ = dataStore.applyIdentifiedState(to: "11")
                expect(consumer.getSessionId()).to(beNil())
            }

            it("returns nil after `stopRecording` is called") {
                _ = dataStore.applyIdentifiedState(to: "11")
                consumer.startRecording("11")
                consumer.stopRecording()
                expect(consumer.getSessionId()).to(beNil())
            }
            
            it("returns a value when Heap is recording and the session has not expired") {
                _ = dataStore.applyIdentifiedState(to: "11")
                consumer.startRecording("11")
                expect(consumer.getSessionId()).notTo(beNil())
            }
            
            it("returns nil when Heap is recording and the session has expired") {
                _ = dataStore.applyIdentifiedState(to: "11")
                consumer.startRecording("11")
                expect(consumer.getSessionId(timestamp: Date().addingTimeInterval(3000))).to(beNil())
            }
        }
    }
}
