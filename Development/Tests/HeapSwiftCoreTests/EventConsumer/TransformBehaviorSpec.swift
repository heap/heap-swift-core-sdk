import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class TransformBehaviorSpec: HeapSpec {
    
    override func spec() {
        
        context("A session replay transform exists") {
            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            var restoreState: StateRestorer!
            var transformer: TriggerableTransformer!

            beforeEach {
                (dataStore, consumer, _, _, restoreState) = prepareEventConsumerWithCountingDelegates()
                transformer = TriggerableTransformer(name: "SRTransformer", timeout: 0.5)
                consumer.addTransformer(transformer)
                consumer.startRecording("11", with: [ .startSessionImmediately: true ])
            }
            
            afterEach {
                restoreState()
            }
            
            describe("Session creation") {
                
                it("inserts messages when the transformer times out") {
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                }
                
                it("inserts messages with replay data when received") {
                    transformer.applyToAll(sessionReplay: "SR")
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    expect(messages.map(\.sessionReplay)).to(allPass(equal("SR")), description: "Each message should have the replay info")
                }
            }
            
            describe("PendingEvent") {
                
                var pendingEvent: PendingEvent!
                
                beforeEach {
                    let message = Message(forPartialEventAt: Date(), sourceLibrary: nil, in: consumer.stateManager.current!)
                    pendingEvent = PendingEvent(partialEventMessage: message, toBeCommittedTo: consumer.transformPipeline)
                }
                
                it("triggers a transform on creation") {
                    expect(transformer.receivedTransforms).toEventuallyNot(beEmpty())
                }
                
                it("gets added to the data store when the transformer times out") {
                    pendingEvent.setKind(.custom(name: "x", properties: [:]))
                    pendingEvent.setPageviewInfo(consumer.stateManager.current!.lastPageviewInfo)
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    try dataStore.assertOnlySession(for: user, hasPostStartMessageCount: 1)
                }
                
                it("accepts data that was transformed before commit") {
                    transformer.applyToAll(sessionReplay: "SR")
                    expect(transformer.receivedTransforms).toEventually(haveCount(4), description: "Should have received session start messages and the event")
                    
                    pendingEvent.setKind(.custom(name: "x", properties: [:]))
                    pendingEvent.setPageviewInfo(consumer.stateManager.current!.lastPageviewInfo)
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    
                    // NOTE: This is in fact testing more than just the last event, but it was easier to just validate all.
                    expect(messages.map(\.sessionReplay)).to(allPass(equal("SR")), description: "Each message should have the replay info")
                    expect(transformer.receivedTransforms).toAlways(haveCount(4), description: "Each message should have only had one processor")
                }
                
                it("accepts data that was transformed after commit") {
                    pendingEvent.setKind(.custom(name: "x", properties: [:]))
                    pendingEvent.setPageviewInfo(consumer.stateManager.current!.lastPageviewInfo)
                    transformer.applyToAll(sessionReplay: "SR")
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    
                    // NOTE: This is in fact testing more than just the last event, but it was easier to just validate all.
                    expect(messages.map(\.sessionReplay)).to(allPass(equal("SR")), description: "Each message should have the replay info")
                    expect(transformer.receivedTransforms).toAlways(haveCount(4), description: "Each message should have only had one processor")
                }
            }
        }
    }
}
