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
                it("returns empty values") {
                    let result = consumer.advanceOrExtendSession(source: .other)
                    expect(result.environmentId).to(beNil())
                    expect(result.userId).to(beNil())
                    expect(result.sessionId).to(beNil())
                    expect(result.newSessionCreated).to(beFalse())
                }
            }
            
            context("Heap is recording, with a session") {
                var sessionTimestamp: Date!
                
                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", with: [ .startSessionImmediately: true ])
                }
                
                context("calling with .other") {
                    let source = _ContentsquareSessionExtensionSource.other
                    
                    it("extends the session if not expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(60)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        try consumer.assertSessionWasExtended(from: timestamp)
                    }
                    
                    it("returns the current session details if not expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(60)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(equal(consumer.sessionId))
                        expect(properties.newSessionCreated).to(equal(false))
                    }
                    
                    it("create a new session if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        let originalSessionId = consumer.sessionId
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        try consumer.assertSessionWasExtended(from: timestamp)
                        expect(consumer.sessionId).notTo(equal(originalSessionId))
                    }
                    
                    it("returns the new session's details if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(equal(consumer.sessionId))
                        expect(properties.newSessionCreated).to(equal(true))
                    }
                    
                    it("mark the new session as coming from Contentsquare") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(consumer.currentSessionProperties).to(equal(.createdByContentsquare))
                    }
                }
                
                context("calling with .screenview") {
                    let source = _ContentsquareSessionExtensionSource.screenview
                    
                    it("extends the session if not expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(60)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        try consumer.assertSessionWasExtended(from: timestamp)
                    }
                    
                    it("returns the current session details if not expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(60)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(equal(consumer.sessionId))
                        expect(properties.newSessionCreated).to(equal(false))
                    }
                    
                    it("create a new session if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        let originalSessionId = consumer.sessionId
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        try consumer.assertSessionWasExtended(from: timestamp)
                        expect(consumer.sessionId).notTo(equal(originalSessionId))
                    }
                    
                    it("returns the new session's details if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(equal(consumer.sessionId))
                        expect(properties.newSessionCreated).to(equal(true))
                    }
                    
                    it("mark the new session as coming from a Contentsquare screen view") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(consumer.currentSessionProperties).to(equal(.createdByContentsquareScreenView))
                    }
                }
                
                context("calling with .appStartOrShow") {
                    let source = _ContentsquareSessionExtensionSource.appStartOrShow
                    
                    it("extends the session if not expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(60)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        try consumer.assertSessionWasExtended(from: timestamp)
                    }
                    
                    it("returns the current session details if not expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(60)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(equal(consumer.sessionId))
                        expect(properties.newSessionCreated).to(equal(false))
                    }
                    
                    it("does not create a new session if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        try consumer.assertSessionWasExtended(from: sessionTimestamp)
                        expect(consumer.getSessionId(timestamp: timestamp)).to(beNil())
                    }
                    
                    it("returns the null session details if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(beNil())
                        expect(properties.newSessionCreated).to(equal(false))
                    }
                }
            }
            
            context("Heap is recording, without a session") {
                var sessionTimestamp: Date!
                
                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", with: [ : ])
                }
                
                context("calling with .appStartOrShow") {
                    let source = _ContentsquareSessionExtensionSource.appStartOrShow
                    
                    it("does not create a new session if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        _ = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(consumer.getSessionId(timestamp: timestamp)).to(beNil())
                    }
                    
                    it("returns the null session details if expired") {
                        let timestamp = sessionTimestamp.addingTimeInterval(6000)
                        let properties = consumer.advanceOrExtendSession(source: source, timestamp: timestamp)
                        expect(properties.environmentId).to(equal("11"))
                        expect(properties.userId).to(equal(consumer.userId))
                        expect(properties.sessionId).to(beNil())
                        expect(properties.newSessionCreated).to(equal(false))
                    }
                }
            }
        }
    }
}
