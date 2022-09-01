import Foundation
@testable import HeapSwiftCore

extension EventConsumer {

    func assertSessionWasExtended(from date: Date, file: StaticString = #file, line: UInt = #line) throws {
        
        guard let sessionExpirationTime = self.sessionExpirationTime else {
            throw TestFailure("Session expiration time not set", file: file, line: line)
        }

        let expectedExpiration = date.addingTimeInterval(300)

        let delta = abs(expectedExpiration.timeIntervalSince(sessionExpirationTime))

        // Allow a second of error becaue we're dealing with floating points.
        if delta > 1 {
            throw TestFailure("Expected session to be extended 300 seconds after \(date) but it is at \(sessionExpirationTime.timeIntervalSince(date)) seconds", file: file, line: line)
        }
    }
}
