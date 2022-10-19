import Foundation

class EventConsumer<StateStore: StateStoreProtocol, DataStore: DataStoreProtocol> {
    
    let dataStore: DataStore
    let stateManager: StateManager<StateStore>

    init(stateStore: StateStore, dataStore: DataStore) {
        self.dataStore = dataStore
        self.stateManager = StateManager(stateStore: stateStore)
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
            dataStore.createSessionIfNeeded(with: .init(forSessionIn: state))
            dataStore.insertPendingMessage(.init(forPageviewWith: state.lastPageviewInfo, in: state))
        }

        if updateResults.outcomes.currentStarted {
            dataStore.pruneOldData(
                activeEnvironmentId: environment.envID,
                activeUserId: environment.userID,
                activeSessionId: sessionInfo.id,
                minLastMessageDate: timestamp.addingTimeInterval(-86_400 * 6),
                minUserCreationDate: timestamp.addingTimeInterval(-86_400 * 6)
            )
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
    
    // TODO: Move this, refactor
    func logSanitizedProperties(_ functionName: String, _ keys: [String], _ values: [String])  {
        if !keys.isEmpty { print("\(functionName): The following properties were omitted because the key exceeded 512 utf-16 code units:\n\(keys)") }
        if !values.isEmpty { print("\(functionName): The following properties were truncated because the value exceeded 1024 utf-16 code units:\n\(values)") }
    }

    func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil) {
        
        if event.utf16.count > 1024 {
            // TODO: Update per Logging Spec
            print("Error: Event name too long, exceeds 1024 UTF-16 code units.")
            return
        }
        let (sanitizedProperties, omittedKeys, truncatedValues) = properties.sanitized()
        logSanitizedProperties("track", omittedKeys, truncatedValues)
        
        let sourceLibrary = sourceInfo?.libraryInfo
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: true, at: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        guard let state = results.current else { return }
        
        let message = Message(forPartialEventAt: timestamp, sourceLibrary: sourceLibrary, in: state)
        
        let pendingEvent = PendingEvent(partialEventMessage: message, toBeCommittedTo: dataStore)
        pendingEvent.setKind(.custom(name: event, properties: sanitizedProperties.mapValues(\.protoValue)))
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
        
        let (sanitizedProperties, omittedKeys, truncatedValues) = properties.sanitized()
        logSanitizedProperties("addUserProperties", omittedKeys, truncatedValues)
        
        guard let environment = stateManager.current?.environment else { return }
        
        
        for (name, value) in sanitizedProperties {
            dataStore.insertOrUpdateUserProperty(
                environmentId: environment.envID,
                userId: environment.userID,
                name: name, value: value)
        }
    }

    func addEventProperties(_ properties: [String: HeapPropertyValue]) {

        let (sanitizedProperties, omittedKeys, truncatedValues) = properties.sanitized()
        logSanitizedProperties("addEventProperties", omittedKeys, truncatedValues)
        
        stateManager.addEventProperties(sanitizedProperties.mapValues(\.protoValue))
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

extension Dictionary where Key == String, Value == HeapPropertyValue {
    
    /// Sanitizes property dictionary given API constraints.
    /// Omits keys that exceed a 512 utf-16 count.
    /// Truncates values that exceed 1024 utf-16 count.
    /// - Returns: Sanitized Dictionary.
    func sanitized() -> (result: [String: String], sanitizedKeys: [String], sanitizedValues: [String])  {
        
        var sanitizedKeys: [String] = []
        var sanitizedValues: [String] = []
        let sanitizedDictionary = mapValues({
            let (value, wasTruncated) = $0.heapValue.truncated()
            if wasTruncated {
                sanitizedValues.append(value)
            }
            return value
        })
            .filter({
                if ($0.key.utf16.count <= 512) {
                    return true
                } else {
                    sanitizedKeys.append($0.key)
                    return false
                }
            })

        return (sanitizedDictionary, sanitizedKeys, sanitizedValues)
    }
}

extension String {
    
    /// Truncates a string so it fits in a utf-16 count, without splitting characters.
    /// - Parameter count: The number of code units to truncate to.
    /// - Returns: The truncated string.
    func truncated(toUtf16Count count: Int = 1024) -> (result: String, wasTruncated: Bool) {
        if (utf16.count <= count) { return (self, false) }
        
        // This is pretty complicated because it deals with changes in the Swift runtime behavior
        // but it is significantly faster than iterating over indices until we find the right one.
        let exactTruncationIndex = String.Index(utf16Offset: count + 1, in: self)
        let minEndIndex = self.index(before: exactTruncationIndex)
        
        if String.indexBeforeSkipsSeeksBeyondCurrentCharacter {
            let maxEndIndex = self.index(after: minEndIndex)
            let endIndex = maxEndIndex.utf16Offset(in: self) <= count ? maxEndIndex : minEndIndex
            return (String(self[..<endIndex]), true)
        } else {
            return (String(self[..<minEndIndex]), true)
        }
    }
    
    /// Determines if the runtime will skip beyond the current character if the truncation index is
    /// in the middle of a character.
    ///
    /// Prior to iOS 16, `index(before:)` would stop at the start of the current character when in
    /// the middle, but it also had a bug where `index(after: index(before:))` would return you to
    /// the originally passed in index rather than the true next character.
    static let indexBeforeSkipsSeeksBeyondCurrentCharacter: Bool = {
        let testString = "👨‍👨‍👧‍👧👨‍👨‍👧‍👧"
        return testString.index(before: .init(utf16Offset: 16, in: testString)) == testString.startIndex
    }()
}
