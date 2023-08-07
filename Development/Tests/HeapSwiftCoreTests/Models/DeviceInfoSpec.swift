import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DeviceInfoSpec: HeapSpec {
    
    override func spec() {
        describe("DeviceInfo.current") {
            
            context("default options") {
                
                var current: DeviceInfo!
                
                beforeEach {
                    current = .current(with: .init(with: [:]), includeCarrier: false)
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
                
                it("does not have a vendorId") {
                    expect(current.hasVendorID).to(beFalse())
                }
                
                it("does not have a user agent") {
                    expect(current.hasUserAgent).to(beFalse())
                }
                
                it("does not have an advertiserId") {
                    expect(current.hasAdvertiserID).to(beFalse(), description: "Should not have been set, but has \(current.advertiserID)")
                }
                
                // TODO: Need a cellular device to test carrier
            }
            
            context("captureAdvertiserId is enabled") {

                it("does not have an advertiserId when AdSupport is not linked, even if enabled") {
                    let current: DeviceInfo = .current(with: .init(with: [
                        .captureAdvertiserId: true // Set to true so we can validate the on behavior
                    ]), includeCarrier: false)
                    
                    expect(current.hasAdvertiserID).to(beFalse())
                }
            }
            
            context("captureVendorId is disabled") {

                it("does not have a vendorId") {
                    let current: DeviceInfo = .current(with: .init(with: [
                        .captureVendorId: false // Explicitly set to false so we can validate the off behavior
                    ]), includeCarrier: false)
                    
                    expect(current.hasVendorID).to(beFalse())
                }
            }
            
            context("captureVendorId is enabled") {
                
                var current: DeviceInfo!
                
                beforeEach {
                    current = .current(with: .init(with: [
                        .captureVendorId: true // Set to true so we can validate the on behavior
                    ]), includeCarrier: false)
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
            }
        }
    }
}
