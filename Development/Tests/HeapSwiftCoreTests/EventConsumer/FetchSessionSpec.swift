import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_FetchSessionSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.fetchSession") {
            
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
            
            it("returns nil before `startRecording` is called") {
                expect(consumer.fetchSession()).to(beNil())
            }

            it("does not extend the session before `startRecording` is called") {
                _ = consumer.fetchSession()
                expect(consumer.sessionExpirationTime).to(beNil())
            }
            
            it("returns nil after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                expect(consumer.fetchSession()).to(beNil())
            }
            
            it("does not extend the session after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                _ = consumer.fetchSession()
                expect(consumer.sessionExpirationTime).to(beNil())
            }

            context("Heap is recording") {

                beforeEach {
                    consumer.startRecording("11")
                }
                
                context("called before the first session starts") {
                    
                    var sessionTimestamp: Date!
                    var state: State?
                    
                    beforeEach {
                        sessionTimestamp = Date()
                        state = consumer.fetchSession(timestamp: sessionTimestamp)
                    }
                    
                    it("creates a new session") {
                        
                        guard let sessionId = consumer.activeOrExpiredSessionId else {
                            throw TestFailure("fetchSession should have created a new session.")
                        }

                        expect(sessionId).to(beAValidId())
            
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(1))
                    }
                    
                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: sessionTimestamp)
                    }

                    it("returns a current state") {
                        expect(state?.sessionInfo).to(equal(consumer.stateManager.current?.sessionInfo))
                        expect(state?.environment).to(equal(consumer.stateManager.current?.environment))
                    }
                }

                context("called before the session expires") {

                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var fetchSessionTimestamp: Date!
                    var state: State?

                    beforeEach {
                        (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                        
                        fetchSessionTimestamp = sessionTimestamp.addingTimeInterval(60) // Before the session expires
                        state = consumer.fetchSession(timestamp: fetchSessionTimestamp)
                    }

                    it("does not create a new session") {
                        expect(consumer.activeOrExpiredSessionId).to(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(1))
                    }
                        
                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: sessionTimestamp)
                    }

                    it("returns a current state") {
                        expect(state?.sessionInfo).to(equal(consumer.stateManager.current?.sessionInfo))
                        expect(state?.environment).to(equal(consumer.stateManager.current?.environment))
                    }
                }

                context("called after the session expires") {

                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var fetchSessionTimestamp: Date!
                    var state: State?

                    beforeEach {
                        (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                        
                        fetchSessionTimestamp = sessionTimestamp.addingTimeInterval(600)
                        state = consumer.fetchSession(timestamp: fetchSessionTimestamp)
                    }

                    it("does not create a new user") {
                        try dataStore.assertOnlyOneUserToUpload()
                    }
                        
                    it("creates a new session and pageview") {
                        expect(consumer.activeOrExpiredSessionId).notTo(beNil())
                        expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                            
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(2))

                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 2)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: fetchSessionTimestamp, eventProperties: consumer.eventProperties)
                    }
                    
                    it("notifies bridges and sources about the new session") {
                        expect(bridge.sessions).to(haveCount(2))
                        expect(source.sessions).to(equal(bridge.sessions))
                    }

                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: fetchSessionTimestamp)
                    }

                    it("returns a current state") {
                        expect(state?.sessionInfo).to(equal(consumer.stateManager.current?.sessionInfo))
                        expect(state?.environment).to(equal(consumer.stateManager.current?.environment))
                    }
                }
            }
        }
    }
}
