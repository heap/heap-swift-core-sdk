import Foundation

struct CallbackError: Error {
    let message: String
}

typealias CallbackResult<T> = Result<T, CallbackError>
typealias Callback<T> = (CallbackResult<T>) -> Void

/// This class is a token-based callback store with a watchdog timeout.
///
/// This class guarantees that the callback will be called exactly once and no later the provided
/// timeout.  No attempt is made to signal to the original source that the timeout has expired, so
/// it is up to the caller to determine the correct behavior.
class CallbackStore<T> {
    
    typealias Entry = (callback: Callback<T>, timer: HeapTimer)
    
    private var callbacks: [String: Entry] = [:]
    
    var callbackIdsForCallbackQueueOnly: [String] { Array(callbacks.keys) }
    
    func add(timeout: TimeInterval, callback: @escaping Callback<T>) -> String {
        
        let callbackId = UUID().uuidString
        
        OperationQueue.callback.addOperation {
            
            let timer = HeapTimer.schedule(in: .callback, after: timeout) {
                self.resolve(callbackId: callbackId, result: .failure(.init(message: "A timeout occurred while waiting for the bridge.")))
            }

            self.callbacks[callbackId] = (callback, timer)
        }
        
        return callbackId
    }
    
    func cancelAllSync() {
        
        OperationQueue.callback.addOperationAndWait { [self] in
            for callbackId in callbackIdsForCallbackQueueOnly {
                resolve(callbackId: callbackId, result: .failure(.init(message: "All callbacks cancelled.")))
            }
        }
        
    }
    
    private func resolve(callbackId: String, result: CallbackResult<T>) {
        guard let (callback, timer) = callbacks[callbackId] else { return }
        callbacks[callbackId] = nil
        
        timer.cancel()
        callback(result)
    }
    
    func success(callbackId: String, data: T) {
        OperationQueue.callback.addOperation {
            self.resolve(callbackId: callbackId, result: .success(data))
        }
    }
    
    func failure(callbackId: String, error: String) {
        OperationQueue.callback.addOperation {
            self.resolve(callbackId: callbackId, result: .failure(.init(message: error)))
        }
    }
}
