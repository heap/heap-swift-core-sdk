import Foundation
@testable import HeapSwiftCore

extension SDKInfo {
    static let withoutAdvertiserId = SDKInfo.current(with: .default)
    static let withAdvertiserId = SDKInfo.current(with: .init(with: [ .captureAdvertiserId: true ]))
}

extension State {
    init(environmentId: String, userId: String, sessionId: String, timestamp: Date = Date()) {
        self.init(partialWith: .with { $0.envID = environmentId; $0.userID = userId }, sanitizedOptions: [:])
        
        let initialPageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        sessionInfo = .init(newSessionAt: timestamp, id: sessionId)
        unattributedPageviewInfo = initialPageviewInfo
        lastPageviewInfo = initialPageviewInfo
        sessionExpirationDate = timestamp.addingTimeInterval(300)
    }
}
