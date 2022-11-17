import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

import XCTest

final class PageviewResolutionSpec: HeapSpec {

    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            consumer.startRecording("11")
            HeapLogger.shared.logLevel = .debug
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .prod
        }
        
        describe("EventConsumer.track") {
            
            context("a pageview is provided") {
                
                it("resolves Pageview.none to the initial pageview") {
                    
                    _ = consumer.trackPageview(.with({ $0.title = "A" }))
                    
                    consumer.track("event", pageview: Pageview.none)
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                    
                    expect(messages.last?.pageviewInfo).to(equal(consumer.stateManager.current?.unattributedPageviewInfo))
                }
                
                it("resolves provided pageviews from the current session to that pageview") {
                    let pageview = consumer.trackPageview(.with({ $0.title = "A" }))
                    _ = consumer.trackPageview(.with({ $0.title = "B" }))

                    consumer.track("event", pageview: pageview)
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)
                    
                    expect(messages.last?.pageviewInfo).to(equal(pageview?.pageviewInfo))
                }
                
                context("the provided pageview is from another session") {
                    
                    var bridge: CountingRuntimeBridge!
                    var defaultSource: CountingSource!

                    beforeEach {
                        bridge = CountingRuntimeBridge()
                        defaultSource = CountingSource(name: "A", version: "1")
                        consumer.addSource(defaultSource, isDefault: true)
                    }
                    
                    context("the pageview has a bridge") {
                        it("requests a reissue of the pageview from the bridge") {
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), bridge: bridge)
                            consumer.track("event", timestamp: session2Timestamp, pageview: stalePageview)
                            
                            expect(bridge.calls).toEventually(equal([
                                .reissuePageview,
                            ]))
                        }
                        
                        it("returns the pageview from the bridge if it is in the current session") {
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), bridge: bridge)
                            consumer.track("event", timestamp: session2Timestamp, pageview: stalePageview)
                            
                            let pageview = consumer.trackPageview(.with({ $0.title = "B" }))
                            _ = consumer.trackPageview(.with({ $0.title = "C" }))

                            bridge.resolveReissuePageview(pageview)
                            
                            let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: pageview?.sessionId, count: 5)
                            
                            expect(messages.last?.pageviewInfo).to(equal(pageview?.pageviewInfo))
                        }
                        
                        it("falls back to the default source if the bridge returns a stale pageview") {
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), bridge: bridge)
                            let stalePageview2 = consumer.trackPageview(.with({ $0.title = "B" }), bridge: bridge)
                            consumer.track("event", timestamp: session2Timestamp, pageview: stalePageview)
                            
                            _ = consumer.trackPageview(.with({ $0.title = "C" }))

                            bridge.resolveReissuePageview(stalePageview2)
                            
                            expect(defaultSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                        }
                        
                        it("falls back to the default source if the bridge returns nil") {
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), bridge: bridge)
                            consumer.track("event", timestamp: session2Timestamp, pageview: stalePageview)
                            
                            bridge.resolveReissuePageview(nil)
                            
                            expect(defaultSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                        }
                        
                        it("does not fall back to the pageview source with a matching name") {
                            
                            // We don't fall back because bridged pageviews expect bridged sources, not native ones.
                            
                            let source = CountingSource(name: "B", version: "1")
                            let sourceInfo = SourceInfo(name: "B", version: "1", platform: "bridged")
                            consumer.addSource(source)

                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), sourceInfo: sourceInfo, bridge: bridge)
                            consumer.track("event", timestamp: session2Timestamp, pageview: stalePageview)
                            
                            bridge.resolveReissuePageview(nil)
                            
                            expect(defaultSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                            
                            expect(source.calls).to(equal([
                                .didStartRecording,
                                .sessionDidStart,
                            ]))
                        }
                        
                        it("does not fall back to the event source with a matching name") {
                            
                            // We don't fall back because bridged pageviews expect bridged sources, not native ones.
                            
                            let source = CountingSource(name: "B", version: "1")
                            let sourceInfo = SourceInfo(name: "B", version: "1", platform: "bridged")
                            consumer.addSource(source)

                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), bridge: bridge)
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: sourceInfo, pageview: stalePageview)
                            
                            bridge.resolveReissuePageview(nil)
                            
                            expect(defaultSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                            
                            expect(source.calls).to(equal([
                                .didStartRecording,
                                .sessionDidStart,
                            ]))
                        }
                        
                        it("does not fall back to the event source with a matching name even if the bridge was deallocated") {
                            
                            let source = CountingSource(name: "B", version: "1")
                            let sourceInfo = SourceInfo(name: "B", version: "1", platform: "bridged")
                            consumer.addSource(source)
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), bridge: CountingRuntimeBridge())
                            
                            expect(stalePageview?.bridge).toEventually(beNil(), description: "PRECONDITION: The pageview should not have a strong reference to the bridge since this can create retain cycles")
                            
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: sourceInfo, pageview: stalePageview)
                            
                            expect(defaultSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                            
                            expect(source.calls).to(equal([
                                .didStartRecording,
                                .sessionDidStart,
                            ]))
                        }
                    }
                    
                    context("the pageview has a source") {
                        
                        var pageviewSource: CountingSource!
                        var eventSource: CountingSource!
                        var pageviewSourceInfo: SourceInfo!
                        var eventSourceInfo: SourceInfo!

                        beforeEach {
                            pageviewSource = CountingSource(name: "A", version: "1")
                            eventSource = CountingSource(name: "B", version: "1")
                            consumer.addSource(pageviewSource)
                            consumer.addSource(eventSource)
                            
                            pageviewSourceInfo = SourceInfo(name: "A", version: "1", platform: "test host")
                            eventSourceInfo = SourceInfo(name: "B", version: "1", platform: "test host")
                        }
                        
                        it("requests a reissue of the pageview from the pageview source, if registered") {
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), sourceInfo: pageviewSourceInfo)
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: eventSourceInfo, pageview: stalePageview)
                            
                            expect(pageviewSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .reissuePageview,
                            ]))
                        }
                        
                        it("returns the pageview from the pageview source if it is in the current session") {
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), sourceInfo: pageviewSourceInfo)
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: eventSourceInfo, pageview: stalePageview)
                            
                            let pageview = consumer.trackPageview(.with({ $0.title = "B" }), timestamp: session2Timestamp)
                            _ = consumer.trackPageview(.with({ $0.title = "C" }), timestamp: session2Timestamp)
                            
                            pageviewSource.resolveReissuePageview(pageview)
                            
                            let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                            let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: pageview?.sessionId, count: 5)
                            
                            expect(messages.last?.pageviewInfo).to(equal(pageview?.pageviewInfo))
                        }
                        
                        it("falls back to the event source if the pageview source is not registered") {
                            consumer.removeSource("A")
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), sourceInfo: pageviewSourceInfo)
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: eventSourceInfo, pageview: stalePageview)
                            
                            expect(eventSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                        }
                        
                        it("falls back to the event source if the pageview source returns a stale pageview") {
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), sourceInfo: pageviewSourceInfo)
                            let stalePageview2 = consumer.trackPageview(.with({ $0.title = "B" }), sourceInfo: pageviewSourceInfo)
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: eventSourceInfo, pageview: stalePageview)
                            
                            pageviewSource.resolveReissuePageview(stalePageview2)
                            
                            expect(eventSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                        }
                        
                        it("falls back to the event source if the pageview source returns nil") {
                            
                            let session2Timestamp = Date().addingTimeInterval(1000)
                            let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }), sourceInfo: pageviewSourceInfo)
                            consumer.track("event", timestamp: session2Timestamp, sourceInfo: eventSourceInfo, pageview: stalePageview)
                            
                            pageviewSource.resolveReissuePageview(nil)
                            
                            expect(eventSource.calls).toEventually(equal([
                                .didStartRecording,
                                .sessionDidStart,
                                .activePageview,
                            ]))
                        }
                    }
                }
            }
            
            context("a pageview is not provided") {
                
                context("the event has a source") {
                    
                    var defaultSource: CountingSource!
                    var source: CountingSource!
                    var sourceInfo: SourceInfo!
                    
                    beforeEach {
                        source = CountingSource(name: "A", version: "1")
                        defaultSource = CountingSource(name: "B", version: "1")
                        consumer.addSource(source)
                        consumer.addSource(defaultSource, isDefault: true)
                        
                        sourceInfo = SourceInfo(name: "A", version: "1", platform: "test host")
                    }
                    
                    it("requests the active pageview from the event source, if registered") {
                        
                        consumer.track("event", sourceInfo: sourceInfo)
                        expect(source.calls).toEventually(equal([
                            .didStartRecording,
                            .sessionDidStart,
                            .activePageview,
                        ]))
                    }
                    
                    it("returns the pageview from the event source if it is in the current session") {
                        
                        consumer.track("event", sourceInfo: sourceInfo)

                        let pageview = consumer.trackPageview(.with({ $0.title = "A" }))
                        _ = consumer.trackPageview(.with({ $0.title = "B" }))
                        
                        source.resolveActivePageview(pageview)
                        
                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)
                        
                        expect(messages.last?.pageviewInfo).to(equal(pageview?.pageviewInfo))
                    }
                    
                    it("falls back to the default source if the event source is not registered") {
                        
                        consumer.track("event", sourceInfo: .init(name: "C", version: "1", platform: "nonexistant"))
                        
                        expect(defaultSource.calls).toEventually(equal([
                            .didStartRecording,
                            .sessionDidStart,
                            .activePageview,
                        ]))
                    }
                    
                    it("falls back to the default source if the event source returns a stale pageview") {
                        
                        let session2Timestamp = Date().addingTimeInterval(1000)
                        
                        let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }))
                        
                        consumer.track("event", timestamp: session2Timestamp, sourceInfo: sourceInfo)
                        
                        source.resolveActivePageview(stalePageview)
                        
                        expect(defaultSource.calls).toEventually(equal([
                            .didStartRecording,
                            .sessionDidStart,
                            .activePageview,
                        ]))
                    }
                    
                    it("falls back to the default source if the event source returns nil") {
                        
                        consumer.track("event", sourceInfo: sourceInfo)
                        
                        source.resolveActivePageview(nil)
                        
                        expect(defaultSource.calls).toEventually(equal([
                            .didStartRecording,
                            .sessionDidStart,
                            .activePageview,
                        ]))
                    }
                }
                
                context("there is a default source") {
                    
                    var defaultSource: CountingSource!
                    
                    beforeEach {
                        defaultSource = CountingSource(name: "A", version: "1")
                        consumer.addSource(defaultSource, isDefault: true)
                    }
                    
                    it("requests the active pageview from the default source") {
                        
                        consumer.track("event")
                        expect(defaultSource.calls).toEventually(equal([
                            .didStartRecording,
                            .sessionDidStart,
                            .activePageview,
                        ]))
                    }
                    
                    it("returns the pageview from the default source if it is in the current session") {
                        
                        consumer.track("event")
                        
                        let pageview = consumer.trackPageview(.with({ $0.title = "A" }))
                        _ = consumer.trackPageview(.with({ $0.title = "B" }))
                        
                        defaultSource.resolveActivePageview(pageview)
                        
                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)
                        
                        expect(messages.last?.pageviewInfo).to(equal(pageview?.pageviewInfo))
                    }
                    
                    it("falls back to the original last pageview if the default source returns a stale pageview") {
                        
                        let session2Timestamp = Date().addingTimeInterval(1000)
                        
                        let stalePageview = consumer.trackPageview(.with({ $0.title = "A" }))
                        let lastPageview = consumer.trackPageview(.with({ $0.title = "B" }), timestamp: session2Timestamp)
                        
                        consumer.track("event", timestamp: session2Timestamp)
                        _ = consumer.trackPageview(.with({ $0.title = "C" }), timestamp: session2Timestamp)

                        defaultSource.resolveActivePageview(stalePageview)
                        
                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: lastPageview?.sessionId, count: 5)
                        
                        expect(messages.last?.pageviewInfo).to(equal(lastPageview?.pageviewInfo))
                    }
                    
                    it("falls back to the original last pageview if the default source returns nil") {
                        
                        let lastPageview = consumer.trackPageview(.with({ $0.title = "A" }))
                        
                        consumer.track("event")
                        _ = consumer.trackPageview(.with({ $0.title = "B" }))

                        defaultSource.resolveActivePageview(nil)
                        
                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)
                        
                        expect(messages.last?.pageviewInfo).to(equal(lastPageview?.pageviewInfo))
                    }
                }
                
                context("there is not a default source or event source") {
                    it("resolve to the last pageview") {
                        
                        _ = consumer.trackPageview(.with({ $0.title = "A" }))
                        let lastPageview = consumer.trackPageview(.with({ $0.title = "B" }))
                        
                        consumer.track("event")
                        
                        let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                        let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)
                        
                        expect(messages.last?.pageviewInfo).to(equal(lastPageview?.pageviewInfo))
                    }
                }
            }
        }
    }
}
