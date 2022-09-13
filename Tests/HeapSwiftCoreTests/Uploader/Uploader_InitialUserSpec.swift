import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class Uploader_InitialUserSpec: UploaderSpec {

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
            
            it("uploads a new user") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                ]))
                
                guard case .addUserProperties(.success(let userProperties)) = APIProtocol.requests.first
                else { return }
                
                expect(userProperties.envID).to(equal("11"))
                expect(userProperties.userID).to(equal("123"))
                expect(userProperties.hasInitialDevice).to(beTrue())
                expect(userProperties.initialDevice).to(equal(SDKInfo.current.deviceInfo))
                expect(userProperties.hasInitialApplication).to(beTrue())
                expect(userProperties.initialApplication).to(equal(SDKInfo.current.applicationInfo))
                expect(userProperties.hasLibrary).to(beTrue())
                expect(userProperties.library).to(equal(SDKInfo.current.libraryInfo))
                expect(userProperties.properties).to(beEmpty())
            }
            
            it("marks a new user as uploaded after a successful upload") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                expect(user.needsInitialUpload).to(beFalse(), description: "The user should not be marked for an additional upload")
            }
            
            it("does not upload the new user again after a successful upload") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                expectUploadAll(in: uploader).toEventually(beSuccess())
                expectUploadAll(in: uploader).toEventually(beSuccess())

                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                ]), description: "There should have been a single attempt to upload")
            }
            
            context("multiple new users are present") {
                
                it("uploads all the users") {
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "345", identity: nil, creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beSuccess())

                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "Three users should have been uploaded")
                    
                    expect(APIProtocol.addUserPropertyPayloads.map(\.userID)).to(contain("123", "234", "345"), description: "Each user Id should have been uploaded.")
                }
                
                it("uploads the active user first") {
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "345", identity: nil, creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beSuccess())

                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "Three users should have been uploaded")
                    
                    expect(APIProtocol.addUserPropertyPayloads.first?.userID).to(equal("123"), description: "The first user should have been the active user")
                }
            }
            
            context("a network failure occurs when uploading the initial user") {
                itHandlesANotFatalErrorResponse(.failWithNetworkError, with: .networkError)
                itHandlesTheErrorResponse(.failWithNetworkError, with: .networkError)
            }
            
            context("an unexpected failure occurs when uploading the initial user") {
                itHandlesANotFatalErrorResponse(.failWithUnexpectedStatus, with: .unknownError)
                itHandlesTheErrorResponse(.failWithUnexpectedStatus, with: .unknownError)
            }
            
            context("a \"bad request\" failure occurs when uploading the initial user") {
                
                itHandlesTheErrorResponse(.failWithBadRequest, with: .normalError)
                
                it("does not mark the user as uploaded if the user is active") {
                    APIProtocol.addUserPropertiesResponse = .failWithBadRequest
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: .normalError))
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    expect(user.needsInitialUpload).to(beTrue(), description: "The user should still be eligible for upload")
                }
                
                it("deletes the user if the user is not active") {
                    APIProtocol.addUserPropertiesResponse = .failWithBadRequest
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: .normalError))
                    
                    expect(dataStore.usersToUpload()).to(beEmpty(), description: "The user should have been deleted")
                }
                
                it("does not attempt to upload the active user again") {
                    APIProtocol.addUserPropertiesResponse = .failWithBadRequest
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: .normalError))
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                    ]), description: "There should only have been one attempt to upload the user")
                }
            }
            
            func itHandlesANotFatalErrorResponse(_ response: APIResponse, with error: UploadError) {
                it("does not mark the user as uploaded") {
                    APIProtocol.addUserPropertiesResponse = response
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    expect(user.needsInitialUpload).to(beTrue(), description: "The user should still be eligible for upload")
                }
                
                it("reattempts the upload on future calls, until it succeeds") {
                    APIProtocol.addUserPropertiesResponse = response
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                    
                    APIProtocol.addUserPropertiesResponse = .normal
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "There should have been two uploads that failed, followed by the one that succeeded")
                    
                    let user = try dataStore.assertOnlyOneUserToUpload()
                    expect(user.needsInitialUpload).to(beFalse(), description: "The user should not be marked for an additional upload")
                }
            }

            func itHandlesTheErrorResponse(_ response: APIResponse, with error: UploadError) {
                it("returns that there was a network failure") {
                    APIProtocol.addUserPropertiesResponse = response
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                }
                
                it("does not continue to upload the identity") {
                    APIProtocol.addUserPropertiesResponse = response
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                    ]), description: "There should be no subsequent requests after the user upload")
                }
                
                it("does not continue to upload the user properties") {
                    APIProtocol.addUserPropertiesResponse = response
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "hello", value: "world")
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                    ]), description: "There should be no subsequent requests after the user upload")
                }
                
                it("does not continue to upload the messages") {
                    APIProtocol.addUserPropertiesResponse = response
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    dataStore.createSessionIfNeeded(environmentId: "11", userId: "123", sessionId: "456", timestamp: timestamp)
                    
                    expectUploadAll(in: uploader).toEventually(beFailure(with: error))
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                    ]), description: "There should be no subsequent requests after the user upload")
                }
            }
        }
    }
}
