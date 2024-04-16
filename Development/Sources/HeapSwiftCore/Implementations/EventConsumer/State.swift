import Foundation
import HeapSwiftCoreInterfaces

struct State {
    let options: [Option: Any]
    let sdkInfo: SDKInfo
    let fieldSettings: FieldSettings
    let behaviorSettings: BehaviorSettings
    
    var environment: EnvironmentState
    var sessionInfo: SessionInfo {
        get { environment.sessionInfo }
        set { environment.sessionInfo = newValue }
    }
    
    /// A synthetic pageview created at the start of the session.
    ///
    /// This event should be used when tracking with `Pageview.none` to signal that the event
    /// doesn't belong to a pageview.
    var unattributedPageviewInfo: PageviewInfo {
        get { environment.unattributedPageviewInfo }
        set { environment.unattributedPageviewInfo = newValue }
    }
    
    /// The `pageviewInfo` for the last pageview tracked in the session.
    ///
    /// Events will be attributed to this if tracked without a pageview or if the appropriate
    /// pageview cannot be resolved.
    var lastPageviewInfo: PageviewInfo = .init()
    
    /// The session expiration date, truncating to the second.
    ///
    /// The expiration date is truncated to the second to reduce the odds of state being written
    /// more than once per second.  In testing (StateStorePerformanceTests), this eliminated the
    /// already miniscule overhead of writing to disk.
    var sessionExpirationDate: Date {
        get { environment.sessionExpirationDate.date }
        set { environment.sessionExpirationDate = .init(date: newValue).truncatedToSeconds }
    }
    
    /// Properties of the session start, used to drive Contentsquare integration behavior.
    ///
    /// This property is not persisted across app launches.
    var contentsquareSessionProperties: _ContentsquareSessionProperties = .init()
    
    var hasCheckedForVersionChange = false
    
    init(partialWith loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any]) {
        environment = loadedEnvironment
        
        options = sanitizedOptions
        fieldSettings = .init(with: sanitizedOptions)
        behaviorSettings = .init(with: sanitizedOptions)
        sdkInfo = .current(with: fieldSettings)
    }
    
    struct UpdateResults {

        struct Outcomes {
            var previousStopped = false
            var currentStarted = false
            var alreadyRecording = false
            var userCreated = false
            var sessionCreated = false
            var sessionRestored = false
            var identitySet = false
            var identityReset = false
            var wasAlreadyUnindentified = false
            var wasAlreadyIdentified = false
            var versionChanged = false
            var lastObservedVersion: ApplicationInfo? = nil
            var userDeleted = false
        }

        let previous: State?
        let current: State?
        let outcomes: Outcomes
    }
}

extension State.UpdateResults.Outcomes {
    var shouldSendChangeToHeapJs: Bool {
        // Several state changes are ignored because they trigger session creation.
        identitySet || sessionCreated
    }
}

extension State {
    
    init(loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any], at timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout State.UpdateResults.Outcomes) {
        
        self.init(partialWith: loadedEnvironment, sanitizedOptions: sanitizedOptions)
        
        if !environment.hasUserID {
            createUser(identity: nil, outcomes: &outcomes)
        } else if behaviorSettings.resumePreviousSession && sessionExpirationDate >= timestamp {
            outcomes.sessionRestored = true
        } else {
            endSession()
        }
        
        if behaviorSettings.startSessionImmediately {
            createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    private mutating func createSession(at timestamp: Date, properties: _ContentsquareSessionProperties, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        let initialPageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        sessionInfo = .init(newSessionAt: timestamp)
        unattributedPageviewInfo = initialPageviewInfo
        lastPageviewInfo = initialPageviewInfo
        contentsquareSessionProperties = properties
        extendCurrentSessionUnconditionally(timestamp: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        outcomes.sessionCreated = true
        
        checkForVersionChange(outcomes: &outcomes)
    }
    
    private mutating func endSession() {
        sessionInfo = .init()
        sessionExpirationDate = .init(timeIntervalSince1970: 0)
    }
    
    private mutating func checkForVersionChange(outcomes: inout UpdateResults.Outcomes) {
        guard !hasCheckedForVersionChange else { return }
        hasCheckedForVersionChange = true
        
        let previousVersion = environment.hasLastObservedVersion ? environment.lastObservedVersion : nil
        let currentVersion = sdkInfo.applicationInfo
        if currentVersion != previousVersion {
            environment.lastObservedVersion = currentVersion
            outcomes.versionChanged = true
            outcomes.lastObservedVersion = previousVersion
        }
    }
    
    mutating func createSessionIfExpired(extendIfNotExpired: Bool, properties: _ContentsquareSessionProperties, at timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        if sessionExpirationDate < timestamp {
            createSession(at: timestamp, properties: properties, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        } else if extendIfNotExpired {
            extendCurrentSessionUnconditionally(timestamp: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    private mutating func createUser(identity: String?, outcomes: inout UpdateResults.Outcomes) {
        environment.userID = generateRandomHeapId()
        endSession()
        
        if let identity = identity {
            environment.identity = identity
            outcomes.identitySet = true
        } else {
            environment.clearIdentity()
        }
        
        if behaviorSettings.clearEventPropertiesOnNewUser {
            environment.properties.removeAll()
        }
        
        outcomes.userCreated = true
    }
 
    mutating func extendSessionAndSetLastPageview(_ pageviewInfo: inout PageviewInfo, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: pageviewInfo.time.date, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        
        // It is a little counter-intuitive to bury the logic here, but we need to know the current
        // state to know the field settings to know whether the title should be used.
        //
        // To do things atomically, we need to clear the title at the point it is first consumed,
        // which is when it is applied to the session.  We then need to bubble that up to
        // `trackPageview` using an `inout` property.
        if !fieldSettings.capturePageviewTitle {
            pageviewInfo.clearTitle()
        }

        lastPageviewInfo = pageviewInfo
    }
    
    mutating func extendSession(sessionId: String, preferredExpirationDate: Date, timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        guard sessionInfo.id == sessionId else { return }
        extendCurrentSessionUnconditionally(preferredExpirationDate: preferredExpirationDate, timestamp: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
    }
    
    private mutating func extendCurrentSessionUnconditionally(preferredExpirationDate: Date? = nil, timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        
        let targetExpirationDate: Date
        
        if let preferredExpirationDate = preferredExpirationDate {
            let candidates = [
                timestamp.advancedBySessionExpirationTimeout(),
                preferredExpirationDate,
                timestamp.advancedByHeapJsSessionExpirationTimeout(),
            ]
            
            // This is a funny little idea because maybe we'll fiddle with expiration dates in the future.
            // If the value is out of range, the minimum or maximum will get shifted in.
            targetExpirationDate = candidates.sorted()[1]
        } else {
            targetExpirationDate = timestamp.advancedBySessionExpirationTimeout()
        }
        
        // Only set the date if it is greater than the existing date.
        if sessionExpirationDate < targetExpirationDate {
            sessionExpirationDate = targetExpirationDate
        }
        
        // If Contentsquare proves a session timeout, and it's greater than the Heap timeout,
        // extend the session to that date.
        if let contentsquareTimeout = contentsquareTimeout {
            let contentsquareExpirationDate = timestamp.addingTimeInterval(contentsquareTimeout)
            if sessionExpirationDate < contentsquareExpirationDate {
                sessionExpirationDate = contentsquareExpirationDate
            }
        }

        // This is a strange place to put this, but it's a good spot for it.  We want version
        // change events to be the first event of an app launch but we don't want them to cause a
        // session to start.  If they can start a session, customers with background launch can end
        // up with phantom sessions that just have a version change event.
        //
        // For apps without `resumePreviousSession`, the appropriate point is when the first
        // session is created.  For apps with `resumePreviousSession`, the appropriate point is
        // when the first event (or whatever) asks to extend the session.  In both cases, they
        // pass through this method.
        checkForVersionChange(outcomes: &outcomes)
    }
    
    mutating func resetIdentity(at timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        
        // Don't do anything if Heap isn't running or the user isn't identified.
        guard environment.hasIdentity else {
            outcomes.wasAlreadyUnindentified = true
            return
        }
        
        outcomes.identityReset = true
        
        createUser(identity: nil, outcomes: &outcomes)
        createSession(at: timestamp, properties: .fromNewUser, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
    }
    
    mutating func identify(_ identity: String, at timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout UpdateResults.Outcomes) {
        
        // Don't do anything if the identity isn't changing.
        if environment.hasIdentity && environment.identity == identity {
            outcomes.wasAlreadyIdentified = true
            return
        }
        
        // Don't set an empty identity
        if identity.isEmpty { return }
        
        if environment.hasIdentity {
            createUser(identity: identity, outcomes: &outcomes)
            createSession(at: timestamp, properties: .fromNewUser, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        } else {
            environment.identity = identity
            outcomes.identitySet = true
            
            createSessionIfExpired(extendIfNotExpired: true, properties: .init(), at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
}

extension Optional where Wrapped == State {
    
    mutating func start(loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any], at timestamp: Date, contentsquareTimeout: TimeInterval?, outcomes: inout State.UpdateResults.Outcomes) {
        
        if case .some(let state) = self {
            
            guard state.environment.envID != loadedEnvironment.envID || !state.options.matches(sanitizedOptions) else {
                // Do nothing since nothing since we'd be switching to the same environment.
                outcomes.alreadyRecording = true
                return
            }

            outcomes.previousStopped = true
        }
        
        self = State.init(loadedEnvironment: loadedEnvironment, sanitizedOptions: sanitizedOptions, at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        outcomes.currentStarted = true
    }
    
    mutating func stop(deleteUser: Bool, outcomes: inout State.UpdateResults.Outcomes) {
        
        // Don't stop if we're already stopped.
        guard case .some = self else { return }
        
        self = .none
        outcomes.previousStopped = true
        outcomes.userDeleted = deleteUser
    }
}
