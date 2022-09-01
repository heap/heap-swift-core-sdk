import Foundation

class EventConsumer<DataStore: DataStoreProtocol> {
    
    let dataStore: DataStore
    let stateManager: StateManager<DataStore>
    let messageFactory = MessageFactory()

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.stateManager = StateManager(dataStore: dataStore)
    }

    /// For testing, returns the last set session ID without attempting to extend the session.
    var activeOrExpiredSessionId: String? {
        return stateManager.current?.sessionInfo.id
    }

    /// For testing, returns the last set session expiration time without attempting to extend the session.
    var sessionExpirationTime: Date? {
        return stateManager.current?.sessionExpirationDate
    }
    
    /// Performs actions as a result of state changes.
    func handleChanges(_ updateResults: State.UpdateResults, timestamp: Date) {

        if updateResults.outcomes.previousStopped {
            // Nothing to do yet
        }
        
        guard let state = updateResults.current else {
            return
        }
        
        let environment = state.environment
        let sessionInfo = state.sessionInfo

        if updateResults.outcomes.currentStarted || updateResults.outcomes.userCreated {
            dataStore.createNewUserIfNeeded(
                environmentId: environment.envID,
                userId: environment.userID,
                identity: environment.hasIdentity ? environment.identity : nil,
                creationDate: sessionInfo.time.date)
        } else if updateResults.outcomes.identitySet {
            dataStore.setIdentityIfNull(environmentId: environment.envID, userId: environment.userID, identity: environment.identity)
        }

        if updateResults.outcomes.sessionCreated {
            dataStore.createSessionIfNeeded(with: messageFactory.sessionMessage(for: state))
            dataStore.insertPendingMessage(messageFactory.pageviewMessage(for: state.lastPageviewInfo, in: state))
        }

        if updateResults.outcomes.currentStarted {
            dataStore.pruneOldData(
                activeEnvironmentId: environment.envID,
                activeUserId: environment.userID,
                activeSessionId: sessionInfo.id,
                minLastMessageDate: timestamp.addingTimeInterval(-86_400 * 6),
                minUserCreationDate: timestamp.addingTimeInterval(-86_400 * 6),
                currentDate: timestamp)
        }
    }
}

extension EventConsumer: EventConsumerProtocol {
    func startRecording(_ environmentId: String, with options: [Option: Any] = [:], timestamp: Date = Date()) {
        let sanitizedOptions = options.sanitizedCopy()
        let results = stateManager.start(environmentId: environmentId, sanitizedOptions: sanitizedOptions, at: timestamp)
        handleChanges(results, timestamp: timestamp)
    }

    func stopRecording(timestamp: Date = Date()) {
        let results = stateManager.stop()
        handleChanges(results, timestamp: timestamp)
    }

    func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil) {
        let sanitizedProperties = properties.mapValues(\.protoValue)
        let sourceLibrary = sourceInfo?.libraryInfo
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: true, at: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        guard let state = results.current else { return }
        
        let pendingEvent = messageFactory.pendingEvent(timestamp: timestamp, sourceLibrary: sourceLibrary, in: state, toBeCommittedTo: dataStore)
        pendingEvent.setKind(.custom(name: event, properties: sanitizedProperties))
        pendingEvent.setPageviewInfo(state.lastPageviewInfo)
    }

    func identify(_ identity: String, timestamp: Date = Date()) {
        guard !identity.isEmpty else { return }
        let results = stateManager.identify(identity, at: timestamp)
        handleChanges(results, timestamp: timestamp)
    }

    func resetIdentity(timestamp: Date = Date()) {
        let results = stateManager.resetIdentity(at: timestamp)
        handleChanges(results, timestamp: timestamp)
    }

    func addUserProperties(_ properties: [String: HeapPropertyValue]) {
        
        let sanitizedProperties = properties.mapValues(\.heapValue)
        guard let environment = stateManager.current?.environment else { return }
        
        for (name, value) in sanitizedProperties {
            dataStore.insertOrUpdateUserProperty(
                environmentId: environment.envID,
                userId: environment.userID,
                name: name, value: value)
        }
    }

    func addEventProperties(_ properties: [String: HeapPropertyValue]) {
        let sanitizedEventProperties = properties.mapValues(\.protoValue)
        stateManager.addEventProperties(sanitizedEventProperties)
    }

    func removeEventProperty(_ name: String) {
        stateManager.removeEventProperty(name)
    }

    func clearEventProperties() {
        stateManager.clearEventProperties()
    }

    var userId: String? {
        return stateManager.current?.environment.userID
    }

    var identity: String? {
        guard let environment = stateManager.current?.environment, environment.hasIdentity else {
            return nil
        }
        
        return environment.identity
    }

    var eventProperties: [String: Value] {
        stateManager.current?.environment.properties ?? [:]
    }

    func getSessionId(timestamp: Date = Date()) -> String? {
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: false, at: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        return results.current?.sessionInfo.id
    }
}

extension EventConsumer: ActiveSessionProvider {
    var activeSession: ActiveSession? {
        guard let state = stateManager.current else { return nil }
        return .init(environmentId: state.environment.envID, userId: state.environment.userID, sessionId: state.sessionInfo.id)
    }
}
