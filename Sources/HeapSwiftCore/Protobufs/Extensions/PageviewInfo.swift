import Foundation

extension PageviewInfo {

    init(newPageviewAt timestamp: Date) {
        self.init()
        self.id = generateRandomHeapId()
        self.time = .init(date: timestamp)
    }
}

extension URL {
    
    var pageviewUrl: PageviewInfo.Url {
        .with {
            $0.setIfNotNil(\.domain, host)
            $0.path = path
            $0.setIfNotNil(\.query, query)
            $0.setIfNotNil(\.hash, fragment)
        }
    }
}
