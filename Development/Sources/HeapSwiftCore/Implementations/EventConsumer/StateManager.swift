import Foundation

class StateManager<StateStore: StateStoreProtocol> {
    let stateStore: StateStore
    private var _loadedEnvironmentStates: [String: EnvironmentState] = [:]
    private var _current: State? = nil
    private let _currentLock = DispatchSemaphore(value: 1)

    init(stateStore: StateStore) {
        self.stateStore = stateStore
    }
    
    func update(block: (inout State?, inout State.UpdateResults.Outcomes) -> Void) -> State.UpdateResults {
        
        _currentLock.wait()
        
        var outcomes = State.UpdateResults.Outcomes()
        let previous = _current
        block(&_current, &outcomes)
        let current = _current

        if let current = current, current.environment != previous?.environment {
            _loadedEnvironmentStates[current.environment.envID] = current.environment
            stateStore.save(current.environment)
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
        update { state, outcomes in
            state.start(loadedEnvironment: loadEnvironmentState(environmentId), sanitizedOptions: sanitizedOptions, at: timestamp, outcomes: &outcomes)
        }
    }
    
    func stop() -> State.UpdateResults {
        update { state, outcomes in
            state.stop(outcomes: &outcomes)
        }
    }
    
    func createSessionIfExpired(extendIfNotExpired: Bool, at timestamp: Date) -> State.UpdateResults {
        update { state, outcomes in
            state?.createSessionIfExpired(extendIfNotExpired: extendIfNotExpired, at: timestamp, outcomes: &outcomes)
        }
    }
    
    func extendSessionAndSetLastPageview(_ pageviewInfo: PageviewInfo) -> State.UpdateResults {
        update { state, outcomes in
            state?.extendSessionAndSetLastPageview(pageviewInfo, outcomes: &outcomes)
        }
    }
    
    func identify(_ identity: String, at timestamp: Date) -> State.UpdateResults {
        update { state, outcomes in
            state?.identify(identity, at: timestamp, outcomes: &outcomes)
        }
    }
    
    func resetIdentity(at timestamp: Date) -> State.UpdateResults {
        update { state, outcomes in
            state?.resetIdentity(at: timestamp, outcomes: &outcomes)
        }
    }
    
    func addEventProperties(_ sanitizedEventProperties: [String: Value]) {
        _ = update { state, outcomes in
            state?.environment.properties.merge(sanitizedEventProperties, uniquingKeysWith: { $1 })
        }
    }
    
    func removeEventProperty(_ name: String) {
        _ = update { state, outcomes in
            state?.environment.properties.removeValue(forKey: name)
        }
    }
    
    func clearEventProperties() {
        _ = update { state, outcomes in
            state?.environment.properties.removeAll()
        }
    }
}
