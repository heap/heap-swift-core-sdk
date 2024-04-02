import Foundation

/// An abstraction around a struct to ensure thread-safe mutation.
class Lockable<T> {
    private let _lock = DispatchSemaphore(value: 1)
    private var _data: T
    
    init(initial: T) {
        self._data = initial
    }
    
    @discardableResult func mutate<U>(_ fn: (_ data: inout T) -> U) -> U {
        _lock.wait()
        defer { _lock.signal() }
        return fn(&_data)
    }
    
    var current: T {
        _lock.wait()
        defer { _lock.signal() }
        return _data
    }
}
