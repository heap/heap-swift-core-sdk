import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_ExtendSessionSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.extendSession") {
            
            var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            var restoreState: StateRestorer!

            beforeEach {
                (_, consumer, _, _, restoreState) = prepareEventConsumerWithCountingDelegates()
            }
            
            afterEach {
                restoreState()
            }
            
            it("doesn't change the state before `startRecording` is called") {
                consumer.extendSession(sessionId: "123", preferredExpirationDate: .init(timeIntervalSinceNow: 600))
                
                expect(consumer.stateManager.current).to(beNil())
            }
            
            it("doesn't change the state after `stopRecording` is called") {
                consumer.startRecording("11", with: [:])
                consumer.stopRecording()
                consumer.extendSession(sessionId: "123", preferredExpirationDate: .init(timeIntervalSinceNow: 600))
                
                expect(consumer.stateManager.current).to(beNil())
            }
            
            context("Heap is recording with a session") {
                
                var sessionTimestamp: Date!
                var originalSessionId: String!
                var originalExpirationDate: Date!
                
                beforeEach {
                    consumer.startRecording("11")
                    (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingIdentify()
                    originalExpirationDate = consumer.sessionExpirationDate
                }
                
                it("does not extend the session if the id doesn't match") {
                    
                    let preferredExpirationDate = sessionTimestamp.addingTimeInterval(600)
                    let expectedExpirationDate = originalExpirationDate!

                    consumer.extendSession(sessionId: "my session", preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("extends the session to the preferred time if it is in the range") {
                    
                    let preferredExpirationDate = sessionTimestamp.addingTimeInterval(600)
                    let expectedExpirationDate = preferredExpirationDate
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("extends the session to no less than the mobile extension") {
                    
                    let preferredExpirationDate = Date.distantPast
                    let expectedExpirationDate = sessionTimestamp.addingTimeInterval(60 * 5)
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("extends the session to no more than the web extension") {
                    
                    let preferredExpirationDate = Date.distantFuture
                    let expectedExpirationDate = sessionTimestamp.addingTimeInterval(60 * 30)
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("does not decrease the session expiration time when preferred date decreases") {
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantFuture, timestamp: sessionTimestamp)
                    let expectedExpirationDate = consumer.sessionExpirationDate!
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantPast, timestamp: sessionTimestamp)
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("does not decrease the session expiration time when timestamp decreases") {
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantPast, timestamp: sessionTimestamp)
                    let expectedExpirationDate = consumer.sessionExpirationDate!
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantPast, timestamp: sessionTimestamp.addingTimeInterval(-60))
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }

                it("extends an expired session") {
                    
                    let timestamp = originalExpirationDate.addingTimeInterval(60)
                    let preferredExpirationDate = timestamp.addingTimeInterval(600)

                    expect(consumer.getSessionId(timestamp: timestamp)).to(beNil())
                    
                    consumer.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: timestamp)
                    
                    expect(consumer.sessionExpirationDate).to(beCloseTo(preferredExpirationDate, within: 1))
                    expect(consumer.getSessionId(timestamp: timestamp)).to(equal(originalSessionId))
                }
            }
        }
    }
}
