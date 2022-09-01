import XCTest
import Quick
import Nimble
import AdSupport
@testable import HeapSwiftCore

final class DeviceInfoSpec: QuickSpec {
    
    override func spec() {
        describe("DeviceInfo.current") {
            
            beforeEach {
                _ = ASIdentifierManager.shared() // Force AdSupport to load
            }
            
            it("has an advertiserId when AdSupport is linked") {
                let deviceInfo = DeviceInfo.current(includeCarrier: false)
                expect(deviceInfo.hasAdvertiserID).to(beTrue())
                expect(UUID(uuidString: deviceInfo.advertiserID)).notTo(beNil(), description: "\(deviceInfo.advertiserID) should be a UUID")
            }
        }
    }
}
