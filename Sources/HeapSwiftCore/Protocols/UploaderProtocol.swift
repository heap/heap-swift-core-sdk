import Foundation

struct AppContext {
    let application: ApplicationInfo
    let device: DeviceInfo
    let baseLibrary: LibraryInfo
}

struct ActiveSession {
    let environmentId: String
    let userId: String
    let sessionId: String
}

enum UploadError: Error {
    case normalError
    case unknownError(Error)
}

protocol UploaderProtocol {

    func startScheduledUploads(with options: [Option: Any])
    func stopScheduledUploads()
    var nextScheduledUploadDate: Date { get }

    func uploadAll(activeSession: ActiveSession, options: [Option: Any], complete: (Result<Void, UploadError>) -> Void)
    func uploadUser(_ user: UserToUpload, activeSession: ActiveSession, options: [Option: Any], complete: (Result<Void, UploadError>) -> Void)
    func uploadSession(with sessionId: String, activeSession: ActiveSession, options: [Option: Any], complete: (Result<Void, UploadError>) -> Void)
}
