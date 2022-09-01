import Foundation
@testable import HeapSwiftCore

extension Event {

    @discardableResult
    func assertIsCustomEvent(message: String? = nil, file: StaticString = #file, line: UInt = #line) throws -> Event.Custom {
        guard case let .some(.custom(custom)) = kind else {
            throw TestFailure(message ?? "Expected an custom event, got \(String(describing: kind))", file: file, line: line)
        }
        return custom
    }
}
