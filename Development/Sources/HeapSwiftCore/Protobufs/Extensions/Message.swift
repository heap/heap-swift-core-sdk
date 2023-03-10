import Foundation

extension Message {
    
    private init(baseMessageIn state: State) {
        self.init()
        
        envID = state.environment.envID
        userID = state.environment.userID
        
        baseLibrary = state.sdkInfo.libraryInfo
        application = state.sdkInfo.applicationInfo
        device = state.sdkInfo.deviceInfo
        
        sessionInfo = state.sessionInfo

        properties = state.environment.properties
    }
    
    init(forSessionIn state: State) {
        self.init(baseMessageIn: state)
        self.id = state.sessionInfo.id
        self.time = state.sessionInfo.time
        self.kind = .session(.init())
    }
    
    init(forPageviewWith pageviewInfo: PageviewInfo, sourceLibrary: LibraryInfo?, in state: State) {
        self.init(baseMessageIn: state)
        self.id = pageviewInfo.id
        self.time = pageviewInfo.time
        self.pageviewInfo = pageviewInfo
        self.setIfNotNil(\.sourceLibrary, sourceLibrary)
        self.kind = .pageview(.init())
    }
    
    init(forPartialEventAt timestamp: Date, sourceLibrary: LibraryInfo?, in state: State) {
        self.init(baseMessageIn: state)
        
        self.id = generateRandomHeapId()
        self.time = .init(date: timestamp)
        if let sourceLibrary = sourceLibrary {
            self.sourceLibrary = sourceLibrary
        }
        self.kind = .event(.init())
    }
}
