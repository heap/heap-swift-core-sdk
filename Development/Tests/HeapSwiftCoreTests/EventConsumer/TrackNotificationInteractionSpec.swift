import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_TrackNotificationInteractionSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.trackNotificationInteraction") {
            
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
            
            it("doesn't track an event before `startRecording` is called") {
                
                for _ in 1...10 {
                    consumer.trackNotificationInteraction(properties: .init())
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.sessionIds).to(beEmpty(), description: "No events should have been sent, so there shouldn't be a session.")
            }
            
            it("doesn't track an event after `stopRecording` is called") {
                
                consumer.startRecording("11")
                consumer.stopRecording()

                for _ in 1...10 {
                    consumer.trackNotificationInteraction(properties: .init())
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")

                for sessionId in user.sessionIds {
                    try dataStore.assertExactPendingMessagesCount(for: user, sessionId: sessionId, count: 2)
                }
            }
            
            context("Heap is recording") {

                beforeEach {
                    consumer.startRecording("11")
                }

                context("called before the session expires") {

                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var trackTimestamp: Date!

                    beforeEach {
                        (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingIdentify()
                        trackTimestamp = sessionTimestamp.addingTimeInterval(60)
                        consumer.trackNotificationInteraction(properties: .init(), timestamp: trackTimestamp)
                    }

                    it("does not create a new user") {
                        try dataStore.assertOnlyOneUserToUpload()
                    }

                    it("does not create a new session") {
                        expect(consumer.activeOrExpiredSessionId).to(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(1))
                    }
                        
                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: trackTimestamp)
                    }

                    it("adds the event to the current session") {
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 4)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, eventProperties: consumer.eventProperties)
                        messages[3].expectEventMessage(user: user, timestamp: trackTimestamp, hasSourceLibrary: false, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
                    }
                }

                context("called after the session expires") {
                    
                    var sessionTimestamp: Date!
                    var originalSessionId: String?
                    var trackTimestamp: Date!

                    beforeEach {
                        (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingIdentify()
                        trackTimestamp = sessionTimestamp.addingTimeInterval(600)
                        consumer.trackNotificationInteraction(properties: .init(), timestamp: trackTimestamp)
                    }

                    it("does not create a new user") {
                        try dataStore.assertOnlyOneUserToUpload()
                    }

                    it("creates a new session") {
                        expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        expect(user.sessionIds.count).to(equal(2))
                    }
                    
                    it("notifies bridges and sources about the new session") {
                        expect(bridge.sessions).to(haveCount(2))
                        expect(source.sessions).to(equal(bridge.sessions))
                    }

                    it("extends the session") {
                        try consumer.assertSessionWasExtended(from: trackTimestamp)
                    }

                    it("uses the event time for session and pageview times") {
                        expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()

                        let messages = try dataStore.getPendingMessages(for: user, sessionId: consumer.activeOrExpiredSessionId!)
                        expect(messages.map(\.hasTime)).to(allPass(beTrue()))
                        expect(messages.map(\.time.date)).to(allPass(equal(trackTimestamp)))
                    }

                    it("adds the event to the new session") {
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 3)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: trackTimestamp, eventProperties: consumer.eventProperties)
                        messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, hasSourceLibrary: false, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
                    }

                    it("produces valid messages in the new session") {

                        let user = try dataStore.assertOnlyOneUserToUpload()
                        let firstSessionMessages = try dataStore.getPendingMessages(for: user, sessionId: originalSessionId)
                        let secondSessionMessages = try dataStore.getPendingMessages(for: user, sessionId: consumer.activeOrExpiredSessionId)
                        
                        expect((firstSessionMessages + secondSessionMessages).map(\.id)).to(allBeUniqueAndValidIds())
                        try firstSessionMessages.assertAllSessionInfosMatch()
                        try secondSessionMessages.assertAllSessionInfosMatch()
                    }
                }

                it("populates the event correctly") {

                    let trackTimestamp = Date()
                    consumer.trackNotificationInteraction(properties: .with({
                        $0.source = .geofence
                        $0.titleText = "Title"
                        $0.bodyText = "Body"
                        $0.action = "Action"
                        $0.category = "Category"
                        $0.componentOrClassName = "Component"
                    }), timestamp: trackTimestamp)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)

                    let pageviewMessage = messages[1]
                    let eventMessage = messages[3]

                    messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, eventProperties: consumer.eventProperties)

                    let event = try eventMessage.assertEventMessage(user: user, timestamp: trackTimestamp, hasSourceLibrary: false, eventProperties: consumer.eventProperties, pageviewMessage: pageviewMessage)
                    let notificationEvent = try event.assertIsNotificationInteractionEvent()

                    expect(notificationEvent.source).to(equal(.sourceGeofence))
                    expect(notificationEvent.titleText).to(equal("Title"))
                    expect(notificationEvent.bodyText).to(equal("Body"))
                    expect(notificationEvent.action).to(equal("Action"))
                    expect(notificationEvent.category).to(equal("Category"))
                    expect(notificationEvent.componentOrClassName).to(equal("Component"))
                }
                
                it("truncates properties") {

                    consumer.startRecording("11")
                    consumer.trackNotificationInteraction(properties: .with({
                        $0.titleText = String(repeating: "あ", count: 1030)
                        $0.bodyText = String(repeating: "あ", count: 1030)
                        $0.action = String(repeating: "あ", count: 1030)
                        $0.category = String(repeating: "あ", count: 1030)
                        $0.componentOrClassName = String(repeating: "あ", count: 1030)
                    }))

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    let event = try messages[3].assertEventMessage(user: user)
                    let notificationEvent = try event.assertIsNotificationInteractionEvent()
                    
                    expect(notificationEvent.titleText).to(equal(String(repeating: "あ", count: 1024)))
                    expect(notificationEvent.bodyText).to(equal(String(repeating: "あ", count: 1024)))
                    expect(notificationEvent.action).to(equal(String(repeating: "あ", count: 1024)))
                    expect(notificationEvent.category).to(equal(String(repeating: "あ", count: 1024)))
                    expect(notificationEvent.componentOrClassName).to(equal(String(repeating: "あ", count: 1024)))
                }

                it("sets sourceLibrary when provided") {

                    let sourceInfo = SourceInfo(name: "heap-turbo-pascal", version: "0.0.0-beta.10", platform: "comadore 64", properties: ["a": 1, "b": false])
                    consumer.trackNotificationInteraction(properties: .init(), sourceInfo: sourceInfo)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)

                    var sourceLibrary = LibraryInfo()
                    sourceLibrary.name = "heap-turbo-pascal"
                    sourceLibrary.version = "0.0.0-beta.10"
                    sourceLibrary.platform = "comadore 64"
                    sourceLibrary.properties = [
                        "a": .init(value: "1"),
                        "b": .init(value: "false"),
                    ]

                    messages[3].expectEventMessage(user: user, hasSourceLibrary: true, sourceLibrary: sourceLibrary)
                }

                it("uses the current event properties") {
                    consumer.addEventProperties(["a": 1, "b": 2, "c": true])
                    consumer.removeEventProperty("c")
                    consumer.trackNotificationInteraction(properties: .init())
                    consumer.addEventProperties(["a": "hello", "d": "4"])
                    consumer.removeEventProperty("b")

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)

                    messages[3].expectEventMessage(user: user, eventProperties: [
                        "a": .init(value: "1"),
                        "b": .init(value: "2"),
                    ])
                }
            }
        }
    }
}
