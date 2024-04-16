/// This operation is used to ensure sequential insertion of transformed messages into the data
/// store.
///
/// When messages are sent to a transformer, it will insert this object into a serial queue,
/// ensuring that it will be inserted sequentially when the transform completes rather than
/// in the order of completion.
class CommitAfterTransformOperation: AsynchronousOperation {
    
    let message: Message
    let isSessionMessage: Bool
    let transformProcessor: TransformProcessor
    let dataStore: any DataStoreProtocol
    
    init(message: Message, isSessionMessage: Bool, transformProcessor: TransformProcessor, dataStore: any DataStoreProtocol) {
        self.message = message
        self.isSessionMessage = isSessionMessage
        self.transformProcessor = transformProcessor
        self.dataStore = dataStore
    }
    
    override func startAsync() {
        transformProcessor.execute()
        transformProcessor.addCallback { [self] transformable in
            let transformedMessage = transformable.apply(to: message)
            if isSessionMessage {
                dataStore.createSessionIfNeeded(with: transformedMessage)
                HeapLogger.shared.trace("Committed session message:\n\(transformedMessage)")
            } else {
                dataStore.insertPendingMessage(transformedMessage)
                HeapLogger.shared.trace("Committed event message:\n\(transformedMessage)")
            }
            finish()
        }
    }
}

fileprivate extension TransformableEvent {
    func apply(to message: Message) -> Message {
        var message = message
        
        if !sessionReplays.isEmpty {
            message.sessionReplay = sessionReplays.joined(separator: ";")
        }
        
        if let contentsquareProperties = contentsquareProperties {
            message.csProperties.cspid = contentsquareProperties.cspid
            message.csProperties.cspvid = contentsquareProperties.cspvid
            message.csProperties.cssn = contentsquareProperties.cssn
            message.csProperties.csts = contentsquareProperties.csts
            message.csProperties.csuu = contentsquareProperties.csuu
        }
        
        return message
    }
}

fileprivate extension Transformable {
    func apply(to message: Message) -> Message {
        
        if let event = self as? TransformableEvent {
            return event.apply(to: message)
        } else {
            return message
        }
    }
}
