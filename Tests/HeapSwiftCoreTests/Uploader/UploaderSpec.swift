import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

class TestActiveSessionProvider: ActiveSessionProvider {
    
    var environmentId: String = "11"
    var userId: String = "123"
    var sessionId: String = "456"
    
    var activeSession: ActiveSession? {
        .init(environmentId: environmentId, userId: userId, sessionId: sessionId)
    }
}

final class UploaderSpec: HeapSpec {
    
#if os(watchOS)
    override func setUpWithError() throws {
        throw XCTSkip("watchOS does not support URLProtocol-based tests")
    }
#endif

    override func spec() {
        describe("Uploader.uploadAll") {

            let activeSessionProvider = TestActiveSessionProvider()
            var dataStore: InMemoryDataStore!
            var uploader: Uploader<InMemoryDataStore, TestActiveSessionProvider>!

            beforeEach {
                dataStore = InMemoryDataStore()
                uploader = Uploader(dataStore: dataStore, activeSessionProvider: activeSessionProvider, urlSessionConfiguration: APIProtocol.ephemeralUrlSessionConfig)
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
            
            it("does not mark the new user as uploaded after a failed upload") {
                APIProtocol.addUserPropertiesResponse = .failWithNetworkError
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beFailure(with: UploadError.networkError))
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                expect(user.needsInitialUpload).to(beTrue(), description: "The user should still be eligible for upload")
            }
            
            it("uploads the new user again if the request failed at the network level, until it succeeds") {
                APIProtocol.addUserPropertiesResponse = .failWithNetworkError
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beFailure(with: UploadError.networkError))
                expectUploadAll(in: uploader).toEventually(beFailure(with: UploadError.networkError))

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
            
            it("does not upload identity for a user if the new user request fails") {
                APIProtocol.addUserPropertiesResponse = .failWithNetworkError
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: timestamp)
                expectUploadAll(in: uploader).toEventually(beFailure(with: UploadError.networkError))

                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                ]), description: "There should be no subsequent requests after the user upload")
            }
            
            it("does not upload properties for a user if the new user request fails") {
                APIProtocol.addUserPropertiesResponse = .failWithNetworkError
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "hello", value: "world")
                expectUploadAll(in: uploader).toEventually(beFailure(with: UploadError.networkError))

                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                ]), description: "There should be no subsequent requests after the user upload")
            }
            
            it("does not upload messages for a user if the new user request fails") {
                APIProtocol.addUserPropertiesResponse = .failWithNetworkError
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                
                // TODO: Write a helper for this.
                dataStore.createSessionIfNeeded(with: .init(forSessionIn: .init(environment: .with { $0.envID = "11"; $0.userID = "123" }, options: [:], sessionInfo: .init(newSessionAt: timestamp), lastPageviewInfo: .init(newPageviewAt: timestamp), sessionExpirationDate: timestamp)))
                
                expectUploadAll(in: uploader).toEventually(beFailure(with: UploadError.networkError))

                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                ]), description: "There should be no subsequent requests after the user upload")
            }
        }
    }
}

func expectUploadAll(file: StaticString = #file, line: UInt = #line, in upload: Uploader<InMemoryDataStore, TestActiveSessionProvider>) -> Expectation<Result<Void, UploadError>> {
    
    var result: Result<Void, UploadError>? = nil
    upload.uploadAll(activeSession: upload.activeSessionProvider.activeSession!, options: [:]) {
        result = $0
    }
    
    return expect(file: file, line: line, result)
}

public func beFailure<Success, Failure: Equatable>(with error: Failure) -> Predicate<Result<Success, Failure>> {
    beFailure(test: { expect($0).to(equal(error)) })
}
