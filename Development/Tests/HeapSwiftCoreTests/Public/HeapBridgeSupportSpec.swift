import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupportSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var uploader: CountingUploader!
        var webConsumer: HeapBridgeSupport!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            uploader = CountingUploader()
            webConsumer = HeapBridgeSupport(eventConsumer: consumer, uploader: uploader)
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }
        
        func describeMethod(_ method: String, closure: (_ method: String) -> Void) {
            describe("WebviewEventConsumer.\(method)", closure: { closure(method) })
        }
        
        describeMethod("startRecording") { method in
            
            it("starts the uploader") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
                expect(uploader.isStarted).to(beTrue())
            }
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": [String: Any](),
                ])
            }
            
            it("does not throw when options are omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
            }
            
            it("does not throw when passed unknown options") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": ["UNKNOWN": "VALUE"],
                ])
            }
            
            it("consumes a known option") {
                // Using `disablePageviewAutocapture` because it's not currently used anywhere.
                // Otherwise, this test only produces valid failures when run in isolation with `fit`.
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": ["disablePageviewAutocapture": NSNumber(booleanLiteral: true)],
                ])
                
                expect(consumer.stateManager.current?.options.boolean(at: .disablePageviewAutocapture)).to(beTrue())
            }
            
            it("throws when environmentId is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when environmentId is empty") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when options is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("starts recording") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
                expect(consumer.stateManager.current).notTo(beNil())
            }
        }
        
        describeMethod("stopRecording") { method in
            
            it("stops recording recording") {
                consumer.startRecording("11")
                _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                expect(consumer.stateManager.current).to(beNil())
            }
        }
        
        describeMethod("track") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": [String: Any](),
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when the timestamp is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": [String: Any](),
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                ])
            }
            
            it("does not throw when sourceLibrary is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": [String: Any](),
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when properties are omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }

            it("does not throw when passed unsupported property types") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": ["UNKNOWN": ["a", "b"]],
                ])
            }
            
            it("throws when event is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when event is empty") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.name is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.version is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "name": "my source",
                        "platform": "my platform",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.platform is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("populates the event correctly") {
                consumer.startRecording("11")
                let timestamp = Date().addingTimeInterval(30)
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": [
                        "a": 1,
                        "b": "2",
                        "c": false,
                        "d": 1.5,
                    ] as [String : Any],
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                        "properties": [
                            "foo": "bar",
                        ],
                    ] as [String : Any],
                    "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                ])
                let user = try dataStore.assertOnlyOneUserToUpload()
                let message = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)[2]
                let event = try message.assertEventMessage(user: user, hasSourceLibrary: true, sourceLibrary: .with({
                    $0.name = "my source"
                    $0.version = "1.0.0"
                    $0.platform = "my platform"
                    $0.properties = [ "foo": "bar".protoValue ]
                }))
                let customEvent = try event.assertIsCustomEvent()
                
                expect(customEvent.name).to(equal("my-event"))
                expect(message.time.date).to(beCloseTo(timestamp))
                expect(customEvent.properties["a"]).to(equal(.init(value: "1")))
                expect(customEvent.properties["b"]).to(equal(.init(value: "2")))
                expect(customEvent.properties["c"]).to(equal(.init(value: "false")))
                expect(customEvent.properties["d"]).to(equal(.init(value: "1.5")))
            }
            
            context("with trackPageview") {
                
                it("applies the provided pageview to the event") {
                    
                    consumer.startRecording("11")
                    let result = try webConsumer.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Passed in pageview component", ],
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    _ = try webConsumer.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                    ])
                    
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "event": "my-event",
                        "pageviewKey": result.pageviewKey,
                    ])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    
                    let message = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)[4]
                    expect(message.pageviewInfo.componentOrClassName).to(equal("Passed in pageview component"))
                }
                
                it("applies the last pageview if the passed in pageview is no longer available") {
                    
                    consumer.startRecording("11")
                    let result = try webConsumer.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Passed in pageview component", ],
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    _ = try webConsumer.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                        "deadKeys": [ result.pageviewKey, ], // Invalidate the key
                    ])
                    
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "event": "my-event",
                        "pageviewKey": result.pageviewKey,
                    ])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    
                    let message = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 5)[4]
                    expect(message.pageviewInfo.componentOrClassName).to(equal("Last pageview component"))
                }
            }
        }
        
        describeMethod("trackPageview") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                    "deadKeys": ["a", "b", "c"],
                ])
            }
            
            it("does not throw when the timestamp is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "deadKeys": ["a", "b", "c"],
                ])
            }
            
            it("does not throw when sourceLibrary is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                    "deadKeys": ["a", "b", "c"],
                ])
            }
            
            it("does not throw when the deadKeys is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when properties.componentOrClassName is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "title": "My page",
                        "url": "https://example.com/",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                ])
            }
            
            it("does not throw when properties.title is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "url": "https://example.com/",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                ])
            }
            
            it("does not throw when properties.url is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                ])
            }
            
            it("does not throw when properties.sourceProperties is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/",
                    ] as [String : Any],
                ])
            }
            
            it("does not throw when passed unknown properties") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "foo": "bar",
                    ] as [String : Any],
                ])
            }

            it("does not throw when passed unsupported source property types") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "sourceProperties": ["UNKNOWN": ["a", "b"]],
                    ] as [String : Any],
                ])
            }
            
            it("throws when properties is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.componentOrClassName is not a string") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": 42,
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.title is not a string") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "title": 42,
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.url is not a string") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "url": 42,
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.url is not a valid url") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "url": "http:\\\\example.com",
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.sourceProperties is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": ["sourceProperties": "something else"],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.name is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.version is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "name": "my source",
                        "platform": "my platform",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.platform is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("populates the event correctly") {
                consumer.startRecording("11")
                let timestamp = Date().addingTimeInterval(30)
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/path/to/resource.jsp?state=AAABBBCCCDDD#!/elsewhere",
                        "sourceProperties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ] as [String : Any],
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                        "properties": [
                            "foo": "bar",
                        ],
                    ] as [String : Any],
                    "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                ])
                let user = try dataStore.assertOnlyOneUserToUpload()
                let message = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)[2]
                
                message.expectPageviewMessage(user: user, timestamp: timestamp, hasSourceLibrary: true, sourceLibrary: .with({
                    $0.name = "my source"
                    $0.version = "1.0.0"
                    $0.platform = "my platform"
                    $0.properties = [ "foo": "bar".protoValue ]
                }))
                
                let pageviewInfo = message.pageviewInfo
                expect(pageviewInfo.componentOrClassName).to(equal("My Component"))
                expect(pageviewInfo.title).to(equal("My page"))
                expect(pageviewInfo.url.domain).to(equal("example.com"))
                expect(pageviewInfo.url.path).to(equal("/path/to/resource.jsp"))
                expect(pageviewInfo.url.query).to(equal("state=AAABBBCCCDDD"))
                expect(pageviewInfo.url.hash).to(equal("!/elsewhere"))
                expect(pageviewInfo.sourceProperties["a"]).to(equal(.init(value: "1")))
                expect(pageviewInfo.sourceProperties["b"]).to(equal(.init(value: "2")))
                expect(pageviewInfo.sourceProperties["c"]).to(equal(.init(value: "false")))
                expect(pageviewInfo.sourceProperties["d"]).to(equal(.init(value: "1.5")))
            }
            
            it("returns a valid payload") {
                consumer.startRecording("11")
                let result = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ])
                
                try result.assertTrackPageviewResponse()
            }
            
            it("returns a stored pageview key") {
                consumer.startRecording("11")
                let result = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ]).assertTrackPageviewResponse(isPrecondition: true)

                expect(webConsumer.pageviews[result.pageviewKey]).notTo(beNil())
            }
            
            it("returns a stored pageview key") {
                consumer.startRecording("11")
                let result = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ]).assertTrackPageviewResponse(isPrecondition: true)

                expect(result.sessionId).to(equal(consumer.sessionId))
            }
            
            it("returns the passed dead keys as removedKeys") {
                consumer.startRecording("11")
                let result = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                    "deadKeys": ["a", "b", "c"],
                ]).assertTrackPageviewResponse(isPrecondition: true)
                
                expect(result.removedKeys).to(equal(["a", "b", "c"]))
            }
            
            it("removes dead keys from the pageviews array") {
                consumer.startRecording("11")
                let result = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ])
                
                guard let result = result else {
                    throw TestFailure("PRECONDITION: Call returned nil")
                }
                
                guard
                    case let .object(dictionary) = result._toHeapJSON(),
                    case let .string(pageviewKey) = dictionary["pageviewKey"]
                else {
                    throw TestFailure("PRECONDITION: \((try result.toJSONString()) ?? "nil") does not match expectations")
                }
                
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                    "deadKeys": [ pageviewKey ]
                ])
                
                expect(webConsumer.pageviews.keys).notTo(contain(pageviewKey))
            }
        }
        
        describeMethod("identify") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                ])
            }
            it("throws when identity is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when identity is empty") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("sets the identity") {
                consumer.startRecording("11")
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                ])
                expect(consumer.stateManager.current?.environment.identity).to(equal("user-1"))
            }
        }
        
        describeMethod("resetIdentity") { method in
            
            it("resets the identity") {
                consumer.startRecording("11")
                consumer.identify("user-1")
                _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                expect(consumer.stateManager.current?.environment.hasIdentity).to(beFalse())
            }
        }
        
        describeMethod("addUserProperties") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [String: Any](),
                ])
            }
            
            it("does not throw when properties are omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [:])
            }

            it("does not throw when passed unsupported property types") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": ["UNKNOWN": ["a", "b"]],
                ])
            }
            
            it("throws when properties is not an object") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("adds user properties") {
                consumer.startRecording("11")
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "properties": [
                        "a": 1,
                        "b": "2",
                        "c": false,
                        "d": 1.5,
                    ] as [String : Any],
                ])
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                expect(user.pendingUserProperties["a"]).to(equal("1"))
                expect(user.pendingUserProperties["b"]).to(equal("2"))
                expect(user.pendingUserProperties["c"]).to(equal("false"))
                expect(user.pendingUserProperties["d"]).to(equal("1.5"))
            }
            
            describeMethod("addEventProperties") { method in
                
                it("does not throw when all options are provided") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "properties": [String: Any](),
                    ])
                }
                
                it("does not throw when properties are omitted") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                }
                
                it("does not throw when passed unsupported property types") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "properties": ["UNKNOWN": ["a", "b"]],
                    ])
                }
                
                it("throws when properties is not an object") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "properties": "something else",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("adds event properties") {
                    consumer.startRecording("11")
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "properties": [
                            "a": 1,
                            "b": "2",
                            "c": false,
                            "d": 1.5,
                        ] as [String : Any],
                    ])
                    
                    expect(consumer.eventProperties["a"]).to(equal(.init(value: "1")))
                    expect(consumer.eventProperties["b"]).to(equal(.init(value: "2")))
                    expect(consumer.eventProperties["c"]).to(equal(.init(value: "false")))
                    expect(consumer.eventProperties["d"]).to(equal(.init(value: "1.5")))
                }
            }
            
            describeMethod("removeEventProperty") { method in
                
                it("does not throw when all options are provided") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "name": "prop",
                    ])
                }
                
                it("throws when name is omitted") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when name is empty") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "name": "",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("removes event properties") {
                    consumer.startRecording("11")
                    consumer.addEventProperties([
                        "prop1": "value",
                        "prop2": "value",
                    ])
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "name": "prop1",
                    ])
                    
                    expect(consumer.eventProperties["prop1"]).to(beNil())
                    expect(consumer.eventProperties["prop2"]).notTo(beNil())
                }
            }
            
            describeMethod("clearEventProperties") { method in
                
                it("removes all event properties") {
                    consumer.startRecording("11")
                    consumer.addEventProperties([
                        "prop1": "value",
                        "prop2": "value",
                    ])
                    _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                    
                    expect(consumer.eventProperties).to(beEmpty())
                }
            }
            
            describeMethod("userId") { method in
                
                it("returns the user id when Heap is recording") {
                    consumer.startRecording("11")
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal(consumer.userId))
                }
                
                it("returns null when Heap is not recording") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
                }
            }
            
            describeMethod("identity") { method in
                
                it("returns the identity when identified") {
                    consumer.startRecording("11")
                    consumer.identify("user-1")
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("user-1"))
                }
                
                it("returns null when unidentified") {
                    consumer.startRecording("11")
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
                }
            }
            
            describeMethod("sessionId") { method in
                
                it("returns null when Heap is recording and the first session has not yet started") {
                    consumer.startRecording("11")
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
                }
                
                it("returns the session id when Heap is recording and the session is not expired") {
                    consumer.startRecording("11")
                    let (_, sessionId) = consumer.ensureSessionExistsUsingTrack()
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal(sessionId))
                }
                
                it("returns null when Heap is recording and the session is expired") {
                    consumer.startRecording("11", timestamp: Date().addingTimeInterval(-3000))
                    _ = consumer.ensureSessionExistsUsingTrack(timestamp: Date().addingTimeInterval(-3000))
                    let sessionId = try webConsumer.handleInvocation(method: method, arguments: [:])
                    expect(sessionId).to(beNil())
                }
                
                it("returns null when Heap is not recording") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
                }
            }
            
            describeMethod("fetchSessionId") { method in
                
                it("starts a new session if expired") {
                    consumer.startRecording("11", timestamp: Date().addingTimeInterval(-3000))
                    _ = consumer.ensureSessionExistsUsingTrack(timestamp: Date().addingTimeInterval(-3000))
                    _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                    expect(consumer.stateManager.current?.sessionInfo.time.date).to(beCloseTo(Date(), within: 1))
                }
                
                it("returns the session id when Heap is recording") {
                    consumer.startRecording("11")
                    let sessionId = try webConsumer.handleInvocation(method: method, arguments: [:])
                    expect(sessionId as! String?).to(equal(consumer.activeSession!.sessionId))
                }
                
                it("returns null when Heap is not recording") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
                }
            }
            
            describeMethod("heapLogger_log") { method in
                
                it("does not throw when all options are provided") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw when source is omitted") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "message": "Message from the log test",
                    ])
                }
                
                it("throws when source is not a string") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "message": "Message from the log test",
                        "source": ["foo": "bar"],
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when message is omitted") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when message is not a string") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "message": ["foo": "bar"],
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when message is empty") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "message": "",
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("does not throw for the error log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "error",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw for the warn log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "warn",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw for the info log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "info",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw for the debug log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw for the trace log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("throws for an unknown log level") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "quack",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when log level is omitted") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
            }
            
            describeMethod("heapLogger_setLogLevel") { method in
                
                it("can set the log level to error") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "error",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.error))
                }
                
                it("can set the log level to warn") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "warn",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.warn))
                }
                
                it("can set the log level to info") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "info",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.info))
                }
                
                it("can set the log level to debug") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.debug))
                }
                
                it("can set the log level to trace") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "trace",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.trace))
                }
                
                it("can set the log level to none") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "none",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(LogLevel.none))
                }
                
                it("throws when for an unknown log level") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "quack",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when log level is omitted") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
                }
            }
            
            describeMethod("heapLogger_logLevel") { method in
                
                it("gets the error log level") {
                    HeapLogger.shared.logLevel = .error
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("error"))
                }
                
                it("gets the info log level") {
                    HeapLogger.shared.logLevel = .info
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("info"))
                }
                
                it("gets the debug log level") {
                    HeapLogger.shared.logLevel = .debug
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("debug"))
                }
                
                it("gets the trace log level") {
                    HeapLogger.shared.logLevel = .trace
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("trace"))
                }
                
                it("gets the none log level") {
                    HeapLogger.shared.logLevel = .none
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("none"))
                }
            }
        }
    }
}

extension JSONEncodable? {
    
    @discardableResult
    func assertTrackPageviewResponse(file: StaticString = #file, line: UInt = #line, isPrecondition: Bool = false) throws -> (pageviewKey: String, sessionId: String, removedKeys: [String]) {
        
        let prefix = isPrecondition ? "PRECONDITION: " : "";
        
        guard let result = self else {
            throw TestFailure(prefix + "Result was nil.")
        }
        
        guard
            case let .object(dictionary) = result._toHeapJSON(),
            case let .string(pageviewKey) = dictionary["pageviewKey"],
            case let .string(sessionId) = dictionary["sessionId"],
            case let .array(removedKeysRaw) = dictionary["removedKeys"]
        else {
            throw TestFailure(prefix + "\((try result.toJSONString()) ?? "nil") does not have required fields.")
        }
        
        let removedKeys = try removedKeysRaw.map {
            guard case let .string(key) = $0 else {
                throw TestFailure(prefix + "Key \($0) is not a string.")
            }
            return key
        }
        
        return (pageviewKey, sessionId, removedKeys)
    }
}
