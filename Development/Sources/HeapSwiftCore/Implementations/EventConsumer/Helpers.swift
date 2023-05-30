import Foundation

func generateRandomHeapId() -> String {
    String(UInt64.random(in: 0...0x1FFFFFFFFFFFFF))
}

extension Date {
    func advancedBySessionExpirationTimeout() -> Date {
        return addingTimeInterval(60 * 5)
    }
    
    func advancedByHeapJsSessionExpirationTimeout() -> Date {
        return addingTimeInterval(60 * 30)
    }
}

func onMainThread(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}
