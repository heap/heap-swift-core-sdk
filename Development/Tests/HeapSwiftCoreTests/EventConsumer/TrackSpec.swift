import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_TrackSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.track") {
            
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
                
                for n in 1...10 {
                    consumer.track("event-\(n)")
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 2)
            }
            
            it("doesn't track an event after `stopRecording` is called") {
                
                consumer.startRecording("11")
                consumer.stopRecording()

                for n in 1...10 {
                    consumer.track("event-\(n)")
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")

                for sessionId in user.sessionIds {
                    try dataStore.assertExactPendingMessagesCount(for: user, sessionId: sessionId, count: 2)
                }
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

                    var trackTimestamp: Date!

                    beforeEach {
                        trackTimestamp = sessionTimestamp.addingTimeInterval(60)
                        consumer.track("my-event", timestamp: trackTimestamp)
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
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 3)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: sessionTimestamp, eventProperties: consumer.eventProperties)
                        messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, hasSourceLibrary: false, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
                    }
                }

                context("called after the session expires") {

                    var trackTimestamp: Date!

                    beforeEach {
                        trackTimestamp = sessionTimestamp.addingTimeInterval(600)
                        consumer.track("my-event", timestamp: trackTimestamp)
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

                    let trackTimestamp = sessionTimestamp!
                    consumer.track("my-event", properties: ["a": 1, "b": "2", "c": false], timestamp: trackTimestamp)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)

                    let pageviewMessage = messages[1]
                    let eventMessage = messages[2]

                    messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: sessionTimestamp, eventProperties: consumer.eventProperties)

                    let event = try eventMessage.assertEventMessage(user: user, timestamp: trackTimestamp, hasSourceLibrary: false, eventProperties: consumer.eventProperties, pageviewMessage: pageviewMessage)
                    let customEvent = try event.assertIsCustomEvent()

                    expect(customEvent.name).to(equal("my-event"))
                    expect(customEvent.properties["a"]).to(equal(.init(value: "1")))
                    expect(customEvent.properties["b"]).to(equal(.init(value: "2")))
                    expect(customEvent.properties["c"]).to(equal(.init(value: "false")))
                }
                
                it("does not truncate properties exactly 1024 characters long") {
                    let value = String(repeating: "あ", count: 1024)
                    let expectedValue = value
                    
                    consumer.track("my-event", properties: ["key": value])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let event = try messages[2].assertEventMessage(user: user)
                    let customEvent = try event.assertIsCustomEvent()
                    
                    expect(customEvent.properties["key"]?.string).to(equal(expectedValue))
                    expect(customEvent.properties["key"]?.string.count).to(equal(expectedValue.count))
                }
                
                it("truncates properties that are more than 1024 characters long") {
                    let value = String(repeating: "あ", count: 1030)
                    let expectedValue = String(repeating: "あ", count: 1024)
                    
                    consumer.track("my-event", properties: ["key": value])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let event = try messages[2].assertEventMessage(user: user)
                    let customEvent = try event.assertIsCustomEvent()
                    
                    expect(customEvent.properties["key"]?.string).to(equal(expectedValue))
                    expect(customEvent.properties["key"]?.string.count).to(equal(expectedValue.count))
                }
                
                it("does not partially truncate emoji") {
                    let value = String(repeating: "あ", count: 1020).appending("👨‍👨‍👧‍👧")
                    let expectedValue = String(repeating: "あ", count: 1020)
                    
                    consumer.track("my-event", properties: ["key": value])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let event = try messages[2].assertEventMessage(user: user)
                    let customEvent = try event.assertIsCustomEvent()
                    
                    expect(customEvent.properties["key"]?.string).to(equal(expectedValue))
                    expect(customEvent.properties["key"]?.string.count).to(equal(expectedValue.count))
                }
                
                it("does not partially truncate diacritics") {
                    let value = String(repeating: "あ", count: 1000).appending("A̶̧̨̨̡̡̼̯̯͖̖͔̗̞̣̯̲̰̞̹͎̝̱̪̬̹̰͔̹̫̙̤̞̯͓̖̣͉̻̣̙͉̰̦͔͚̔̍̍̃͌͆̎̊̈̇̽̿̕͜͠͝ͅ")
                    let expectedValue = String(repeating: "あ", count: 1000)
                    
                    consumer.track("my-event", properties: ["key": value])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let event = try messages[2].assertEventMessage(user: user)
                    let customEvent = try event.assertIsCustomEvent()
                    
                    expect(customEvent.properties["key"]?.string).to(equal(expectedValue))
                    expect(customEvent.properties["key"]?.string.count).to(equal(expectedValue.count))
                }
                
                it("does not omit properties where the key is the maximum length") {
                    let key = String(repeating: "あ", count: 512)
                    
                    consumer.track("my-event", properties: [key: "value"])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let event = try messages[2].assertEventMessage(user: user)
                    let customEvent = try event.assertIsCustomEvent()
                    
                    expect(customEvent.properties[key]).toNot(beNil())
                }
                
                it("omits properties where the key is above the maximum length") {
                    let key = String(repeating: "あ", count: 513)
                    
                    consumer.track("my-event", properties: [key: "value"])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let event = try messages[2].assertEventMessage(user: user)
                    let customEvent = try event.assertIsCustomEvent()
                    
                    expect(customEvent.properties[key]).to(beNil())
                }
                
                it("sends events where the event name is the maximum length") {
                    let name = String(repeating: "あ", count: 512)
                    consumer.track(name)
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                }
                
                it("does not send event where the event name is above the maximum length") {
                    let name = String(repeating: "あ", count: 513)
                    consumer.track(name)
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 2)
                }

                it("records events sequentially on the main thread") {

                    // Disable logging for this test because it's a lot of messages and slows things down.
                    HeapLogger.shared.logLevel = .prod
                    
                    for n in 1...1000 {
                        consumer.track("event-\(n)")
                    }

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 1002)

                    expect(messages.map(\.id)).to(allBeUniqueAndValidIds())

                    for n in 1...1000 {
                        let eventMessage = messages[n + 1]
                        let event = try eventMessage.assertEventMessage(user: user, pageviewMessage: messages[1])
                        let customEvent = try event.assertIsCustomEvent()
                        expect(customEvent.name).to(equal("event-\(n)"), description: "Event received out of order")
                    }
                }
                
                it("records events sequentially from a background thread") {
                    
                    // Disable logging for this test because it's a lot of messages and slows things down.
                    HeapLogger.shared.logLevel = .prod
                    
                    Thread.detachNewThread {
                        expect(Thread.isMainThread).to(beFalse(), description: "PRECONDITION: Expected work to happen in a background queue")
                        for n in 1...1000 {
                            consumer.track("event-\(n)")
                        }
                    }
                    
                    // Background events dispatch tasks onto the main queue, so it needs a chance to process them.
                    CFRunLoopRunInMode(.defaultMode, 0.5, false)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 1002)

                    expect(messages.map(\.id)).to(allBeUniqueAndValidIds())

                    for n in 1...1000 {
                        let eventMessage = messages[n + 1]
                        let event = try eventMessage.assertEventMessage(user: user, pageviewMessage: messages[1])
                        let customEvent = try event.assertIsCustomEvent()
                        expect(customEvent.name).to(equal("event-\(n)"), description: "Event received out of order")
                    }
                }

                it("sets sourceLibrary when provided") {

                    let sourceInfo = SourceInfo(name: "heap-turbo-pascal", version: "0.0.0-beta.10", platform: "comadore 64", properties: ["a": 1, "b": false])
                    consumer.track("my-event", sourceInfo: sourceInfo)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)

                    var sourceLibrary = LibraryInfo()
                    sourceLibrary.name = "heap-turbo-pascal"
                    sourceLibrary.version = "0.0.0-beta.10"
                    sourceLibrary.platform = "comadore 64"
                    sourceLibrary.properties = [
                        "a": .init(value: "1"),
                        "b": .init(value: "false"),
                    ]

                    messages[2].expectEventMessage(user: user, hasSourceLibrary: true, sourceLibrary: sourceLibrary)
                }

                it("uses the current event properties") {
                    consumer.addEventProperties(["a": 1, "b": 2, "c": true])
                    consumer.removeEventProperty("c")
                    consumer.track("my-event")
                    consumer.addEventProperties(["a": "hello", "d": "4"])
                    consumer.removeEventProperty("b")

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)

                    messages[2].expectEventMessage(user: user, eventProperties: [
                        "a": .init(value: "1"),
                        "b": .init(value: "2"),
                    ])
                }
            }
        }
    }
}
