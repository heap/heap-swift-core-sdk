import Foundation
import HeapSwiftCoreInterfaces

class StateManager<StateStore: StateStoreProtocol> {
    let stateStore: StateStore
    private var _loadedEnvironmentStates: [String: EnvironmentState] = [:]
    private var _current: State? = nil
    private let _currentLock = DispatchSemaphore(value: 1)
    private var _contentsquareIntegration: _ContentsquareIntegration?

    init(stateStore: StateStore) {
        self.stateStore = stateStore
    }
    
    func update(block: (_ state: inout State?, _ contentsquareTimeout: TimeInterval?, _ outcomes: inout State.UpdateResults.Outcomes) -> Void) -> State.UpdateResults {
        
        _currentLock.wait()
        
        var outcomes = State.UpdateResults.Outcomes()
        let previous = _current
        block(&_current, _contentsquareIntegration?.sessionTimeoutDuration, &outcomes)
        let current = _current

        if let current = current, current.environment != previous?.environment {
            _loadedEnvironmentStates[current.environment.envID] = current.environment
            stateStore.save(current.environment)
        } else if let previous = previous, outcomes.userDeleted {
            let emptyEnvironment = EnvironmentState(environmentId: previous.environment.envID)
            _loadedEnvironmentStates[previous.environment.envID] = emptyEnvironment
            stateStore.save(emptyEnvironment)
        }

        _currentLock.signal()
        
        return .init(previous: previous, current: current, outcomes: outcomes)
    }
    
    var current: State? {
        _currentLock.wait()
        let current = _current
        _currentLock.signal()
        
        return current
    }

    fileprivate func loadEnvironmentState(_ environmentId: String) -> EnvironmentState {
        if let state = _loadedEnvironmentStates[environmentId] { return state }
        let state = stateStore.loadState(for: environmentId)
        _loadedEnvironmentStates[environmentId] = state
        return state
    }
}

extension StateManager {
    
    func start(environmentId: String, sanitizedOptions: [Option: Any], at timestamp: Date) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state.start(loadedEnvironment: loadEnvironmentState(environmentId), sanitizedOptions: sanitizedOptions, at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func stop(deleteUser: Bool) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state.stop(deleteUser: deleteUser, outcomes: &outcomes)
        }
    }
    
    func createSessionIfExpired(extendIfNotExpired: Bool, properties: _ContentsquareSessionProperties, at timestamp: Date) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state?.createSessionIfExpired(extendIfNotExpired: extendIfNotExpired, properties: properties, at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func extendSessionAndSetLastPageview(_ pageviewInfo: inout PageviewInfo) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state?.extendSessionAndSetLastPageview(&pageviewInfo, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func extendSession(sessionId: String, preferredExpirationDate: Date, timestamp: Date) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state?.extendSession(sessionId: sessionId, preferredExpirationDate: preferredExpirationDate, timestamp: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func extendSessionIfNotExpired(timestamp: Date) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state?.extendSessionIfNotExpired(timestamp: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func identify(_ identity: String, at timestamp: Date) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state?.identify(identity, at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func resetIdentity(at timestamp: Date) -> State.UpdateResults {
        update { state, contentsquareTimeout, outcomes in
            state?.resetIdentity(at: timestamp, contentsquareTimeout: contentsquareTimeout, outcomes: &outcomes)
        }
    }
    
    func addEventProperties(_ sanitizedEventProperties: [String: Value]) {
        _ = update { state, contentsquareTimeout, outcomes in
            state?.environment.properties.merge(sanitizedEventProperties, uniquingKeysWith: { $1 })
        }
    }
    
    func removeEventProperty(_ name: String) {
        _ = update { state, contentsquareTimeout, outcomes in
            state?.environment.properties.removeValue(forKey: name)
        }
    }
    
    func clearEventProperties() {
        _ = update { state, contentsquareTimeout, outcomes in
            state?.environment.properties.removeAll()
        }
    }
    
    var contentsquareIntegration: _ContentsquareIntegration? {
        get {
            _currentLock.wait()
            defer { _currentLock.signal() }
            return _contentsquareIntegration
        }
        set {
            _currentLock.wait()
            defer { _currentLock.signal() }
            _contentsquareIntegration = newValue
        }
    }
}
