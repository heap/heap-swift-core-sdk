import Foundation

struct State {
    var environment: EnvironmentState
    var options: [Option: Any]
    var sessionInfo: SessionInfo
    var lastPageviewInfo: PageviewInfo
    var sessionExpirationDate: Date
    
    struct UpdateResults {

        struct Outcomes {
            var previousStopped = false
            var currentStarted = false
            var userCreated = false
            var sessionCreated = false
            var identitySet = false
        }

        let previous: State?
        let current: State?
        let outcomes: Outcomes
    }
}

extension State {
    
    init(loadedEnvironment: EnvironmentState, sanitizedOptions: [Option: Any], at timestamp: Date, outcomes: inout State.UpdateResults.Outcomes) {
        
        // Init with placeholder data while we get started. Otherwise, we have to recreaet logic here.
        self.init(environment: loadedEnvironment, options: sanitizedOptions, sessionInfo: .init(), lastPageviewInfo: .init(), sessionExpirationDate: .init(timeIntervalSince1970: 0))
        
        if !environment.hasUserID {
            createUserAndSession(identity: nil, at: timestamp, outcomes: &outcomes)
        } else {
            createSession(at: timestamp, outcomes: &outcomes)
        }
    }
    
    mutating func createSession(at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        sessionInfo = .init(newSessionAt: timestamp)
        lastPageviewInfo = .init(newPageviewAt: timestamp)
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
    
    mutating func resetIdentity(at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        
        // Don't do anything if Heap isn't running or the user isn't identified.
        guard environment.hasIdentity else { return }
        
        createUserAndSession(identity: nil, at: timestamp, outcomes: &outcomes)
    }
    
    mutating func identify(_ identity: String, at timestamp: Date, outcomes: inout UpdateResults.Outcomes) {
        
        // Don't do anything if the identity isn't changing.
        if environment.hasIdentity && environment.identity == identity { return }
        
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
                return // Do nothing since nothing since we'd be switching to the same environment.
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
