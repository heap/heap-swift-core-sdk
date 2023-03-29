import Foundation
import HeapSwiftCoreInterfaces

struct PageviewResolver {
    
    static func resolvePageviewInfo(requestedPageview: Pageview?, eventSourceName: String?, timestamp: Date, delegates: DelegateManager.Snapshot, state: State, complete: @escaping (PageviewInfo) -> Void) {
        
        // None pageview is not a ConcretePageview so it needs to be handled first.
        guard requestedPageview?.isNone != true else {
            complete(state.unattributedPageviewInfo)
            return
        }
        
        guard let requestedPageview = requestedPageview as? ConcretePageview else {
            activePageviewInfoFromEventSourceOrFallback(eventSourceName: eventSourceName, timestamp: timestamp, delegates: delegates, state: state, complete: complete)
            return
        }
        
        if requestedPageview.sessionInfo == state.sessionInfo {
            complete(requestedPageview.pageviewInfo)
        } else if let bridge = requestedPageview.bridge {
            reissuePageviewInfoFromBridgeOrFallback(requestedPageview: requestedPageview, bridge: bridge, timestamp: timestamp, delegates: delegates, state: state, complete: complete)
        } else if requestedPageview.isFromBridge {
            // The pageview is from a deallocated bridge, so we shouldn't fallback to sources.
            activePageviewInfoFromDefaultSourceOrFallback(timestamp: timestamp, delegates: delegates, state: state, complete: complete)
        } else {
            reissuePageviewInfoFromPageviewSourceOrFallback(requestedPageview: requestedPageview, eventSourceName: eventSourceName, timestamp: timestamp, delegates: delegates, state: state, complete: complete)
        }
    }
    
    static func reissuePageviewInfoFromBridgeOrFallback(requestedPageview: ConcretePageview, bridge: RuntimeBridge, timestamp: Date, delegates: DelegateManager.Snapshot, state: State, complete: @escaping (PageviewInfo) -> Void) {
        
        func fallback() {
            activePageviewInfoFromDefaultSourceOrFallback(timestamp: timestamp, delegates: delegates, state: state, complete: complete)
        }
        
        bridge.reissuePageview(requestedPageview, sessionId: state.sessionInfo.id, timestamp: timestamp, complete: callbackOrFallback(complete, fallback, state))
    }
    
    static func reissuePageviewInfoFromPageviewSourceOrFallback(requestedPageview: ConcretePageview, eventSourceName: String?, timestamp: Date, delegates: DelegateManager.Snapshot, state: State, complete: @escaping (PageviewInfo) -> Void) {
        
        func fallback() {
            activePageviewInfoFromEventSourceOrFallback(eventSourceName: eventSourceName, timestamp: timestamp, delegates: delegates, state: state, complete: complete)
        }
        
        guard let sourceName = requestedPageview.sourceLibrary?.name,
              let source = delegates.sources[sourceName]
        else {
            fallback()
            return
        }
        
        source.reissuePageview(requestedPageview, sessionId: state.sessionInfo.id, timestamp: timestamp, complete: callbackOrFallback(complete, fallback, state))
    }

    
    static func activePageviewInfoFromEventSourceOrFallback(eventSourceName: String?, timestamp: Date, delegates: DelegateManager.Snapshot, state: State, complete: @escaping (PageviewInfo) -> Void) {
        
        func fallback() {
            activePageviewInfoFromDefaultSourceOrFallback(timestamp: timestamp, delegates: delegates, state: state, complete: complete)
        }
        
        guard let sourceName = eventSourceName,
              let source = delegates.sources[sourceName]
        else {
            fallback()
            return
        }
        
        source.activePageview(sessionId: state.sessionInfo.id, timestamp: timestamp, complete: callbackOrFallback(complete, fallback, state))
    }
    
    static func activePageviewInfoFromDefaultSourceOrFallback(timestamp: Date, delegates: DelegateManager.Snapshot, state: State, complete: @escaping (PageviewInfo) -> Void) {
        
        func fallback() {
            complete(state.lastPageviewInfo)
        }
        
        guard let defaultSource = delegates.defaultSource else {
            fallback()
            return
        }

        defaultSource.activePageview(sessionId: state.sessionInfo.id, timestamp: timestamp, complete: callbackOrFallback(complete, fallback, state))
    }
    
    static func callbackOrFallback(_ complete: @escaping (PageviewInfo) -> Void, _ fallback: @escaping () -> Void, _ state: State) -> (Pageview?) -> Void {
        return { pageview in
            if let pageview = pageview as? ConcretePageview, pageview.sessionInfo == state.sessionInfo {
                complete(pageview.pageviewInfo)
            } else {
                fallback()
            }
        }
    }
}
