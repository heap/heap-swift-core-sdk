import Foundation
@testable import HeapSwiftCore

class CountingUploader: NSObject, UploaderProtocol {
    var nextScheduledUploadDate: Date = Date()
    var isStarted: Bool = false
    
    func startScheduledUploads(with options: [Option : Any]) {
        isStarted = true
    }
    
    func stopScheduledUploads() {
        isStarted = false
    }
    
    func uploadAll(activeSession: HeapSwiftCore.ActiveSession, options: [HeapSwiftCore.Option : Any], complete: @escaping (HeapSwiftCore.UploadResult) -> Void) {
    }
}
