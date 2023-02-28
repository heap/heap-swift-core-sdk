#if !os(watchOS)
import XCTest
import Quick
import Nimble
import AdSupport
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DeviceInfoSpec: QuickSpec {
    
    override func spec() {
        describe("DeviceInfo.current") {
            
            beforeEach {
                _ = ASIdentifierManager.shared() // Force AdSupport to load
            }
            
            it("has an advertiserId when AdSupport is linked and captureAdvertiserId is enabled") {
                let deviceInfo = DeviceInfo.current(with: [ .captureAdvertiserId: true ], includeCarrier: false)
                expect(deviceInfo.hasAdvertiserID).to(beTrue())
                expect(UUID(uuidString: deviceInfo.advertiserID)).notTo(beNil(), description: "\(deviceInfo.advertiserID) should be a UUID")
            }
            
            it("does not have an advertiserId when AdSupport is linked and captureAdvertiserId is disabled") {
                let deviceInfo = DeviceInfo.current(with: [:], includeCarrier: false)
                expect(deviceInfo.hasAdvertiserID).to(beFalse())
            }
        }
    }
}
#endif
