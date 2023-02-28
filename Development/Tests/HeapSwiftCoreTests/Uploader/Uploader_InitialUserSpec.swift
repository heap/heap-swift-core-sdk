import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

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
            }
            
            it("uploads the correct properties") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                guard case .addUserProperties(.success(let userProperties)) = APIProtocol.requests.first
                else { throw TestFailure("Could not get first user properties") }
                
                let sdkInfo = SDKInfo.withoutAdvertiserId
                
                expect(userProperties.envID).to(equal("11"))
                expect(userProperties.userID).to(equal("123"))
                expect(userProperties.hasInitialDevice).to(beTrue())
                expect(userProperties.initialDevice).to(equal(sdkInfo.deviceInfo))
                expect(userProperties.hasInitialApplication).to(beTrue())
                expect(userProperties.initialApplication).to(equal(sdkInfo.applicationInfo))
                expect(userProperties.hasLibrary).to(beTrue())
                expect(userProperties.library).to(equal(sdkInfo.libraryInfo))
                expect(userProperties.properties).to(beEmpty())
            }
            
            context("multiple new users are present") {
                
                beforeEach {
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "345", identity: nil, creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                }
                
                it("uploads all the users") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "Three users should have been uploaded")
                    
                    expect(APIProtocol.addUserPropertyPayloads.map(\.userID)).to(contain("123", "234", "345"), description: "Each user Id should have been uploaded.")
                }
                
                it("uploads the active user first") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "Three users should have been uploaded")
                    
                    expect(APIProtocol.addUserPropertyPayloads.first?.userID).to(equal("123"), description: "The first user should have been the active user")
                }
            }
            
            // MARK: - Different network responses
            
            func queueJustANewUserUpload() {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
            }
            
            func itFinishesUploadingSuccessfully(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItFinishesUploadingSuccessfully.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itMarksTheUserAsUploaded(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheUserAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsASingleUserPropertiesRequest(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItSendsASingleRequestOfKind.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive isActive: Bool, andAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response) {
                        let timestamp = Date()
                        dataStore.createNewUserIfNeeded(environmentId: "11", userId: isActive ? "123" : "234", identity: nil, creationDate: timestamp)
                    }
                }
            }

            func itRetriesUntilTheErrorClears(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItRetriesUntilTheErrorClears.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itCausesTheUploadToFail(with error: UploadError, whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheUploadToFail.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, error: error, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itDoesNotMarkAnythingAsUploaded(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotMarkAnythingAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itCausesTheCurrentUploadPassToStopSendingData(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheCurrentUploadPassToStopSendingData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsQueuedMessages(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItConsumesAllTheMessages.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsQueuedIdentity(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheIdentityAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsQueuedUserProperties(whenAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksUserPropertiesAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itDeletesTheUserAfterTheInitialUpload(whenTheUserIsActive isActive: Bool, andAddUserProperitiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDeletesTheUserAfterUploading.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response) {
                        let timestamp = Date()
                        dataStore.createNewUserIfNeeded(environmentId: "11", userId: isActive ? "123" : "234", identity: nil, creationDate: timestamp)
                    }
                }
            }
            
            context("uploading the user succeeds") {
                itFinishesUploadingSuccessfully(whenAddUserProperitiesReceives: .success)
                itMarksTheUserAsUploaded(whenAddUserProperitiesReceives: .success)
                itSendsASingleUserPropertiesRequest(whenAddUserProperitiesReceives: .success)
                itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: true, andAddUserProperitiesReceives: .success)
                
                context("there is other data to send") {
                    itSendsQueuedIdentity(whenAddUserProperitiesReceives: .success)
                    itSendsQueuedMessages(whenAddUserProperitiesReceives: .success)
                    itSendsQueuedUserProperties(whenAddUserProperitiesReceives: .success)
                }
            }
            
            context("a network failure occurs when uploading the initial user") {
                itCausesTheUploadToFail(with: .networkFailure, whenAddUserProperitiesReceives: .networkFailure)
                itDoesNotMarkAnythingAsUploaded(whenAddUserProperitiesReceives: .networkFailure)
                itRetriesUntilTheErrorClears(whenAddUserProperitiesReceives: .networkFailure)
                
                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenAddUserProperitiesReceives: .networkFailure)
                }
            }
            
            context("an unexpected failure occurs when uploading the initial user") {
                itCausesTheUploadToFail(with: .unexpectedServerResponse, whenAddUserProperitiesReceives: .serviceUnavailable)
                itDoesNotMarkAnythingAsUploaded(whenAddUserProperitiesReceives: .serviceUnavailable)
                itRetriesUntilTheErrorClears(whenAddUserProperitiesReceives: .serviceUnavailable)
                
                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenAddUserProperitiesReceives: .serviceUnavailable)
                }
            }
            
            context("a \"bad request\" failure occurs when uploading the initial user") {
                itCausesTheUploadToFail(with: .badRequest, whenAddUserProperitiesReceives: .badRequest)
                
                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenAddUserProperitiesReceives: .badRequest)
                }
                
                context("the user is the active user") {
                    itDoesNotMarkAnythingAsUploaded(whenAddUserProperitiesReceives: .badRequest)
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: true, andAddUserProperitiesReceives: .badRequest)
                }
                
                context("The user is some other user") {
                    itDeletesTheUserAfterTheInitialUpload(whenTheUserIsActive: false, andAddUserProperitiesReceives: .badRequest)
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: false, andAddUserProperitiesReceives: .badRequest)
                }
            }
        }
    }
}
