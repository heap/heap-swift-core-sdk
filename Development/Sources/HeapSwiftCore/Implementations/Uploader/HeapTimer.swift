import Foundation

class HeapTimer {
    private(set) var isRunning: Bool = false
    private var source: DispatchSourceTimer?
    private weak var queue: OperationQueue?
    
    func cancel() {
        isRunning = false
        queue?.addOperation { [self] in
            source?.cancel()
            source = nil
        }
    }
    
    static func schedule(in queue: OperationQueue?, at date: Date, block: @escaping () -> Void) -> HeapTimer {
        schedule(in: queue, after: date.timeIntervalSince(Date()), block: block)
    }

    static func schedule(in queue: OperationQueue?, after delay: TimeInterval, block: @escaping () -> Void) -> HeapTimer {
        let timer = HeapTimer()
        
        let source = DispatchSource.makeTimerSource(flags: [], queue: queue?.underlyingQueue)
        source.setEventHandler {
            timer.source?.cancel()
            timer.source = nil
            timer.isRunning = false
            timer.queue?.addOperation(block)
        }
        source.schedule(deadline: .now() + .milliseconds(Int(1000 * delay)))

        timer.queue = queue
        timer.isRunning = true
        timer.source = source
        source.resume()
        
        return timer
    }
}
