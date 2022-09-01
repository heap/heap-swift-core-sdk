import Quick
import Nimble
@testable import HeapSwiftCore
import Foundation

final class ApplicationInfoSpec: QuickSpec {
    
    override func spec() {
        describe("ApplicationInfo.current") {
            var bundle: Bundle!
            var current: ApplicationInfo!
            
            beforeEach {
                bundle = .main
                current = .current
            }
            
            it("uses `CFBundleName` for `name`") {
                expect(current.hasName).to(beTrue())
                expect(current.name).to(equal(bundle.infoDictionary?["CFBundleName"] as? String))
            }
            
            it("uses `CFBundleIdentifier` for `identifier`") {
                expect(current.hasIdentifier).to(beTrue())
                expect(current.identifier).to(equal(bundle.infoDictionary?["CFBundleIdentifier"] as? String))
            }
            
            it("uses `CFBundleShortVersionString` for `versionString`") {
                expect(current.hasVersionString).to(beTrue())
                expect(current.versionString).to(equal(bundle.infoDictionary?["CFBundleShortVersionString"] as? String))
            }
        }
    }
}
