import Foundation
@testable import HeapSwiftCore

extension State {
    init(environmentId: String, userId: String, sessionId: String, timestamp: Date = Date()) {
        let initialPageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        self.init(
            environment: .with { $0.envID = environmentId; $0.userID = userId },
            options: [:],
            sessionInfo: .init(newSessionAt: timestamp, id: sessionId),
            unattributedPageviewInfo: initialPageviewInfo,
            lastPageviewInfo: initialPageviewInfo,
            sessionExpirationDate: timestamp
        )
    }
}
