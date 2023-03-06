import Foundation
@testable import HeapSwiftCore

class CountingUploader: NSObject, UploaderProtocol {
    var nextScheduledUploadDate: Date = Date()
    var isStarted: Bool = false
    
    func startScheduledUploads(with settings: UploaderSettings) {
        isStarted = true
    }
    
    func stopScheduledUploads() {
        isStarted = false
    }
    
    
    func uploadAll(activeSession: ActiveSession, settings: UploaderSettings, complete: @escaping (UploadResult) -> Void) {
    }
}
