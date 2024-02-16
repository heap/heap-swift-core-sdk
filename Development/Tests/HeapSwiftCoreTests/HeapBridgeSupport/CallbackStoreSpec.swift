import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class CallbackStoreSpec: HeapSpec {
    
    override func spec() {
        
        var callCount = 0
        var isSuccess = false
        var value: Any? = nil
        var error: String? = nil
        
        var callbackStore: CallbackStore!
        
        beforeEach {
            callbackStore = .init()
            callCount = 0
            isSuccess = false
            value = nil
            error = nil
        }
        
        afterEach {
            callbackStore.cancelAllSync()
        }
        
        func unpackResult(_ callbackResult: CallbackResult) {
            callCount += 1
            if case let .success(_value) = callbackResult { value = _value; isSuccess = true }
            if case let .failure(_error) = callbackResult { error = _error.message }
        }
        
        describe("CallbackStore") {
            
            describe("add") {
                it("stores the callback") {
                    let callbackId = callbackStore.add(timeout: 5) { _ in }
                    expect(callbackStore.callbackIds).toEventually(contain(callbackId))
                }
            }
            
            describe("dispatch") {

                it("causes the callback to complete with success when both data and error are nil") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.dispatch(callbackId: callbackId, data: nil, error: nil)
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beTrue())
                    expect(value).to(beNil())
                    expect(error).to(beNil())
                }
                
                it("causes the callback to complete with its value when just error is nil") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.dispatch(callbackId: callbackId, data: "test", error: nil)
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beTrue())
                    expect(value as? String).to(equal("test"))
                    expect(error).to(beNil())
                }
                
                it("causes the callback to complete with the error message whene error is set") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.dispatch(callbackId: callbackId, data: "test", error: "my message")
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beFalse())
                    expect(value).to(beNil())
                    expect(error).to(equal("my message"))
                }
                
                it("ignores subsequent calls for the same ID") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.dispatch(callbackId: callbackId, data: "test", error: "my message")
                    callbackStore.dispatch(callbackId: callbackId, data: "test", error: nil)
                    callbackStore.dispatch(callbackId: callbackId, data: nil, error: nil)
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beFalse())
                    expect(value).to(beNil())
                    expect(error).to(equal("my message"))
                }
                
                it("removes the callback") {
                    let callbackId = callbackStore.add(timeout: 5) { _ in }
                    expect(callbackStore.callbackIds).toEventually(contain(callbackId), description: "PRECONDITION")
                    callbackStore.dispatch(callbackId: callbackId, data: nil, error: nil)
                    expect(callbackStore.callbackIds).toEventually(beEmpty(), description: "PRECONDITION")
                }
            }
            
            context("when the timeout elapses") {
                
                it("calls the callback with an error") {
                    _ = callbackStore.add(timeout: 0.5, callback: unpackResult(_:))
                    expect(callCount).toEventually(equal(1), timeout: .seconds(2))
                    expect(isSuccess).to(beFalse())
                    expect(value).to(beNil())
                    expect(error).to(equal("A timeout occurred while waiting for the bridge."))
                }
                
                it("ignores subsequent calls for the same ID") {
                    let callbackId = callbackStore.add(timeout: 0.5, callback: unpackResult(_:))
                    expect(callCount).toEventually(equal(1), timeout: .seconds(2), description: "PRECONDITION")
                    
                    callbackStore.dispatch(callbackId: callbackId, data: "test", error: "my message")
                    callbackStore.dispatch(callbackId: callbackId, data: "test", error: nil)
                    callbackStore.dispatch(callbackId: callbackId, data: nil, error: nil)
                    expect(callCount).toAlways(equal(1), until: .seconds(1))
                    expect(isSuccess).to(beFalse())
                    expect(value).to(beNil())
                    expect(error).to(equal("A timeout occurred while waiting for the bridge."))
                }
                
                
                it("removes the callback") {
                    let callbackId = callbackStore.add(timeout: 0.5) { _ in }
                    expect(callbackStore.callbackIds).toEventually(contain(callbackId), description: "PRECONDITION")
                    expect(callbackStore.callbackIds).toEventually(beEmpty(), timeout: .seconds(2))
                }
            }
        }
    }
}

fileprivate extension CallbackStore {
    
    // Helper to get the callback ids without violating thread safety.
    var callbackIds: [String] {
        OperationQueue.callback.addOperationAndWait {
            self.callbackIdsForCallbackQueueOnly
        }
    }
}
