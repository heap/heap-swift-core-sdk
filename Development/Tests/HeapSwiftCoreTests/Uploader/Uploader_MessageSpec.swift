import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

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
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.createSessionIfNeeded(environmentId: "11", userId: "123", sessionId: "456", timestamp: timestamp, includePageview: true)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .addUserProperties(true),
                    .track(true),
                ]))
            }
            
            it("uploads messages if the user has already been uploaded") {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
                dataStore.createSessionIfNeeded(environmentId: "11", userId: "123", sessionId: "456", timestamp: timestamp, includePageview: true)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    .track(true),
                ]))
            }
            
            func createSession(userId: String, sessionId: String, includePageview: Bool = false, includeEvent: Bool = false) {
                let timestamp = Date()
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: userId, identity: nil, creationDate: timestamp)
                dataStore.setHasSentInitialUser(environmentId: "11", userId: userId)
                dataStore.createSessionIfNeeded(environmentId: "11", userId: userId, sessionId: sessionId, timestamp: timestamp, includePageview: includePageview, includeEvent: includeEvent)
            }
            
            it("uploads the correct data") {
                createSession(userId: "123", sessionId: "456", includePageview: true)
                expectUploadAll(in: uploader).toEventually(beSuccess())
                
                guard let messages = APIProtocol.trackPayloads.first?.events
                else { throw TestFailure("Could not get the first message batch") }
                
                expect(messages.map(\.kind)).to(equal([
                    .session(.init()),
                    .pageview(.init()),
                ]), description: "Expected a session and a pageview")
            }
            
            context("multiple users with messages are present") {
                
                beforeEach {
                    createSession(userId: "345", sessionId: "678")
                    createSession(userId: "234", sessionId: "567")
                    createSession(userId: "123", sessionId: "456")
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                }
                
                it("uploads all the messages") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .track(true),
                        .track(true),
                        .track(true),
                    ]), description: "Each session should have had a payload")
                    
                    expect(APIProtocol.trackPayloads.map(\.events.first?.userID)).to(contain("123", "234", "345"), description: "Each user Id should have been uploaded.")
                    expect(APIProtocol.trackPayloads.map(\.events.first?.sessionInfo.id)).to(contain("456", "567", "678"), description: "Each session Id should have been uploaded.")
                }
                
                it("uploads the active user's messages first") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .track(true),
                        .track(true),
                        .track(true),
                    ]), description: "Each session should have had a payload")
                    
                    expect(APIProtocol.trackPayloads.first?.events.first?.userID).to(equal("123"), description: "The first user should have been the active user")
                    expect(APIProtocol.trackPayloads.first?.events.first?.sessionInfo.id).to(equal("456"), description: "The first user should have been the active user")
                }
            }
            
            context("multiple sessions with messages are present on the active user") {
                
                beforeEach {
                    createSession(userId: "123", sessionId: "678")
                    createSession(userId: "123", sessionId: "567")
                    createSession(userId: "123", sessionId: "456")
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                }
                
                it("uploads all the messages") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .track(true),
                        .track(true),
                        .track(true),
                    ]), description: "Each session should have had a payload")
                    
                    expect(APIProtocol.trackPayloads.map(\.events.first?.sessionInfo.id)).to(contain("456", "567", "678"), description: "Each session Id should have been uploaded.")
                }
                
                it("uploads the active sessions's messages first") {
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .track(true),
                        .track(true),
                        .track(true),
                    ]), description: "Each session should have had a payload")
                    
                    expect(APIProtocol.trackPayloads.first?.events.first?.sessionInfo.id).to(equal("456"), description: "The first session should have been the active session")
                }
            }
            
            context("the messages in queue exceed the byte count limit") {
                
                beforeEach {
                    createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
                    
                    // All payloads will be more than a byte
                    expectUploadAll(in: uploader, with: [.messageBatchByteLimit: 1]).toEventually(beSuccess())
                }
                
                it("splits the messages into multiple batches") {
                    expect(APIProtocol.requests.map(\.simplified).count).to(beGreaterThan(1), description: "The session should have been split")
                }
                
                it("sends all the messages") {
                    expect(APIProtocol.trackPayloads.flatMap(\.events).map(\.kind)).to(equal([
                        .session(.init()),
                        .pageview(.init()),
                        .event(Event.with({ $0.custom = .init(name: "my-event", properties: [:]) })),
                    ]), description: "Expected a session, a pageview, and an event")
                }
                
                it("sends a single message in batches where the first message exceeds the byte count") {
                    expect(APIProtocol.trackPayloads.map(\.events.count)).to(equal([1, 1, 1]), description: "Each batch should have had one element since all exceed the byte count")
                }
            }
            
            context("the messages in queue exceed the message count limit") {
                
                beforeEach {
                    createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)

                    // All payloads will be more than a byte
                    expectUploadAll(in: uploader, with: [.messageBatchMessageLimit: 2]).toEventually(beSuccess())
                }
                
                it("splits the messages into multiple batches") {
                    expect(APIProtocol.requests.map(\.simplified).count).to(beGreaterThan(1), description: "The session should have been split")
                }
                
                it("sends all the messages") {
                    expect(APIProtocol.trackPayloads.flatMap(\.events).map(\.kind)).to(equal([
                        .session(.init()),
                        .pageview(.init()),
                        .event(Event.with({ $0.custom = .init(name: "my-event", properties: [:]) })),
                    ]), description: "Expected a session, a pageview, and an event")
                }
                
                it("splits batches to no more than the limit") {
                    expect(APIProtocol.trackPayloads.map(\.events)).to(allPass({ $0.count <= 2 }), description: "Each batch should have had no more than two elements")
                }
                
                it("splits batches to no more than the limit") {
                    expect(APIProtocol.trackPayloads.map(\.events.count)).to(equal([2, 1]), description: "The first batch should have the limit")
                }
            }
            
            // MARK: - Different network responses
            
            func queueJustAMessageUpload() {
                createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
            }
            
            func itFinishesUploadingSuccessfully(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItFinishesUploadingSuccessfully.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, beforeEach: queueJustAMessageUpload)
                }
            }
            
            func itConsumesAllTheMessages(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItConsumesAllTheMessages.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, newUser: false)
                }
            }
            
            func itSendsASingleTrackRequest(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItSendsASingleRequestOfKind.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, beforeEach: queueJustAMessageUpload)
                }
            }
            
            func itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheSessionIsActive isActive: Bool, andTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response) {
                        createSession(userId: "123", sessionId: isActive ? "456" : "567", includePageview: true, includeEvent: true)
                    }
                }
            }
            
            func itRetriesUntilTheErrorClears(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItRetriesUntilTheErrorClears.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, beforeEach: queueJustAMessageUpload)
                }
            }
            
            func itCausesTheUploadToFail(with error: UploadError, whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheUploadToFail.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, error: error, beforeEach: queueJustAMessageUpload)
                }
            }
            
            func itDoesNotMarkAnythingAsUploaded(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItDoesNotMarkAnythingAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, beforeEach: queueJustAMessageUpload)
                }
            }
            
            func itCausesTheCurrentUploadPassToStopSendingData(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItCausesTheCurrentUploadPassToStopSendingData.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, newUser: false)
                }
            }
            
            func itSendsQueuedMessages(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItConsumesAllTheMessages.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, newUser: false)
                }
            }
            
            func itSendsQueuedIdentity(whenTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                itBehavesLike(ItMarksTheIdentityAsUploaded.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, newUser: false)
                }
            }
            
            func itDeletesTheSessionAfterTheInitialUpload(whenTheSessionIsActive isActive: Bool, andTrackReceives response: APIResponse, file: FileString = #file, line: UInt = #line) {
                let sessionId = isActive ? "456" : "567"
                itBehavesLike(ItDeletesTheSessionAfterUploading.self, file: file, line: line) {
                    .init(uploader: uploader, request: .track(true), response: response, sessionId: sessionId) {
                        createSession(userId: "123", sessionId: sessionId, includePageview: true, includeEvent: true)
                    }
                }
            }
            
            context("uploading the messages succeeds") {
                
                itFinishesUploadingSuccessfully(whenTrackReceives: .success)
                itConsumesAllTheMessages(whenTrackReceives: .success)
                itSendsASingleTrackRequest(whenTrackReceives: .success) // Technically, it can, but this payload fits in one batch.
                itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheSessionIsActive: true, andTrackReceives: .success)
                
                it("does not prevent future messages from being sent in the same session") {
                    createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                    
                    // The session won't be inserted again, but the other events will be.
                    createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .track(true),
                        .track(true),
                    ]))
                }
            }
            
            context("a \"bad request\" failure occurs when uploading the messages") {
                
                itCausesTheUploadToFail(with: .badRequest, whenTrackReceives: .badRequest)
                
                context("the session is the active session") {
                    itDoesNotMarkAnythingAsUploaded(whenTrackReceives: .badRequest)
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheSessionIsActive: true, andTrackReceives: .badRequest)
                }
                
                context("the session is not active") {
                    itDeletesTheSessionAfterTheInitialUpload(whenTheSessionIsActive: false, andTrackReceives: .badRequest)
                    itDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData(whenTheSessionIsActive: false, andTrackReceives: .badRequest)
                }
                
                it("prevents future messages from being sent in the same session") {
                    APIProtocol.trackResponse = .badRequest
                    createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
                    expectUploadAll(in: uploader).toEventually(beFailure())
                    
                    // The session won't be inserted again, but the other events will be.
                    createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
                    expectUploadAll(in: uploader).toEventually(beSuccess())
                    
                    expect(APIProtocol.requests.map(\.simplified)).to(equal([
                        .track(true),
                    ]))
                }
                
                context("there is other data to send") {
                    
                    it("does not prevent different sessions from sending messages in the same pass") {
                        APIProtocol.trackResponse = .badRequest
                        createSession(userId: "123", sessionId: "456", includePageview: true, includeEvent: true)
                        createSession(userId: "123", sessionId: "567", includePageview: true, includeEvent: true)
                        createSession(userId: "123", sessionId: "678", includePageview: true, includeEvent: true)
                        expectUploadAll(in: uploader).toEventually(beFailure())
                        expect(APIProtocol.requests.map(\.simplified)).to(equal([
                            .track(true),
                            .track(true),
                            .track(true),
                        ]), description: "Each session should send despite the previous being rejected")
                    }
                }
            }
            
            context("a network failure occurs when uploading the messages") {
                itCausesTheUploadToFail(with: .networkFailure, whenTrackReceives: .networkFailure)
                itDoesNotMarkAnythingAsUploaded(whenTrackReceives: .networkFailure)
                itRetriesUntilTheErrorClears(whenTrackReceives: .networkFailure)
                
                context("there is other data to send") {
                    
                    beforeEach {
                        dataStore.createNewUserIfNeeded(environmentId: "11", userId: "999", identity: nil, creationDate: Date())
                    }
                    
                    itCausesTheCurrentUploadPassToStopSendingData(whenTrackReceives: .networkFailure)
                }
            }
            
            context("an unexpected failure occurs when uploading the messages") {
                itCausesTheUploadToFail(with: .unexpectedServerResponse, whenTrackReceives: .serviceUnavailable)
                itDoesNotMarkAnythingAsUploaded(whenTrackReceives: .serviceUnavailable)
                itRetriesUntilTheErrorClears(whenTrackReceives: .serviceUnavailable)
                
                context("there is other data to send") {
                    
                    beforeEach {
                        dataStore.createNewUserIfNeeded(environmentId: "11", userId: "999", identity: nil, creationDate: Date())
                    }
                    
                    itCausesTheCurrentUploadPassToStopSendingData(whenTrackReceives: .serviceUnavailable)
                }
            }
        }
    }
}
