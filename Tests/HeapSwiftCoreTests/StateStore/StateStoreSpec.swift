import Foundation
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class StateStoreSpec: HeapSpec {

    override func spec() {
        
        context("InMemoryDataStore") {
            var stateStore: InMemoryDataStore! = nil
            
            beforeEach {
                stateStore = InMemoryDataStore()
            }
            
            spec(stateStore: { stateStore })
        }
        
        context("FileBasedStateStore") {
            
            var stateStore: FileBasedStateStore! = nil
            
            beforeEach {
                stateStore = FileBasedStateStore(directoryUrl: FileManager.default.temporaryDirectory)
            }
            
            afterEach {
                stateStore.delete(environmentId: "11")
                stateStore.delete(environmentId: "12")
            }
            
            spec(stateStore: { stateStore })
        }
    }
    
    func spec<StateStore>(stateStore: @escaping () -> StateStore) where StateStore : StateStoreProtocol {
        
        describe("loadState") {
            it("returns an empty state if given an unknown environment id") {
                
                let blankState = EnvironmentState.with {
                    $0.envID = "99999"
                }
                
                expect(stateStore().loadState(for: "99999")).to(equal(blankState))
            }
        }
        
        it("can persist state") {
            
            var state = stateStore().loadState(for: "11")
            state.userID = "test"
            state.identity = "other-test"
            state.properties = ["foo": .init(value: "bar")]
            
            stateStore().save(state)
            
            expect(stateStore().loadState(for: "11")).toEventually(equal(state))
        }
        
        it("can persist multiple states") {
            var state1 = stateStore().loadState(for: "11")
            state1.userID = "test1"
            var state2 = stateStore().loadState(for: "12")
            state2.userID = "test2"

            stateStore().save(state1)
            stateStore().save(state2)

            expect(stateStore().loadState(for: "11")).toEventually(equal(state1))
            expect(stateStore().loadState(for: "12")).toEventually(equal(state2))
        }
    }
}

final class FileBasedStateStoreSpec: HeapSpec {

    override func spec() {
        
        describe("FileBasedStateStore.loadState") {
            
            var stateStore: FileBasedStateStore! = nil
            
            beforeEach {
                stateStore = FileBasedStateStore(directoryUrl: FileManager.default.temporaryDirectory)
            }
            
            afterEach {
                stateStore.delete(environmentId: "11")
            }
            
            it("returns an empty state when corrupted") {
                
                let blankState = EnvironmentState.with {
                    $0.envID = "11"
                }
                
                // Write garbage
                try Data(repeating: 0x20, count: 50).write(to: stateStore.url(for: "11"))
                
                expect(stateStore.loadState(for: "11")).to(equal(blankState))
            }
        }
    }
}
