import Foundation

class TransformPipeline {
    
    struct State {
        var transformers: [Transformer] = []
    }
    
    var state: Lockable<State> = .init(initial: .init(transformers: []))
    
    private let dataStore: any DataStoreProtocol
    
    init(dataStore: any DataStoreProtocol) {
        self.dataStore = dataStore
    }
    
    func add(_ transformer: Transformer) {
        // We may eventually support additional phases. This switch is a reminder that we need to handle them.
        switch transformer.phase {
        case .early:
            state.mutate { data in
                data.transformers.append(transformer)
            }
        @unknown default:
            // This is not technically possible since we always link to a specific version of HeapSwiftCoreInterfaces.
            HeapLogger.shared.warn("Transformer \(transformer.name) added with unknown phase: \(transformer.phase)")
        }
    }
    
    var transformers: [Transformer] {
        state.current.transformers
    }
    
    func processor(environmentId: String, userId: String, sessionId: String, timestamp: Date) -> TransformProcessor {
        return TransformProcessor(
            transformable: TransformableEvent(
                environmentId: environmentId,
                userId: userId,
                sessionId: sessionId,
                timestamp: timestamp
            ),
            transformers: transformers)
    }
    
    func processor(for message: Message) -> TransformProcessor {
        return processor(environmentId: message.envID, userId: message.userID, sessionId: message.sessionInfo.id, timestamp: message.time.date)
    }
    
    func createSessionIfNeeded(with message: Message, processor: TransformProcessor? = nil) {
        transformAndCommit(message: message, isSessionMessage: true, processor: processor)
    }
    
    func insertPendingMessage(_ message: Message, processor: TransformProcessor? = nil) {
        transformAndCommit(message: message, isSessionMessage: false, processor: processor)
    }
    
    private func transformAndCommit(message: Message, isSessionMessage: Bool, processor: TransformProcessor?) {
        
        let destinationProcessor = processor ?? self.processor(for: message)
        destinationProcessor.execute() // Execute immediately so they can operate in parallel.
        
        OperationQueue.transform.addOperation(CommitAfterTransformOperation(
            message: message,
            isSessionMessage: isSessionMessage,
            transformProcessor: destinationProcessor,
            dataStore: dataStore
        ))
    }
}
