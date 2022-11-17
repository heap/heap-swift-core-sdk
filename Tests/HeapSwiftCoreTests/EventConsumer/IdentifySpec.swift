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

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
                HeapLogger.shared.logLevel = .debug
            }
            
            afterEach {
                HeapLogger.shared.logLevel = .prod
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

                    var sessionTimestamp: Date!
                    var originalSessionId: String?

                    beforeEach {
                        sessionTimestamp = Date()
                        consumer.startRecording("11", timestamp: sessionTimestamp)
                        originalSessionId = consumer.activeOrExpiredSessionId
                    }

                    it("doesn't set the identity when given an empty string") {
                        consumer.identify("")

                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let state = dataStore.loadState(for: "11")
                        
                        expect(state.hasIdentity).to(beFalse(), description: "Values should not have changed")
                        expect(user.identity).to(beNil(), description: "Values should not have changed")
                    }
                    
                    context("called with a valid identity, before the session expires") {

                        var identifyTimestamp: Date!

                        beforeEach {
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(60)
                            consumer.identify("user1", timestamp: identifyTimestamp)
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

                        var identifyTimestamp: Date!

                        beforeEach {
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(600)
                            consumer.identify("user1", timestamp: identifyTimestamp)
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
                        
                        it("creates a new session and pageview") {
                            expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                            expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                            let user = try dataStore.assertOnlyOneUserToUpload()
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                            messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: identifyTimestamp, eventProperties: consumer.eventProperties)
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
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

                    var sessionTimestamp: Date!
                    var originalSessionId: String?

                    beforeEach {
                        sessionTimestamp = Date()
                        consumer.startRecording("11", timestamp: sessionTimestamp)
                        originalSessionId = consumer.activeOrExpiredSessionId
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

                        var identifyTimestamp: Date!

                        beforeEach {
                            identifyTimestamp = sessionTimestamp.addingTimeInterval(60)
                            consumer.identify("user1", timestamp: identifyTimestamp)
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
                        
                        it("resets event properties") {
                            let state = dataStore.loadState(for: "11")
                            expect(state.properties).to(equal([:]))
                        }
                        
                        it("creates a new session and pageview for the new user") {
                            expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                            expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                            let user = try dataStore.assertUserToUploadExists(with: consumer.userId!)
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                            messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: identifyTimestamp, eventProperties: consumer.eventProperties)
                        }
                        
                        it("extends the session") {
                            try consumer.assertSessionWasExtended(from: identifyTimestamp)
                        }
                    }
                }
            }
        }
    }
}
