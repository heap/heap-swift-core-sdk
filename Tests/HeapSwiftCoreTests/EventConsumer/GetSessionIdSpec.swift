import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class EventConsumer_GetSessionIdSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.getSessionid") {
            
            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore>!

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(dataStore: dataStore)
            }
            
            it("returns nil before `startRecording` is called") {
                expect(consumer.getSessionId()).to(beNil())
            }

            it("does not extend the session before `startRecording` is called") {
                _ = consumer.getSessionId()
                expect(consumer.sessionExpirationTime).to(beNil())
            }
            
            it("returns nil after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                expect(consumer.getSessionId()).to(beNil())
            }
            
            it("does not extend the session after `stopRecording` is called") {
                consumer.startRecording("11")
                consumer.stopRecording()
                _ = consumer.getSessionId()
                expect(consumer.sessionExpirationTime).to(beNil())
            }

            context("Heap is recording") {

                var sessionTimestamp: Date!
                var originalSessionId: String?

                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", timestamp: sessionTimestamp)
                    originalSessionId = consumer.activeOrExpiredSessionId
                }

                context("called before the session expires") {

                    var getSessionIdTimestamp: Date!
                    var sessionId: String?

                    beforeEach {
                        getSessionIdTimestamp = sessionTimestamp.addingTimeInterval(60)
                        sessionId = consumer.getSessionId(timestamp: getSessionIdTimestamp)
                    }

                    it("does not create a new session") {
                        expect(consumer.activeOrExpiredSessionId).to(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(1))
                    }
                        
                    it("does not extend the session") {
                        try consumer.assertSessionWasExtended(from: sessionTimestamp)
                    }

                    it("returns the current session id") {
                        expect(sessionId).to(equal(consumer.activeOrExpiredSessionId))
                    }
                }

                context("called after the session expires") {

                    var getSessionIdTimestamp: Date!
                    var sessionId: String?

                    beforeEach {
                        getSessionIdTimestamp = sessionTimestamp.addingTimeInterval(600)
                        sessionId = consumer.getSessionId(timestamp: getSessionIdTimestamp)
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
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: getSessionIdTimestamp, eventProperties: consumer.eventProperties)
                    }

                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: getSessionIdTimestamp)
                    }

                    it("returns the current session id") {
                        expect(sessionId).to(equal(consumer.activeOrExpiredSessionId))
                    }
                }
            }
        }
    }
}
