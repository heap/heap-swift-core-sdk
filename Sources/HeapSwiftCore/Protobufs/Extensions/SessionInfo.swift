import Foundation

extension SessionInfo {

    init(newSessionAt timestamp: Date) {
        self.init()
        self.id = generateRandomHeapId()
        self.time = .init(date: timestamp)
    }
}
