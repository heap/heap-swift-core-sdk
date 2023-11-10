import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupport_RuntimeBridgeSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var uploader: CountingUploader!
        var bridgeSupport: HeapBridgeSupport!
        var delegate: CountingHeapBridgeSupportDelegate!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            uploader = CountingUploader()
            bridgeSupport = HeapBridgeSupport(eventConsumer: consumer, uploader: uploader)
            delegate = .init()
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
            consumer.removeRuntimeBridge(bridgeSupport)
            bridgeSupport.callbackStore.cancelAllSync()
        }
        
        func describeMethod(_ method: String, closure: (_ method: String) -> Void) {
            describe("WebviewEventConsumer.\(method)", closure: { closure(method) })
        }
        
        describe("HeapBridgeSupport.attachRuntimeBridge") {
            
            it("does not attach as a bridge when delegate is null") {
                let result = try bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                expect(result as? Bool).to(equal(false))
                expect(consumer.delegateManager.current.runtimeBridges).to(beEmpty())
            }
            
            it("adds a runtime bridge when the delegate is set") {
                bridgeSupport.delegate = delegate
                let result = try bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                expect(result as? Bool).to(equal(true))
                expect(consumer.delegateManager.current.runtimeBridges).to(haveCount(1))
            }
            
            it("only adds the delegate once") {
                bridgeSupport.delegate = delegate
                _ = try bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                _ = try bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                _ = try bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                _ = try bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                expect(consumer.delegateManager.current.runtimeBridges).to(haveCount(1))
            }
        }
        
        describe("HeapBridgeSupportDelegate") {
            
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
            }
            
#if os(watchOS)
            // WatchOS tests run in an inactive extension, which is defined as follows:
            // The Watch app is running in the foreground, but is not yet responding to actions from controls or gestures.
            
            it("receives notifications when recording starts and the session has started") {
                consumer.startRecording("11", with: [.startSessionImmediately: true])
                expect(delegate.invocations.map(\.method)).toEventually(equal([
                    "didStartRecording",
                    "sessionDidStart",
                    "applicationDidEnterForeground",
                ]))
            }
            
            it("receives notifications when recording starts and the session has not started") {
                consumer.startRecording("11", with: [:])
                expect(delegate.invocations.map(\.method)).toEventually(equal([
                    "didStartRecording",
                    "applicationDidEnterForeground",
                ]))
            }
#else
            it("receives notifications when recording starts and the session has started") {
                consumer.startRecording("11", with: [.startSessionImmediately: true])
                expect(delegate.invocations.map(\.method)).toEventually(equal([
                    "didStartRecording",
                    "sessionDidStart",
                ]))
            }
            
            it("receives notifications when recording starts and the session has not started") {
                consumer.startRecording("11", with: [:])
                expect(delegate.invocations.map(\.method)).toEventually(equal([
                    "didStartRecording",
                ]))
            }
#endif
        }
        
        describe("HeapBridgeSupport.didStartRecording") {
            
            var completed = false
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                completed = false
            }
            
            func handleComplete() {
                completed = true
            }
            
            it("sends expected parameters") {
                bridgeSupport.didStartRecording(options: [
                    .disablePageviewAutocapture: true,
                    .baseUrl: "https://example.com/"
                ], complete: handleComplete)
                
                expect(delegate.invocations).toEventuallyNot(beEmpty())
                guard let invocation = delegate.invocations.first else { return }
                
                expect(invocation.method).to(equal("didStartRecording"))
                expect(invocation.callbackId).toNot(beNil())
                expect(invocation.arguments?["options"]).to(equal(.object([
                    "disablePageviewAutocapture": .bool(true),
                    "baseUrl": .string("https://example.com/")
                ])))
            }
            
            it("completes when the callback succeeds") {
                
                bridgeSupport.didStartRecording(options: [
                    .disablePageviewAutocapture: true,
                    .baseUrl: "https://example.com/"
                ], complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback fails") {
                
                bridgeSupport.didStartRecording(options: [
                    .disablePageviewAutocapture: true,
                    .baseUrl: "https://example.com/"
                ], complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback times out") {
                bridgeSupport.delegateTimeout = 0.1
                bridgeSupport.didStartRecording(options: [
                    .disablePageviewAutocapture: true,
                    .baseUrl: "https://example.com/"
                ], complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the delegate is nil") {
                bridgeSupport.delegate = nil
                bridgeSupport.didStartRecording(options: [
                    .disablePageviewAutocapture: true,
                    .baseUrl: "https://example.com/"
                ], complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
        }
        
        describe("HeapBridgeSupport.didStopRecording") {
            
            var completed = false
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                completed = false
            }
            
            func handleComplete() {
                completed = true
            }
            
            it("sends expected parameters") {
                bridgeSupport.didStopRecording(complete: handleComplete)
                
                expect(delegate.invocations).toEventuallyNot(beEmpty())
                guard let invocation = delegate.invocations.first else { return }
                
                expect(invocation.method).to(equal("didStopRecording"))
                expect(invocation.callbackId).toNot(beNil())
            }
            
            it("completes when the callback succeeds") {
                bridgeSupport.didStopRecording(complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback fails") {
                bridgeSupport.didStopRecording(complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback times out") {
                bridgeSupport.delegateTimeout = 0.1
                bridgeSupport.didStopRecording(complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the delegate is nil") {
                bridgeSupport.delegate = nil
                bridgeSupport.didStopRecording(complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
        }
        
        describe("HeapBridgeSupport.sessionDidStart") {
            
            var completed = false
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                completed = false
            }
            
            func handleComplete() {
                completed = true
            }
            
            it("sends expected parameters") {
                bridgeSupport.sessionDidStart(sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), foregrounded: true, complete: handleComplete)
                
                expect(delegate.invocations).toEventuallyNot(beEmpty())
                guard let invocation = delegate.invocations.first else { return }
                
                expect(invocation.method).to(equal("sessionDidStart"))
                expect(invocation.callbackId).toNot(beNil())
                expect(invocation.arguments?["sessionId"]).to(equal(.string("123")))
                expect(invocation.arguments?["javascriptEpochTimestamp"]).to(equal(.number(978307200000)))
                expect(invocation.arguments?["foregrounded"]).to(equal(.bool(true)))
            }
            
            it("completes when the callback succeeds") {
                
                bridgeSupport.sessionDidStart(sessionId: "11", timestamp: Date(timeIntervalSinceReferenceDate: 0), foregrounded: true, complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback fails") {
                
                bridgeSupport.sessionDidStart(sessionId: "11", timestamp: Date(timeIntervalSinceReferenceDate: 0), foregrounded: true, complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback times out") {
                bridgeSupport.delegateTimeout = 0.1
                bridgeSupport.sessionDidStart(sessionId: "11", timestamp: Date(timeIntervalSinceReferenceDate: 0), foregrounded: true, complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the delegate is nil") {
                bridgeSupport.delegate = nil
                bridgeSupport.sessionDidStart(sessionId: "11", timestamp: Date(timeIntervalSinceReferenceDate: 0), foregrounded: true, complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
        }
        
        describe("HeapBridgeSupport.applicationDidEnterForeground") {
            
            var completed = false
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                completed = false
            }
            
            func handleComplete() {
                completed = true
            }
            
            it("sends expected parameters") {
                bridgeSupport.applicationDidEnterForeground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations).toEventuallyNot(beEmpty())
                guard let invocation = delegate.invocations.first else { return }
                
                expect(invocation.method).to(equal("applicationDidEnterForeground"))
                expect(invocation.callbackId).toNot(beNil())
                expect(invocation.arguments?["javascriptEpochTimestamp"]).to(equal(.number(978307200000)))
            }
            
            it("completes when the callback succeeds") {
                bridgeSupport.applicationDidEnterForeground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback fails") {
                bridgeSupport.applicationDidEnterForeground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback times out") {
                bridgeSupport.delegateTimeout = 0.1
                bridgeSupport.applicationDidEnterForeground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the delegate is nil") {
                bridgeSupport.delegate = nil
                bridgeSupport.applicationDidEnterForeground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
        }
        
        describe("HeapBridgeSupport.applicationDidEnterBackground") {
            
            var completed = false
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                completed = false
            }
            
            func handleComplete() {
                completed = true
            }
            
            it("sends expected parameters") {
                bridgeSupport.applicationDidEnterBackground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations).toEventuallyNot(beEmpty())
                guard let invocation = delegate.invocations.first else { return }
                
                expect(invocation.method).to(equal("applicationDidEnterBackground"))
                expect(invocation.callbackId).toNot(beNil())
                expect(invocation.arguments?["javascriptEpochTimestamp"]).to(equal(.number(978307200000)))
            }
            
            it("completes when the callback succeeds") {
                bridgeSupport.applicationDidEnterBackground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback fails") {
                bridgeSupport.applicationDidEnterBackground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the callback times out") {
                bridgeSupport.delegateTimeout = 0.1
                bridgeSupport.applicationDidEnterBackground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
            
            it("completes when the delegate is nil") {
                bridgeSupport.delegate = nil
                bridgeSupport.applicationDidEnterBackground(timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(completed).toEventually(beTrue())
            }
        }
        
        describe("HeapBridgeSupport.reissuePageview") {
            
            var pageview: (key: String, value: Pageview)?
            var completed = false
            var returnedPageview: Pageview? = nil
            
            beforeEach {
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachRuntimeBridge", arguments: [:])
                completed = false
                returnedPageview = nil
                
                consumer.startRecording("11", with: [.startSessionImmediately: true])
                expect(delegate.invocations.count).toEventually(beGreaterThanOrEqualTo(2), description: "PRECONDITION")
                delegate.invocations.removeAll()
                _ = try? bridgeSupport.trackPageview(arguments: [
                    "properties": [String: Any](),
                ])
                
                expect(bridgeSupport.pageviewStore.keys).to(haveCount(1), description: "PRECONDITION: Expected exactly one pageview.")
                if let key = bridgeSupport.pageviewStore.keys.first,
                   let value = bridgeSupport.pageviewStore.get(key) {
                    pageview = (key, value)
                }
            }
            
            func handleComplete(_ pageview: Pageview?) {
                completed = true
                returnedPageview = pageview
            }
            
            it("sends expected parameters") {
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)
                
                expect(delegate.invocations).toEventuallyNot(beEmpty())
                guard let invocation = delegate.invocations.first else { return }
                
                expect(invocation.method).to(equal("reissuePageview"))
                expect(invocation.callbackId).toNot(beNil())
                expect(invocation.arguments?["pageviewKey"]).to(equal(.string(pageview.key)))
                expect(invocation.arguments?["sessionId"]).to(equal(.string("123")))
                expect(invocation.arguments?["javascriptEpochTimestamp"]).to(equal(.number(978307200000)))
            }
            
            it("completes with nil when the callback succeeds with no data") {
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)

                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
                expect(returnedPageview).to(beNil())
            }
            
            it("completes with nil when the callback succeeds with an unknown pageview id") {
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)

                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: "test", error: nil)
                expect(completed).toEventually(beTrue())
                expect(returnedPageview).to(beNil())
            }
            
            it("completes with a pageview when the callback succeeds with a known pageview id") {
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)

                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: pageview.key, error: nil)
                expect(completed).toEventually(beTrue())
                expect(returnedPageview.map(ObjectIdentifier.init(_:))).to(equal(ObjectIdentifier(pageview.value)))
            }
            
            it("completes with nil when the callback fails") {
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)

                expect(delegate.invocations.first?.callbackId).toEventuallyNot(beNil())
                guard let callbackId = delegate.invocations.first?.callbackId else { return }
                
                bridgeSupport.handleResult(callbackId: callbackId, data: nil, error: nil)
                expect(completed).toEventually(beTrue())
                expect(returnedPageview).to(beNil())
            }
            
            it("completes with nil when the callback times out") {
                bridgeSupport.delegateTimeout = 0.1
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)

                expect(completed).toEventually(beTrue())
                expect(returnedPageview).to(beNil())
            }
            
            it("completes ith nil when the delegate is nil") {
                bridgeSupport.delegate = nil
                guard let pageview = pageview else { throw TestFailure("trackPageview did not issue a pageview") }
                
                bridgeSupport.reissuePageview(pageview.value, sessionId: "123", timestamp: Date(timeIntervalSinceReferenceDate: 0), complete: handleComplete)

                expect(completed).toEventually(beTrue())
                expect(returnedPageview).to(beNil())
            }
        }
    }
}
