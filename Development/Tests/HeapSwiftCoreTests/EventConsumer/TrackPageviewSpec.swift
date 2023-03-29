import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_TrackPageviewSpec: HeapSpec {
    
    override func spec() {
        
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
        
        describe("EventConsumer.trackPageview") {
            
            it("doesn't track a pageview before `startRecording` is called") {
                
                for n in 1...10 {
                    _ = consumer.trackPageview(.with({ $0.title = "page-\(n)" }))
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 2)
            }
            
            it("doesn't track a pageview after `stopRecording` is called") {
                
                consumer.startRecording("11")
                consumer.stopRecording()

                for n in 1...10 {
                    _ = consumer.trackPageview(.with({ $0.title = "page-\(n)" }))
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
                    var pageview: Pageview!
                    var finalState: State!

                    beforeEach {
                        trackTimestamp = sessionTimestamp.addingTimeInterval(60)
                        pageview = consumer.trackPageview(.with({ $0.title = "page 1" }), timestamp: trackTimestamp)
                        finalState = consumer.stateManager.current
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
                    
                    it("sets lastPageviewInfo") {
                        expect(finalState.lastPageviewInfo).to(equal(pageview._pageviewInfo))
                    }
                    
                    it("does not modify unattributedPageviewInfo") {
                        expect(finalState.unattributedPageviewInfo).notTo(equal(pageview._pageviewInfo))
                    }
                    
                    it("returns a pageview with the final session ID") {
                        expect(pageview.sessionId).to(equal(finalState.sessionInfo.id))
                    }

                    it("adds the pageview message at the end of the current session") {
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 3)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: sessionTimestamp, eventProperties: consumer.eventProperties)
                        
                        messages[2].expectPageviewMessage(user: user, timestamp: trackTimestamp, sessionMessage: messages[0])
                        expect(messages[2].pageviewInfo).to(equal(pageview._pageviewInfo))
                    }
                }

                context("called after the session expires") {
                    
                    var trackTimestamp: Date!
                    var pageview: Pageview!
                    var finalState: State!

                    beforeEach {
                        trackTimestamp = sessionTimestamp.addingTimeInterval(600)
                        pageview = consumer.trackPageview(.with({ $0.title = "page 1" }), timestamp: trackTimestamp)
                        finalState = consumer.stateManager.current
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
                    
                    it("sets lastPageviewInfo") {
                        expect(finalState.lastPageviewInfo).to(equal(pageview._pageviewInfo))
                    }
                    
                    it("does not modify unattributedPageviewInfo") {
                        expect(finalState.unattributedPageviewInfo).notTo(equal(pageview._pageviewInfo))
                    }
                    
                    it("returns a pageview with the final session ID") {
                        expect(pageview.sessionId).to(equal(finalState.sessionInfo.id))
                    }

                    it("uses the event time for session and unattributed pageview times") {
                        expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
                        let user = try dataStore.assertOnlyOneUserToUpload()

                        let messages = try dataStore.getPendingMessages(for: user, sessionId: consumer.activeOrExpiredSessionId!)
                        expect(messages.map(\.hasTime)).to(allPass(beTrue()))
                        expect(messages.map(\.time.date)).to(allPass(equal(trackTimestamp)))
                    }

                    it("adds the unattributed pageview immediately after the new session's session message") {
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 3)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: trackTimestamp, eventProperties: consumer.eventProperties)
                        expect(messages[1].pageviewInfo).to(equal(finalState.unattributedPageviewInfo))
                    }
                    
                    it("adds the provided pageview at the end of the new session") {
                        let user = try dataStore.assertOnlyOneUserToUpload()
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: consumer.activeOrExpiredSessionId, count: 3)
                        messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: trackTimestamp, eventProperties: consumer.eventProperties)
                        
                        messages[2].expectPageviewMessage(user: user, timestamp: trackTimestamp, sessionMessage: messages[0])
                        expect(messages[2].pageviewInfo).to(equal(pageview._pageviewInfo))
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

                it("populates the pageview info correctly") {
                    
                    let trackTimestamp = sessionTimestamp!
                    _ = consumer.trackPageview(.with({
                        $0.componentOrClassName = "MyViewController"
                        $0.title = "Home screen"
                        $0.url = URL(string: "https://example.com/path/to/resource.jsp?state=AAABBBCCCDDD#!/elsewhere")
                        $0.sourceProperties = ["a": 1, "b": "2", "c": false]
                    }), timestamp: trackTimestamp)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)

                    let sessionMessage = messages[0]
                    let pageviewMessage = messages[2]
                    let pageviewInfo = messages[2].pageviewInfo

                    messages.expectStartOfSessionWithSynthesizedPageview(user: user, sessionId: consumer.activeOrExpiredSessionId, sessionTimestamp: sessionTimestamp, eventProperties: consumer.eventProperties)
                    
                    pageviewMessage.expectPageviewMessage(user: user, sessionMessage: sessionMessage)
                    
                    expect(pageviewInfo.componentOrClassName).to(equal("MyViewController"))
                    expect(pageviewInfo.title).to(equal("Home screen"))
                    expect(pageviewInfo.url.domain).to(equal("example.com"))
                    expect(pageviewInfo.url.path).to(equal("/path/to/resource.jsp"))
                    expect(pageviewInfo.url.query).to(equal("state=AAABBBCCCDDD"))
                    expect(pageviewInfo.url.hash).to(equal("!/elsewhere"))
                    expect(pageviewInfo.sourceProperties["a"]).to(equal(.init(value: "1")))
                    expect(pageviewInfo.sourceProperties["b"]).to(equal(.init(value: "2")))
                    expect(pageviewInfo.sourceProperties["c"]).to(equal(.init(value: "false")))
                }
                
                
                it("sanitizes sourceProperties using [String: HeapPropertyValue].sanitized") {
                    
                    _ = consumer.trackPageview(.with({
                        $0.sourceProperties = [
                            "a": String(repeating: "あ", count: 1030),
                            "b": "    ",
                            " ": "test",
                            String(repeating: "あ", count: 513): "?",
                        ]
                    }))
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let pageviewInfo = messages[2].pageviewInfo
                    
                    expect(pageviewInfo.sourceProperties).to(equal([
                        "a": .init(value: String(repeating: "あ", count: 1024)),
                    ]))
                }
                
                it("truncates title") {
                    let longValue = String(repeating: "あ", count: 1030)
                    let expectedValue = String(repeating: "あ", count: 1024)
                    
                    _ = consumer.trackPageview(.with({
                        $0.title = longValue
                    }))
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let pageviewInfo = messages[2].pageviewInfo
                    
                    expect(pageviewInfo.title).to(equal(expectedValue))
                }
                
                it("records pageviews sequentially on the main thread") {

                    // Disable logging for this test because it's a lot of messages and slows things down.
                    HeapLogger.shared.logLevel = .info
                    
                    for n in 1...1000 {
                        _ = consumer.trackPageview(.with({ $0.title = "page-\(n)" }))
                    }

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 1002)

                    expect(messages.map(\.id)).to(allBeUniqueAndValidIds())

                    for n in 1...1000 {
                        let pageviewMessage = messages[n + 1]
                        pageviewMessage.expectPageviewMessage(user: user, sessionMessage: messages[0])
                        expect(pageviewMessage.pageviewInfo.title).to(equal("page-\(n)"), description: "Pageview received out of order")
                    }
                }
                
                it("records events sequentially from a background thread") {
                    
                    // Disable logging for this test because it's a lot of messages and slows things down.
                    HeapLogger.shared.logLevel = .info
                    
                    Thread.detachNewThread {
                        expect(Thread.isMainThread).to(beFalse(), description: "PRECONDITION: Expected work to happen in a background queue")
                        for n in 1...1000 {
                            _ = consumer.trackPageview(.with({ $0.title = "page-\(n)" }))
                        }
                    }
                    
                    // Background events dispatch tasks onto the main queue, so it needs a chance to process them.
                    CFRunLoopRunInMode(.defaultMode, 0.5, false)

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 1002)

                    expect(messages.map(\.id)).to(allBeUniqueAndValidIds())

                    for n in 1...1000 {
                        let pageviewMessage = messages[n + 1]
                        pageviewMessage.expectPageviewMessage(user: user, sessionMessage: messages[0])
                        expect(pageviewMessage.pageviewInfo.title).to(equal("page-\(n)"), description: "Pageview received out of order")
                    }
                }

                it("sets sourceLibrary when provided") {

                    let sourceInfo = SourceInfo(name: "heap-turbo-pascal", version: "0.0.0-beta.10", platform: "comadore 64", properties: ["a": 1, "b": false])
                    _ = consumer.trackPageview(.with({ _ in }), sourceInfo: sourceInfo)

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

                    messages[2].expectPageviewMessage(user: user, hasSourceLibrary: true, sourceLibrary: sourceLibrary)
                }

                it("uses the current event properties") {
                    consumer.addEventProperties(["a": 1, "b": 2, "c": true])
                    consumer.removeEventProperty("c")
                    _ = consumer.trackPageview(.with({ _ in }))
                    consumer.addEventProperties(["a": "hello", "d": "4"])
                    consumer.removeEventProperty("b")

                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)

                    messages[2].expectPageviewMessage(user: user, eventProperties: [
                        "a": .init(value: "1"),
                        "b": .init(value: "2"),
                    ])
                }
                
                it("returns a fully configured Pageview") {
                    
                    let sourceInfo = SourceInfo(name: "heap-turbo-pascal", version: "0.0.0-beta.10", platform: "comadore 64", properties: ["a": 1, "b": false])
                    let bridge = CountingRuntimeBridge()
                    let userInfo = NSObject()

                    let properties = PageviewProperties.with({
                        $0.title = "page 1 of 100"
                    })
                    
                    let pageview = consumer.trackPageview(properties, sourceInfo: sourceInfo, bridge: bridge, userInfo: userInfo)
                    
                    expect(pageview).notTo(beNil())
                    expect(pageview?.isNone).to(beFalse())
                    expect(pageview?._sessionInfo).to(equal(consumer.stateManager.current?.sessionInfo))
                    expect(pageview?._pageviewInfo).to(equal(consumer.stateManager.current?.lastPageviewInfo))
                    expect(pageview?._sourceLibrary).to(equal(sourceInfo.libraryInfo))
                    expect(pageview?._bridge as? CountingRuntimeBridge).to(equal(bridge))
                    expect(pageview?._isFromBridge).to(beTrue())
                    expect(pageview?.sessionId).to(equal(consumer.getSessionId()))
                    expect(pageview?.properties.title).to(equal(properties.title))
                    expect(pageview?.userInfo as? NSObject).to(equal(userInfo))
                }
                
                it("does not retrain the bridge") {
                    let pageview = consumer.trackPageview(.with({ _ in }), bridge: CountingRuntimeBridge())
                    expect(pageview?._bridge).toEventually(beNil())
                    expect(pageview?._isFromBridge).to(beTrue())
                }
            }
            
            context("field options are applied") {
                
                it("prevents pageview title capture when .disablePageviewTitleCapture is true") {

                    consumer.startRecording("11", with: [.disablePageviewTitleCapture: true])
                    
                    _ = consumer.trackPageview(.with({
                        $0.title = "FooTitle"
                    }))
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let pageviewInfo = messages[2].pageviewInfo
                    
                    expect(pageviewInfo.hasTitle).to(beFalse())
                    expect(consumer.stateManager.current?.lastPageviewInfo.hasTitle).to(beFalse())
                }
                
                it("does not capture pageview title on events attributed to the last pageview when title is disabled") {
                    
                    consumer.startRecording("11", with: [.disablePageviewTitleCapture: true])
                    
                    _ = consumer.trackPageview(.with({
                        $0.title = "FooTitle"
                    }))
                    
                    consumer.track("my event")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    let pageviewInfo = messages[3].pageviewInfo
                    
                    expect(pageviewInfo.hasTitle).to(beFalse())
                }
                
                it("does not capture pageview title on events attributed to the last pageview when title is disabled") {
                    
                    consumer.startRecording("11", with: [.disablePageviewTitleCapture: true])
                    
                    let pageview = consumer.trackPageview(.with({
                        $0.title = "FooTitle"
                    }))
                    
                    consumer.track("my event", pageview: pageview)
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    let pageviewInfo = messages[3].pageviewInfo
                    
                    expect(pageviewInfo.hasTitle).to(beFalse())
                }
                
                it("captures pageview title when .disablePageviewTitleCapture is false") {

                    consumer.startRecording("11", with: [.disablePageviewTitleCapture: false])
                    
                    _ = consumer.trackPageview(.with({
                        $0.title = "FooTitle"
                    }))
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                    let pageviewInfo = messages[2].pageviewInfo
                    
                    expect(pageviewInfo.title).to(equal("FooTitle"))
                    expect(consumer.stateManager.current?.lastPageviewInfo.title).to(equal("FooTitle"))
                }
            }
        }
    }
}
