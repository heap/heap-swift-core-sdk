import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

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
            
            func createSingleUserPropertyRequest(userId: String, propertyName: String, value: String) {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: userId, identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: userId)
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: userId, name: propertyName, value: value)
            }
            
            it("uploads user properties after uploading the new user") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop", value: "val")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                    .addUserProperties(true),
                ]))
            }
            
            it("uploads user properties if the user has already been uploaded") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop", value: "val")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                ]))
            }
            
            it("uploads the correct properties") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop1", value: "val1")
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop2", value: "val2")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                guard let userProperties = APIProtocol.addUserPropertyPayloads.first
                else { throw TestFailure("Could not get first user properties") }
                
                expect(userProperties.envID).to(equal("11"))
                expect(userProperties.userID).to(equal("123"))
                expect(userProperties.properties).to(equal([
                    "prop1": .init(value: "val1"),
                    "prop2": .init(value: "val2"),
                ]))
                expect(userProperties.library).to(equal(SDKInfo.withoutAdvertiserId.libraryInfo))
            }
            
            it("uploads properties each time they are changed") {
                
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop1", value: "val1")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop2", value: "val2")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop2", value: "val3")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                // No change
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop2", value: "val3")
                expectUploadAll(in: uploader).toEventually(beSuccess())

                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                    .addUserProperties(true),
                    .addUserProperties(true),
                ]), description: "Three user properties should have been uploaded")
                
                expect(APIProtocol.addUserPropertyPayloads.map(\.properties)).to(equal([
                    ["prop1": .init(value: "val1")],
                    ["prop2": .init(value: "val2")],
                    ["prop2": .init(value: "val3")],
                ]), description: "The correct properties should have been uploaded each time")
            }
            
            it("sets query properties and header") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop1", value: "val1")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                expect(APIProtocol.requests).to(haveCount(1), description: "PRECONDITION: There should only be one request")

                expect(APIProtocol.requests.first?.rawRequest).to(haveMetadata(environmentId: "11", userId: "123", identity: nil, library: SDKInfo.withoutAdvertiserId.libraryInfo.name))
            }
            
            it("sets query properties and header when identity is set") {
                
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                dataStore.setHasSentIdentity(environmentId: "11", userId: "123")
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop1", value: "val1")
                expectUploadAll(in: uploader).toEventually(beSuccess())
                expect(APIProtocol.requests).to(haveCount(1), description: "PRECONDITION: There should only be one request")
                
                expect(APIProtocol.requests.first?.rawRequest).to(haveMetadata(environmentId: "11", userId: "123", identity: "user-1", library: SDKInfo.withoutAdvertiserId.libraryInfo.name))
            }

            context("multiple users with user properties are present") {
                
                beforeEach {
                    createSingleUserPropertyRequest(userId: "345", propertyName: "prop3", value: "value3")
                    createSingleUserPropertyRequest(userId: "234", propertyName: "prop2", value: "value2")
                    createSingleUserPropertyRequest(userId: "123", propertyName: "prop1", value: "value1")
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                }
                
                it("uploads all the user properties") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "Three user properties should have been uploaded")
                    
                    expect(APIProtocol.addUserPropertyPayloads.map(\.userID)).to(contain("123", "234", "345"), description: "Each user Id should have been uploaded.")
                    expect(APIProtocol.addUserPropertyPayloads.map(\.properties)).to(contain(
                        ["prop1": .init(value: "value1")],
                        ["prop2": .init(value: "value2")],
                        ["prop3": .init(value: "value3")]
                    ), description: "Each property set should have been uploaded.")

                }
                
                it("uploads the active user properties first") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .addUserProperties(true),
                        .addUserProperties(true),
                        .addUserProperties(true),
                    ]), description: "Three user properties should have been uploaded")
                    
                    expect(APIProtocol.addUserPropertyPayloads.first?.userID).to(equal("123"), description: "The first user should have been the active user")
                    expect(APIProtocol.addUserPropertyPayloads.first?.properties).to(equal(["prop1": .init(value: "value1")]), description: "The first user should have been the active user")
                }
            }
            
            // MARK: - Different network responses
            
            func queueJustAUserPropertyUpload() {
                createSingleUserPropertyRequest(userId: "123", propertyName: "name", value: "value")
            }
            
            func itFinishesUploadingSuccessfully(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItFinishesUploadingSuccessfully.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustAUserPropertyUpload)
                }
            }
            
            func itMarksTheUserPropertiesAsUploaded(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksUserPropertiesAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: false)
                }
            }
            
            func itSendsASingleAddUserPropertiesRequest(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItSendsASingleRequestOfKind.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustAUserPropertyUpload)
                }
            }
            
            func itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustAUserPropertyUpload)
                }
            }
            
            func itRetriesUntilTheErrorClears(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItRetriesUntilTheErrorClears.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustAUserPropertyUpload)
                }
            }
            
            func itCausesTheUploadToFail(with error: UploadError, whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheUploadToFail.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, error: error, beforeEach: queueJustAUserPropertyUpload)
                }
            }
            
            func itDoesNotMarkAnythingAsUploaded(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotMarkAnythingAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, beforeEach: queueJustAUserPropertyUpload)
                }
            }
            
            func itCausesTheCurrentUploadPassToStopSendingData(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheCurrentUploadPassToStopSendingData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: false)
                }
            }
            
            func itSendsQueuedMessages(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItConsumesAllTheMessages.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: false)
                }
            }
            
            func itSendsQueuedIdentity(whenAddUserPropertiesReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheIdentityAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .addUserProperties(true), response: response, newUser: false)
                }
            }
            
            context("uploading the user properties succeeds") {
                itFinishesUploadingSuccessfully(whenAddUserPropertiesReceives: .success)
                itMarksTheUserPropertiesAsUploaded(whenAddUserPropertiesReceives: .success)
                itSendsASingleAddUserPropertiesRequest(whenAddUserPropertiesReceives: .success)
                itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenAddUserPropertiesReceives: .success)
                
                context("there is other data to send") {
                    itSendsQueuedMessages(whenAddUserPropertiesReceives: .success)
                    itSendsQueuedIdentity(whenAddUserPropertiesReceives: .success)
                }
            }
            
            context("a \"bad request\" failure occurs when uploading user properties") {
                itCausesTheUploadToFail(with: .badRequest, whenAddUserPropertiesReceives: .badRequest)
                itMarksTheUserPropertiesAsUploaded(whenAddUserPropertiesReceives: .badRequest)
                itSendsASingleAddUserPropertiesRequest(whenAddUserPropertiesReceives: .badRequest)
                itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenAddUserPropertiesReceives: .badRequest)
                
                context("there is other data to send") {
                    itSendsQueuedMessages(whenAddUserPropertiesReceives: .badRequest)
                    itSendsQueuedIdentity(whenAddUserPropertiesReceives: .badRequest)
                }
            }
            
            context("a network failure occurs when uploading user properties") {
                itCausesTheUploadToFail(with: .networkFailure, whenAddUserPropertiesReceives: .networkFailure)
                itDoesNotMarkAnythingAsUploaded(whenAddUserPropertiesReceives: .networkFailure)
                itRetriesUntilTheErrorClears(whenAddUserPropertiesReceives: .networkFailure)

                context("there is other data to send") {
                    itCausesTheCurrentUploadPassToStopSendingData(whenAddUserPropertiesReceives: .networkFailure)
                }
            }
            
            context("an unexpected failure occurs when uploading user properties") {
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
