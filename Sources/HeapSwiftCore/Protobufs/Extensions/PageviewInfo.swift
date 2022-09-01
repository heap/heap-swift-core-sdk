import Foundation

extension PageviewInfo {

    init(newPageviewAt timestamp: Date) {
        self.init()
        self.id = generateRandomHeapId()
        self.time = .init(date: timestamp)
    }
}
