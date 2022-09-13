import Foundation

extension SessionInfo {

    init(newSessionAt timestamp: Date, id: String = generateRandomHeapId()) {
        self.init()
        self.id = id
        self.time = .init(date: timestamp)
    }
}
