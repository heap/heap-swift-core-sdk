import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_ContentsquareMethodsSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.advanceOrExtendSession") {
            
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
            
            context("Heap is not recording") {
                
                it("returns nil") {
                    let result = consumer.advanceOrExtendSession(fromContentsquareScreenView: false)
                    expect(result).to(beNil())
                }
            }
            
            context("Heap is recording") {
                var sessionTimestamp: Date!
                
                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", with: [ .startSessionImmediately: true ])
                }
                
                it("extends the session if not expired") {
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    _ = consumer.advanceOrExtendSession(fromContentsquareScreenView: false, timestamp: timestamp)
                    try consumer.assertSessionWasExtended(from: timestamp)
                }
                
                it("returns the current session details if not expired") {
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    let properties = consumer.advanceOrExtendSession(fromContentsquareScreenView: false, timestamp: timestamp)
                    expect(properties?.environmentId).to(equal("11"))
                    expect(properties?.userId).to(equal(consumer.userId))
                    expect(properties?.sessionId).to(equal(consumer.sessionId))
                }
                
                it("create a new session if expired") {
                    let timestamp = sessionTimestamp.addingTimeInterval(6000)
                    let originalSessionId = consumer.sessionId
                    _ = consumer.advanceOrExtendSession(fromContentsquareScreenView: false, timestamp: timestamp)
                    try consumer.assertSessionWasExtended(from: timestamp)
                    expect(consumer.sessionId).notTo(equal(originalSessionId))
                }
                
                it("returns the new session's details if expired") {
                    let timestamp = sessionTimestamp.addingTimeInterval(6000)
                    let properties = consumer.advanceOrExtendSession(fromContentsquareScreenView: false, timestamp: timestamp)
                    expect(properties?.environmentId).to(equal("11"))
                    expect(properties?.userId).to(equal(consumer.userId))
                    expect(properties?.sessionId).to(equal(consumer.sessionId))
                }
                
                it("does not mark the new session as coming from a Contentsquare screenview if false") {
                    let timestamp = sessionTimestamp.addingTimeInterval(6000)
                    _ = consumer.advanceOrExtendSession(fromContentsquareScreenView: false, timestamp: timestamp)
                    expect(consumer.currentSessionProperties.createdByContentsquareScreenView).to(beFalse())
                }
                
                it("marks the new session as coming from a Contentsquare screenview if true") {
                    let timestamp = sessionTimestamp.addingTimeInterval(6000)
                    _ = consumer.advanceOrExtendSession(fromContentsquareScreenView: true, timestamp: timestamp)
                    expect(consumer.currentSessionProperties.createdByContentsquareScreenView).to(beTrue())
                }
            }
        }
    }
}
