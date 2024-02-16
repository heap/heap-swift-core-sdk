import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupport_AutocaptureExtensionsSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var uploader: CountingUploader!
        var bridgeSupport: HeapBridgeSupport!
        
        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            uploader = CountingUploader()
            bridgeSupport = HeapBridgeSupport(eventConsumer: consumer, uploader: uploader)
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }
        
        func describeMethod(_ method: String, closure: (_ method: String) -> Void) {
            describe("HeapBridgeSupport.\(method)", closure: { closure(method) })
        }
        
        describeMethod("trackPageview") { method in
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "url": "https://example.com/",
                    ] as [String : Any],
                ])
            }
            
            it("does not throw when passed unknown properties") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [
                        "foo": "bar",
                    ] as [String : Any],
                ])
            }

            it("does not throw when passed unsupported source property types") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": "My Component",
                        "title": "My page",
                        "sourceProperties": ["UNKNOWN": ["a", "b"]],
                    ] as [String : Any],
                ])
            }
            
            it("throws when properties is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.componentOrClassName is not a string") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [
                        "componentOrClassName": 42,
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.title is not a string") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [
                        "title": 42,
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.url is not a string") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [
                        "url": 42,
                    ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.url is not a valid url") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [ "url": "" ] as [String : Any],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties.sourceProperties is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": ["sourceProperties": "something else"],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.name is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.version is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "sourceLibrary": [
                        "name": "my source",
                        "platform": "my platform",
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when sourceLibrary.platform is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                let messages = try dataStore.assertOnlySession(for: user, hasPostStartMessageCount: 1)
                let message = messages.postStartMessages[0]
                
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
                let result = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ])
                
                try result.assertTrackPageviewResponse()
            }
            
            it("returns a stored pageview key") {
                consumer.startRecording("11")
                let result = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ]).assertTrackPageviewResponse(isPrecondition: true)

                expect(bridgeSupport.pageviewStore.get(result.pageviewKey)).notTo(beNil())
            }
            
            it("returns a stored pageview key") {
                consumer.startRecording("11")
                let result = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ]).assertTrackPageviewResponse(isPrecondition: true)

                expect(result.sessionId).to(equal(consumer.sessionId))
            }
            
            it("returns the passed dead keys as removedKeys") {
                consumer.startRecording("11")
                let result = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                    "deadKeys": ["a", "b", "c"],
                ]).assertTrackPageviewResponse(isPrecondition: true)
                
                expect(result.removedKeys).to(equal(["a", "b", "c"]))
            }
            
            it("removes dead keys from the pageviews array") {
                consumer.startRecording("11")
                let result = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                    "deadKeys": [ pageviewKey ]
                ])
                
                expect(bridgeSupport.pageviewStore.keys).notTo(contain(pageviewKey))
            }
            
            it("doesn't prune pageviews below the limit") {
                consumer.startRecording("11")
                for _ in 1...bridgeSupport.pageviewStore.maxSize {
                    let result = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "properties": [String : Any](),
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    expect(result.removedKeys).to(beEmpty())
                }
            }
            
            it("prune pageviews when it reaches the limit") {
                consumer.startRecording("11")
                for _ in 1...bridgeSupport.pageviewStore.maxSize {
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "properties": [String : Any](),
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                }
                
                let result = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String : Any](),
                ]).assertTrackPageviewResponse()
                
                expect(result.removedKeys).to(haveCount(bridgeSupport.pageviewStore.numberToPruneWhenPruning))
            }
        }
        
        describeMethod("trackInteraction") { method in
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                            "attributes": [
                                "aria-role": "button",
                            ],
                            "referencingPropertyName": "addButton",
                            "nodeText": "Add",
                            "accessibilityLabel": "Add item to cart",
                            "href": "/cart/add",
                        ],
                        [
                            "nodeName": "div",
                            "nodeId": "header",
                            "nodeHtmlClass": "foo bar",
                        ],
                    ] as [[String : Any]],
                    "callbackName": "addToCart",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "sourceProperties": [
                        "a": 1,
                        "b": "2",
                    ],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                    "pageviewKey": "1234",
                ])
            }
            
            it("does not throw when pageviewKey is omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                        [
                            "nodeName": "div",
                        ],
                    ] as [[String : Any]],
                    "callbackName": "addToCart",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when javascriptEpochTimestamp is omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                        [
                            "nodeName": "div",
                        ],
                    ] as [[String : Any]],
                    "callbackName": "addToCart",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                ])
            }
            
            it("does not throw when sourceLibrary is omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                        [
                            "nodeName": "div",
                        ],
                    ] as [[String : Any]],
                    "callbackName": "addToCart",
                ])
            }
            
            it("does not throw when callbackName is omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                        [
                            "nodeName": "div",
                        ],
                    ] as [[String : Any]],
                ])
            }
            
            it("throws when nodes.nodeName is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                        [:],
                    ] as [[String : Any]],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when nodes is empty") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [Any](),
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when nodes is missing") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("does not throw when interaction is a builtin name") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "unspecified",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])
            }
            
            it("does not throw when interaction is a custom event") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": [
                        "custom": "my-event",
                    ],
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])
            }
            
            it("does not throw when interaction is a builtin ID") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": [
                        "builtin": 1024,
                    ],
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])
            }
            
            it("throws when interaction is an unknown string") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "hello world",
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when interaction is an unknown type") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": 9999,
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }

            it("throws when interaction is missing") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("populates the event correctly") {
                consumer.startRecording("11")
                let timestamp = Date().addingTimeInterval(30)
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": "change",
                    "nodes": [
                        [
                            "nodeName": "a",
                            "attributes": [
                                "aria-role": "button",
                            ],
                            "referencingPropertyName": "addButton",
                            "nodeText": "Add",
                            "accessibilityLabel": "Add item to cart",
                            "href": "/cart/add",
                        ],
                        [
                            "nodeName": "div",
                            "nodeId": "header",
                            "nodeHtmlClass": "foo bar",
                        ],
                    ] as [[String : Any]],
                    "callbackName": "addToCart",
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                    ],
                    "sourceProperties": [
                        "a": 1,
                        "b": "2",
                    ],
                    "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                    "pageviewKey": "1234",
                ])
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertOnlySession(for: user, hasPostStartMessageCount: 1)
                let message = messages.postStartMessages[0]
                
                message.expectInteractionEventMessage(
                    user: user,
                    timestamp: timestamp,
                    hasSourceLibrary: true,
                    sourceLibrary: .with({
                        $0.name = "my source"
                        $0.version = "1.0.0"
                        $0.platform = "my platform"
                    }),
                    sourceProperties: [
                        "a": .init(value: "1"),
                        "b": .init(value: "2"),
                    ],
                    interaction: .builtin(.change),
                    nodes: [
                        .with({
                            $0.nodeName = "a"
                            $0.attributes = [
                                "aria-role": .init(value: "button"),
                            ]
                            $0.referencingPropertyName = "addButton"
                            $0.nodeText = "Add"
                            $0.accessibilityLabel = "Add item to cart"
                            $0.href = "/cart/add"
                        }),
                        .with({
                            $0.nodeName = "div"
                            $0.nodeID = "header"
                            $0.nodeHtmlClass = "foo bar"
                        })
                    ],
                    callbackName: "addToCart"
                )
            }
            
            it("accepts custom interactions") {
                consumer.startRecording("11")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": [
                        "custom": "hello world",
                    ],
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertOnlySession(for: user, hasPostStartMessageCount: 1)
                let message = messages.postStartMessages[0]
                
                message.expectInteractionEventMessage(
                    user: user,
                    interaction: .custom("hello world"),
                    nodes: [
                        .with({
                            $0.nodeName = "a"
                        })
                    ],
                    callbackName: nil
                )
            }
            
            it("accepts custom interactions") {
                consumer.startRecording("11")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "interaction": [
                        "builtin": 1024,
                    ],
                    "nodes": [
                        [
                            "nodeName": "a",
                        ],
                    ],
                ])
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertOnlySession(for: user, hasPostStartMessageCount: 1)
                let message = messages.postStartMessages[0]
                
                message.expectInteractionEventMessage(
                    user: user,
                    interaction: .builtin(.UNRECOGNIZED(1024)),
                    nodes: [
                        .with({
                            $0.nodeName = "a"
                        })
                    ],
                    callbackName: nil
                )
            }
            
            context("with trackPageview") {
                
                it("applies the provided pageview to the event") {
                    
                    consumer.startRecording("11")
                    let result = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Passed in pageview component", ],
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    _ = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                    ])
                    
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "interaction": "unspecified",
                        "nodes": [
                            [
                                "nodeName": "a",
                            ],
                        ],
                        "pageviewKey": result.pageviewKey,
                    ])
                    
                    let messages = try dataStore.assertOnlySession(hasPostStartMessageCount: 3)
                    let message = messages.postStartMessages[2]
                    expect(message.pageviewInfo.componentOrClassName).to(equal("Passed in pageview component"))
                }
                
                it("uses the none pageview if specified") {
                    
                    consumer.startRecording("11")
                    
                    _ = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                    ])
                    
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "interaction": "unspecified",
                        "nodes": [
                            [
                                "nodeName": "a",
                            ],
                        ],
                        "pageviewKey": "none",
                    ])
                    
                    let messages = try dataStore.assertOnlySession(hasPostStartMessageCount: 2)
                    let nonePageviewMessage = messages.initialPageviewMessage
                    let message = messages.postStartMessages[1]
                    expect(message.pageviewInfo).to(equal(nonePageviewMessage?.pageviewInfo))
                }
                
                it("applies the last pageview if the passed in pageview is no longer available") {
                    
                    consumer.startRecording("11")
                    let result = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Passed in pageview component", ],
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    _ = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                        "deadKeys": [ result.pageviewKey, ], // Invalidate the key
                    ])
                    
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "interaction": "unspecified",
                        "nodes": [
                            [
                                "nodeName": "a",
                            ],
                        ],
                        "pageviewKey": result.pageviewKey,
                    ])
                    
                    let messages = try dataStore.assertOnlySession(hasPostStartMessageCount: 3)
                    let message = messages.postStartMessages[2]
                    expect(message.pageviewInfo.componentOrClassName).to(equal("Last pageview component"))
                }
            }
        }
        
        describeMethod("track") { method in
            
            context("with trackPageview") {
                
                it("applies the provided pageview to the event") {
                    
                    consumer.startRecording("11")
                    let result = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Passed in pageview component", ],
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    _ = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                    ])
                    
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "event": "my-event",
                        "pageviewKey": result.pageviewKey,
                    ])
                    
                    let messages = try dataStore.assertOnlySession(hasPostStartMessageCount: 3)
                    let message = messages.postStartMessages[2]
                    expect(message.pageviewInfo.componentOrClassName).to(equal("Passed in pageview component"))
                }
                
                it("uses the none pageview if specified") {
                    
                    consumer.startRecording("11")
                    
                    _ = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                    ])
                    
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "event": "my-event",
                        "pageviewKey": "none",
                    ])
                    
                    let messages = try dataStore.assertOnlySession(hasPostStartMessageCount: 2)
                    let nonePageviewMessage = messages.initialPageviewMessage
                    let message = messages.postStartMessages[1]
                    expect(message.pageviewInfo).to(equal(nonePageviewMessage?.pageviewInfo))
                }
                
                it("applies the last pageview if the passed in pageview is no longer available") {
                    
                    consumer.startRecording("11")
                    let result = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Passed in pageview component", ],
                    ]).assertTrackPageviewResponse(isPrecondition: true)
                    
                    _ = try bridgeSupport.handleInvocation(method: "trackPageview", arguments: [
                        "properties": [ "componentOrClassName": "Last pageview component", ],
                        "deadKeys": [ result.pageviewKey, ], // Invalidate the key
                    ])
                    
                    _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                        "event": "my-event",
                        "pageviewKey": result.pageviewKey,
                    ])
                    
                    let messages = try dataStore.assertOnlySession(hasPostStartMessageCount: 3)
                    let message = messages.postStartMessages[2]
                    expect(message.pageviewInfo.componentOrClassName).to(equal("Last pageview component"))
                }
            }
        }
    }
}
