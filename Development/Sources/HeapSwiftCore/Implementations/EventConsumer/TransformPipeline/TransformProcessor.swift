/// This class manages the transformation of a single message.
///
/// When `execute` is called, the first transformer from the list is executed, moving on to each
/// subsequent transformer as they complete or time out.  Upon completion, any callbacks added
/// are executed.  If a callback is added after the transformation completes, it is immediately
/// executed.
class TransformProcessor {
    
    static let callbackStore: CallbackStore<Transformable> = .init()
    
    struct State {
        var transformable: Transformable
        var remainingTransformers: [Transformer]
        var phase: TransformPhase = .early
        var executing = false
        var callbacks: [(Transformable) -> Void] = []
    }
    
    private enum Action {
        case doNothing
        case signalCompletion([(Transformable) -> Void], Transformable)
        case startTransformer(Transformer, Transformable)
    }

    var state: Lockable<State>
    
    init(transformable: Transformable, transformers: [Transformer]) {
        self.state = .init(initial: .init(transformable: transformable, remainingTransformers: transformers))
    }
    
    func execute() {
        execute(abortIfExecuting: true, newValue: nil)
    }
    
    /// Executes the next transformer, either from `execute` or `handle` (result).
    private func execute(abortIfExecuting: Bool, newValue: Transformable?) {
        
        perform(state.mutate { data in
            if data.executing && abortIfExecuting { return .doNothing }
            
            if let newValue = newValue {
                data.transformable = newValue
            }
            
            if data.remainingTransformers.isEmpty {
                data.executing = false
                let callbacks = data.callbacks
                data.callbacks.removeAll()
                return .signalCompletion(callbacks, data.transformable)
            }
            
            // Pause until the state advances.
            if data.remainingTransformers[0].phase.rawValue > data.phase.rawValue {
                assertionFailure("Phase functionality not built yet.")
            }
            
            data.executing = true
            return .startTransformer(data.remainingTransformers.removeFirst(), data.transformable)
        })
    }
    
    func addCallback(_ callback: @escaping (_ transformable: Transformable) -> Void) {
        perform(state.mutate { data in
            if !data.executing && data.remainingTransformers.isEmpty {
                return .signalCompletion([callback], data.transformable)
            } else {
                data.callbacks.append(callback)
                return .doNothing
            }
        })
        
    }
    
    private func perform(_ action: Action) {
        switch action {
        case .doNothing:
            break
        case .signalCompletion(let callbacks, let transformable):
            for callback in callbacks {
                callback(transformable)
            }
        case .startTransformer(let transformer, let transformable):
            let callbackId = TransformProcessor.callbackStore.add(timeout: transformer.timeout) { self.handle($0) }
            
            if let event = transformable as? TransformableEvent {
                transformer.transform(event) { TransformProcessor.callbackStore.handleTransformResult(callbackId: callbackId, result: $0) }
            } else {
                TransformProcessor.callbackStore.failure(callbackId: callbackId, error: "Unknown transformable type: \(type(of: transformable))")
            }
        }
    }
    
    private func handle(_ result: CallbackResult<Transformable>) {
        
        let newValue: Transformable?
        switch result {
        case .success(let transformable):
            newValue = transformable
        case .failure(let error):
            HeapLogger.shared.trace("Skipping transform that failed with the following error: \(error.message)")
            newValue = nil
        }
        
        execute(abortIfExecuting: false, newValue: newValue)
    }
}

fileprivate extension CallbackStore<Transformable> {
    func handleTransformResult<U: Transformable>(callbackId: String, result: TransformResult<U>) {
        switch result {
        case .continue(let result):
            self.success(callbackId: callbackId, data: result)
        @unknown default:
            // This is not technically possible since we always link to a specific version of HeapSwiftCoreInterfaces.
            self.failure(callbackId: callbackId, error: "Unknown continuation")
        }
    }
}
