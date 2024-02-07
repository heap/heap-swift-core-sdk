import Foundation
import HeapSwiftCoreInterfaces

struct State {
    let options: [Option: Any]
    let sdkInfo: SDKInfo
    let fieldSettings: FieldSettings
    let behaviorSettings: BehaviorSettings
    
    var environment: EnvironmentState
    var sessionInfo: SessionInfo
    
    /// A synthetic pageview created at the start of the session.
    ///
    /// This event should be used when tracking with `Pageview.none` to signal that the event
    /// doesn't belong to a pageview.
    var unattributedPageviewInfo: PageviewInfo
    
    /// The `pageviewInfo` for the last pageview tracked in the session.
    ///
    /// Events will be attributed to this if tracked without a pageview or if the appropriate
    /// pageview cannot be resolved.
    var lastPageviewInfo: PageviewInfo
    
    var sessionExpirationDate: Date
    
    init(partialWith loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any]) {
        environment = loadedEnvironment
        
        options = sanitizedOptions
        fieldSettings = .init(with: sanitizedOptions)
        behaviorSettings = .init(with: sanitizedOptions)
        sdkInfo = .current(with: fieldSettings)
        
        // Init with placeholder data while we get started. Otherwise, we have to recreate logic here.
        sessionInfo = .init()
        unattributedPageviewInfo = .init()
        lastPageviewInfo = .init()
        sessionExpirationDate = .init(timeIntervalSince1970: 0)
    }
    
    struct UpdateResults {

        struct Outcomes {
            var previousStopped = false
            var currentStarted = false
            var alreadyRecording = false
            var userCreated = false
            var sessionCreated = false
            var identitySet = false
            var identityReset = false
            var wasAlreadyUnindentified = false
            var wasAlreadyIdentified = false
            var versionChanged = false
            var lastObservedVersion: ApplicationInfo? = nil
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
    
    init(loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any], at timestamp: Date, outcomes: inout State.UpdateResults.Outcomes) {
        
        self.init(partialWith: loadedEnvironment, sanitizedOptions: sanitizedOptions)
        
        if !environment.hasUserID {
            createUser(identity: nil, outcomes: &outcomes)
        }
        
        if behaviorSettings.startSessionImmediately {
            createSession(at: timestamp, outcomes: &outcomes)
        } else {
            createExpiredSession()
        }
    }
    
    mutating func createSession(at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        let initialPageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        sessionInfo = .init(newSessionAt: timestamp)
        unattributedPageviewInfo = initialPageviewInfo
        lastPageviewInfo = initialPageviewInfo
        extendCurrentSessionUnconditionally(timestamp: timestamp)
        outcomes.sessionCreated = true
        
        checkForVersionChange(outcomes: &outcomes)
    }
    
    mutating func checkForVersionChange(outcomes: inout UpdateResults.Outcomes) {
        
        let previousVersion = environment.hasLastObservedVersion ? environment.lastObservedVersion : nil
        let currentVersion = sdkInfo.applicationInfo
        if currentVersion != previousVersion {
            environment.lastObservedVersion = currentVersion
            outcomes.versionChanged = true
            outcomes.lastObservedVersion = previousVersion
        }
    }
    
    
    mutating func createExpiredSession() {
        sessionInfo = .init()
    }
    
    mutating func createSessionIfExpired(extendIfNotExpired: Bool, at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        if sessionExpirationDate < timestamp {
            createSession(at: timestamp, outcomes: &outcomes)
        } else if extendIfNotExpired {
            extendCurrentSessionUnconditionally(timestamp: timestamp)
        }
    }
    
    mutating func createUser(identity: String?, outcomes: inout UpdateResults.Outcomes) {
        environment.userID = generateRandomHeapId()
        if let identity = identity {
            environment.identity = identity
            outcomes.identitySet = true
        } else {
            environment.clearIdentity()
        }
        
        if behaviorSettings.clearEventPropertiesOnNewUser
        {
            environment.properties.removeAll()
        }
        outcomes.userCreated = true
    }
    
    mutating func createUserAndSession(identity: String?, at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        createUser(identity: identity, outcomes: &outcomes)
        createSession(at: timestamp, outcomes: &outcomes)
    }
 
    mutating func extendSessionAndSetLastPageview(_ pageviewInfo: inout PageviewInfo, outcomes: inout UpdateResults.Outcomes) {
        createSessionIfExpired(extendIfNotExpired: true, at: pageviewInfo.time.date, outcomes: &outcomes)
        
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
    
    mutating func extendSession(sessionId: String, preferredExpirationDate: Date, timestamp: Date) {
        guard sessionInfo.id == sessionId else { return }
        extendCurrentSessionUnconditionally(preferredExpirationDate: preferredExpirationDate, timestamp: timestamp)
    }
    
    private mutating func extendCurrentSessionUnconditionally(preferredExpirationDate: Date? = nil, timestamp: Date) {
        
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
    }
    
    mutating func resetIdentity(at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        
        // Don't do anything if Heap isn't running or the user isn't identified.
        guard environment.hasIdentity else {
            outcomes.wasAlreadyUnindentified = true
            return
        }
        
        outcomes.identityReset = true
        createUserAndSession(identity: nil, at: timestamp, outcomes: &outcomes)
    }
    
    mutating func identify(_ identity: String, at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        
        // Don't do anything if the identity isn't changing.
        if environment.hasIdentity && environment.identity == identity {
            outcomes.wasAlreadyIdentified = true
            return
        }
        
        // Don't set an empty identity
        if identity.isEmpty { return }
        
        if environment.hasIdentity {
            createUserAndSession(identity: identity, at: timestamp, outcomes: &outcomes)
        } else {
            environment.identity = identity
            outcomes.identitySet = true
            
            createSessionIfExpired(extendIfNotExpired: true, at: timestamp, outcomes: &outcomes)
        }
    }
}

extension Optional where Wrapped == State {
    
    mutating func start(loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any], at timestamp: Date, outcomes: inout State.UpdateResults.Outcomes) {
        
        if case .some(let state) = self {
            
            guard state.environment.envID != loadedEnvironment.envID || !state.options.matches(sanitizedOptions) else {
                // Do nothing since nothing since we'd be switching to the same environment.
                outcomes.alreadyRecording = true
                return
            }

            outcomes.previousStopped = true
        }
        
        self = State.init(loadedEnvironment: loadedEnvironment, sanitizedOptions: sanitizedOptions, at: timestamp, outcomes: &outcomes)
        outcomes.currentStarted = true
    }
    
    mutating func stop(outcomes: inout State.UpdateResults.Outcomes) {
        
        // Don't stop if we're already stopped.
        guard case .some = self else { return }
        
        self = .none
        outcomes.previousStopped = true
    }
}
