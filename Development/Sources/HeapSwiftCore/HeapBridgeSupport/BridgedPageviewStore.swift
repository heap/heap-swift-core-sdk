import Foundation

class BridgedPageviewStore {
    
    let maxSize: Int
    let numberToPruneWhenPruning: Int
    
    init(maxSize: Int = 100, numberToPruneWhenPruning: Int = 20) {
        self.maxSize = maxSize
        self.numberToPruneWhenPruning = numberToPruneWhenPruning
    }
    
    private let _lock = DispatchSemaphore(value: 1)
    private var _pageviews: [String: (pageview: Pageview, lastUsedDate: Date)] = [:]
    
    func add(_ pageview: Pageview, at pageviewKey: String) -> [String] {
        
        _lock.wait()
        defer { _lock.signal() }
        
        _pageviews[pageviewKey] = (pageview, Date())
        
        if _pageviews.count <= maxSize {
            return []
        }
        
        let keysToRemove = _pageviews
            .map({ ($0.key, $0.value.lastUsedDate) })
            .sorted(by: { $0.1 < $1.1 })
            .prefix(numberToPruneWhenPruning)
            .map(\.0)
        
        for key in keysToRemove {
            _pageviews[key] = nil
        }
        
        return keysToRemove
    }
    
    func remove(_ deadKeys: [String]) -> [String] {
        
        _lock.wait()
        defer { _lock.signal() }
        
        for key in deadKeys {
            _pageviews[key] = nil
        }

        return deadKeys
    }
    
    func get(_ pageviewKey: String) -> Pageview? {
        
        _lock.wait()
        defer { _lock.signal() }
        
        guard let (pageview, _) = _pageviews[pageviewKey] else { return nil }
        _pageviews[pageviewKey] = (pageview, Date())

        return pageview
    }
    
    var keys: Set<String> {
        _lock.wait()
        defer { _lock.signal() }
        
        return Set(_pageviews.keys)
    }
}
