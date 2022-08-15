import XCTest
@testable import HeapSwiftCore

final class HeapSwiftCoreTests: XCTestCase {
    
    func testCoreInit() throws {
        XCTAssertNotNil(HeapSwiftCore())
    }
}
