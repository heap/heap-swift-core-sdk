import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_ResetIdentitySpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.resetIdentity") {
            
            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            var bridge: CountingRuntimeBridge!
            var source: CountingSource!
            var restoreState: StateRestorer!

            beforeEach {
                (dataStore, consumer, bridge, source, restoreState) = prepareEventConsumerWithCountingDelegates()
            }
            
            afterEach {
                restoreState()
            }
            
            context("identity is not set") {
                var originalState: EnvironmentState!

                beforeEach {
                    originalState = dataStore.applyUnidentifiedState(to: "11")
                }
                
                it("doesn't reset the identity before `startRecording` is called") {
                    
                    consumer.resetIdentity()
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(beNil(), description: "Values should not have changed")
                }
                
                it("doesn't reset the identity after `stopRecording` is called") {
                    
                    consumer.startRecording("11")
                    consumer.stopRecording()
                    consumer.resetIdentity()
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(beNil(), description: "Values should not have changed")
                }
                
                it("doesn't reset the identity") {
                    
                    consumer.startRecording("11")
                    let originalSessionId = consumer.activeOrExpiredSessionId
                    consumer.resetIdentity()
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(beNil(), description: "Values should not have changed")
                    expect(consumer.activeOrExpiredSessionId).to(equal(originalSessionId), description: "Session should not have reset")
                }
            }

            context("identity has already been set") {

                var originalState: EnvironmentState!

                beforeEach {
                    originalState = dataStore.applyIdentifiedState(to: "11")
                }
                
                it("doesn't reset the identity before `startRecording` is called") {
                    
                    consumer.resetIdentity()
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "startRecording should have created a user and resetIdentity shouldn't have created another.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.identity).to(equal(originalState.identity), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(equal(originalState.identity), description: "Values should not have changed")
                }
                
                it("doesn't reset the identity after `stopRecording` is called") {
                    
                    consumer.startRecording("11")
                    consumer.stopRecording()
                    consumer.resetIdentity()
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "startRecording should have created a user and resetIdentity shouldn't have created another.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.identity).to(equal(originalState.identity), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(equal(originalState.identity), description: "Values should not have changed")
                }

                context("Heap is recording") {

                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var resetTimestamp: Date!

                    beforeEach {
                        sessionTimestamp = Date()
                        resetTimestamp = sessionTimestamp.addingTimeInterval(60)
                        consumer.startRecording("11", with: [.startSessionImmediately: true], timestamp: sessionTimestamp)
                        originalSessionId = consumer.activeOrExpiredSessionId
                        consumer.resetIdentity(timestamp: resetTimestamp)
                    }
                    
                    it("resets the identity") {
                        expect(consumer.identity).to(beNil())
                    }
                    
                    it("creates a new user") {
                        expect(consumer.userId).notTo(equal(originalState.userID))
                        expect(dataStore.usersToUpload().count).to(equal(2))
                    }
                    
                    it("does not add an identity to the new uploadable user") {
                        let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                        expect(user.identity).to(beNil())
                    }
                    
                    it("resets event properties") {
                        let state = dataStore.loadState(for: "11")
                        expect(state.properties).to(equal([:]))
                    }
                    
                    it("persists the new state") {
                        expect(dataStore.loadState(for: "11").hasIdentity).to(beFalse())
                        expect(dataStore.loadState(for: "11").userID).to(equal(consumer.userId))
                        expect(dataStore.loadState(for: "11").properties).to(beEmpty())
                    }
                    
                    it("creates a new session and pageview for the new user") {
                        expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                        expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                        
                        let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: resetTimestamp, eventProperties: consumer.eventProperties)
                    }
                    
                    it("notifies bridges and sources about the new session") {
                        expect(bridge.sessions).to(haveCount(2))
                        expect(source.sessions).to(equal(bridge.sessions))
                    }
                    
                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: resetTimestamp)
                    }                    
                }
            }
        }
    }
}
