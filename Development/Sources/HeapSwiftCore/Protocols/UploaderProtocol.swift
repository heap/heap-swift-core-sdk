import Foundation

/// A representation of the current session.
struct ActiveSession {
    let environmentId: String
    let userId: String
    let sessionId: String
}

/// The simplified set of failures that can be received from an upload request.
enum UploadError: Error, Equatable {
    
    /// The server identified the request being a "Bad Request", meaning the server didn't and
    /// cannot process it.
    case badRequest
    
    /// The server emitted some response we did not expect, most likely indicating a transient
    /// issue with the server.  Requests can be retransmitted, but failures may be recurring
    /// for the near future.
    case unexpectedServerResponse
    
    /// A failure was reported from the network stack and not from the server.  For example, if
    /// the host is unavailable.  Requests can be retransmitted, but failures may be recurring
    /// for the near future.
    case networkFailure
}

/// The result of an upload operation.
typealias UploadResult = Result<Void, UploadError>

/// A protocol to be implemented by an uploader.
protocol UploaderProtocol {

    /// Starts scheduling regular uploads to the Heap server.
    /// - Parameter options: Options to be used when configuring the scheduled uploader.
    func startScheduledUploads(with options: [Option: Any])
    
    /// Stops the scheduled uploads.
    func stopScheduledUploads()
    
    /// The next date at which the scheduled uploader will fire.
    var nextScheduledUploadDate: Date { get }

    /// Attempts to upload all queued data to the server.
    ///
    /// - Parameters:
    ///   - activeSession: Information about the active session.
    ///   - options: Any options passed while starting the scheduled upload.
    ///   - complete: A completion block that fires when the upload process completes.
    func uploadAll(activeSession: ActiveSession, options: [Option: Any], complete: @escaping (UploadResult) -> Void)
}
