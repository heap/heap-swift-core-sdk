import Foundation

struct MessageFactory {

    let applicationInfo = ApplicationInfo.current
    let deviceInfo = DeviceInfo.current(includeCarrier: true)
    let libraryInfo = LibraryInfo() // TODO

    func sessionMessage(for state: State) -> Message {
        var message = baseMessage(from: state)
        message.id = state.sessionInfo.id
        message.time = state.sessionInfo.time
        message.kind = .session(.init())
        return message
    }

    func pageviewMessage(for pageviewInfo: PageviewInfo, in state: State) -> Message {
        var message = baseMessage(from: state)
        message.id = pageviewInfo.id
        message.time = pageviewInfo.time
        message.pageviewInfo = pageviewInfo
        message.kind = .pageview(.init())
        return message
    }
    
    func customEventMessage(name: String, sanitizedProperties: [String: Value], timestamp: Date, pageviewInfo: PageviewInfo, sourceLibrary: LibraryInfo?, in state: State) -> Message {
        
        var custom = Event.Custom()
        custom.name = name
        custom.properties = sanitizedProperties
        
        var event = Event()
        event.kind = .custom(custom)
        event.appVisibilityState = .unknown // TODO
        
        var message = baseMessage(from: state)
        message.id = generateRandomHeapId()
        message.time = .init(date: timestamp)
        message.pageviewInfo = pageviewInfo
        if let sourceLibrary = sourceLibrary {
            message.sourceLibrary = sourceLibrary
        }
        message.kind = .event(event)
        
        return message
    }

    private func baseMessage(from state: State) -> Message {
        var message = Message()
        
        message.envID = state.environment.envID
        message.userID = state.environment.userID
        
        message.baseLibrary = libraryInfo
        message.application = applicationInfo
        message.device = deviceInfo

        message.sessionInfo = state.sessionInfo

        message.properties = state.environment.properties
        
        return message
    }
}
