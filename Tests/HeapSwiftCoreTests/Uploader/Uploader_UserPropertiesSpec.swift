import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class Uploader_UserPropertiesSpec: UploaderSpec {

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
            
            it("uploads user properties after uploading the new user") {
                XCTFail()
            }
            
            it("uploads user properties if the user has already been uploaded") {
                XCTFail()
            }
            
            context("uploading the user properties succeeds") {
                
                it("marks the user properties as uploaded") {
                    XCTFail()
                }
                
                it("does not upload the same user properties again on future calls") {
                    XCTFail()
                }
                
                it("does not prevent new user properties from uploading") {
                    XCTFail()
                }
            }
            
            context("multiple users with user properties are present") {
                
                it("uploads all the user properties") {
                    XCTFail()
                }
                
                it("uploads the active user properties first") {
                    XCTFail()
                }
            }
            
            context("a network failure occurs when uploading user properties") {
                
                it("returns that there was a network failure") {
                    XCTFail()
                }
                
                it("does not mark the user properties as uploaded") {
                    XCTFail()
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    XCTFail()
                }
                
                it("prevents messages from uploading") {
                    XCTFail()
                }
            }
            
            context("an unexpected failure occurs when uploading user properties") {
                
                it("returns that there was a unexpected failure") {
                    XCTFail()
                }
                
                it("does not mark the user properties as uploaded") {
                    XCTFail()
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    XCTFail()
                }
                
                it("prevents messages from uploading") {
                    XCTFail()
                }
            }
            
            context("a \"bad request\" failure occurs when uploading user properties") {
                
                it("returns that there was a \"bad request\" failure") {
                    XCTFail()
                }
                
                it("marks the user properties as uploaded") {
                    XCTFail()
                }
                
                it("does not upload the same user properties again on future calls") {
                    XCTFail()
                }
                
                it("does not prevent new user properties from uploading") {
                    XCTFail()
                }

                it("does not prevent messages from uploading") {
                    XCTFail()
                }
                
                it("does not prevent identity from uploading") {
                    XCTFail()
                }
            }
        }
    }
}

