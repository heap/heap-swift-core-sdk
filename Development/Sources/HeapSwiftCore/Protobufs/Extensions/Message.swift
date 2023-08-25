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
        self.properties = state.environment.properties
    }
    
    init(forPartialEventAt timestamp: Date, sourceLibrary: LibraryInfo?, in state: State) {
        self.init(baseMessageIn: state)
        
        self.id = generateRandomHeapId()
        self.time = .init(date: timestamp)
        if let sourceLibrary = sourceLibrary {
            self.sourceLibrary = sourceLibrary
        }
        self.kind = .event(.init())
        self.properties = state.environment.properties
    }
    
    init(forVersionChangeEventAt timestamp: Date, sourceLibrary: LibraryInfo?, in state: State, previousVersion: ApplicationInfo?) {
        self.init(forPartialEventAt: timestamp, sourceLibrary: sourceLibrary, in: state)
        self.pageviewInfo = state.unattributedPageviewInfo
        
        let versionChange = VersionChange.with {
            if let previousVersion = previousVersion {
                $0.previousVersion = previousVersion
            }
            $0.currentVersion = state.sdkInfo.applicationInfo
        }
        
        self.event.kind = .versionChange(versionChange)
        self.event.appVisibilityState = .current
    }
}
