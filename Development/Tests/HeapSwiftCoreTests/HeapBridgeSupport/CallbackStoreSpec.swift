import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class CallbackStoreSpec: HeapSpec {
    
    override func spec() {
        
        var callCount = 0
        var isSuccess = false
        var value: String? = nil
        var error: String? = nil
        
        var callbackStore: CallbackStore<String>!
        
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
        
        func unpackResult(_ callbackResult: CallbackResult<String>) {
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
            
            describe("success") {

                it("causes the callback to complete with success") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.success(callbackId: callbackId, data: "Hello")
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beTrue())
                    expect(value).to(equal("Hello"))
                    expect(error).to(beNil())
                }
                
                it("ignores subsequent calls for the same ID") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.success(callbackId: callbackId, data: "Hello")
                    callbackStore.failure(callbackId: callbackId, error: "Tough luck")
                    callbackStore.success(callbackId: callbackId, data: "Hi")
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beTrue())
                    expect(value).to(equal("Hello"))
                    expect(error).to(beNil())
                }
                
                it("removes the callback") {
                    let callbackId = callbackStore.add(timeout: 5) { _ in }
                    expect(callbackStore.callbackIds).toEventually(contain(callbackId), description: "PRECONDITION")
                    callbackStore.success(callbackId: callbackId, data: "Hello")
                    expect(callbackStore.callbackIds).toEventually(beEmpty(), description: "PRECONDITION")
                }
            }
            
            describe("dispatch") {

                it("causes the callback to complete with the error message") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.failure(callbackId: callbackId, error: "Tough luck")
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beFalse())
                    expect(value).to(beNil())
                    expect(error).to(equal("Tough luck"))
                }
                
                it("ignores subsequent calls for the same ID") {
                    let callbackId = callbackStore.add(timeout: 5, callback: unpackResult(_:))
                    callbackStore.failure(callbackId: callbackId, error: "Tough luck")
                    callbackStore.success(callbackId: callbackId, data: "Hello")
                    callbackStore.failure(callbackId: callbackId, error: "Oops")
                    expect(callCount).toEventually(equal(1))
                    expect(isSuccess).to(beFalse())
                    expect(value).to(beNil())
                    expect(error).to(equal("Tough luck"))
                }
                
                it("removes the callback") {
                    let callbackId = callbackStore.add(timeout: 5) { _ in }
                    expect(callbackStore.callbackIds).toEventually(contain(callbackId), description: "PRECONDITION")
                    callbackStore.failure(callbackId: callbackId, error: "Tough luck")
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
                    callbackStore.success(callbackId: callbackId, data: "Hello")
                    callbackStore.failure(callbackId: callbackId, error: "Tough luck")
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
