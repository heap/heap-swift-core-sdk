import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DelegateManagerSpec: HeapSpec {
    
    override func spec() {
        
        var delegateManager: DelegateManager!
        var sourceA1: CountingSource!
        var sourceA2: CountingSource!
        var sourceB1: CountingSource!
        
        var bridge1: CountingRuntimeBridge!
        var bridge2: CountingRuntimeBridge!
        var bridge3: CountingRuntimeBridge!

        beforeEach {
            delegateManager = DelegateManager()
            sourceA1 = CountingSource(name: "A", version: "1")
            sourceA2 = CountingSource(name: "A", version: "2")
            sourceB1 = CountingSource(name: "B", version: "1")
            bridge1 = CountingRuntimeBridge()
            bridge2 = CountingRuntimeBridge()
            bridge3 = CountingRuntimeBridge()
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }
        
        describe("DelegateManager.addSource") {
            
            it("adds the source if it was not already added") {
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                
                expect(delegateManager.current.sources.count).to(equal(1))
                expect(delegateManager.current.sources["A"] as? CountingSource).to(equal(sourceA1))
            }
            
            it("does not add the source if it was already added") {
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)

                expect(delegateManager.current.sources.count).to(equal(1))
                expect(delegateManager.current.sources["A"] as? CountingSource).to(equal(sourceA1))
            }
            
            it("replaces the source if a different source with the same name was used") {
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceA2, isDefault: false, timestamp: .init(), currentState: nil)

                expect(delegateManager.current.sources.count).to(equal(1))
                expect(delegateManager.current.sources["A"] as? CountingSource).to(equal(sourceA2))
                
            }
            
            it("sets the default source if `isDefault` is true") {
                delegateManager.addSource(sourceA1, isDefault: true, timestamp: .init(), currentState: nil)

                expect(delegateManager.current.defaultSource as? CountingSource).to(equal(sourceA1))
            }
            
            it("replaces the default source if `isDefault` is true") {
                delegateManager.addSource(sourceA1, isDefault: true, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceB1, isDefault: true, timestamp: .init(), currentState: nil)

                expect(delegateManager.current.defaultSource as? CountingSource).to(equal(sourceB1))
            }
            
            it("does not change the default source if `isDefault` is false") {
                delegateManager.addSource(sourceA1, isDefault: true, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceB1, isDefault: false, timestamp: .init(), currentState: nil)

                expect(delegateManager.current.defaultSource as? CountingSource).to(equal(sourceA1))
            }
            
            it("clears the default source if `isDefault` is false and we're replacing a source of the same name") {
                
                delegateManager.addSource(sourceA1, isDefault: true, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceA2, isDefault: false, timestamp: .init(), currentState: nil)

                expect(delegateManager.current.defaultSource).to(beNil())
            }
            
            it("calls `didStartRecording` and `sessionDidStart` if there's a current envrionment") {
                
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: currentState)
                
                expect(sourceA1.calls).to(equal([
                    .didStartRecording,
                    .sessionDidStart,
                ]))
            }
            
            it("does not call `didStartRecording` and `sessionDidStart` if there's not a envrionment") {
                
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                
                expect(sourceA1.calls).to(beEmpty())
            }
            
            it("does not call `didStartRecording` and `sessionDidStart` if the source was previously added") {
                
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: currentState)
                
                sourceA1.calls.removeAll()
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: currentState)

                expect(sourceA1.calls).to(beEmpty())
            }
            
            it("calls `didStopRecording` on the removed source if there is a current envrironment") {
                
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: currentState)
                
                delegateManager.addSource(sourceA2, isDefault: false, timestamp: .init(), currentState: currentState)

                expect(sourceA1.calls).to(equal([
                    .didStartRecording,
                    .sessionDidStart,
                    .didStopRecording,
                ]))
            }
            
            it("does not call `didStopRecording` on the removed source if there is not a current envrionment") {
                
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceA2, isDefault: false, timestamp: .init(), currentState: nil)

                expect(sourceA1.calls).to(beEmpty())
            }
        }
        
        describe("DelegateManager.removeSource") {
            
            it("does nothing if the source wasn't added") {
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.removeSource("B", currentState: nil)
                
                expect(delegateManager.current.sources.count).to(equal(1))
            }
            
            it("removes the source") {
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.removeSource("A", currentState: nil)
                
                expect(delegateManager.current.sources).to(beEmpty())
            }
            
            it("removes the default source if it was the removed source") {
                delegateManager.addSource(sourceA1, isDefault: true, timestamp: .init(), currentState: nil)
                delegateManager.removeSource("A", currentState: nil)
                
                expect(delegateManager.current.defaultSource).to(beNil())
            }
            
            it("does not remove the default source if it was not the removed source") {
                delegateManager.addSource(sourceA1, isDefault: true, timestamp: .init(), currentState: nil)
                delegateManager.addSource(sourceB1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.removeSource("B", currentState: nil)
                
                expect(delegateManager.current.defaultSource as? CountingSource).to(equal(sourceA1))

            }

            it("calls `didStopRecording` if there is a current envrironment") {
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.removeSource("A", currentState: currentState)

                expect(sourceA1.calls).to(equal([
                    .didStopRecording,
                ]))
            }
            
            it("does not call `didStopRecording` if there is not a current envrionment") {
                delegateManager.addSource(sourceA1, isDefault: false, timestamp: .init(), currentState: nil)
                delegateManager.removeSource("A", currentState: nil)

                expect(sourceA1.calls).to(beEmpty())
            }

        }
        
        describe("DelegateManager.addRuntimeBridge") {
            
            it("adds the bridge if it was not already added") {
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                delegateManager.addRuntimeBridge(bridge2, timestamp: .init(), currentState: nil)
                
                expect(delegateManager.current.runtimeBridges.map({ $0 as? CountingRuntimeBridge})).to(equal([bridge1, bridge2]))
            }
            
            it("does not add the bridge if it was already added") {
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                
                expect(delegateManager.current.runtimeBridges.map({ $0 as? CountingRuntimeBridge})).to(equal([bridge1]))
            }
            
            it("calls `didStartRecording` and `sessionDidStart` if there's a current envrionment") {
                
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: currentState)
                
                expect(bridge1.calls).to(equal([
                    .didStartRecording,
                    .sessionDidStart,
                ]))
            }
            
            it("does not call `didStartRecording` and `sessionDidStart` if there's not a envrionment") {
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                
                expect(bridge1.calls).to(beEmpty())
            }
            
            it("does not call `didStartRecording` and `sessionDidStart` if the bridge was previously added") {
                
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: currentState)
                bridge1.calls.removeAll()
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: currentState)
                
                expect(bridge1.calls).to(beEmpty())
            }
        }
        
        describe("DelegateManager.removeRuntimeBridge") {
            
            it("does nothing if the bridge wasn't added") {
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                delegateManager.addRuntimeBridge(bridge2, timestamp: .init(), currentState: nil)
                
                delegateManager.removeRuntimeBridge(bridge3, currentState: nil)
                
                expect(delegateManager.current.runtimeBridges.map({ $0 as? CountingRuntimeBridge})).to(equal([bridge1, bridge2]))
                
            }
            
            it("removes the bridge") {
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                delegateManager.addRuntimeBridge(bridge2, timestamp: .init(), currentState: nil)
                
                delegateManager.removeRuntimeBridge(bridge1, currentState: nil)
                
                expect(delegateManager.current.runtimeBridges.map({ $0 as? CountingRuntimeBridge})).to(equal([bridge2]))
            }
            
            it("calls `didStopRecording` if there is a current envrironment") {
                
                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: currentState)
                delegateManager.removeRuntimeBridge(bridge1, currentState: currentState)
                
                expect(bridge1.calls).to(equal([
                    .didStartRecording,
                    .sessionDidStart,
                    .didStopRecording,
                ]))
            }
            
            it("does not call `didStopRecording` if there is not a current envrionment") {
                
                delegateManager.addRuntimeBridge(bridge1, timestamp: .init(), currentState: nil)
                delegateManager.removeRuntimeBridge(bridge1, currentState: nil)
                
                expect(bridge1.calls).to(beEmpty())
            }
            
            it("does not call `didStopRecording` if the source was not added") {

                let currentState = State(environmentId: "1", userId: "2", sessionId: "3")
                
                delegateManager.removeRuntimeBridge(bridge1, currentState: currentState)
                
                expect(bridge1.calls).to(beEmpty())
            }
        }
    }
}
