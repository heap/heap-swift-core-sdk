@testable import HeapSwiftCore

extension StateStoreProtocol {
    
    func applyIdentifiedState(to environmentId: String) -> EnvironmentState {
        var state = loadState(for: environmentId)
        state.userID = "9999999"
        state.identity = "__initial_identity__"
        state.properties = ["__initial__": .init(value: "__value__")]
        save(state)
        return state
    }

    func applyUnidentifiedState(to environmentId: String) -> EnvironmentState {
        var state = loadState(for: environmentId)
        state.userID = "9999999"
        state.clearIdentity()
        state.properties = ["__initial__": .init(value: "__value__")]
        save(state)
        return state
    }
    
    func applyApplicationInfo(to environmentId: String, applicationInfo: ApplicationInfo) -> EnvironmentState {
        var state = loadState(for: environmentId)
        state.lastObservedVersion = applicationInfo
        save(state)
        return state
    }
}
