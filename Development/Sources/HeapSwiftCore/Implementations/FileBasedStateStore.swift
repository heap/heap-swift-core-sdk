import Foundation

class FileBasedStateStore: StateStoreProtocol {
    
    private let directoryUrl: URL
    
    init(directoryUrl: URL) {
        self.directoryUrl = directoryUrl
    }
    
    func url(for environmentId: String) -> URL {
        return directoryUrl.appendingPathComponent("environment-\(environmentId).bin")
    }
    
    func loadState(for environmentId: String) -> EnvironmentState {
        let fileUrl = url(for: environmentId)
        
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileUrl.path) else {
            return .with { $0.envID = environmentId }
        }
        
        do {
            let state = try EnvironmentState(serializedData: try Data(contentsOf: fileUrl))
            if state.envID == environmentId && !state.userID.isEmpty {
                return state
            } else {
                HeapLogger.shared.warn("The environment state at \(fileUrl) is corrupted and will be ignored.")
            }
        } catch {
            HeapLogger.shared.warn("The environment state at \(fileUrl) is corrupted and will be ignored.")
            HeapLogger.shared.debug("Reading state failed with the following error: \(error.localizedDescription)")
        }
        
        return .with { $0.envID = environmentId }
    }
    
    func save(_ environmentState: EnvironmentState) {
        let fileUrl = url(for: environmentState.envID)
        do {
            try environmentState.serializedData().write(to: fileUrl)
        } catch {
            HeapLogger.shared.warn("An error occurred while writing the environment state to \(fileUrl).")
            HeapLogger.shared.debug("Writing state failed with the following error: \(error.localizedDescription)")
        }
    }
    
    func delete(environmentId: String) {
        let fileUrl = url(for: environmentId)
        
        do {
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            HeapLogger.shared.warn("An error occurred while deleting the environment state at \(fileUrl).")
            HeapLogger.shared.debug("Deleting state state failed with the following error: \(error.localizedDescription)")
        }
    }
}
