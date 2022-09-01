import Quick
import Nimble
@testable import HeapSwiftCore
import Foundation

final class LibraryInfoInfoSpec: QuickSpec {
    
    override func spec() {
        describe("LibraryInfo.baseInfo") {
            
            it("has the right name") {
                expect(LibraryInfo.baseInfo(with: .init()).name).to(equal("HeapSwiftCore"))
            }

            it("gets the platfrom from device info") {
                var deviceInfo = DeviceInfo()
                deviceInfo.platform = "N64"
                expect(LibraryInfo.baseInfo(with: deviceInfo).platform).to(equal("N64"))
            }
            
            it("has a valid version") {
                expect(LibraryInfo.baseInfo(with: .init()).version).to(match(regex: #"\A\d+\.\d+\.\d+(?:-(?:alpha|beta|rc)\.\d+)?\z"#))

                /*
                    Swift 5.7:

                    Regex {
                        Anchor.startOfSubject
                        OneOrMore(.digit)
                        "."
                        OneOrMore(.digit)
                        "."
                        OneOrMore(.digit)
                        Optionally {
                            Regex {
                            "-"
                            ChoiceOf {
                                "alpha"
                                "beta"
                                "rc"
                            }
                            "."
                            OneOrMore(.digit)
                            }
                        }
                        Anchor.endOfSubject
                    }
                */
            }
        }
    }
}
