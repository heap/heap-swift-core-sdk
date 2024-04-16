import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class TransformPipelineSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var pipeline: TransformPipeline!
        var transformerA: TriggerableTransformer!
        var transformerB: TriggerableTransformer!
        var transformerC: TriggerableTransformer!
        var transformer100ms: TriggerableTransformer!

        beforeEach {
            dataStore = InMemoryDataStore()
            pipeline = TransformPipeline(dataStore: dataStore)
            transformerA = TriggerableTransformer(name: "A", timeout: 1)
            transformerB = TriggerableTransformer(name: "B", timeout: 1)
            transformerC = TriggerableTransformer(name: "C", timeout: 1)
            transformer100ms = TriggerableTransformer(name: "OneHundredMS", timeout: 0.1)
        }
        
        afterEach {
            for transformer in [transformerA, transformerB, transformerC, transformer100ms] {
                for (event, callback) in transformer!.receivedTransforms {
                    callback(.continue(event))
                }
            }
        }
        
        describe("TransformPipeline.processor") {
            it("returns the a processor with the current transformers") {
                pipeline.add(transformerA)
                pipeline.add(transformerB)
                pipeline.add(transformerC)
                
                let processor = pipeline.processor(environmentId: "1", userId: "2", sessionId: "3", timestamp: Date(), transformableDescription: "my transformable")
                expect(processor.state.current.remainingTransformers.map(\.name)).to(equal(["A", "B", "C"]))
            }
            
            it("returns an processor with the correct property values") {
                let timestamp = Date(timeIntervalSinceReferenceDate: 0)
                let processor = pipeline.processor(environmentId: "1", userId: "2", sessionId: "3", timestamp: timestamp, transformableDescription: "my transformable")
                let state = processor.state.current
                let transformable = state.transformable as? TransformableEvent
                
                expect(state.transformable as? TransformableEvent).notTo(beNil())
                guard let transformable = transformable else { return }
                
                expect(transformable.environmentId).to(equal("1"))
                expect(transformable.userId).to(equal("2"))
                expect(transformable.sessionId).to(equal("3"))
                expect(transformable.timestamp).to(equal(timestamp))
                expect(transformable.sessionReplays).to(beEmpty())
                expect(transformable.contentsquareProperties).to(beNil())
            }
        }
        
        describe("TransformPipeline.createSessionIfNeeded") {
            
            beforeEach {
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
            }
            
            it("inserts the session") {
                pipeline.createSessionIfNeeded(with: .init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                expect(dataStore.usersToUpload().first?.sessionIds).toEventually(equal(["456"]))
            }
            
            it("transforms the data") {
                transformerA.applyToAll(sessionReplay: "SR", contentsquareProperties: .init(cspid: "PID", cspvid: "PVID", cssn: "SN", csts: "TS", csuu: "UU"))
                
                pipeline.add(transformerA)
                dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                pipeline.createSessionIfNeeded(with: .init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                
                expect(dataStore.usersToUpload().first?.sessionIds).toEventually(equal(["456"]))
                let messages = try dataStore.getPendingMessagesInOnlySession(for: dataStore.usersToUpload()[0])
                expect(messages).to(haveCount(1))
                expect(messages.first?.sessionReplay).to(equal("SR"))
                expect(messages.first?.csProperties).to(equal(.with({
                    $0.cspid = "PID"
                    $0.cspvid = "PVID"
                    $0.cssn = "SN"
                    $0.csts = "TS"
                    $0.csuu = "UU"
                })))
            }
            
            describe("TransformPipeline.insertPendingMessage") {
                
                var state: State!
                var user: UserToUpload!
                var message: Message!
                
                beforeEach {
                    state = .init(environmentId: "11", userId: "123", sessionId: "456")
                    dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                    dataStore.createSessionIfNeeded(with: .init(forSessionIn: state))
                    user = dataStore.usersToUpload()[0]
                    message = .init(forPageviewWith: .init(newPageviewAt: Date()), sourceLibrary: nil, in: state)
                }
                
                it("inserts the message") {
                    pipeline.insertPendingMessage(message)
                    expect(try dataStore.getPendingMessagesInOnlySession(for: user)).toEventually(haveCount(2))
                }
                
                it("transforms the data") {
                    transformerA.applyToAll(sessionReplay: "SR", contentsquareProperties: .init(cspid: "PID", cspvid: "PVID", cssn: "SN", csts: "TS", csuu: "UU"))
                    pipeline.add(transformerA)
                    
                    pipeline.insertPendingMessage(message)
                    
                    expect(try dataStore.getPendingMessagesInOnlySession(for: user)).toEventually(haveCount(2))
                    let messages = try dataStore.getPendingMessagesInOnlySession(for: user)
                    expect(messages.last?.sessionReplay).to(equal("SR"))
                    expect(messages.last?.csProperties).to(equal(.with({
                        $0.cspid = "PID"
                        $0.cspvid = "PVID"
                        $0.cssn = "SN"
                        $0.csts = "TS"
                        $0.csuu = "UU"
                    })))
                }
                
                it("works with an already completed processor") {
                    transformerA.applyToAll(sessionReplay: "SR", contentsquareProperties: .init(cspid: "PID", cspvid: "PVID", cssn: "SN", csts: "TS", csuu: "UU"))
                    pipeline.add(transformerA)
                    
                    let processor = pipeline.processor(for: message)
                    processor.execute()
                    expect(processor.state.current.executing).toEventually(beFalse())
                    
                    pipeline.insertPendingMessage(message)
                    expect(try dataStore.getPendingMessagesInOnlySession(for: user)).toEventually(haveCount(2))
                    let messages = try dataStore.getPendingMessagesInOnlySession(for: user)
                    expect(messages.last?.sessionReplay).to(equal("SR"))
                }
                
                // This verifies that the transforms execute in parallel because if they don't it will take 10 seconds to empty the queue.
                it("executes processors in parallel") {
                    pipeline.add(transformer100ms)
                    
                    for _ in 1...100 {
                        pipeline.insertPendingMessage(message)
                    }
                    
                    var done = false
                    OperationQueue.transform.addOperation { done = true }
                    expect(done).toEventually(equal(true), description: "The queue should have emptied within 1 second.")
                }
                
                it("inserts messages in order") {
                    pipeline.add(transformerA)
                    for _ in 1...10 {
                        pipeline.insertPendingMessage(message)
                    }
                    expect(transformerA.receivedTransforms).to(haveCount(10))
                    
                    let indices = (1...10).map(\.description)
                    
                    // Resolve each event with sessionReplay equal to its index, but in reverse order.
                    for ((event, callback), index) in zip(transformerA.receivedTransforms, indices).reversed() {
                        callback(.continue(event.applying(sessionReplay: index)))
                        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
                    }
                    
                    expect(try dataStore.getPendingMessagesInOnlySession(for: user)).toEventually(haveCount(11))
                    
                    let events = try dataStore.getPendingMessagesInOnlySession(for: user).suffix(10)
                    expect(events.map(\.sessionReplay)).to(equal(indices), description: "Even though they resolved in reverse order, events should have been inserted in their original order.")
                }
            }
        }
    }
}

class TriggerableTransformer: Transformer {
    let name: String
    let timeout: TimeInterval
    let phase: HeapSwiftCore.TransformPhase
    var receivedTransforms: [(TransformableEvent, (TransformResult<TransformableEvent>) -> Void)] = []
    
    private var valuesToApply: (String?, TransformableEvent.ContentsquareProperties?)? = nil
    
    init(name: String, timeout: TimeInterval, phase: HeapSwiftCore.TransformPhase = .early) {
        self.name = name
        self.timeout = timeout
        self.phase = phase
    }
    
    func transform(_ event: TransformableEvent, complete: @escaping (TransformResult<TransformableEvent>) -> Void) {
        receivedTransforms.append((event, complete))
        if let (sessionReplay, contentsquareProperties) = valuesToApply {
            complete(.continue(event.applying(sessionReplay: sessionReplay, contentsquareProperties: contentsquareProperties)))
            
        }
    }
    
    func applyToAll(sessionReplay: String? = nil, contentsquareProperties: TransformableEvent.ContentsquareProperties? = nil) {
        valuesToApply = (sessionReplay, contentsquareProperties)
        for (event, callback) in receivedTransforms {
            callback(.continue(event.applying(sessionReplay: sessionReplay, contentsquareProperties: contentsquareProperties)))
        }
    }
}
