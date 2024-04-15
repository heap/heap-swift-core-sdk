import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class BridgedPageviewStoreSpec: HeapSpec {
    
    override func spec() {
        
        var store: BridgedPageviewStore!
        
        beforeEach {
            store = .init()
        }
        
        func simplePageview() -> Pageview {
            .init(sessionId: "1", properties: .with({ _ in }), timestamp: Date(), sourceInfo: nil, userInfo: nil)
        }
        
        it("stores pageviews up to the limit") {
            
            for i in 1...store.maxSize {
                _ = store.add(simplePageview(), at: "\(i)")
            }
            
            expect(store.keys).to(haveCount(store.maxSize))
        }
        
        it("prunes entries when passing the limit") {
            for i in 1...store.maxSize {
                _ = store.add(simplePageview(), at: "\(i)")
            }
            
            let removedKeys = store.add(simplePageview(), at: "last")
            expect(removedKeys).to(haveCount(store.numberToPruneWhenPruning))
            expect(store.keys).to(haveCount(store.maxSize + 1 - store.numberToPruneWhenPruning))
            expect(store.keys).toNot(contain(removedKeys))
        }
        
        it("prunes the oldest items first if none have been used") {
            for i in 1...store.numberToPruneWhenPruning {
                _ = store.add(simplePageview(), at: "\(i)")
            }
            
            let oldestKeys = store.keys
            
            Thread.sleep(forTimeInterval: 0.05)
            
            for i in (store.numberToPruneWhenPruning + 1)...store.maxSize {
                _ = store.add(simplePageview(), at: "\(i)")
            }

            let removedKeys = store.add(simplePageview(), at: "last")
            expect(removedKeys).to(haveCount(store.numberToPruneWhenPruning))
            expect(Set(removedKeys)).to(equal(oldestKeys))
        }
        
        it("doesn't prune recently used items, even if they're old") {
            
            for i in 1...10 {
                _ = store.add(simplePageview(), at: "\(i)")
            }

            Thread.sleep(forTimeInterval: 0.05)
            
            for i in 11...store.maxSize {
                _ = store.add(simplePageview(), at: "\(i)")
            }
            
            let touchedKeys = ["1", "3", "5", "7", "9"]
            
            Thread.sleep(forTimeInterval: 0.05)

            for key in touchedKeys {
                _ = store.get(key)
            }
            
            let removedKeys = store.add(simplePageview(), at: "last")
            expect(removedKeys).notTo(contain(touchedKeys))
            expect(store.keys).to(contain(touchedKeys))
            print(removedKeys)
        }
    }
}
