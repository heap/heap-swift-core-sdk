import Foundation
import Quick
import Nimble
import XCTest
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

@objc
fileprivate protocol Foo: AnyObject {
    @objc(_setContentsquareIntegration:)
    func _setContentsquareIntegration(_ integration: AnyObject)
}

final class ContentsquareIntegrationSpec: QuickSpec {
    
    override func spec() {
        
        describe("Heap") {
            
            let selector = #selector(Foo._setContentsquareIntegration(_:))
            
            it("responds to _setContentsquareIntegration:") {
                expect(Heap.shared.responds(to: selector)).to(beTrue())
            }
            
            describe("_setContentsquareIntegration") {
                it("sets the integration") {
                    let integration = CountingContentsquareIntegration(sessionTimeoutDuration: 600)
                    _ = Heap.shared.perform(selector, with: integration)
                    expect(Heap.shared.consumer.contentsquareIntegration).toNot(beNil())
                }
                
                it("triggers setContentsquareMethods") {
                    let integration = CountingContentsquareIntegration(sessionTimeoutDuration: 600)
                    _ = Heap.shared.perform(selector, with: integration)
                    expect(integration.contentsquareMethods).toNot(beNil())
                }
            }
        }
    }
}
