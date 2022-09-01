import XCTest
@testable import HeapSwiftCore

final class HeapSwiftCoreTests: XCTestCase {
    
    func testLogDeviceInfo() throws {
        // Not a real test, just outputs device info.
        print(DeviceInfo.current)
    }
}
