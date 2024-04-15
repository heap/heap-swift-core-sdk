import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupport_CoreSpec: HeapSpec {
    
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
        
        describeMethod("startRecording") { method in
            
            it("starts the uploader") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
                expect(uploader.isStarted).to(beTrue())
            }
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": [String: Any](),
                ])
            }
            
            it("does not throw when options are omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
            }
            
            it("does not throw when passed unknown options") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": ["UNKNOWN": "VALUE"],
                ])
            }
            
            it("consumes a known option") {
                // Using `disablePageviewAutocapture` because it's not currently used anywhere.
                // Otherwise, this test only produces valid failures when run in isolation with `fit`.
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": ["disablePageviewAutocapture": NSNumber(booleanLiteral: true)],
                ])
                
                expect(consumer.stateManager.current?.options.boolean(at: .disablePageviewAutocapture)).to(beTrue())
            }
            
            it("throws when environmentId is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when environmentId is empty") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when options is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                    "options": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("starts recording") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "11",
                ])
                expect(consumer.stateManager.current).notTo(beNil())
            }
        }
        
        describeMethod("stopRecording") { method in
            
            it("stops recording recording") {
                consumer.startRecording("11")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                expect(consumer.stateManager.current).to(beNil())
            }
            
            it("throws when deleteUser is not a boolean") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "deleteUser": "quack",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("does not delete the user when deleteUser is omitted") {
                consumer.startRecording("11")
                let userId = consumer.userId
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                consumer.startRecording("11")
                expect(consumer.userId).to(equal(userId))
            }
            
            it("does not delete the user when deleteUser is ObjC false") {
                consumer.startRecording("11")
                let userId = consumer.userId
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "deleteUser": NSNumber(false)
                ])
                consumer.startRecording("11")
                expect(consumer.userId).to(equal(userId))
            }
            
            it("does not delete the user when deleteUser is false") {
                consumer.startRecording("11")
                let userId = consumer.userId
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "deleteUser": false
                ])
                consumer.startRecording("11")
                expect(consumer.userId).to(equal(userId))
            }
            
            it("deletes the user when deleteUser is ObjC true") {
                consumer.startRecording("11")
                let userId = consumer.userId
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "deleteUser": NSNumber(true)
                ])
                consumer.startRecording("11")
                expect(consumer.userId).notTo(equal(userId))
            }
            
            it("deletes the user when deleteUser is true") {
                consumer.startRecording("11")
                let userId = consumer.userId
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "deleteUser": true
                ])
                consumer.startRecording("11")
                expect(consumer.userId).notTo(equal(userId))
            }
        }
        
        describeMethod("track") { method in
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": [String: Any](),
                    "javascriptEpochTimestamp": Date().timeIntervalSince1970 * 1000,
                ])
            }
            
            it("does not throw when properties are omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": ["UNKNOWN": ["a", "b"]],
                ])
            }
            
            it("throws when event is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when event is empty") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "environmentId": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when properties is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": "something else",
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
                let messages = try dataStore.assertOnlySession(for: user, hasPostStartMessageCount: 1)
                let message = messages.postStartMessages[0]
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                ])
            }
            it("throws when identity is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when identity is empty") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "identity": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("sets the identity") {
                consumer.startRecording("11")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "identity": "user-1",
                ])
                expect(consumer.stateManager.current?.environment.identity).to(equal("user-1"))
            }
        }
        
        describeMethod("resetIdentity") { method in
            
            it("resets the identity") {
                consumer.startRecording("11")
                consumer.identify("user-1")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                expect(consumer.stateManager.current?.environment.hasIdentity).to(beFalse())
            }
        }
        
        describeMethod("addUserProperties") { method in
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String: Any](),
                ])
            }
            
            it("does not throw when properties are omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
            }

            it("does not throw when passed unsupported property types") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": ["UNKNOWN": ["a", "b"]],
                ])
            }
            
            it("throws when properties is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "event": "my-event",
                    "properties": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("adds user properties") {
                consumer.startRecording("11")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
        }
        
        describeMethod("addEventProperties") { method in
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": [String: Any](),
                ])
            }
            
            it("does not throw when properties are omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
            }
            
            it("does not throw when passed unsupported property types") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": ["UNKNOWN": ["a", "b"]],
                ])
            }
            
            it("throws when properties is not an object") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "properties": "something else",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("adds event properties") {
                consumer.startRecording("11")
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "name": "prop",
                ])
            }
            
            it("throws when name is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when name is empty") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "name": "",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("removes event properties") {
                consumer.startRecording("11")
                consumer.addEventProperties([
                    "prop1": "value",
                    "prop2": "value",
                ])
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
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
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                
                expect(consumer.eventProperties).to(beEmpty())
            }
        }
        
        describeMethod("environmentId") { method in
            
            it("returns the user id when Heap is recording") {
                consumer.startRecording("11")
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal(consumer.environmentId))
            }
            
            it("returns null when Heap is not recording") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
            }
        }
        
        describeMethod("userId") { method in
            
            it("returns the user id when Heap is recording") {
                consumer.startRecording("11")
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal(consumer.userId))
            }
            
            it("returns null when Heap is not recording") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
            }
        }
        
        describeMethod("identity") { method in
            
            it("returns the identity when identified") {
                consumer.startRecording("11")
                consumer.identify("user-1")
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("user-1"))
            }
            
            it("returns null when unidentified") {
                consumer.startRecording("11")
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
            }
        }
        
        describeMethod("sessionId") { method in
            
            it("returns null when Heap is recording and the first session has not yet started") {
                consumer.startRecording("11")
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
            }
            
            it("returns the session id when Heap is recording and the session is not expired") {
                consumer.startRecording("11")
                let (_, sessionId) = consumer.ensureSessionExistsUsingTrack()
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal(sessionId))
            }
            
            it("returns null when Heap is recording and the session is expired") {
                consumer.startRecording("11", timestamp: Date().addingTimeInterval(-3000))
                _ = consumer.ensureSessionExistsUsingTrack(timestamp: Date().addingTimeInterval(-3000))
                let sessionId = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                expect(sessionId).to(beNil())
            }
            
            it("returns null when Heap is not recording") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
            }
        }
        
        describeMethod("fetchSessionId") { method in
            
            it("starts a new session if expired") {
                consumer.startRecording("11", timestamp: Date().addingTimeInterval(-3000))
                _ = consumer.ensureSessionExistsUsingTrack(timestamp: Date().addingTimeInterval(-3000))
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                expect(consumer.stateManager.current?.sessionInfo.time.date).to(beCloseTo(Date(), within: 1))
            }
            
            it("returns the session id when Heap is recording") {
                consumer.startRecording("11")
                let sessionId = try bridgeSupport.handleInvocation(method: method, arguments: [:])
                expect(sessionId as! String?).to(equal(consumer.activeSession!.sessionId))
            }
            
            it("returns null when Heap is not recording") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(beNil())
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
