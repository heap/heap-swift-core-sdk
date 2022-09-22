protocol StateStoreProtocol {
    func loadState(for environmentId: String) -> EnvironmentState
    func save(_ environmentState: EnvironmentState)
}
