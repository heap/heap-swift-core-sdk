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

class TestConnectivityTester: ConnectivityTesterProtocol {
    var isOnline: Bool = true
}

typealias TestableUploader = Uploader<InMemoryDataStore, TestActiveSessionProvider, TestConnectivityTester>

class UploaderSpec: HeapSpec {
    
    let activeSessionProvider = TestActiveSessionProvider()
    let connectivityTester = TestConnectivityTester()
    
    func prepareUploader(dataStore: inout InMemoryDataStore?, uploader: inout TestableUploader?) {
        dataStore = InMemoryDataStore()
        uploader = Uploader(dataStore: dataStore!, activeSessionProvider: activeSessionProvider, connectivityTester: connectivityTester, urlSessionConfiguration: APIProtocol.ephemeralUrlSessionConfig)
    }
    
#if os(watchOS)
    override func setUpWithError() throws {
        throw XCTSkip("watchOS does not support URLProtocol-based tests")
    }
#endif
}

func expectUploadAll(file: StaticString = #file, line: UInt = #line, in upload: TestableUploader) -> Expectation<Result<Void, UploadError>> {
    
    var result: Result<Void, UploadError>? = nil
    upload.uploadAll(activeSession: upload.activeSessionProvider.activeSession!, options: [:]) {
        result = $0
    }
    
    return expect(file: file, line: line, result)
}

public func beFailure<Success, Failure: Equatable>(file: StaticString = #file, line: UInt = #line, with error: Failure) -> Predicate<Result<Success, Failure>> {
    beFailure(test: { expect(file: file, line: line, $0).to(equal(error)) })
}
