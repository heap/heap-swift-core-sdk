import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupportSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var webConsumer: HeapBridgeSupport!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            webConsumer = HeapBridgeSupport(eventConsumer: consumer)
            HeapLogger.shared.logLevel = .debug
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .prod
        }
        
        func describeMethod(_ method: String, closure: (_ method: String) -> Void) {
            describe("WebviewEventConsumer.\(method)", closure: { closure(method) })
        }
        
        describeMethod("startRecording") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": [String: Any](),
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when the timestamp is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": [String: Any](),
                ])
            }
            
            it("does not throw when options are omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when passed unknown options") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": ["UNKNOWN": "VALUE"],
                ])
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
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("starts recording") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
                expect(consumer.stateManager.current).notTo(beNil())
            }
            
            it("uses the passed in time for the session start time") {
                let timestamp = Date().addingTimeInterval(3000)
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                ])
                expect(consumer.stateManager.current?.sessionInfo.time.date).to(beCloseTo(timestamp))
            }
        }
        
        describeMethod("stopRecording") { method in

            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when the timestamp is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [:])
            }
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
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
                    ],
                    "sourceLibrary": [
                        "name": "my source",
                        "version": "1.0.0",
                        "platform": "my platform",
                        "properties": [
                            "foo": "bar",
                        ],
                    ],
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
        }
        
        describeMethod("identify") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when the timestamp is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                ])
            }
            
            it("throws when identity is omitted") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when identity is empty") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "",
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("sets the identity") {
                consumer.startRecording("11")
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                ])
                expect(consumer.stateManager.current?.environment.identity).to(equal("user-1"))
            }
            
            it("uses the passed in time for the session start time if starting a new session") {
                let timestamp = Date().addingTimeInterval(3000)
                consumer.startRecording("11")
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                    "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                ])
                expect(consumer.stateManager.current?.sessionInfo.time.date).to(beCloseTo(timestamp))
            }
        }
        
        describeMethod("resetIdentity") { method in
            
            it("does not throw when all options are provided") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when the timestamp is omitted") {
                _ = try webConsumer.handleInvocation(method: method, arguments: [:])
            }
            
            it("throws when javascriptEpochTimestamp is not a number") {
                expect(try webConsumer.handleInvocation(method: method, arguments: [
                    "javascriptEpochTimestamp": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("resets the identity") {
                consumer.startRecording("11")
                consumer.identify("user-1")
                _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                expect(consumer.stateManager.current?.environment.hasIdentity).to(beFalse())
            }
            
            it("uses the passed in time for the session start time if starting a new session") {
                let timestamp = Date().addingTimeInterval(3000)
                consumer.startRecording("11")
                consumer.identify("user-1")
                _ = try webConsumer.handleInvocation(method: method, arguments: [
                    "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                ])
                expect(consumer.stateManager.current?.sessionInfo.time.date).to(beCloseTo(timestamp))
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
                    ],
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
                        ],
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
                
                it("does not throw when all options are provided") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                    ])
                }
                
                it("does not throw when the timestamp is omitted") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [:])
                }
                
                it("throws when javascriptEpochTimestamp is not a number") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "javascriptEpochTimestamp": "something else",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("uses the passed in time for the session start time when extending the session") {
                    let timestamp = Date().addingTimeInterval(3000)
                    consumer.startRecording("11")
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "javascriptEpochTimestamp": timestamp.timeIntervalSince1970 * 1000,
                    ])
                    expect(consumer.stateManager.current?.sessionInfo.time.date).to(beCloseTo(timestamp))
                }
                
                it("returns the session id when Heap is recording") {
                    consumer.startRecording("11")
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal(consumer.activeSession!.sessionId))
                }
                
                it("returns null when Heap is not recording") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
                }
            }
            
            describeMethod("heapLogger_log") { method in
                
                it("does not throw when all options are provided") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw when source is omitted") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "message": "Message from the log test",
                    ])
                }
                
                it("throws when source is not a string") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "message": "Message from the log test",
                        "source": ["foo": "bar"],
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when message is omitted") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when message is not a string") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "message": ["foo": "bar"],
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("throws when message is empty") {
                    expect(try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                        "message": "",
                        "source": "test runner",
                    ])).to(throwError(InvocationError.invalidParameters))
                }
                
                it("does not throw for the critical log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "critical",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw for the prod log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "prod",
                        "message": "Message from the log test",
                        "source": "test runner",
                    ])
                }
                
                it("does not throw for the dev log level") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "dev",
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
                
                it("can set the log level to critical") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "critical",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.critical))
                }
                
                it("can set the log level to prod") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "prod",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.prod))
                }
                
                it("can set the log level to dev") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "dev",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.dev))
                }
                
                it("can set the log level to debug") {
                    _ = try webConsumer.handleInvocation(method: method, arguments: [
                        "logLevel": "debug",
                    ])
                    expect(HeapLogger.shared.logLevel).to(equal(.debug))
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
                
                it("gets the critical log level") {
                    HeapLogger.shared.logLevel = .critical
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("critical"))
                }
                
                it("gets the prod log level") {
                    HeapLogger.shared.logLevel = .prod
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("prod"))
                }
                
                it("gets the dev log level") {
                    HeapLogger.shared.logLevel = .dev
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("dev"))
                }
                
                it("gets the debug log level") {
                    HeapLogger.shared.logLevel = .debug
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("debug"))
                }
                
                it("gets the none log level") {
                    HeapLogger.shared.logLevel = .none
                    expect (try webConsumer.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("none"))
                }
            }
        }
    }
}
