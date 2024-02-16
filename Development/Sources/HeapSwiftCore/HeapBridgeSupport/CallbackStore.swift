import Foundation

struct CallbackError: Error {
    let message: String
}

typealias CallbackResult = Result<Any?, CallbackError>
typealias Callback = (CallbackResult) -> Void

class CallbackStore {
    
    typealias Entry = (callback: Callback, timer: HeapTimer)
    
    private var callbacks: [String: Entry] = [:]
    
    var callbackIdsForCallbackQueueOnly: [String] { Array(callbacks.keys) }
    
    func add(timeout: TimeInterval, callback: @escaping Callback) -> String {
        
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
    
    private func resolve(callbackId: String, result: CallbackResult) {
        guard let (callback, timer) = callbacks[callbackId] else { return }
        callbacks[callbackId] = nil
        
        timer.cancel()
        callback(result)
    }
    
    func dispatch(callbackId: String, data: Any?, error: String?) {
        
        let result: CallbackResult
        if let error = error {
            result = .failure(.init(message: error))
        } else {
            result = .success(data)
        }
        
        OperationQueue.callback.addOperation {
            self.resolve(callbackId: callbackId, result: result)
        }
    }
}
