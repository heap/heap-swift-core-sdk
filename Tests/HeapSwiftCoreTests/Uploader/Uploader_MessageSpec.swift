import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class Uploader_MessageSpec: UploaderSpec {

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
            
            it("uploads messages after uploading the new user") {
                XCTFail()
            }
            
            it("uploads messages if the user has already been uploaded") {
                XCTFail()
            }
            
            context("uploading the messages succeeds") {
                
                it("removes the messages from the queue") {
                    XCTFail()
                }
                
                it("does not upload the messages again on future calls") {
                    XCTFail()
                }
                
                it("does not prevent future messages from being sent") {
                    XCTFail()
                }
            }
            
            context("multiple users with messages are present") {
                
                it("uploads all the messages") {
                    XCTFail()
                }
                
                it("uploads the active user's messages first") {
                    XCTFail()
                }
            }
            
            context("multiple sessions with messages are present on the active user") {
                
                it("uploads all the messages") {
                    XCTFail()
                }
                
                it("uploads the active sessions's messages first") {
                    XCTFail()
                }
            }
            
            context("the messages in queue exceed the byte count limit") {
                
                it("splits the messages into multiple batches") {
                    XCTFail()
                }
                
                it("sends all the messages") {
                    XCTFail()
                }
                
                it("sends a single message if the first message is over the byte count") {
                    XCTFail()
                }
            }
            
            context("the messages in queue exceed the message count limit") {
                
                it("splits the messages into multiple batches") {
                    XCTFail()
                }
                
                it("sends all the messages") {
                    XCTFail()
                }
            }
            
            context("a network failure occurs when uploading the messages") {
                
                it("returns that there was a network failure") {
                    XCTFail()
                }
                
                it("does not mark the messages as uploaded") {
                    XCTFail()
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    XCTFail()
                }
                
                it("prevents messages from uploading subsequent batches") {
                    XCTFail()
                }
            }
            
            context("an unexpected failure occurs when uploading the messages") {
                
                it("returns that there was a unexpected failure") {
                    XCTFail()
                }
                
                it("does not mark the messages as uploaded") {
                    XCTFail()
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    XCTFail()
                }
                
                it("prevents messages from uploading subsequent batches") {
                    XCTFail()
                }
            }
            
            context("a \"bad request\" failure occurs when uploading the messages") {
                
                it("returns that there was a \"bad request\" failure") {
                    XCTFail()
                }
                
                it("does not matrk the messages as uploaded if the session is active") {
                    XCTFail()
                }
                
                it("deletes the session if the session is not active") {
                    XCTFail()
                }
                
                it("does not attempt to upload the active session again") {
                    XCTFail()
                }
            }
        }
    }
}
