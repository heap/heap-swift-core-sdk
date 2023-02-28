import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

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
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                    .identify(true),
                ]))
            }
            
            it("uploads identity if the user has already been uploaded") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .identify(true),
                ]))
            }
            
            it("uploads the correct properties") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                guard let userIdentification = APIProtocol.identifyPayloads.first
                else { throw TestFailure("Could not get first identity") }
                
                expect(userIdentification.envID).to(equal("11"))
                expect(userIdentification.userID).to(equal("123"))
                expect(userIdentification.identity).to(equal("user-1"))
                expect(userIdentification.library).to(equal(SDKInfo.withoutAdvertiserId.libraryInfo))
            }
            
            context("multiple identities are present") {
                
                beforeEach {
                    let timestamp = Date()
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "345", identity: "user-3", creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "234", identity: "user-2", creationDate: timestamp)
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                    dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                    dataStore.setHasSentInitialUser(environmentId: "11", userId: "234")
                    dataStore.setHasSentInitialUser(environmentId: "11", userId: "345")
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                }
                
                it("uploads all the identities") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .identify(true),
                        .identify(true),
                        .identify(true),
                    ]), description: "Three identities should have been uploaded")
                    
                    expect(APIProtocol.identifyPayloads.map(\.userID)).to(contain("123", "234", "345"), description: "Each user Id should have been uploaded.")
                    expect(APIProtocol.identifyPayloads.map(\.identity)).to(contain("user-1", "user-2", "user-3"), description: "Each identity should have been uploaded.")
                }
                
                it("uploads the active identity first") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .identify(true),
                        .identify(true),
                        .identify(true),
                    ]), description: "Three identities should have been uploaded")
                    
                    expect(APIProtocol.identifyPayloads.first?.userID).to(equal("123"), description: "The first user should have been the active user")
                    expect(APIProtocol.identifyPayloads.first?.identity).to(equal("user-1"), description: "The first user should have been the active user")
                }
            }
            
            // MARK: - Different network responses
            
            func queueJustAnIdentityUpload() {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
            }
            
            func itFinishesUploadingSuccessfully(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItFinishesUploadingSuccessfully.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, beforeEach: queueJustAnIdentityUpload)
                }
            }
            
            func itMarksTheIdentityAsUploaded(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheIdentityAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, newUser: false)
                }
            }
            
            func itSendsASingleIdentifyRequest(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItSendsASingleRequestOfKind.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, beforeEach: queueJustAnIdentityUpload)
                }
            }
            
            func itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, beforeEach: queueJustAnIdentityUpload)
                }
            }

            func itRetriesUntilTheErrorClears(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItRetriesUntilTheErrorClears.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, beforeEach: queueJustAnIdentityUpload)
                }
            }
            
            func itCausesTheUploadToFail(with error: UploadError, whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheUploadToFail.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, error: error, beforeEach: queueJustAnIdentityUpload)
                }
            }
            
            func itDoesNotMarkAnythingAsUploaded(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotMarkAnythingAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, beforeEach: queueJustAnIdentityUpload)
                }
            }
            
            func itCausesTheCurrentUploadPassToStopSendingData(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheCurrentUploadPassToStopSendingData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, newUser: false)
                }
            }
            
            func itSendsQueuedMessages(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItConsumesAllTheMessages.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, newUser: false)
                }
            }
            
            func itSendsQueuedUserProperties(whenIdentityReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksUserPropertiesAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .identify(true), response: response, newUser: false)
                }
            }

            context("uploading the identity succeeds") {
                itFinishesUploadingSuccessfully(whenIdentityReceives: .success)
                itMarksTheIdentityAsUploaded(whenIdentityReceives: .success)
                itSendsASingleIdentifyRequest(whenIdentityReceives: .success)
                itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenIdentityReceives: .success)
                
                context("there is other data to send") {
                    itSendsQueuedMessages(whenIdentityReceives: .success)
                    itSendsQueuedUserProperties(whenIdentityReceives: .success)
                }
            }
            
            context("a \"bad request\" failure occurs when uploading the identity") {
                itCausesTheUploadToFail(with: .badRequest, whenIdentityReceives: .badRequest)
                itMarksTheIdentityAsUploaded(whenIdentityReceives: .badRequest)
                itSendsASingleIdentifyRequest(whenIdentityReceives: .badRequest)
                itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenIdentityReceives: .badRequest)
                
                context("there is other data to send") {
                    itSendsQueuedMessages(whenIdentityReceives: .badRequest)
                    itSendsQueuedUserProperties(whenIdentityReceives: .badRequest)
                }
            }
            
            context("a network failure occurs when uploading the identity") {
                itCausesTheUploadToFail(with: .networkFailure, whenIdentityReceives: .networkFailure)
                itDoesNotMarkAnythingAsUploaded(whenIdentityReceives: .networkFailure)
                itRetriesUntilTheErrorClears(whenIdentityReceives: .networkFailure)

                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenIdentityReceives: .networkFailure)
                }
            }
            
            context("an unexpected failure occurs when uploading the identity") {
                itCausesTheUploadToFail(with: .unexpectedServerResponse, whenIdentityReceives: .serviceUnavailable)
                itDoesNotMarkAnythingAsUploaded(whenIdentityReceives: .serviceUnavailable)
                itRetriesUntilTheErrorClears(whenIdentityReceives: .serviceUnavailable)
                
                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenIdentityReceives: .serviceUnavailable)
                }
            }
        }
    }
}
