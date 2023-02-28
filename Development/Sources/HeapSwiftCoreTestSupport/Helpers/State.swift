import Foundation
@testable import HeapSwiftCore

extension SDKInfo {
    static let withoutAdvertiserId = SDKInfo.current(with: [:])
    static let withAdvertiserId = SDKInfo.current(with: [ .captureAdvertiserId: true ])
}

extension State {
    init(environmentId: String, userId: String, sessionId: String, timestamp: Date = Date()) {
        let initialPageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        self.init(
            options: [:],
            sdkInfo: .withoutAdvertiserId,
            environment: .with { $0.envID = environmentId; $0.userID = userId },
            sessionInfo: .init(newSessionAt: timestamp, id: sessionId),
            unattributedPageviewInfo: initialPageviewInfo,
            lastPageviewInfo: initialPageviewInfo,
            sessionExpirationDate: timestamp
        )
    }
}
