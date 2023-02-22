import Foundation

/// An asyncronous wrapper around `Operation`, providing `startAsync`, `cancelAsync`, and `finish` methods for implementing behavior.
class AsynchronousOperation: Operation {
    final override var isAsynchronous: Bool { true }
    
    /// A backing property for `isCancelled` which emits KVO events when set.
    private var _isCancelled: Bool = false {
        willSet {
            willChangeValue(forKey: "isCancelled")
        }
        didSet {
            didChangeValue(forKey: "isCancelled")
        }
    }
    
    /// A backing property for `isExecuting` which emits KVO events when set.
    private var _isExecuting: Bool = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    /// A backing property for `isFinished` which emits KVO events when set.
    private var _isFinished: Bool = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    final override var isCancelled: Bool {
        get { _isCancelled }
    }
    
    final override var isExecuting: Bool {
        get { _isExecuting }
    }
    
    final override var isFinished: Bool {
        get { _isFinished }
    }
    
    final override func cancel() {
        guard !isFinished else { return }
        _isCancelled = true
        cancelAsync()
    }
    
    final override func start() {
        _isExecuting = true
        startAsync()
    }
    
    /// Starts the asynchronous work that will be executed by the operation.
    ///
    /// Override this method to start work that will eventually call `finish()` on completion.
    ///
    /// - Important: This method must be overridden by the implementing class and must call
    ///              `finish()` upon completion of work.
    open func startAsync() {
        preconditionFailure("`startAsync` must be overridden the implementing class")
    }
    
    /// Called when the operation is cancelled.
    ///
    /// Override this method to perform any cancellation of work, if possible.
    ///
    /// - Important: This method does not stop any work, but instead gives the operation an
    ///              opportunity to stop it.
    open func cancelAsync() {}
    
    /// Notifies the operation queue that the task has been completed.
    ///
    /// - Important: This function must be called if `startAsync` has ever been called.
    open func finish() {
        _isFinished = true
        _isExecuting = false
    }
}
