import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_FetchSessionIdSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.fetchSessionId") {
            
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
                expect(consumer.fetchSessionId()).to(beNil())
            }

            it("does not extend the session before `startRecording` is called") {
                _ = consumer.fetchSessionId()
                expect(consumer.sessionExpirationDate).to(beNil())
            }
            
            it("returns nil after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                expect(consumer.fetchSessionId()).to(beNil())
            }
            
            it("does not extend the session after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                _ = consumer.fetchSessionId()
                expect(consumer.sessionExpirationDate).to(beNil())
            }

            context("Heap is recording") {

                beforeEach {
                    consumer.startRecording("11")
                }
                
                context("called before the first session starts") {
                    
                    var sessionTimestamp: Date!
                    var sessionId: String?
                    
                    beforeEach {
                        sessionTimestamp = Date()
                        sessionId = consumer.fetchSessionId(timestamp: sessionTimestamp)
                    }
                    
                    it("creates a new session") {
                        
                        guard let sessionId = consumer.activeOrExpiredSessionId else {
                            throw TestFailure("fetchSessionId should have created a new session.")
                        }

                        expect(sessionId).to(beAValidId())
            
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(1))
                    }
                    
                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: sessionTimestamp)
                    }

                    it("returns a current session id") {
                        expect(sessionId).to(equal(consumer.activeOrExpiredSessionId))
                    }
                }

                context("called before the session expires") {

                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var fetchSessionIdTimestamp: Date!
                    var sessionId: String?

                    beforeEach {
                        (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                        
                        fetchSessionIdTimestamp = sessionTimestamp.addingTimeInterval(60) // Before the session expires
                        sessionId = consumer.fetchSessionId(timestamp: fetchSessionIdTimestamp)
                    }

                    it("does not create a new session") {
                        expect(consumer.activeOrExpiredSessionId).to(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(1))
                    }
                        
                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: sessionTimestamp)
                    }

                    it("returns the current session id") {
                        expect(sessionId).to(equal(consumer.activeOrExpiredSessionId))
                    }
                }

                context("called after the session expires") {

                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var fetchSessionIdTimestamp: Date!
                    var sessionId: String?

                    beforeEach {
                        (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                        
                        fetchSessionIdTimestamp = sessionTimestamp.addingTimeInterval(600)
                        sessionId = consumer.fetchSessionId(timestamp: fetchSessionIdTimestamp)
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
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: fetchSessionIdTimestamp, eventProperties: consumer.eventProperties)
                    }
                    
                    it("notifies bridges and sources about the new session") {
                        expect(bridge.sessions).to(haveCount(2))
                        expect(source.sessions).to(equal(bridge.sessions))
                    }

                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: fetchSessionIdTimestamp)
                    }

                    it("returns the current session id") {
                        expect(sessionId).to(equal(consumer.activeOrExpiredSessionId))
                    }
                }
            }
        }
    }
}
