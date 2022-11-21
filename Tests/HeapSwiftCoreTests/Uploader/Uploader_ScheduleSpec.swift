import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class Uploader_ScheduleSpec: UploaderSpec {

    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var uploader: TestableUploader!

        beforeEach {
            self.prepareUploader(dataStore: &dataStore, uploader: &uploader)
        }
        
        afterEach {
            uploader.stopScheduledUploads()
            APIProtocol.reset()
        }

        describe("Uploader.performScheduledUpload") {
            
            context("the next upload date is in the past") {
                
                beforeEach {
                    uploader.nextScheduledUploadDate = Date().addingTimeInterval(-5)
                }
                
                context("there is data to upload") {
                    beforeEach {
                        uploader.dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                    }
                    
                    it("performs Uploader.uploadAll") {
                        expectPerformScheduledUpload(in: uploader).toEventuallyNot(beNil())
                        expect(APIProtocol.addUserPropertyPayloads).toNot(beEmpty(), description: "The scheduled uploader should have uploaded a new user")
                    }
                    
                    it("completes with the new upload date, 15 seconds in the future for a successful request") {
                        let startDate = Date()
                        expectPerformScheduledUpload(in: uploader).toEventually(beCloseTo(15, after: startDate))
                    }
                    
                    it("completes with the new upload date, 15 seconds in the future for a \"bad request\" request") {
                        APIProtocol.addUserPropertiesResponse = .badRequest
                        let startDate = Date()
                        expectPerformScheduledUpload(in: uploader).toEventually(beCloseTo(15, after: startDate))
                    }
                    
                    it("completes with the new upload date, 60 seconds in the future for a network error") {
                        APIProtocol.addUserPropertiesResponse = .networkFailure
                        let startDate = Date()
                        expectPerformScheduledUpload(in: uploader).toEventually(beCloseTo(60, after: startDate))
                    }
                    
                    it("completes with the new upload date, 60 seconds in the future for an unknown error") {
                        APIProtocol.addUserPropertiesResponse = .serviceUnavailable
                        let startDate = Date()
                        expectPerformScheduledUpload(in: uploader).toEventually(beCloseTo(60, after: startDate))
                    }
                }
                
                context("there is no data to upload") {
                    
                    it("completes with the new upload date, 15 seconds in the future") {
                        let startDate = Date()
                        expectPerformScheduledUpload(in: uploader).toEventually(beCloseTo(15, after: startDate))
                    }
                }
            }
            
            context("the next upload date is in the future") {
                
                var initialNextScheduledUploadDate: Date!
                beforeEach {
                    initialNextScheduledUploadDate = Date().addingTimeInterval(5)
                    uploader.nextScheduledUploadDate = initialNextScheduledUploadDate
                    uploader.dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                }
                
                it("does not make any requests") {
                    expectPerformScheduledUpload(in: uploader).toEventuallyNot(beNil())
                    expect(APIProtocol.requests).to(beEmpty(), description: "No requests should have been made when the next upload date is in the future")
                }
                
                it("completes with the current next upload date") {
                    expectPerformScheduledUpload(in: uploader).toEventually(equal(initialNextScheduledUploadDate), description: "The next upload date should not have changed")
                }
            }
        }
        
        describe("Uploader.startScheduledUploads") {
            
            var initialNextScheduledUploadDate: Date!
            beforeEach {
                initialNextScheduledUploadDate = uploader.nextScheduledUploadDate
            }
            
            it("performs an immediate upload attempt when called the first time") {
                uploader.startScheduledUploads(with: [:])
                expect(uploader.nextScheduledUploadDate).toEventuallyNot(equal(initialNextScheduledUploadDate))
            }
            
            it("does not perform subsequent initial uploads when called repeatedly") {
                uploader.startScheduledUploads(with: [:])
                expect(uploader.nextScheduledUploadDate).toEventuallyNot(equal(initialNextScheduledUploadDate))
                let subsequentNextScheduledUploadDate = uploader.nextScheduledUploadDate
                uploader.startScheduledUploads(with: [:])
                uploader.startScheduledUploads(with: [:])
                uploader.startScheduledUploads(with: [:])
                expect(uploader.nextScheduledUploadDate).toAlways(equal(subsequentNextScheduledUploadDate), description: "Extra start calls should not trigger additional uploads")
            }
            
            it("performs uploads at a regular interval") {
                uploader.startScheduledUploads(with: [.uploadInterval: TimeInterval(0.1) ])
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: Date())
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "345", identity: nil, creationDate: Date())
                }
                
                expect(APIProtocol.addUserPropertyPayloads).toEventually(haveCount(1), description: "Given the spacing, we should have uploaded one user per upload cycle time")
                expect(APIProtocol.addUserPropertyPayloads).toEventually(haveCount(2), description: "Given the spacing, we should have uploaded one user per upload cycle time")
                expect(APIProtocol.addUserPropertyPayloads).toEventually(haveCount(3), description: "Given the spacing, we should have uploaded one user per upload cycle time")
            }
            
            it("uses the baseUrl option") {
                let baseUrl = URL(string: "https://example.com:123/foo/bar/")!
                APIProtocol.baseUrlOverride = baseUrl
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                uploader.startScheduledUploads(with: [ .baseUrl: baseUrl ])
                expect(APIProtocol.addUserPropertyPayloads).toEventually(haveCount(1), description: "The user should have been uploaded to the custom location")
            }
        }
        
        describe("Uploader.stopScheduledUploads") {
            
            it("stops scheduled uploads") {
                uploader.startScheduledUploads(with: [.uploadInterval: TimeInterval(0.1) ])
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(500)) {
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(1000)) {
                    uploader.stopScheduledUploads()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                }
                
                expect(APIProtocol.addUserPropertyPayloads).toEventually(haveCount(1), description: "The first user should have uploaded prior to stopping")
                expect(APIProtocol.addUserPropertyPayloads).toAlways(haveCount(1), description: "The second user hsould not have been uploaded")
            }
        }
    }
}
