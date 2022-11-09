import Foundation

struct State {
    var environment: EnvironmentState
    var options: [Option: Any]
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
        }

        let previous: State?
        let current: State?
        let outcomes: Outcomes
    }
}

extension State {
    
    init(loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any], at timestamp: Date, outcomes: inout State.UpdateResults.Outcomes) {
        
        // Init with placeholder data while we get started. Otherwise, we have to recreaet logic here.
        self.init(environment: loadedEnvironment, options: sanitizedOptions, sessionInfo: .init(), unattributedPageviewInfo: .init(), lastPageviewInfo: .init(), sessionExpirationDate: .init(timeIntervalSince1970: 0))
        
        if !environment.hasUserID {
            createUserAndSession(identity: nil, at: timestamp, outcomes: &outcomes)
        } else {
            createSession(at: timestamp, outcomes: &outcomes)
        }
    }
    
    mutating func createSession(at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        let initialPageviewInfo = PageviewInfo(newPageviewAt: timestamp)
        sessionInfo = .init(newSessionAt: timestamp)
        unattributedPageviewInfo = initialPageviewInfo
        lastPageviewInfo = initialPageviewInfo
        sessionExpirationDate = timestamp.advancedBySessionExpirationTimeout()
        outcomes.sessionCreated = true
    }
    
    mutating func createSessionIfExpired(extendIfNotExpired: Bool, at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        if sessionExpirationDate < timestamp {
            createSession(at: timestamp, outcomes: &outcomes)
        } else if extendIfNotExpired {
            sessionExpirationDate = timestamp.advancedBySessionExpirationTimeout()
        }
    }
    
    mutating func createUserAndSession(identity: String?, at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        environment.userID = generateRandomHeapId()
        if let identity = identity {
            environment.identity = identity
            outcomes.identitySet = true
        } else {
            environment.clearIdentity()
        }
        environment.properties.removeAll()
        outcomes.userCreated = true

        createSession(at: timestamp, outcomes: &outcomes)
    }
    
    mutating func extendSessionAndSetLastPageview(_ pageviewInfo: PageviewInfo, outcomes: inout UpdateResults.Outcomes) {
        createSessionIfExpired(extendIfNotExpired: true, at: pageviewInfo.time.date, outcomes: &outcomes)
        lastPageviewInfo = pageviewInfo
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
