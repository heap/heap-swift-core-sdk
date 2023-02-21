import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DeviceInfoSpec: HeapSpec {
    
    override func spec() {
        describe("DeviceInfo.current") {
            
            var current: DeviceInfo!
            
            beforeEach {
                current = .current(includeCarrier: false)
            }
            
            it("has a model") {
                expect(current.model).toNot(beEmpty())
            }
            
            it("has a platform") {
                expect(current.platform).toNot(beEmpty())
            }
            
            it("has a type") {
                expect(current.type).toNot(equal(.unknownUnspecified))
            }
            
            #if os(macOS)
            
            it("does not have a vendorId") {
                expect(current.hasVendorID).to(beFalse())
            }
            
            #else
            
            it("has a vendorId") {
                expect(current.hasVendorID).to(beTrue())
                expect(current.vendorID).toNot(beEmpty())
            }
            
            #endif
            
            it("does not have a user agent") {
                expect(current.hasUserAgent).to(beFalse())
            }
            
            it("does not have an advertiserId when AdSupport is not linked") {
                expect(current.hasAdvertiserID).to(beFalse(), description: "Should not have been set, but has \(current.advertiserID)")
            }
            
            // TODO: Need a cellular device to test carrier
        }
    }
}
