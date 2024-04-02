import Foundation
import HeapSwiftCoreInterfaces

class PendingEvent {
    
    private var _eventMessage: Message
    private var _lock = DispatchSemaphore(value: 1)
    private var _needsAppVisibilityState: Bool = true
    private var _needsKind: Bool = true
    private var _needsPageviewInfo: Bool = true
    private var _committed: Bool = false
    private var transformPipeline: TransformPipeline
    private let transformProcessor: TransformProcessor
    
    init(partialEventMessage: Message, toBeCommittedTo transformPipeline: TransformPipeline) {
        self._eventMessage = partialEventMessage
        self.transformPipeline = transformPipeline
        self.transformProcessor = transformPipeline.processor(for: partialEventMessage)
        _needsKind = partialEventMessage.event.kind == nil
        _needsPageviewInfo = !partialEventMessage.hasPageviewInfo
        
        transformProcessor.execute()
        onMainThread {
            self.setAppVisibilityState(.current)
        }
    }
    
    func setAppVisibilityState(_ appVisibilityState: Event.AppVisibility) {
        _lock.wait()
        if _needsAppVisibilityState {
            _eventMessage.event.appVisibilityState = appVisibilityState
            _needsAppVisibilityState = false
        }
        _lock.signal()
        commitOnceIfReady()
    }
    
    func setKind(_ kind: Event.OneOf_Kind) {
        _lock.wait()
        if _needsKind {
            _eventMessage.event.kind = kind
            _needsKind = false
        }
        _lock.signal()
        commitOnceIfReady()
    }
    
    func setPageviewInfo(_ pageviewInfo: PageviewInfo) {
        _lock.wait()
        if _needsPageviewInfo {
            _eventMessage.pageviewInfo = pageviewInfo
            _needsPageviewInfo = false
        }
        _lock.signal()
        commitOnceIfReady()
    }
    
    func commitOnceIfReady() {
        _lock.wait()
        let message = !_needsAppVisibilityState && !_needsKind && !_needsPageviewInfo && !_committed ? _eventMessage : nil
        if message != nil {
            _committed = true
        }
        _lock.signal()
        
        if let message = message {
            transformPipeline.insertPendingMessage(message, processor: transformProcessor)
            HeapLogger.shared.trace("Committed event message:\n\(message)")
        }
    }
}
