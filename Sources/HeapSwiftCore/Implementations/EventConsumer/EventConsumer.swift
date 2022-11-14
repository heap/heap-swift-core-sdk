import Foundation

class EventConsumer<StateStore: StateStoreProtocol, DataStore: DataStoreProtocol> {
    
    let dataStore: DataStore
    let stateManager: StateManager<StateStore>
    let delegateManager = DelegateManager()

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
            dataStore.insertPendingMessage(.init(forPageviewWith: state.unattributedPageviewInfo, sourceLibrary: nil, in: state))
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
        
        if environmentId.isEmpty {
            HeapLogger.shared.logDev("Heap.startRecording was called with an invalid environment ID. Recording will not proceed.")
            return
        }
        
        let sanitizedOptions = options.sanitizedCopy()
        let results = stateManager.start(environmentId: environmentId, sanitizedOptions: sanitizedOptions, at: timestamp)
        
        if results.outcomes.currentStarted {
            HeapLogger.shared.logProd("Heap started recording with environment ID \(environmentId).")
            
            // Use the option name when logging.
            HeapLogger.shared.logDev("Heap started recording with the following options: \(Dictionary(sanitizedOptions.map({ ($0.key.name, $0.value)}), uniquingKeysWith: { a, _ in a })).")
            
        } else if results.outcomes.alreadyRecording {
            HeapLogger.shared.logDev("Heap.startRecording was called multiple times with the same parameters. The duplicate call will have no effect.")
        }
        
        handleChanges(results, timestamp: timestamp)
    }

    func stopRecording(timestamp: Date = Date()) {
        
        let results = stateManager.stop()
        
        if results.outcomes.previousStopped {
            HeapLogger.shared.logProd("Heap has stopped recording.")
        }
        
        handleChanges(results, timestamp: timestamp)
    }
    
    func logSanitizedProperties(_ functionName: String, _ keys: [String], _ values: [String])  {
        if !keys.isEmpty { HeapLogger.shared.logDev("\(functionName): The following properties were omitted because the key exceeded 512 utf-16 code units:\n\(keys)") }
        if !values.isEmpty { HeapLogger.shared.logDev("\(functionName): The following properties were truncated because the value exceeded 1024 utf-16 code units:\n\(values)") }
    }

    func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) {
        
        if event.utf16.count > 512 {
            HeapLogger.shared.logDev("Event \(event) was not logged because its name exceeds 512 UTF-16 code units")
            return
        }
        
        let (sanitizedProperties, omittedKeys, truncatedValues) = properties.sanitized()
        logSanitizedProperties("track", omittedKeys, truncatedValues)
        
        if stateManager.current == nil {
            HeapLogger.shared.logDev("Heap.track was called before Heap.startRecording and the event will not be recorded.")
            return
        }
        
        let sourceLibrary = sourceInfo?.libraryInfo
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: true, at: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        guard let state = results.current else { return }
        
        let message = Message(forPartialEventAt: timestamp, sourceLibrary: sourceLibrary, in: state)
        
        let pendingEvent = PendingEvent(partialEventMessage: message, toBeCommittedTo: dataStore)
        pendingEvent.setKind(.custom(name: event, properties: sanitizedProperties.mapValues(\.protoValue)))
        
        PageviewResolver.resolvePageviewInfo(requestedPageview: pageview, eventSourceName: sourceInfo?.name, timestamp: timestamp, delegates: delegateManager.current, state: state) {
            pendingEvent.setPageviewInfo($0)
        }
        
        HeapLogger.shared.logDev("Tracked event named \(event).")
    }
    
    func trackPageview(_ properties: PageviewProperties, timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, bridge: RuntimeBridge? = nil, userInfo: Any? = nil) -> Pageview? {
        
        guard stateManager.current != nil else {
            if let sourceName = sourceInfo?.name {
                HeapLogger.shared.logDev("Heap.trackPageview was called before Heap.startRecording and will not be recorded. It is possible that the \(sourceName) library was not properly configured.")
            } else {
                HeapLogger.shared.logDev("Heap.trackPageview was called before Heap.startRecording and will not be recorded.")
            }
            
            return nil
        }
        
        // TODO: Need to validate what truncation rules to use.
        let truncatedTitle = properties.title?.truncatedLoggingToDev(message: "trackPageview: Pageview title was truncated because the value exceeded 1024 utf-16 code units.")
        
        let (sanitizedSourceProperties, omittedKeys, truncatedValues) = properties.sourceProperties.sanitized()
        logSanitizedProperties("trackPageview", omittedKeys, truncatedValues)
        
        let sourceLibrary = sourceInfo?.libraryInfo
        var pageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        pageviewInfo.setIfNotNil(\.componentOrClassName, properties.componentOrClassName)
        pageviewInfo.setIfNotNil(\.title, truncatedTitle)
        pageviewInfo.setIfNotNil(\.url, properties.url?.pageviewUrl)
        pageviewInfo.sourceProperties = sanitizedSourceProperties.mapValues(\.protoValue)
        
        let results = stateManager.extendSessionAndSetLastPageview(pageviewInfo)
        handleChanges(results, timestamp: timestamp)
        guard let state = results.current else { return nil }
        
        let message = Message(forPageviewWith: pageviewInfo, sourceLibrary: sourceLibrary, in: state)
        
        dataStore.insertPendingMessage(message)
        if let sourceName = sourceInfo?.name {
            HeapLogger.shared.logDev("Tracked pageview from \(sourceName).")
        } else {
            HeapLogger.shared.logDev("Tracked pageview.")
        }
        HeapLogger.shared.logDebug("Committed event message:\n\(message)")
        
        return .init(sessionInfo: state.sessionInfo, pageviewInfo: pageviewInfo, sourceLibrary: sourceLibrary, bridge: bridge, properties: properties, userInfo: userInfo)
    }

    func identify(_ identity: String, timestamp: Date = Date()) {
        
        // Don't set an empty identity
        if identity.isEmpty {
            HeapLogger.shared.logDev("Heap.identify was called with an empty string and the identity will not be set.")
            return
        }
        
        // Check for an environment
        guard stateManager.current != nil else {
            HeapLogger.shared.logDev("Heap.identify was called before Heap.startRecording and will not set the identity.")
            return
        }
        
        let results = stateManager.identify(identity, at: timestamp)
        
        if results.outcomes.wasAlreadyIdentified {
            HeapLogger.shared.logDev("Heap.identify was called with the existing identity so no identity will be set.")
        } else if results.outcomes.identitySet && results.outcomes.userCreated {
            HeapLogger.shared.logDev("Heap.identify was called while already identified, so a new user was created with the new identity.")
        }
        
        if results.outcomes.identitySet {
            HeapLogger.shared.logDev("Identity set to \(identity).")
        }
        
        handleChanges(results, timestamp: timestamp)
    }

    func resetIdentity(timestamp: Date = Date()) {
        
        if stateManager.current == nil {
            HeapLogger.shared.logDev("Heap.resetIdentity was called before Heap.startRecording and will not reset the identity.")
            return
        }
        
        let results = stateManager.resetIdentity(at: timestamp)
        
        if results.outcomes.identityReset {
            HeapLogger.shared.logDev("Identity reset.")
        } else if results.outcomes.wasAlreadyUnindentified {
            HeapLogger.shared.logDev("Heap.resetIdentity was called while already unidentified, so no action will be taken.")
        }
        
        handleChanges(results, timestamp: timestamp)
    }

    func addUserProperties(_ properties: [String: HeapPropertyValue]) {
        
        let (sanitizedProperties, omittedKeys, truncatedValues) = properties.sanitized()
        logSanitizedProperties("addUserProperties", omittedKeys, truncatedValues)
        
        guard let environment = stateManager.current?.environment else {
            HeapLogger.shared.logDev("Heap.addUserProperties was called before Heap.startRecording and will not add user properties.")
            return
        }
        
        
        for (name, value) in sanitizedProperties {
            dataStore.insertOrUpdateUserProperty(
                environmentId: environment.envID,
                userId: environment.userID,
                name: name, value: value)
        }
        HeapLogger.shared.logDev("Added \(sanitizedProperties.count) user properties.")
    }

    func addEventProperties(_ properties: [String: HeapPropertyValue]) {

        let (sanitizedProperties, omittedKeys, truncatedValues) = properties.sanitized()
        logSanitizedProperties("addEventProperties", omittedKeys, truncatedValues)
        
        if stateManager.current == nil {
            HeapLogger.shared.logDev("Heap.addEventProperties was called before Heap.startRecording and will not add event properties.")
            return
        }
        
        stateManager.addEventProperties(sanitizedProperties.mapValues(\.protoValue))
        HeapLogger.shared.logDev("Added \(sanitizedProperties.count) event properties.")
    }

    func removeEventProperty(_ name: String) {
        
        if name.isEmpty {
            HeapLogger.shared.logDev("Heap.removeEventProperty was called with an invalid property name and no action will be taken.")
            return
        }
        
        if stateManager.current == nil {
            HeapLogger.shared.logDev("Heap.removeEventProperty was called before Heap.startRecording and will not remove the event property.")
            return
        }
        
        stateManager.removeEventProperty(name)
        HeapLogger.shared.logDev("Removed the event property named \(name).")
    }

    func clearEventProperties() {
        
        if stateManager.current == nil {
            HeapLogger.shared.logDev("Heap.clearEventProperties was called before Heap.startRecording and will not clear event properties.")
            return
        }
        
        stateManager.clearEventProperties()
        HeapLogger.shared.logDev("Cleared all event properties.")
    }

    var userId: String? {
        
        guard let environment = stateManager.current?.environment else {
            HeapLogger.shared.logDev("Heap.getUserId was called before Heap.startRecording and will return nil.")
            return nil
        }
        
        return environment.userID
    }

    var identity: String? {
        guard let environment = stateManager.current?.environment else {
            HeapLogger.shared.logDev("Heap.identity was called before Heap.startRecording and will return nil.")
            return nil
        }
        
        guard environment.hasIdentity else {
            return nil
        }
        
        return environment.identity
    }

    var eventProperties: [String: Value] {
        stateManager.current?.environment.properties ?? [:]
    }

    func getSessionId(timestamp: Date = Date()) -> String? {
        
        if stateManager.current == nil {
            HeapLogger.shared.logDev("Heap.getSessionId was called before Heap.startRecording and will return nil.")
            return nil
        }
        
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: false, at: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        return results.current?.sessionInfo.id
    }
    
    func addSource(_ source: Source, isDefault: Bool = false, timestamp: Date = Date()) {
        delegateManager.addSource(source, isDefault: isDefault, timestamp: timestamp, currentState: stateManager.current)
    }
    
    func removeSource(_ name: String) {
        delegateManager.removeSource(name, currentState: stateManager.current)
    }
    
    func addRuntimeBridge(_ bridge: RuntimeBridge, timestamp: Date = Date()) {
        delegateManager.addRuntimeBridge(bridge, timestamp: timestamp, currentState: stateManager.current)
    }
    
    func removeRuntimeBridge(_ bridge: RuntimeBridge) {
        delegateManager.removeRuntimeBridge(bridge, currentState: stateManager.current)
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
    
    /// Truncates a string so it fits in a utf-16 count, without splitting characters,
    /// logging a message to dev if the value changed.
    /// - Parameters:
    ///   - count: The number of code units to truncate to.
    ///   - message: The message to log if the length was exceeded.
    /// - Returns: The truncated string.
    func truncatedLoggingToDev(toUtf16Count count: Int = 1024, message: @autoclosure () -> String) -> String {
        let (result, wasTruncated) = truncated(toUtf16Count: count)
        if wasTruncated {
            HeapLogger.shared.logDev(message())
        }
        return result
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
