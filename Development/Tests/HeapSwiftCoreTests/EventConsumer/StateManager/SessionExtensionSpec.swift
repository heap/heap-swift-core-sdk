import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class SessionExtensionSpec: HeapSpec {
    
    override func spec() {
        
        var manager: StateManager<InMemoryDataStore>!
        let sessionTimestamp = Date(timeIntervalSinceReferenceDate: 0)
        var originalSessionId: String!
        var originalExpirationTime: Date!
        
        beforeEach {
            manager = .init(stateStore: InMemoryDataStore())
            let result = manager.start(environmentId: "11", sanitizedOptions: [
                .startSessionImmediately: true,
            ], at: sessionTimestamp)
            originalSessionId = result.current!.sessionInfo.id
            originalExpirationTime = result.current!.sessionExpirationDate
        }
        
        describe("createSessionIfExpired") {
            
            it("does nothing if not expired and extendIfNotExpired is false") {
                let timestamp = sessionTimestamp.addingTimeInterval(60)
                
                let result = manager.createSessionIfExpired(extendIfNotExpired: false, properties: .init(), at: timestamp)
                
                expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                expect(result.current?.sessionExpirationDate).to(beCloseTo(originalExpirationTime, within: 1))
            }
            
            it("extends the session if not expired and extendIfNotExpired is true") {
                let timestamp = sessionTimestamp.addingTimeInterval(60)
                let expectedExpirationDate = timestamp.addingTimeInterval(300)
                
                let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp)
                
                expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("creates a new session if expired") {
                let timestamp = sessionTimestamp.addingTimeInterval(60000)
                let expectedExpirationDate = timestamp.addingTimeInterval(300)
                
                let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp)
                
                expect(result.current?.sessionInfo.id).toNot(equal(originalSessionId))
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("does not decrease the session expiration time when date decreases extendIfNotExpired is true") {
                let originalResult = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantFuture, timestamp: sessionTimestamp)
                let expectedExpirationDate = originalResult.current!.sessionExpirationDate
                
                let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: sessionTimestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("does not apply contentsquareProperties when extending the session") {
                let timestamp = sessionTimestamp.addingTimeInterval(60)
                let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .fromContentsquareScreenView, at: timestamp)
                
                expect(result.current?.contentsquareSessionProperties.createdByContentsquareScreenView).to(beFalse())
            }

            
            it("applies contentsquareProperties when creating the session") {
                let timestamp = sessionTimestamp.addingTimeInterval(60000)
                let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .fromContentsquareScreenView, at: timestamp)
                
                expect(result.current?.contentsquareSessionProperties.createdByContentsquareScreenView).to(beTrue())
            }
            
            context("with _ContentsquareIntegration") {
                
                var integration: CountingContentsquareIntegration!
                
                beforeEach {
                    integration = CountingContentsquareIntegration(sessionTimeoutDuration: 600)
                    manager.contentsquareIntegration = integration
                }
                
                it("extends the session using the Contentsquare expiration date if greater than the default") {
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    let expectedExpirationDate = timestamp.addingTimeInterval(600)
                    
                    let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp)
                    
                    expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                    expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("extends the session using the Heap timeout if greater than the the Contentsquare expiration date") {
                    integration.sessionTimeoutDuration = 5
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    let expectedExpirationDate = timestamp.addingTimeInterval(300)
                    
                    let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp)
                    
                    expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                    expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("extends can extend the session arbitrarily far") {
                    integration.sessionTimeoutDuration = 600_000
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    let expectedExpirationDate = timestamp.addingTimeInterval(600_000)
                    
                    let result = manager.createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp)
                    
                    expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                    expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
            }
        }
        
        describe("extendSessionAndSetLastPageview") {
            
            it("extends the session if not expired") {
                let timestamp = sessionTimestamp.addingTimeInterval(60)
                let expectedExpirationDate = timestamp.addingTimeInterval(300)
                
                var pageview = PageviewInfo(newPageviewAt: timestamp)
                let result = manager.extendSessionAndSetLastPageview(&pageview)
                
                expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("creates a new session if expired") {
                let timestamp = sessionTimestamp.addingTimeInterval(60000)
                let expectedExpirationDate = timestamp.addingTimeInterval(300)
                
                var pageview = PageviewInfo(newPageviewAt: timestamp)
                let result = manager.extendSessionAndSetLastPageview(&pageview)
                
                expect(result.current?.sessionInfo.id).toNot(equal(originalSessionId))
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("does not decrease the session expiration time when date decreases") {
                let originalResult = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantFuture, timestamp: sessionTimestamp)
                let expectedExpirationDate = originalResult.current!.sessionExpirationDate
                
                var pageview = PageviewInfo(newPageviewAt: sessionTimestamp)
                let result = manager.extendSessionAndSetLastPageview(&pageview)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
        }
        
        
        describe("extendSession") {
            
            it("does not extend the session if the id doesn't match") {
                
                let preferredExpirationDate = sessionTimestamp.addingTimeInterval(600)
                let expectedExpirationDate = originalExpirationTime!
                
                let result = manager.extendSession(sessionId: "my session", preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("extends the session to the preferred time if it is in the range") {
                
                let preferredExpirationDate = sessionTimestamp.addingTimeInterval(600)
                let expectedExpirationDate = preferredExpirationDate
                
                let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("extends the session to no less than the mobile extension") {
                
                let preferredExpirationDate = Date.distantPast
                let expectedExpirationDate = sessionTimestamp.addingTimeInterval(60 * 5)
                
                let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("extends the session to no more than the web extension") {
                
                let preferredExpirationDate = Date.distantFuture
                let expectedExpirationDate = sessionTimestamp.addingTimeInterval(60 * 30)
                
                let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: sessionTimestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("does not decrease the session expiration time when preferred date decreases") {
                let originalResult = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantFuture, timestamp: sessionTimestamp)
                let expectedExpirationDate = originalResult.current!.sessionExpirationDate
                
                let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantPast, timestamp: sessionTimestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("does not decrease the session expiration time when timestamp decreases") {
                let originalResult = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantFuture, timestamp: sessionTimestamp)
                let expectedExpirationDate = originalResult.current!.sessionExpirationDate
                
                let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: .distantPast, timestamp: sessionTimestamp.addingTimeInterval(-60))
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
            }
            
            it("extends an expired session") {
                
                let timestamp = originalExpirationTime.addingTimeInterval(60)
                let preferredExpirationDate = timestamp.addingTimeInterval(600)
                
                let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: timestamp)
                
                expect(result.current?.sessionExpirationDate).to(beCloseTo(preferredExpirationDate, within: 1))
                expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
            }
            
            context("with _ContentsquareIntegration") {
                
                var integration: CountingContentsquareIntegration!
                
                beforeEach {
                    integration = CountingContentsquareIntegration(sessionTimeoutDuration: 600)
                    manager.contentsquareIntegration = integration
                }
                
                it("extends the session using the Contentsquare expiration date if greater than the preferred date") {
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    let preferredExpirationDate = timestamp.addingTimeInterval(400)
                    let expectedExpirationDate = timestamp.addingTimeInterval(600)
                    
                    let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: timestamp)
                    
                    expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                    expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
                
                it("extends the session using the preferred date if greater than the Contentsquare expiration date") {
                    let timestamp = sessionTimestamp.addingTimeInterval(60)
                    let preferredExpirationDate = timestamp.addingTimeInterval(1000)
                    let expectedExpirationDate = timestamp.addingTimeInterval(1000)
                    
                    let result = manager.extendSession(sessionId: originalSessionId, preferredExpirationDate: preferredExpirationDate, timestamp: timestamp)
                    
                    expect(result.current?.sessionInfo.id).to(equal(originalSessionId))
                    expect(result.current?.sessionExpirationDate).to(beCloseTo(expectedExpirationDate, within: 1))
                }
            }
        }
    }
}
