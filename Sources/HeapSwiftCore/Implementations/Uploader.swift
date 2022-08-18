import Foundation

protocol ActiveSessionProvider {
    var activeSession: ActiveSession? { get }
}

class Uploader<DataStore: DataStoreProtocol, SessionProvider: ActiveSessionProvider>: UploaderProtocol {
    
    let dataStore: DataStore
    let activeSessionProvider: SessionProvider
    let urlSession: URLSession

    init(dataStore: DataStore, activeSessionProvider: SessionProvider, urlSessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.dataStore = dataStore
        self.activeSessionProvider = activeSessionProvider
        self.urlSession = URLSession(configuration: urlSessionConfiguration)
    }

    func startScheduledUploads(with options: [Option : Any]) {
    }

    func stopScheduledUploads() {
    }

    var nextScheduledUploadDate: Date {
        Date()
    }
    
    func uploadAll(activeSession: ActiveSession, options: [Option : Any], complete: (Result<Void, UploadError>) -> Void) {
    }
    
    func uploadUser(_ user: UserToUpload, activeSession: ActiveSession, options: [Option : Any], complete: (Result<Void, UploadError>) -> Void) {
    }
    
    func uploadSession(with sessionId: String, activeSession: ActiveSession, options: [Option : Any], complete: (Result<Void, UploadError>) -> Void) {
    }
}
