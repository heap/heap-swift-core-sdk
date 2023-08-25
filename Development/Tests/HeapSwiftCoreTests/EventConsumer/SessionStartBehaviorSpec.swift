import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_SessionStartBehaviorSpec: HeapSpec {
    
    override func spec() {
        
        describe("Session Start Behaviors") {
            
            context("Session is started with event properties") {
                
                var dataStore: InMemoryDataStore!
                var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
                
                beforeEach {
                    dataStore = InMemoryDataStore()
                    consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
                    HeapLogger.shared.logLevel = .trace
                    
                    consumer.startRecording("11")
                    consumer.addEventProperties(["a": 1])
                    consumer.track("event")
                }
                
                afterEach {
                    HeapLogger.shared.logLevel = .info
                }
                
                it("does not add event properties to session message") {
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    expect(messages[0].properties).to(beEmpty())
                }
                
                it("adds event properties to pageview message") {
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    
                    expect(messages[1].properties).to(equal([
                        "a": .init(value: "1"),
                    ]))
                }
                
                it("adds event properties to version change message") {
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    
                    expect(messages[2].properties).to(equal([
                        "a": .init(value: "1"),
                    ]))
                }
                
                it("adds event properties to event message") {
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    
                    expect(messages[3].properties).to(equal([
                        "a": .init(value: "1"),
                    ]))
                }
                
            }
        }
    }
}
