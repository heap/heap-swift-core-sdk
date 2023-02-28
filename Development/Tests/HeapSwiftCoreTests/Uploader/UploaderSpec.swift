import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

class TestActiveSessionProvider: ActiveSessionProvider {
    
    var environmentId: String = "11"
    var userId: String = "123"
    var sessionId: String = "456"
    var sdkInfo: SDKInfo = .withoutAdvertiserId
    
    var activeSession: ActiveSession? {
        .init(environmentId: environmentId, userId: userId, sessionId: sessionId, sdkInfo: sdkInfo)
    }
}

typealias TestableUploader = Uploader<InMemoryDataStore, TestActiveSessionProvider>

class UploaderSpec: HeapSpec {
    
    let activeSessionProvider = TestActiveSessionProvider()
    
    func prepareUploader(dataStore: inout InMemoryDataStore?, uploader: inout TestableUploader?) {
        dataStore = InMemoryDataStore()
        uploader = Uploader(dataStore: dataStore!, activeSessionProvider: activeSessionProvider, urlSessionConfiguration: APIProtocol.ephemeralUrlSessionConfig)
    }
    
#if os(watchOS)
    override func setUpWithError() throws {
        throw XCTSkip("watchOS does not support URLProtocol-based tests")
    }
#endif
}

func expectUploadAll(file: StaticString = #file, line: UInt = #line, in uploader: TestableUploader, with options: [Option : Any] = [:]) -> Expectation<Result<Void, UploadError>> {
    
    var result: Result<Void, UploadError>? = nil
    uploader.uploadAll(activeSession: uploader.activeSessionProvider.activeSession!, options: options) {
        result = $0
    }
    
    return expect(file: file, line: line, result)
}

func expectPerformScheduledUpload(file: StaticString = #file, line: UInt = #line, in uploader: TestableUploader) -> Expectation<Date> {
    
    var result: Date? = nil
    uploader.performScheduledUpload {
        result = $0
    }
    
    return expect(file: file, line: line, result)
}

public func beFailure<Success, Failure: Equatable>(file: StaticString = #file, line: UInt = #line, with error: Failure) -> Predicate<Result<Success, Failure>> {
    beFailure(test: { expect(file: file, line: line, $0).to(equal(error)) })
}
