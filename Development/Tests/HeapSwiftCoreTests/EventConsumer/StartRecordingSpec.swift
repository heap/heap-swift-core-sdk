import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

extension Option {
    static let myOption = Option.register(name: "myOption", type: .boolean)
}

final class EventConsumer_StartRecordingSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.startRecording") {
            
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

            context("without an existing persisted state") {

                var sessionTimestamp: Date!

                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", timestamp: sessionTimestamp)
                }

                it("creates a user") {
                    expect(consumer.userId).to(beAValidId())
                    expect(consumer.identity).to(beNil())
                }

                it("persists the new user") {
                    let state = dataStore.loadState(for: "11")
                    expect(state.userID).to(equal(consumer.userId))
                    expect(state.hasIdentity).to(beFalse())
                    expect(state.properties).to(equal([:]))
                }

                it("queues the new user for upload") {
                    let user = try dataStore.assertOnlyOneUserToUpload()

                    expect(user.userId).to(equal(consumer.userId))
                    expect(user.identity).to(beNil())
                    expect(user.pendingUserProperties).to(equal([:]))
                }
            }

            context("with an existing persisted state") {

                var sessionTimestamp: Date!
                var originalState: EnvironmentState!

                beforeEach {
                    sessionTimestamp = Date()
                    originalState = dataStore.applyIdentifiedState(to: "11")
                    consumer.startRecording("11", timestamp: sessionTimestamp)
                }

                it("uses the existing user") {
                    expect(consumer.userId).to(equal(originalState.userID))
                    expect(consumer.identity).to(equal(originalState.identity))
                    expect(consumer.eventProperties).to(equal(originalState.properties))
                }

                it("does not overwrite the original state") {
                    let state = dataStore.loadState(for: "11")
                    expect(state.userID).to(equal(originalState.userID))
                    expect(state.identity).to(equal(originalState.identity))
                    expect(state.properties).to(equal(originalState.properties))
                }

                it("queues the new user for upload if missing") {
                    let user = try dataStore.assertOnlyOneUserToUpload()

                    expect(user.userId).to(equal(consumer.userId))
                    expect(user.identity).to(equal(consumer.identity))
                    expect(user.pendingUserProperties).to(equal([:]))
                }
            }
            
            it("creates an expired session") {
                let sessionTimestamp = Date()
                consumer.startRecording("11", timestamp: sessionTimestamp)
                
                guard let sessionId = consumer.activeOrExpiredSessionId else {
                    throw TestFailure("Starting recording should have created an expired session.")
                }
                expect(sessionId).to(beEmpty())
                expect(consumer.sessionExpirationDate).to(equal(Date(timeIntervalSince1970: 0)))
            }

            it("creates a new session with a synthesized pageview and version change event when called with startSessionImmediately") {

                let sessionTimestamp = Date()
                consumer.startRecording("11", with: [ .startSessionImmediately: true ], timestamp: sessionTimestamp)

                let user = try dataStore.assertOnlyOneUserToUpload()

                guard let sessionId = consumer.activeOrExpiredSessionId else {
                    throw TestFailure("Starting recording should have created a new session.")
                }

                expect(sessionId).to(beAValidId())
                expect(user.sessionIds).to(equal([sessionId]))

                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: sessionTimestamp, eventProperties: consumer.eventProperties)
            }

            it("extends the session when called with startSessionImmediately") {

                let sessionTimestamp = Date()
                consumer.startRecording("11", with: [ .startSessionImmediately: true ], timestamp: sessionTimestamp)

                try consumer.assertSessionWasExtended(from: sessionTimestamp)
            }

            it("only runs once when called repeatedly with the same options") {
                consumer.startRecording("11", with: [ .myOption: true, .startSessionImmediately: true ])
                consumer.startRecording("11", with: [ .myOption: true, .startSessionImmediately: true ])
                consumer.startRecording("11", with: [ .myOption: true, .startSessionImmediately: true ])

                let user = try dataStore.assertOnlyOneUserToUpload()
                expect(user.sessionIds).to(haveCount(1))
            }

            it("reinitializes with a new session when called with different options") {
                consumer.startRecording("11", with: [ .myOption: true, .startSessionImmediately: true ])
                consumer.startRecording("11", with: [ .myOption: false, .startSessionImmediately: true ])

                let user = try dataStore.assertOnlyOneUserToUpload(message: "Calling the method multiple times, even with different options, should not have produced multiple users.")
                expect(user.sessionIds).to(haveCount(2))
            }

            it("creates new users when switching environments") {
                consumer.startRecording("11")
                consumer.startRecording("12")
                consumer.startRecording("13")
                consumer.startRecording("11")
                consumer.startRecording("12")
                consumer.startRecording("13")

                let usersToUpload = dataStore.usersToUpload()

                expect(usersToUpload).to(haveCount(3))
                expect(Set(usersToUpload.map(\.environmentId))).to(equal(["11", "12", "13"]))
                expect(Set(usersToUpload.map(\.userId))).to(haveCount(3), description: "Each environment should have its own persisted user ID")
            }
            
            it("creates new sessions when switching environments when called with startSessionImmediately") {
                consumer.startRecording("11", with: [ .startSessionImmediately: true ])
                consumer.startRecording("12", with: [ .startSessionImmediately: true ])
                consumer.startRecording("13", with: [ .startSessionImmediately: true ])
                consumer.startRecording("11", with: [ .startSessionImmediately: true ])
                consumer.startRecording("12", with: [ .startSessionImmediately: true ])
                consumer.startRecording("13", with: [ .startSessionImmediately: true ])

                let usersToUpload = dataStore.usersToUpload()

                expect(usersToUpload).to(haveCount(3))
                expect(usersToUpload.map(\.sessionIds)).to(allPass(haveCount(2)), description: "Each environment should have its own sessions, and switching should have produced new sessions")
            }

            it("triggers a cleanup of old data") {

                // Preconfigure the data store with data more than a month old
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date().addingTimeInterval(-3_000_000))
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "1234", identity: nil, creationDate: Date().addingTimeInterval(-3_000_000))
                dataStore.createNewUserIfNeeded(environmentId: "12", userId: "12345", identity: nil, creationDate: Date().addingTimeInterval(-3_000_000))

                expect(dataStore.usersToUpload()).to(haveCount(3), description: "PRECONDITION: Data store should have started with three users")
        
                consumer.startRecording("11")

                expect(dataStore.usersToUpload()).to(haveCount(1), description: "Data store should have purged three users and created one more")
            }
            
            context("with a source and bridge added") {
                
                var bridge: CountingRuntimeBridge!
                var source: CountingSource!

                beforeEach {
                    bridge = CountingRuntimeBridge()
                    source = CountingSource(name: "A", version: "1")
                    
                    consumer.addRuntimeBridge(bridge)
                    consumer.addSource(source, isDefault: false)
                    
                    consumer.startRecording("11")
                }
                
                it("calls .didStartRecording on sources and bridges") {

                    expect(bridge.calls).to(equal([
                        .didStartRecording,
                    ] + foregroundEventIfForegrounded()))
                    
                    expect(source.calls).to(equal([
                        .didStartRecording,
                    ] + foregroundEventIfForegrounded()))
                }
                
                it("calls .didStopRecording on sources and bridges") {

                    bridge.calls.removeAll()
                    source.calls.removeAll()
                    consumer.stopRecording()
                    
                    expect(bridge.calls).to(equal([
                        .didStopRecording
                    ]))
                    
                    expect(source.calls).to(equal([
                        .didStopRecording
                    ]))
                }
                
                it("does not call .didStopRecording on sources and bridges when called twice") {

                    bridge.calls.removeAll()
                    source.calls.removeAll()
                    consumer.startRecording("12")
                    
                    expect(bridge.calls).to(equal([
                        .didStartRecording,
                    ] + foregroundEventIfForegrounded()))
                    
                    expect(source.calls).to(equal([
                        .didStartRecording,
                    ] + foregroundEventIfForegrounded()))
                }
            }
            
            context("with a source and bridge added, called with startSessionImmediately") {
                
                var bridge: CountingRuntimeBridge!
                var source: CountingSource!

                beforeEach {
                    bridge = CountingRuntimeBridge()
                    source = CountingSource(name: "A", version: "1")
                    
                    consumer.addRuntimeBridge(bridge)
                    consumer.addSource(source, isDefault: false)
                    
                    consumer.startRecording("11", with: [ .startSessionImmediately: true ])
                }
                
                it("calls .didStartRecording and .sessionDidStart on sources and bridges") {

                    expect(bridge.calls).to(equal([
                        .didStartRecording,
                        .sessionDidStart,
                    ] + foregroundEventIfForegrounded()))
                    
                    expect(source.calls).to(equal([
                        .didStartRecording,
                        .sessionDidStart,
                    ] + foregroundEventIfForegrounded()))
                }
                
                it("calls .didStopRecording on sources and bridges") {

                    bridge.calls.removeAll()
                    source.calls.removeAll()
                    consumer.stopRecording()
                    
                    expect(bridge.calls).to(equal([
                        .didStopRecording
                    ]))
                    
                    expect(source.calls).to(equal([
                        .didStopRecording
                    ]))
                }
                
                it("does not call .didStopRecording on sources and bridges when called twice") {

                    bridge.calls.removeAll()
                    source.calls.removeAll()
                    consumer.startRecording("12", with: [ .startSessionImmediately: true ])
                    
                    expect(bridge.calls).to(equal([
                        .didStartRecording,
                        .sessionDidStart,
                    ] + foregroundEventIfForegrounded()))
                    
                    expect(source.calls).to(equal([
                        .didStartRecording,
                        .sessionDidStart,
                    ] + foregroundEventIfForegrounded()))
                }
            }
            
        }
    }

    // TODO: Validate the the uploader has been scheduled.  This will live outside the event consumer though.

    // TODO: Test that there calling `identify(...);stopRecording();startRecording(...)` does not lose data.  This needs to be done with an actual data store.
}
