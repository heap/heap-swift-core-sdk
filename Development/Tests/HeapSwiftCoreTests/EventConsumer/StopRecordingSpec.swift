import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

// NOTE: Most behaviors around stop recording are covered in other tests, demonstrating that they
// don't do anything before `startRecording` and after `stopRecording`.  This demonstrates
// specifics of `stopRecording`.
final class EventConsumer_StopRecordingSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.startRecording") {
            
            var dataStore: InMemoryDataStore!
            var consumer1: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            var consumer2: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            
            beforeEach {
                dataStore = InMemoryDataStore()
                consumer1 = EventConsumer(stateStore: dataStore, dataStore: dataStore)
                consumer2 = EventConsumer(stateStore: dataStore, dataStore: dataStore)
                HeapLogger.shared.logLevel = .trace
            }
            
            afterEach {
                HeapLogger.shared.logLevel = .info
            }
            
            context("when followed by startRecording on the same consumer") {
                it("does not clear the current user or session when no parameters are given") {
                    consumer1.startRecording("11", with: [ .startSessionImmediately: true ])
                    let userId = consumer1.userId
                    let sessionId = consumer1.sessionId
                    consumer1.stopRecording()
                    consumer1.startRecording("11", with: [ .resumePreviousSession: true ])
                    
                    expect(consumer1.userId).to(equal(userId))
                    expect(consumer1.sessionId).to(equal(sessionId))
                }
                
                it("does not clear the current user or session when deleteUser is false") {
                    consumer1.startRecording("11", with: [ .startSessionImmediately: true ])
                    let userId = consumer1.userId
                    let sessionId = consumer1.sessionId
                    consumer1.stopRecording(deleteUser: false)
                    consumer1.startRecording("11", with: [ .resumePreviousSession: true ])
                    
                    expect(consumer1.userId).to(equal(userId))
                    expect(consumer1.sessionId).to(equal(sessionId))
                }
                
                it("clears the current user and session when deleteUser is true") {
                    consumer1.startRecording("11", with: [ .startSessionImmediately: true ])
                    let userId = consumer1.userId
                    consumer1.stopRecording(deleteUser: true)
                    consumer1.startRecording("11", with: [ .resumePreviousSession: true ])
                    
                    expect(consumer1.userId).notTo(equal(userId))
                    expect(consumer1.sessionId).to(beNil())
                }
            }
            
            context("when followed by startRecording on a different consumer") {
                it("does not clear the current user or session when no parameters are given") {
                    consumer1.startRecording("11", with: [ .startSessionImmediately: true ])
                    let userId = consumer1.userId
                    let sessionId = consumer1.sessionId
                    consumer1.stopRecording()
                    consumer2.startRecording("11", with: [ .resumePreviousSession: true ])
                    
                    expect(consumer2.userId).to(equal(userId))
                    expect(consumer2.sessionId).to(equal(sessionId))
                }
                
                it("does not clear the current user or session when deleteUser is false") {
                    consumer1.startRecording("11", with: [ .startSessionImmediately: true ])
                    let userId = consumer1.userId
                    let sessionId = consumer1.sessionId
                    consumer1.stopRecording(deleteUser: false)
                    consumer2.startRecording("11", with: [ .resumePreviousSession: true ])
                    
                    expect(consumer2.userId).to(equal(userId))
                    expect(consumer2.sessionId).to(equal(sessionId))
                }
                
                it("clears the current user and session when deleteUser is true") {
                    consumer1.startRecording("11", with: [ .startSessionImmediately: true ])
                    let userId = consumer1.userId
                    consumer1.stopRecording(deleteUser: true)
                    consumer2.startRecording("11", with: [ .resumePreviousSession: true ])
                    
                    expect(consumer2.userId).notTo(equal(userId))
                    expect(consumer2.sessionId).to(beNil())
                }
            }
        }
    }
}
