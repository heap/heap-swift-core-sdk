import Foundation
@testable import HeapSwiftCore

extension State {
    init(environmentId: String, userId: String, sessionId: String, timestamp: Date = Date()) {
        self.init(
            environment: .with { $0.envID = environmentId; $0.userID = userId },
            options: [:],
            sessionInfo: .init(newSessionAt: timestamp, id: sessionId),
            lastPageviewInfo: .init(newPageviewAt: timestamp),
            sessionExpirationDate: timestamp
        )
    }
}
