import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class Uploader_IdentifySpec: UploaderSpec {

    override func spec() {
        describe("Uploader.uploadAll") {

            var dataStore: InMemoryDataStore!
            var uploader: TestableUploader!

            beforeEach {
                self.prepareUploader(dataStore: &dataStore, uploader: &uploader)
            }
            
            afterEach {
                APIProtocol.reset()
            }
            
            it("uploads identity after uploading the new user") {
                XCTFail()
            }
            
            it("uploads identity if the user has already been uploaded") {
                XCTFail()
            }
            
            context("uploading the identity succeeds") {
                
                it("marks the identity as uploaded") {
                    XCTFail()
                }
                
                it("does not upload the identity again on future calls") {
                    XCTFail()
                }
            }
            
            context("multiple identities are present") {
                
                it("uploads all the identities") {
                    XCTFail()
                }
                
                it("uploads the active identity first") {
                    XCTFail()
                }
            }
            
            context("a network failure occurs when uploading the identity") {
                
                it("returns that there was a network failure") {
                    XCTFail()
                }
                
                it("does not mark the identity as uploaded") {
                    XCTFail()
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    XCTFail()
                }
                
                it("prevents messages from uploading") {
                    XCTFail()
                }
            }
            
            context("an unexpected failure occurs when uploading the identity") {
                
                it("returns that there was a unexpected failure") {
                    XCTFail()
                }
                
                it("does not mark the identity as uploaded") {
                    XCTFail()
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    XCTFail()
                }
                
                it("prevents messages from uploading") {
                    XCTFail()
                }
            }
            
            context("a \"bad request\" failure occurs when uploading the identity") {
                
                it("returns that there was a \"bad request\" failure") {
                    XCTFail()
                }
                
                it("marks the identity as uploaded") {
                    XCTFail()
                }
                
                it("does not upload the identity again on future calls") {
                    XCTFail()
                }
                
                it("does not prevent messages from uploading") {
                    XCTFail()
                }
                
                it("does not prevent user properties from uploading") {
                    XCTFail()
                }
            }
        }
    }
}
