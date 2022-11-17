import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

extension UploaderSpec {
    
    class ItFinishesUploadingSuccessfully: Behavior<ItFinishesUploadingSuccessfully.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("finishes uploading successfully") {
                expectUploadAll(in: context.uploader).toEventually(beSuccess())
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let beforeEach: () -> Void
        }
    }
    
    class ItCausesTheUploadToFail: Behavior<ItCausesTheUploadToFail.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("returns that there was a failure") {
                expectUploadAll(in: context.uploader).toEventually(beFailure(with: context.error))
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let error: UploadError
            let beforeEach: () -> Void
        }
    }
    
    class ItSetsPropertyToValue<T: Equatable>: Behavior<ItSetsPropertyToValue.Context> {
        
        open class var keyPath: KeyPath<UserToUpload, T>! { nil }
        open class var label: String! { nil }
        open class var expectedValue: T? { nil }
        
        override class func spec(_ contextProvider: @escaping () -> Context) {

            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.uploader.queueWholeSession(newUser: context.newUser)
            }
            
            it(label) {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                let user = try context.uploader.dataStore.assertOnlyOneUserToUpload()
                expect(user[keyPath: keyPath]).to(equal(expectedValue), description: "\(keyPath!) should have changed")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let newUser: Bool
        }
    }
    
    public class ItMarksTheUserAsUploaded: ItSetsPropertyToValue<Bool> {
        public override class var keyPath: KeyPath<UserToUpload, Bool>! { \.needsInitialUpload }
        public override class var label: String! { "marks the user as uploaded" }
        public override class var expectedValue: Bool? { false }
    }
    
    public class ItMarksTheIdentityAsUploaded: ItSetsPropertyToValue<Bool> {
        public override class var keyPath: KeyPath<UserToUpload, Bool>! { \.needsInitialUpload }
        public override class var label: String! { "marks the identity as uploaded" }
        public override class var expectedValue: Bool? { false }
    }
    
    public class ItMarksUserPropertiesAsUploaded: ItSetsPropertyToValue<[String: String]> {
        public override class var keyPath: KeyPath<UserToUpload, [String: String]>! { \.pendingUserProperties }
        public override class var label: String! { "marks the user properties as uploaded" }
        public override class var expectedValue: [String: String]? { [:] }
    }
    
    class ItConsumesAllTheMessages: Behavior<ItConsumesAllTheMessages.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {

            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.uploader.queueWholeSession(newUser: context.newUser)
            }
            
            func messageIds() throws -> Set<String> {
                Set(try context.uploader.dataStore.usersToUpload().flatMap({ user in
                    try user.sessionIds.flatMap { sessionId in
                        try context.uploader.dataStore.getPendingMessages(for: user, sessionId: sessionId).map(\.id)
                    }
                }))
            }
            
            it("marks all the messages as uploaded") {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                expect(try messageIds()).to(beEmpty(), description: "All messages should have been uploaded")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let newUser: Bool
        }
    }
    
    class ItDoesNotMarkAnythingAsUploaded: Behavior<ItDoesNotMarkAnythingAsUploaded.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {

            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            func messageIds(for user: UserToUpload) throws -> Set<String> {
                Set(try user.sessionIds.flatMap { sessionId in
                    try context.uploader.dataStore.getPendingMessages(for: user, sessionId: sessionId).map(\.id)
                })
            }
            
            it("does not mark anything as uploaded") {
                
                let dataStore = context.uploader.dataStore
                let initialUser = try dataStore.assertOnlyOneUserToUpload()
                let initialMessages = try messageIds(for: initialUser)
                
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try messageIds(for: user)
                
                expect(user.needsInitialUpload).to(equal(initialUser.needsInitialUpload), description: "The initial upload changed")
                expect(user.needsIdentityUpload).to(equal(initialUser.needsIdentityUpload), description: "The identity changed")
                expect(user.pendingUserProperties).to(equal(initialUser.pendingUserProperties), description: "The user properties changed")
                expect(messages).to(equal(initialMessages), description: "The messages have changed")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let beforeEach: () -> Void
        }
    }
    
    class ItSendsASingleRequestOfKind: Behavior<ItSendsASingleRequestOfKind.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("send a single request of the kind") {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                expect(APIProtocol.requests.map(\.simplified).filter({ $0 == context.request })).to(haveCount(1), description: "There should have been a single attempt to upload")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let beforeEach: () -> Void
        }
    }
    
    class ItCausesTheCurrentUploadPassToStopSendingData: Behavior<ItCausesTheCurrentUploadPassToStopSendingData.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.uploader.queueWholeSession(newUser: context.newUser)
            }
            
            it("stops uploading after the request") {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                
                expect(APIProtocol.requests.map(\.simplified).last).to(equal(context.request), description: "There should not have been any requests after the failed request")
                expect(APIProtocol.requests.map(\.simplified).filter({ $0 == context.request })).to(haveCount(1), description: "There should only have been one request of the failed type")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let newUser: Bool
        }
    }
    
    class ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData: Behavior<ItDoesNotSendAnyRequestsOnSubsequentUploadPassesWithoutNewData.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("does not send any requests on subsequent uploads without new data") {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                let initialRequests = APIProtocol.requests.map(\.simplified)
                
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())

                expect(APIProtocol.requests.map(\.simplified)).to(equal(initialRequests), description: "Additional calls to `uploadAll` should not have produced additional requests")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let beforeEach: () -> Void
        }
    }
    
    class ItRetriesUntilTheErrorClears: Behavior<ItRetriesUntilTheErrorClears.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {

            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("retries until the error clears, then stops") {
                expectUploadAll(in: context.uploader).toEventually(beFailure())
                expectUploadAll(in: context.uploader).toEventually(beFailure())
                expectUploadAll(in: context.uploader).toEventually(beFailure())
                
                APIProtocol.setResponse(.success, for: context.request)
                expectUploadAll(in: context.uploader).toEventually(beSuccess())
                expectUploadAll(in: context.uploader).toEventually(beSuccess())
                expectUploadAll(in: context.uploader).toEventually(beSuccess())

                expect(APIProtocol.requests.map(\.simplified)).to(equal([
                    context.request,
                    context.request,
                    context.request,
                    context.request,
                ]), description: "There should have been three uploads that failed, followed by the one that succeeded")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let beforeEach: () -> Void
        }
    }
    
    class ItDeletesTheUserAfterUploading: Behavior<ItDeletesTheUserAfterUploading.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("returns that there was a failure") {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                expect(context.uploader.dataStore.usersToUpload()).to(haveCount(0), description: "The user should have been deleted")
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let beforeEach: () -> Void
        }
    }
    
    class ItDeletesTheSessionAfterUploading: Behavior<ItDeletesTheSessionAfterUploading.Context> {
        override class func spec(_ contextProvider: @escaping () -> Context) {
            
            var context: Context!
            
            beforeEach {
                context = contextProvider()
                APIProtocol.setResponse(context.response, for: context.request)
                context.beforeEach()
            }
            
            it("returns that there was a failure") {
                expectUploadAll(in: context.uploader).toEventuallyNot(beNil())
                
                for user in context.uploader.dataStore.usersToUpload() {
                    expect(user.sessionIds).notTo(contain(context.sessionId), description: "The sessions should have been deleted")
                }
            }
        }
        
        struct Context {
            let uploader: TestableUploader!
            let request: APIRequest.Simplified
            let response: APIResponse
            let sessionId: String
            let beforeEach: () -> Void
        }
    }
}

extension TestableUploader {
    func queueWholeSession(newUser: Bool) {
        let timestamp = Date()
        dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "user-1", creationDate: timestamp)
        if !newUser {
            dataStore.setHasSentInitialUser(environmentId: "11", userId: "123")
        }
        dataStore.insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
        dataStore.createSessionIfNeeded(environmentId: "11", userId: "123", sessionId: "456", timestamp: timestamp, includePageview: true)
        dataStore.createSessionIfNeeded(environmentId: "11", userId: "123", sessionId: "567", timestamp: timestamp, includePageview: true)
    }
}

fileprivate extension APIProtocol {
    class func setResponse(_ response: APIResponse, for request: APIRequest.Simplified) {
        switch request {
        case .identify(_):
            identifyResponse = response
        case .addUserProperties(_):
            addUserPropertiesResponse = response
        case .track(_):
            trackResponse = response
        }
    }
}
