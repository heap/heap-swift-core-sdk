import Foundation

class FileBasedStateStore: StateStoreProtocol {
    
    private let directoryUrl: URL
    
    init(directoryUrl: URL) {
        self.directoryUrl = directoryUrl
    }
    
    func url(for environmentId: String) -> URL {
        return directoryUrl.appendingPathComponent("environment-\(environmentId).json")
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
                print("The environment state at \(fileUrl) is corrupted and will be ignored.")
            }
        } catch {
            // TODO: Logging
            print("An error occurred while reading the environment state from \(fileUrl):\n\(error.localizedDescription)")
        }
        
        return .with { $0.envID = environmentId }
    }
    
    func save(_ environmentState: EnvironmentState) {
        let fileUrl = url(for: environmentState.envID)
        do {
            try environmentState.serializedData().write(to: fileUrl)
        } catch {
            // TODO: Logging
            print("An error occurred while writing the environment state to \(fileUrl):\n\(error.localizedDescription)")
        }
    }
    
    func delete(environmentId: String) {
        let fileUrl = url(for: environmentId)
        
        do {
            try FileManager.default.removeItem(at: fileUrl)
        } catch {
            // TODO: Logging
            print("An error occurred while deleting the environment state at \(fileUrl):\n\(error.localizedDescription)")
        }
    }
}
