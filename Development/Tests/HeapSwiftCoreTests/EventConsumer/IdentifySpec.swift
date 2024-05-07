import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_IdentifySpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.identify") {
            
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
                
                it("doesn't set the identity before `startRecording` is called") {
                    
                    consumer.identify("user1")
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(beNil(), description: "Values should not have changed")
                }
                
                it("doesn't set the identity after `stopRecording` is called") {
                    
                    consumer.startRecording("11")
                    consumer.stopRecording()
                    consumer.identify("user1")
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(beNil(), description: "Values should not have changed")
                }
                
                context("Heap is recording") {

                    beforeEach {
                        consumer.startRecording("11")
                    }

                    it("doesn't set the identity when given an empty string") {
                        consumer.identify("")

                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let state = dataStore.loadState(for: "11")
                        
                        expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                        expect(user.identity).to(beNil(), description: "Values should not have changed")
                    }
                    
                    context("called with a valid identity") {
                        
                        beforeEach {
                            consumer.identify("user1")
                        }
                        
                        it("sets the identity") {
                            expect(consumer.identity).to(equal("user1"))
                        }
                        
                        it("persists the identity") {
                            expect(dataStore.loadState(for: "11").identity).to(equal("user1"))
                        }
                        
                        it("queues the identity for upload") {
                            let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                            expect(user.identity).to(equal("user1"))
                        }
                        
                        it("does not create a new user") {
                            expect(consumer.userId).to(equal(originalState.userID))
                            try dataStore.assertOnlyOneUserToUpload()
                        }
                        
                        it("does not reset event properties") {
                            let state = dataStore.loadState(for: "11")
                            expect(state.properties).to(equal(originalState.properties))
                        }
                    }
                    
                    context("called with a valid identity, before the session expires") {

                        var sessionTimestamp: Date!
                        var originalSessionId: String?
                        var identifyTimestamp: Date!

                        beforeEach {
                            (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                            
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(60) // Identify before expiration
                            consumer.identify("user1", timestamp: identifyTimestamp)
                        }
                        
                        it("does not create a new session") {
                            expect(consumer.activeOrExpiredSessionId).to(equal(originalSessionId))
                            let user = try dataStore.assertOnlyOneUserToUpload()
                            expect(user.sessionIds.count).to(equal(1))
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
                        }
                    }

                    context("called with a valid identity, after the session expires") {

                        var sessionTimestamp: Date!
                        var originalSessionId: String?
                        var identifyTimestamp: Date!

                        beforeEach {
                            (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                            
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(600) // Identify after expiration
                            consumer.identify("user1", timestamp: identifyTimestamp)
                        }
                        
                        it("creates a new session and pageview") {
                            expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                            expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                            let user = try dataStore.assertOnlyOneUserToUpload()
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                            messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: identifyTimestamp, eventProperties: consumer.eventProperties)
                        }
                        
                        it("notifies bridges and sources about the new session") {
                            expect(bridge.sessions).to(haveCount(2))
                            expect(source.sessions).to(equal(bridge.sessions))
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
                        }
                        
                        it("does not mark new session as coming from a user change") {
                            expect(consumer.currentSessionProperties).to(equal([]))
                        }
                    }
                }
            }
            
            context("identity has already been set") {

                var originalState: EnvironmentState!

                beforeEach {
                    originalState = dataStore.applyIdentifiedState(to: "11")
                }
                
                it("doesn't set the identity before `startRecording` is called") {
                    
                    consumer.identify("user1")
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "startRecording should have created a user and identify shouldn't have created another.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.identity).to(equal(originalState.identity), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(equal(originalState.identity), description: "Values should not have changed")
                }
                
                it("doesn't set the identity after `stopRecording` is called") {
                    
                    consumer.startRecording("11")
                    consumer.stopRecording()
                    consumer.identify("user1")
                    consumer.startRecording("11")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "startRecording should have created a user and identify shouldn't have created another.")
                    let state = dataStore.loadState(for: "11")

                    expect(state.identity).to(equal(originalState.identity), description: "Values should not have changed")
                    expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                    expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                    expect(user.identity).to(equal(originalState.identity), description: "Values should not have changed")
                }
                
                context("Heap is recording") {

                    beforeEach {
                        consumer.startRecording("11")
                    }

                    it("doesn't set the identity when given an empty string") {
                        consumer.identify("")

                        let user = try dataStore.assertOnlyOneUserToUpload(message: "startRecording should have created a user and identify shouldn't have created another.")
                        let state = dataStore.loadState(for: "11")
                        
                        expect(state.identity).to(equal(originalState.identity), description: "Values should not have changed")
                        expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                        expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                        expect(user.identity).to(equal(originalState.identity), description: "Values should not have changed")
                    }
                    
                    it("doesn't create a new user when called with the current identity") {
                        consumer.identify(originalState.identity)

                        let user = try dataStore.assertOnlyOneUserToUpload(message: "startRecording should have created a user and identify shouldn't have created another.")
                        let state = dataStore.loadState(for: "11")
                        
                        expect(state.userID).to(equal(originalState.userID), description: "Values should not have changed")
                        expect(state.identity).to(equal(originalState.identity), description: "Values should not have changed")
                        expect(state.properties).to(equal(originalState.properties), description: "Values should not have changed")
                        expect(user.identity).to(equal(originalState.identity), description: "Values should not have changed")
                    }
                    
                    context("called with a valid identity") {

                        beforeEach {
                            consumer.identify("user1")
                        }
                        
                        it("sets the identity") {
                            expect(consumer.identity).to(equal("user1"))
                        }
                        
                        it("persists the identity") {
                            expect(dataStore.loadState(for: "11").identity).to(equal("user1"))
                        }
                        
                        it("queues the identity for upload") {
                            let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                            expect(user.identity).to(equal("user1"))
                        }
                        
                        it("creates a new user") {
                            expect(consumer.userId).notTo(equal(originalState.userID))
                            expect(dataStore.usersToUpload().count).to(equal(2))
                        }
                        
                        it("does not reset event properties") {
                            let state = dataStore.loadState(for: "11")
                            expect(state.properties).to(equal(originalState.properties))
                        }
                    }
                    
                    context("called with a valid identity, before the first session has started") {
                        
                        var identifyTimestamp: Date!
                        var originalSessionId: String?
                        
                        beforeEach {
                            identifyTimestamp = Date()
                            originalSessionId = consumer.activeOrExpiredSessionId
                            consumer.identify("user1", timestamp: identifyTimestamp)
                        }
                        
                        it("creates a new session, pageview, and version change event for the new user") {
                            expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                            expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                            let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 3)
                            messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: identifyTimestamp, eventProperties: consumer.eventProperties)
                        }
                        
                        it("notifies bridges and sources about the new session") {
                            expect(bridge.sessions).to(haveCount(1))
                            expect(source.sessions).to(equal(bridge.sessions))
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
                        }
                        
                        it("marks the new session as coming from a user change") {
                            expect(consumer.currentSessionProperties).to(equal(.previousSessionHadDifferentUser))
                        }
                    }
                    
                    context("called with a valid identity, before the session expires") {

                        var sessionTimestamp: Date!
                        var originalSessionId: String?
                        var identifyTimestamp: Date!

                        beforeEach {
                            sessionTimestamp = Date()
                            consumer.track("event", timestamp: sessionTimestamp) // Start the session
                            originalSessionId = consumer.activeOrExpiredSessionId
                            
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(60) // Identify before expiration
                            consumer.identify("user1", timestamp: identifyTimestamp)
                        }
                        
                        it("creates a new session and pageview for the new user") {
                            expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                            expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                            let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                            messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: identifyTimestamp, eventProperties: consumer.eventProperties)
                        }
                        
                        it("notifies bridges and sources about the new session") {
                            expect(bridge.sessions).to(haveCount(2))
                            expect(source.sessions).to(equal(bridge.sessions))
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
                        }
                        
                        it("marks the new session as coming from a user change") {
                            expect(consumer.currentSessionProperties).to(equal(.previousSessionHadDifferentUser))
                        }
                    }

                    context("called with a valid identity, after the session expires") {

                        var sessionTimestamp: Date!
                        var originalSessionId: String?
                        var identifyTimestamp: Date!

                        beforeEach {
                            sessionTimestamp = Date()
                            consumer.track("event", timestamp: sessionTimestamp) // Start the session
                            originalSessionId = consumer.activeOrExpiredSessionId
                            
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(600) // Identify after expiration
                            consumer.identify("user1", timestamp: identifyTimestamp)
                        }
                        
                        it("creates a new session and pageview for the new user") {
                            expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                            expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                            let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                            messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: identifyTimestamp, eventProperties: consumer.eventProperties)
                        }
                        
                        it("notifies bridges and sources about the new session") {
                            expect(bridge.sessions).to(haveCount(2))
                            expect(source.sessions).to(equal(bridge.sessions))
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
                        }
                        
                        it("marks the new session as coming from a user change") {
                            expect(consumer.currentSessionProperties).to(equal(.previousSessionHadDifferentUser))
                        }
                    }
                }
                
                context("Heap is recording with clearEventPropertiesOnNewUser set as false") {

                    beforeEach {
                        consumer.startRecording("11", with: [.clearEventPropertiesOnNewUser: false])
                    }

                    context("called with a valid identity") {

                        beforeEach {
                            consumer.identify("user1")
                        }
                        
                        it("does not reset event properties") {
                            let state = dataStore.loadState(for: "11")
                            expect(state.properties).to(equal(originalState.properties))
                        }
                    }
                }
                
                
                context("Heap is recording with clearEventPropertiesOnNewUser set as true") {

                    beforeEach {
                        consumer.startRecording("11", with: [.clearEventPropertiesOnNewUser: true])
                    }

                    context("called with a valid identity") {

                        beforeEach {
                            consumer.identify("user1")
                        }
                        
                        it("resets event properties") {
                            let state = dataStore.loadState(for: "11")
                            expect(state.properties).to(equal([:]))
                        }
                    }
                    
                }
            }
        }
    }
}
