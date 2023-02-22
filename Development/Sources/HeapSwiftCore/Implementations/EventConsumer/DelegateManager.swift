import Foundation

class DelegateManager {
    
    private let _delegateLock = DispatchSemaphore(value: 1)
    private var _sources: [String: Source] = [:]
    private var _defaultSource: Source? = nil
    private var _runtimeBridges: [RuntimeBridge] = []
    
    func addSource(_ source: Source, isDefault: Bool, timestamp: Date, currentState: State?) {
        
        let removedDefault: Source?
        let oldSource: Source?
        
        do {
            _delegateLock.wait()
            defer { _delegateLock.signal() }

            oldSource = _sources[source.name]
            
            if let oldSource = oldSource,
                ObjectIdentifier(oldSource) == ObjectIdentifier(source) {
                return // The source was already registered.
            }
            
            _sources[source.name] = source
            
            if isDefault {
                removedDefault = _defaultSource
                _defaultSource = source
            } else if _defaultSource?.name == source.name {
                removedDefault = _defaultSource
                _defaultSource = nil
            } else {
                removedDefault = nil
            }
        }
        
        if let removedDefault = removedDefault {
            if isDefault {
                HeapLogger.shared.logDev("Replaced default source \(removedDefault.name) with \(source.name).")
            } else {
                HeapLogger.shared.logDev("Removed default source \(removedDefault.name) when setting a new non-default source of the same name.")
            }
        }
        
        if let currentState = currentState {
            oldSource?.didStopRecording(complete: {})
            
            source.didStartRecording(options: currentState.options, complete: {})
            
            onMainThread {
                source.sessionDidStart(sessionId: currentState.sessionInfo.id, timestamp: timestamp, foregrounded: Event.AppVisibility.current == .foregrounded, complete: {})
            }
        }
    }
    
    func removeSource(_ name: String, currentState: State?) {
        
        let oldSource: Source?
        
        do {
            _delegateLock.wait()
            defer { _delegateLock.signal() }

            oldSource = _sources[name]
            
            _sources[name] = nil
            
            if _defaultSource?.name == name {
                _defaultSource = nil
            }
        }
        
        if currentState != nil {
            oldSource?.didStopRecording(complete: {})
        }
    }
    
    func addRuntimeBridge(_ bridge: RuntimeBridge, timestamp: Date, currentState: State?) {
        do {
            _delegateLock.wait()
            defer { _delegateLock.signal() }
            
            // Don't insert the same bridge twice.
            guard !_runtimeBridges.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(bridge) })
            else { return }
            
            _runtimeBridges.append(bridge)
        }
        
        if let currentState = currentState {
            bridge.didStartRecording(options: currentState.options, complete: {})
            
            onMainThread {
                bridge.sessionDidStart(sessionId: currentState.sessionInfo.id, timestamp: timestamp, foregrounded: Event.AppVisibility.current == .foregrounded, complete: {})
            }
        }
    }
    
    func removeRuntimeBridge(_ bridge: RuntimeBridge, currentState: State?) {
        
        do {
            _delegateLock.wait()
            defer { _delegateLock.signal() }
            
            guard let index = _runtimeBridges.firstIndex(where: { ObjectIdentifier($0) == ObjectIdentifier(bridge) })
            else { return }
            
            _runtimeBridges.remove(at: index)
        }
        
        if currentState != nil {
            bridge.didStopRecording(complete: {})
        }
    }
    
    typealias Snapshot = (sources: [String: Source], defaultSource: Source?, runtimeBridges: [RuntimeBridge])
    
    var current: Snapshot {
        _delegateLock.wait()
        defer { _delegateLock.signal() }
        return (_sources, _defaultSource, _runtimeBridges)
    }
}
