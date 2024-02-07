import Foundation
@testable import HeapSwiftCore

extension EventConsumer {
    
    /// For testing, returns the last set session ID without attempting to extend the session.
    var activeOrExpiredSessionId: String? {
        return stateManager.current?.sessionInfo.id
    }

    /// For testing, returns the last set session expiration date without attempting to extend the session.
    var sessionExpirationDate: Date? {
        return stateManager.current?.sessionExpirationDate
    }

    func assertSessionWasExtended(from date: Date, file: StaticString = #file, line: UInt = #line) throws {
        
        guard let sessionExpirationDate = self.sessionExpirationDate else {
            throw TestFailure("Session expiration time not set", file: file, line: line)
        }

        let expectedExpirationDate = date.addingTimeInterval(300)

        let delta = abs(expectedExpirationDate.timeIntervalSince(sessionExpirationDate))

        // Allow a second of error becaue we're dealing with floating points.
        if delta > 1 {
            throw TestFailure("Expected session to be extended 300 seconds after \(date) but it is at \(sessionExpirationDate.timeIntervalSince(date)) seconds", file: file, line: line)
        }
    }
    
    func ensureSessionExistsUsingTrack(timestamp: Date = .init()) -> (Date, String?) {
        track("START SESSION", timestamp: timestamp)
        return (timestamp, activeOrExpiredSessionId)
    }
    
    func ensureSessionExistsUsingIdentify(timestamp: Date = .init()) -> (Date, String?) {
        identify("SESSION START", timestamp: timestamp)
        return (timestamp, activeOrExpiredSessionId)
    }
}
