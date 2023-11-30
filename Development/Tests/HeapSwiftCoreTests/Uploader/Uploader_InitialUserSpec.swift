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
                
                guard case .addUserProperties(.success(let userProperties), _) = APIProtocol.requests.first
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
            
            it("sets query properties and header") {
                
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                expect(APIProtocol.requests).to(haveCount(1), description: "PRECONDITION: There should only be one request")
                
                expect(APIProtocol.requests.first?.rawRequest).to(haveMetadata(environmentId: "11", userId: "123", identity: nil, library: SDKInfo.withoutAdvertiserId.libraryInfo.name))
            }
            
            it("sets query properties and header when identity is set") {
                
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                dataStore.setHasSentIdentity(environmentId: "11", userId: "123")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                expect(APIProtocol.requests).to(haveCount(1), description: "PRECONDITION: There should only be one request")
                
                expect(APIProtocol.requests.first?.rawRequest).to(haveMetadata(environmentId: "11", userId: "123", identity: "user-1", library: SDKInfo.withoutAdvertiserId.libraryInfo.name))
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
            
            func itFinishesUploadingSuccessfully(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItFinishesUploadingSuccessfully.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itMarksTheUserAsUploaded(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheUserAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsASingleUserPropertiesRequest(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItSendsASingleRequestOfKind.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive isActive: Bool, andAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response) {
                        let timestamp = Date()
                        dataStore.createNewUserIfNeeded(environmentId: "11", userId: isActive ? "123" : "234", identity: nil, creationDate: timestamp)
                    }
                }
            }

            func itRetriesUntilTheErrorClears(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItRetriesUntilTheErrorClears.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itCausesTheUploadToFail(with error: UploadError, whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheUploadToFail.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, error: error, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itDoesNotMarkAnythingAsUploaded(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotMarkAnythingAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustANewUserUpload)
                }
            }
            
            func itCausesTheCurrentUploadPassToStopSendingData(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheCurrentUploadPassToStopSendingData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsQueuedMessages(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItConsumesAllTheMessages.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsQueuedIdentity(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheIdentityAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            func itSendsQueuedUserProperties(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksUserPropertiesAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: true)
                }
            }
            
            context("uploading the user succeeds") {
                itFinishesUploadingSuccessfully(whenAddUserPropertiesReceives: .success)
                itMarksTheUserAsUploaded(whenAddUserPropertiesReceives: .success)
                itSendsASingleUserPropertiesRequest(whenAddUserPropertiesReceives: .success)
                
                context("there is other data to send") {
                    itSendsQueuedIdentity(whenAddUserPropertiesReceives: .success)
                    itSendsQueuedMessages(whenAddUserPropertiesReceives: .success)
                    itSendsQueuedUserProperties(whenAddUserPropertiesReceives: .success)
                }
                
                context("the user is the active user") {
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: true, andAddUserPropertiesReceives: .success)
                }
                
                context("The user is some other user") {
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: false, andAddUserPropertiesReceives: .success)
                }
            }
            
            context("a \"bad request\" failure occurs when uploading the initial user") {
                itCausesTheUploadToFail(with: .badRequest, whenAddUserPropertiesReceives: .badRequest)
                itMarksTheUserAsUploaded(whenAddUserPropertiesReceives: .badRequest)
                itSendsASingleUserPropertiesRequest(whenAddUserPropertiesReceives: .badRequest)
                
                context("there is other data to send") {
                    itSendsQueuedIdentity(whenAddUserPropertiesReceives: .badRequest)
                    itSendsQueuedMessages(whenAddUserPropertiesReceives: .badRequest)
                    itSendsQueuedUserProperties(whenAddUserPropertiesReceives: .badRequest)
                }
                
                context("the user is the active user") {
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: true, andAddUserPropertiesReceives: .badRequest)
                }
                
                context("The user is some other user") {
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheUserIsActive: false, andAddUserPropertiesReceives: .badRequest)
                }
            }
            
            context("a network failure occurs when uploading the initial user") {
                itCausesTheUploadToFail(with: .networkFailure, whenAddUserPropertiesReceives: .networkFailure)
                itDoesNotMarkAnythingAsUploaded(whenAddUserPropertiesReceives: .networkFailure)
                itRetriesUntilTheErrorClears(whenAddUserPropertiesReceives: .networkFailure)
                
                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenAddUserPropertiesReceives: .networkFailure)
                }
            }
            
            context("an unexpected failure occurs when uploading the initial user") {
                itCausesTheUploadToFail(with: .unexpectedServerResponse, whenAddUserPropertiesReceives: .serviceUnavailable)
                itDoesNotMarkAnythingAsUploaded(whenAddUserPropertiesReceives: .serviceUnavailable)
                itRetriesUntilTheErrorClears(whenAddUserPropertiesReceives: .serviceUnavailable)
                
                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenAddUserPropertiesReceives: .serviceUnavailable)
                }
            }
        }
    }
}
