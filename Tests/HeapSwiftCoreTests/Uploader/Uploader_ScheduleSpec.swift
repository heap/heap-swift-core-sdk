import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class Uploader_ScheduleSpec: UploaderSpec {

    override func spec() {
        describe("Uploader.performScheduledUpload") {

            var dataStore: InMemoryDataStore!
            var uploader: TestableUploader!

            beforeEach {
                self.prepareUploader(dataStore: &dataStore, uploader: &uploader)
            }
            
            afterEach {
                APIProtocol.reset()
            }
            
            context("the next upload date is in the past") {
                it("does not make any requests when the network is unreachable") {
                    XCTFail()
                }
                
                it("peforms Uploader.uploadAll") {
                    XCTFail()
                }
                
                it("completes with the new upload date, 15 seconds in the future for a successful request") {
                    XCTFail()
                }
                
                it("completes with the new upload date, 15 seconds in the future for a \"bad request\" request") {
                    XCTFail()
                }
                
                it("completes with the new upload date, 60 seconds in the future for a network error") {
                    XCTFail()
                }
                
                it("completes with the new upload date, 60 seconds in the future for an unknown error") {
                    XCTFail()
                }
            }
            
            context("the next upload date is in the future") {
                
                it("does not make any requests") {
                    XCTFail()
                }
                
                it("completes with the current next upload date") {
                    XCTFail()
                }
            }

            it("performs Uploader.uploadAll when called and the next upload date is in the past") {
                XCTFail()
            }
            
            it("performs Uploader.uploadAll when called and the next upload date is in the past") {
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
