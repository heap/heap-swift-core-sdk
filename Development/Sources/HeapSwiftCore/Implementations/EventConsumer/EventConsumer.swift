import Foundation
import HeapSwiftCoreInterfaces

class EventConsumer<StateStore: StateStoreProtocol, DataStore: DataStoreProtocol> {
    
    let dataStore: DataStore
    let stateManager: StateManager<StateStore>
    let delegateManager = DelegateManager()
    let notificationManager: NotificationManager
    
    init(stateStore: StateStore, dataStore: DataStore) {
        self.dataStore = dataStore
        self.stateManager = StateManager(stateStore: stateStore)
        notificationManager = NotificationManager(delegateManager)
    }
    
    /// Performs actions as a result of state changes.
    func handleChanges(_ updateResults: State.UpdateResults, timestamp: Date) {
        
        let snapshot = delegateManager.current
        if updateResults.outcomes.previousStopped && !updateResults.outcomes.currentStarted {
            
            for (sourceName, source) in snapshot.sources {
                source.didStopRecording {
                    HeapLogger.shared.trace("Source [\(sourceName)] has completed all work related to stopRecording.")
                }
            }

            for bridge in snapshot.runtimeBridges {
                bridge.didStopRecording {
                    HeapLogger.shared.trace("Bridge of type [\(type(of: bridge))] has completed all work related to stopRecording.")
                }
            }
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
                creationDate: timestamp)
        } else if updateResults.outcomes.identitySet {
            dataStore.setIdentityIfNull(environmentId: environment.envID, userId: environment.userID, identity: environment.identity)
        }

        if updateResults.outcomes.sessionCreated {
            
            let sessionMessage = Message(forSessionIn: state)
            let pageviewMessage = Message(forPageviewWith: state.unattributedPageviewInfo, sourceLibrary: nil, in: state)
            
            HeapLogger.shared.trace("Starting new session with session event:\n\(sessionMessage)\nPageview:\n\(pageviewMessage)")

            dataStore.createSessionIfNeeded(with: sessionMessage)
            dataStore.insertPendingMessage(pageviewMessage)
        }

        if updateResults.outcomes.versionChanged {

            let message = Message(forVersionChangeEventAt: timestamp, sourceLibrary: nil, in: state, previousVersion: updateResults.outcomes.lastObservedVersion)
            dataStore.insertPendingMessage(message)
        }

        if updateResults.outcomes.currentStarted {
            
            for (sourceName, source) in snapshot.sources {
                source.didStartRecording(options: state.options) {
                    HeapLogger.shared.trace("Source [\(sourceName)] has completed all work related to startRecording.")
                }
            }
            for bridge in snapshot.runtimeBridges {
                bridge.didStartRecording(options:  state.options) {
                    HeapLogger.shared.trace("Bridge of type [\(type(of: bridge))] has completed all work related to startRecording.")
                }
            }
            
            dataStore.pruneOldData(
                activeEnvironmentId: environment.envID,
                activeUserId: environment.userID,
                activeSessionId: sessionInfo.id,
                minLastMessageDate: timestamp.addingTimeInterval(-86_400 * 6),
                minUserCreationDate: timestamp.addingTimeInterval(-86_400 * 6)
            )
        }
        
        if updateResults.outcomes.sessionCreated {
            // Switch to the main thread so we can check Event.AppVisibility.current.
            onMainThread {
                
                let sessionId = sessionInfo.id
                let foregrounded = Event.AppVisibility.current == .foregrounded
                
                for (sourceName, source) in snapshot.sources {
                    source.sessionDidStart(sessionId: sessionId, timestamp: timestamp, foregrounded: foregrounded) {
                        HeapLogger.shared.trace("Source [\(sourceName)] has completed all work related to session initialization.")
                    }
                }
                
                for bridge in snapshot.runtimeBridges {
                    bridge.sessionDidStart(sessionId: sessionId, timestamp: timestamp, foregrounded: foregrounded) {
                        HeapLogger.shared.trace("Bridge of type [\(type(of: bridge))] has completed all work related to session initialization.")
                    }
                }
            }
        }
        
        if updateResults.outcomes.currentStarted {
            // Switch to the main thread so we can check Event.AppVisibility.current.
            onMainThread {
                
                if Event.AppVisibility.current == .foregrounded {
                    
                    for (sourceName, source) in snapshot.sources {
                        source.applicationDidEnterForeground(timestamp: timestamp) {
                            HeapLogger.shared.trace("Source [\(sourceName)] has completed all work related to session initialization.")
                        }
                    }
                    
                    for bridge in snapshot.runtimeBridges {
                        bridge.applicationDidEnterForeground(timestamp: timestamp) {
                            HeapLogger.shared.trace("Bridge of type [\(type(of: bridge))] has completed all work related to session initialization.")
                        }
                    }
                }
            }
        }
        
        if updateResults.outcomes.shouldSendChangeToHeapJs {
            NotificationCenter.default.post(name: HeapStateForHeapJSChangedNotification, object: nil)
        }
    }
}

extension EventConsumer {
    
    func startRecording(_ environmentId: String, with options: [Option: Any] = [:], timestamp: Date = Date()) {
        
        if environmentId.isEmpty {
            HeapLogger.shared.warn("Heap.startRecording was called with an invalid environment ID. Recording will not proceed.")
            return
        }
        
        let sanitizedOptions = options.sanitizedCopy()
        
        let results = stateManager.start(environmentId: environmentId, sanitizedOptions: sanitizedOptions, at: timestamp)
        
        if results.outcomes.currentStarted {
            HeapLogger.shared.info("Heap started recording with environment ID \(environmentId).")
            
            // Use the option name when logging.
            HeapLogger.shared.debug("Heap started recording with the following options: \(Dictionary(sanitizedOptions.map({ ($0.key.name, $0.value)}), uniquingKeysWith: { a, _ in a })).")
            
        } else if results.outcomes.alreadyRecording {
            HeapLogger.shared.debug("Heap.startRecording was called multiple times with the same parameters. The duplicate call will have no effect.")
        }

        notificationManager.addForegroundAndBackgroundObservers()

        handleChanges(results, timestamp: timestamp)
    }

    func stopRecording(timestamp: Date = Date()) {
        
        let results = stateManager.stop()
        
        if results.outcomes.previousStopped {
            HeapLogger.shared.info("Heap has stopped recording.")
        }
        
        notificationManager.removeForegroundAndBackgroundObservers()
        
        handleChanges(results, timestamp: timestamp)
    }

    func track(_ event: String, properties: [String: HeapPropertyValue] = [:], timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) {
        
        if event.utf16.count > 512 {
            HeapLogger.shared.warn("Event \(event) was not logged because its name exceeds 512 UTF-16 code units")
            return
        }
        
        let sanitizedProperties = properties.sanitized(methodName: "track")
        
        if stateManager.current == nil {
            HeapLogger.shared.debug("Heap.track was called before Heap.startRecording and the event will not be recorded.")
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
        
        HeapLogger.shared.debug("Tracked event named \(event).")
    }
    
    func trackPageview(_ properties: PageviewProperties, timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, bridge: RuntimeBridge? = nil, userInfo: Any? = nil) -> Pageview? {
        
        guard stateManager.current != nil else {
            if let sourceName = sourceInfo?.name {
                HeapLogger.shared.debug("Heap.trackPageview was called before Heap.startRecording and will not be recorded. It is possible that the \(sourceName) library was not properly configured.")
            } else {
                HeapLogger.shared.debug("Heap.trackPageview was called before Heap.startRecording and will not be recorded.")
            }
            
            return nil
        }
        
        let truncatedTitle = properties.title?.truncatedLoggingToDev(message: "trackPageview: Pageview title was truncated because the value exceeded 1024 utf-16 code units.")
        
        let sanitizedSourceProperties = properties.sourceProperties.sanitized(methodName: "trackPageview")
        
        let sourceLibrary = sourceInfo?.libraryInfo
        var pageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        pageviewInfo.setIfNotNil(\.componentOrClassName, properties.componentOrClassName)
        pageviewInfo.setIfNotNil(\.title, truncatedTitle) // Sanitized in the state manager.
        pageviewInfo.setIfNotNil(\.url, properties.url?.pageviewUrl)
        pageviewInfo.sourceProperties = sanitizedSourceProperties.mapValues(\.protoValue)
        
        let results = stateManager.extendSessionAndSetLastPageview(&pageviewInfo)
        handleChanges(results, timestamp: timestamp)
        guard let state = results.current else { return nil }
        
        let message = Message(forPageviewWith: pageviewInfo, sourceLibrary: sourceLibrary, in: state)
        
        dataStore.insertPendingMessage(message)
        if let sourceName = sourceInfo?.name {
            HeapLogger.shared.debug("Tracked pageview from \(sourceName) on \(properties.componentOrClassName ?? "an unknown component") titled \"\(properties.title ?? "")\".")
        } else {
            HeapLogger.shared.debug("Tracked pageview on \(properties.componentOrClassName ?? "an unknown component") titled \"\(properties.title ?? "")\".")
        }
        HeapLogger.shared.trace("Committed event message:\n\(message)")
        
        return ConcretePageview(sessionInfo: state.sessionInfo, pageviewInfo: pageviewInfo, sourceLibrary: sourceLibrary, bridge: bridge, properties: properties, userInfo: userInfo)
    }
    
    func uncommittedInteractionEvent(timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) -> InteractionEventProtocol? {

        guard stateManager.current != nil else {
            if let sourceName = sourceInfo?.name {
                HeapLogger.shared.debug("Heap.uncommitedInteractionEvent was called before Heap.startRecording and the event will not be recorded. It is possible that the \(sourceName) library was not properly configured.")
            } else {
                HeapLogger.shared.debug("Heap.uncommitedInteractionEvent was called before Heap.startRecording and the event will not be recorded.")
            }
            return nil
        }
        
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: true, at: timestamp)
 
        handleChanges(results, timestamp: timestamp)
        
        guard let state = results.current else { return nil }
        let sourceLibrary = sourceInfo?.libraryInfo

        let message = Message(forPartialEventAt: timestamp, sourceLibrary: sourceLibrary, in: state)
        let pendingEvent = PendingEvent(partialEventMessage: message, toBeCommittedTo: dataStore)
        
        let interactionEvent = InteractionEvent(pendingEvent: pendingEvent, fieldSettings: state.fieldSettings)

        PageviewResolver.resolvePageviewInfo(requestedPageview: pageview, eventSourceName: sourceInfo?.name, timestamp: timestamp, delegates: delegateManager.current, state: state) {
            pendingEvent.setPageviewInfo($0)
        }
        
        return interactionEvent
    }
    
    func trackInteraction(interaction: Interaction, nodes: [InteractionNode], callbackName: String? = nil, timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, pageview: Pageview? = nil) {
        trackInteraction(interaction: interaction, nodes: nodes, callbackName: callbackName, timestamp: timestamp, sourceInfo: sourceInfo, sourceProperties: [:], pageview: pageview)
    }
    
    func trackInteraction(interaction: Interaction, nodes: [InteractionNode], callbackName: String? = nil, timestamp: Date = Date(), sourceInfo: SourceInfo? = nil, sourceProperties: [String: HeapPropertyValue] = [:], pageview: Pageview? = nil) {
        guard let event = uncommittedInteractionEvent(timestamp: timestamp, sourceInfo: sourceInfo, pageview: pageview) else { return }

        event.kind = interaction
        event.nodes = nodes
        event.callbackName = callbackName
        event.sourceProperties = sourceProperties
        
        event.commit()
    }

    func identify(_ identity: String, timestamp: Date = Date()) {
        
        // Don't set an empty identity
        if identity.isEmpty {
            HeapLogger.shared.debug("Heap.identify was called with an empty string and the identity will not be set.")
            return
        }
        
        // Check for an environment
        guard stateManager.current != nil else {
            HeapLogger.shared.debug("Heap.identify was called before Heap.startRecording and will not set the identity.")
            return
        }
        
        let results = stateManager.identify(identity, at: timestamp)
        
        if results.outcomes.wasAlreadyIdentified {
            HeapLogger.shared.debug("Heap.identify was called with the existing identity so no identity will be set.")
        } else if results.outcomes.identitySet && results.outcomes.userCreated {
            HeapLogger.shared.debug("Heap.identify was called while already identified, so a new user was created with the new identity.")
        }
        
        if results.outcomes.identitySet {
            HeapLogger.shared.debug("Identity set to \(identity).")
        }
        
        handleChanges(results, timestamp: timestamp)
    }

    func resetIdentity(timestamp: Date = Date()) {
        
        if stateManager.current == nil {
            HeapLogger.shared.debug("Heap.resetIdentity was called before Heap.startRecording and will not reset the identity.")
            return
        }
        
        let results = stateManager.resetIdentity(at: timestamp)
        
        if results.outcomes.identityReset {
            HeapLogger.shared.debug("Identity reset.")
        } else if results.outcomes.wasAlreadyUnindentified {
            HeapLogger.shared.debug("Heap.resetIdentity was called while already unidentified, so no action will be taken.")
        }
        
        handleChanges(results, timestamp: timestamp)
    }

    func addUserProperties(_ properties: [String: HeapPropertyValue]) {
        
        
        let sanitizedProperties = properties.sanitized(methodName: "addUserProperties")
        
        guard let environment = stateManager.current?.environment else {
            HeapLogger.shared.debug("Heap.addUserProperties was called before Heap.startRecording and will not add user properties.")
            return
        }
        
        
        for (name, value) in sanitizedProperties {
            dataStore.insertOrUpdateUserProperty(
                environmentId: environment.envID,
                userId: environment.userID,
                name: name, value: value)
        }
        HeapLogger.shared.debug("Added \(sanitizedProperties.count) user properties.")
    }

    func addEventProperties(_ properties: [String: HeapPropertyValue]) {

        let sanitizedProperties = properties.sanitized(methodName: "addEventProperties")
        
        if stateManager.current == nil {
            HeapLogger.shared.debug("Heap.addEventProperties was called before Heap.startRecording and will not add event properties.")
            return
        }
        
        stateManager.addEventProperties(sanitizedProperties.mapValues(\.protoValue))
        HeapLogger.shared.debug("Added \(sanitizedProperties.count) event properties.")
    }

    func removeEventProperty(_ name: String) {
        
        if name.isEmpty {
            HeapLogger.shared.debug("Heap.removeEventProperty was called with an invalid property name and no action will be taken.")
            return
        }
        
        if stateManager.current == nil {
            HeapLogger.shared.debug("Heap.removeEventProperty was called before Heap.startRecording and will not remove the event property.")
            return
        }
        
        stateManager.removeEventProperty(name)
        HeapLogger.shared.debug("Removed the event property named \(name).")
    }

    func clearEventProperties() {
        
        if stateManager.current == nil {
            HeapLogger.shared.debug("Heap.clearEventProperties was called before Heap.startRecording and will not clear event properties.")
            return
        }
        
        stateManager.clearEventProperties()
        HeapLogger.shared.debug("Cleared all event properties.")
    }
    
    var environmentId: String? {
        return stateManager.current?.environment.envID
    }

    var userId: String? {
        
        guard let environment = stateManager.current?.environment else {
            HeapLogger.shared.debug("Heap.getUserId was called before Heap.startRecording and will return nil.")
            return nil
        }
        
        return environment.userID
    }

    var identity: String? {
        guard let environment = stateManager.current?.environment else {
            HeapLogger.shared.debug("Heap.identity was called before Heap.startRecording and will return nil.")
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
        
        guard let state = stateManager.current else {
            HeapLogger.shared.debug("Heap.getSessionId was called before Heap.startRecording and will return nil.")
            return nil
        }
        
        guard timestamp < state.sessionExpirationDate else {
            HeapLogger.shared.debug("Heap.getSessionId was called after the session expired and will return nil. To get a valid session in this scenario, use fetchSessionId instead.")
            return nil
        }
        
        return state.sessionInfo.id
    }
    
    /// Gets the current state, creating a new session if there is no previous session or the
    /// previous session has expired.
    ///
    /// This internal method is used by `fetchSessionId` and for exposing the current session to
    /// heap.js in a webview.
    func fetchSession(timestamp: Date) -> State? {
        
        let results = stateManager.createSessionIfExpired(extendIfNotExpired: false, at: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        return results.current
    }

    func fetchSessionId(timestamp: Date = Date()) -> String? {
        
        if stateManager.current == nil {
            HeapLogger.shared.debug("Heap.fetchSessionId was called before Heap.startRecording and will return nil.")
            return nil
        }
        
        return fetchSession(timestamp: timestamp)?.sessionInfo.id
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
    
    /// This extends the current session if it matches the provided value.
    ///
    /// The preferred expiration date is used, bounded by the core SDK and heap.js's expiration
    /// times. This will extend the session even if it should have expired in an effort to maximize
    /// consistency between heap.js's view of a session and the SDK's events.
    func extendSession(sessionId: String, preferredExpirationDate: Date, timestamp: Date) {
        let results = stateManager.extendSession(sessionId: sessionId, preferredExpirationDate: preferredExpirationDate, timestamp: timestamp)
        handleChanges(results, timestamp: timestamp)
        
        if let current = results.current {
            if current.sessionInfo.id == sessionId {
                HeapLogger.shared.trace("extendSession: Session \(sessionId) extended to \(current.sessionExpirationDate), \(current.sessionExpirationDate.timeIntervalSinceNow / 60) minutes from now.")
            } else {
                HeapLogger.shared.trace("extendSession: Session \(sessionId) was not extended because the id did not match current session \(current.sessionInfo.id).")
            }
        }
    }
}

extension EventConsumer: InternalHeapProtocol {
    
    func startRecording(_ environmentId: String, with options: [HeapSwiftCoreInterfaces.Option : Any]) {
        startRecording(environmentId, with: options, timestamp: Date())
    }
    
    func stopRecording() {
        stopRecording(timestamp: Date())
    }
    
    func identify(_ identity: String) {
        identify(identity, timestamp: Date())
    }
    
    func resetIdentity() {
        resetIdentity(timestamp: Date())
    }
    
    var sessionId: String? {
        getSessionId(timestamp: Date())
    }
    
    func fetchSessionId() -> String? {
        fetchSessionId(timestamp: Date())
    }
    
    func addSource(_ source: HeapSwiftCoreInterfaces.Source, isDefault: Bool) {
        addSource(source, isDefault: isDefault, timestamp: Date())
    }
    
    func addRuntimeBridge(_ bridge: HeapSwiftCoreInterfaces.RuntimeBridge) {
        addRuntimeBridge(bridge, timestamp: Date())
    }
    
    func extendSession(sessionId: String, preferredExpirationDate: Date) {
        extendSession(sessionId: sessionId, preferredExpirationDate: preferredExpirationDate, timestamp: Date())
    }
    
    func fetchSession() -> State? {
        fetchSession(timestamp: Date())
    }
}
    
extension EventConsumer: ActiveSessionProvider {
    var activeSession: ActiveSession? {
        guard let state = stateManager.current else { return nil }
        return .init(environmentId: state.environment.envID, userId: state.environment.userID, sessionId: state.sessionInfo.id, sdkInfo: state.sdkInfo)
    }
}

internal extension SourceInfo {
    var libraryInfo: LibraryInfo {
        var libraryInfo = LibraryInfo()
        libraryInfo.name = name
        libraryInfo.version = version
        libraryInfo.platform = platform
        libraryInfo.properties = properties.mapValues(\.protoValue)
        return libraryInfo
    }
}

extension Dictionary where Key == String, Value == HeapPropertyValue {
    
    /// Sanitizes property dictionary given API constraints.
    /// Omits keys that exceed a 512 utf-16 count.
    /// Truncates values that exceed 1024 utf-16 count.
    /// - Returns: Sanitized Dictionary.
    func sanitized(methodName: String?) -> [String: String] {
        
        var hasRemovedEmptyKeys = false
        var keysRemovedBecauseTheyWereTooLong: [String] = []
        var keysRemovedBecauseTheValueWasEmpty: [String] = []
        var entriesThatWereTrimmed: [(key: String, value: String)] = []
        
        func sanitize(_ pair: (key: String, value: HeapPropertyValue)) -> (String, String)? {
            
            let key = pair.key
            
            guard key.utf16.count <= 512 else {
                keysRemovedBecauseTheyWereTooLong.append(key)
                return nil
            }
            
            guard key.hasNonWhitespaceCharacters else {
                hasRemovedEmptyKeys = true
                return nil
            }
            
            let (value, wasTruncated) = pair.value.heapValue.truncated()
            
            guard value.hasNonWhitespaceCharacters else {
                keysRemovedBecauseTheValueWasEmpty.append(key)
                return nil
            }
            
            if wasTruncated {
                entriesThatWereTrimmed.append((key, value))
            }
            
            return (key, value)
        }
        
        let sanitizedDictionary = [String: String](uniqueKeysWithValues: compactMap(sanitize))
        
        if let methodName = methodName {
            
            if hasRemovedEmptyKeys {
                HeapLogger.shared.debug("\(methodName): Some properties were removed because the keys were empty or whitespace.")
            }
            
            if !keysRemovedBecauseTheyWereTooLong.isEmpty {
                HeapLogger.shared.debug("\(methodName): The following properties were omitted because their keys exceeded 512 utf-16 code units: \(keysRemovedBecauseTheyWereTooLong.joined(separator: ", "))")
            }
            
            if !keysRemovedBecauseTheValueWasEmpty.isEmpty {
                HeapLogger.shared.debug("\(methodName): The following properties were omitted because their values were empty or whitespace: \(keysRemovedBecauseTheValueWasEmpty.joined(separator: ", "))")
            }
            
            if !entriesThatWereTrimmed.isEmpty {
                HeapLogger.shared.debug("\(methodName): The following properties were truncated because their values exceeded 1024 utf-16 code units:\n\(entriesThatWereTrimmed.map({ "    \($0.key): \($0.value)" }).joined(separator: "\n"))")
            }
        }
        
        return sanitizedDictionary
    }
}

extension String {
    
    /// Trims a string of leading and trailing whitespace.
    /// - Returns: The trimmed string or `nil` if the string was entirely whitespace.
    var trimmed: String? {
        let trimmedString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedString.isEmpty ? nil : trimmedString
    }
    
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
    /// logging a message to debug if the value changed.
    /// - Parameters:
    ///   - count: The number of code units to truncate to.
    ///   - message: The message to log if the length was exceeded.
    /// - Returns: The truncated string.
    func truncatedLoggingToDev(toUtf16Count count: Int = 1024, message: @autoclosure () -> String) -> String {
        let (result, wasTruncated) = truncated(toUtf16Count: count)
        if wasTruncated {
            HeapLogger.shared.debug(message())
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
    
    /// Checks if the string contains any non-whitespace values.
    var hasNonWhitespaceCharacters: Bool { rangeOfCharacter(from: .whitespacesAndNewlines.inverted) != nil }
}
