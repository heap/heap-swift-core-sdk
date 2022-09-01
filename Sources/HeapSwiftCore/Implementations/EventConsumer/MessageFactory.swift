import Foundation

struct MessageFactory {

    let applicationInfo = ApplicationInfo.current
    let deviceInfo = DeviceInfo.current(includeCarrier: true)
    let libraryInfo: LibraryInfo

    init() {
        libraryInfo = LibraryInfo.baseInfo(with: deviceInfo)
    }

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
    
    func pendingEvent<DataStore: DataStoreProtocol>(timestamp: Date, sourceLibrary: LibraryInfo?, in state: State, toBeCommittedTo dataStore: DataStore) -> PendingEvent {
        
        var message = baseMessage(from: state)
        message.id = generateRandomHeapId()
        message.time = .init(date: timestamp)
        if let sourceLibrary = sourceLibrary {
            message.sourceLibrary = sourceLibrary
        }
        message.kind = .event(.init())
        
        let pendingEvent = PendingEvent(partialEventMessage: message, dataStore: dataStore)
        
        if Thread.isMainThread {
            pendingEvent.setAppVisibilityState(.current)
        } else {
            DispatchQueue.main.async {
                pendingEvent.setAppVisibilityState(.current)
            }
        }
        
        return pendingEvent
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
