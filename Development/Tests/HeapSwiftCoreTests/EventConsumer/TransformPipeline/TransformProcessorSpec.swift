import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class TransformProcessorSpec: HeapSpec {
    
    override func spec() {
        
        describe("TransformPipeline.execute") {
            context("with transformers") {
                var transformerA: TriggerableTransformer!
                var transformerB: TriggerableTransformer!
                var transformerC: TriggerableTransformer!
                var event: TransformableEvent!
                var processor: TransformProcessor!
                
                beforeEach {
                    transformerA = TriggerableTransformer(name: "A", timeout: 0.1)
                    transformerB = TriggerableTransformer(name: "B", timeout: 0.1)
                    transformerC = TriggerableTransformer(name: "C", timeout: 0.1)
                    event = TransformableEvent(environmentId: "1", userId: "2", sessionId: "3", timestamp: Date(timeIntervalSinceReferenceDate: 0))
                    processor = TransformProcessor(
                        transformable: event,
                        transformableDescription: "my message",
                        transformers: [transformerA, transformerB, transformerC]
                    )
                    processor.execute()
                }
                
                afterEach {
                    for transformer in [transformerA, transformerB, transformerC] {
                        for (event, callback) in transformer!.receivedTransforms {
                            callback(.continue(event))
                        }
                    }
                }
                
                it("kicks off processing") {
                    expect(processor.state.current.executing).to(beTrue())
                }
                
                it("triggers the first transformer") {
                    expect(transformerA.receivedTransforms).notTo(beEmpty())
                    expect(transformerA.receivedTransforms.first?.0).to(equal(event))
                }
                
                it("does not immediately trigger subsequent transformers") {
                    expect(transformerB.receivedTransforms).to(beEmpty())
                    expect(transformerC.receivedTransforms).to(beEmpty())
                }
                
                it("advances to the second after the first times out") {
                    expect(transformerB.receivedTransforms).toEventuallyNot(beEmpty())
                    expect(transformerB.receivedTransforms.first?.0).to(equal(event))
                }
                
                it("advances to the second after the first resolves") {
                    guard let (event, callback) = transformerA.receivedTransforms.first else {
                        throw TestFailure("PRECONDITION: Transformer A didn't receive an event")
                    }
                    let transformedEvent = event.applying(sessionReplay: "A")
                    callback(.continue(transformedEvent))
                    OperationQueue.callback.waitUntilAllOperationsAreFinished()
                    
                    expect(transformerB.receivedTransforms).toNot(beEmpty())
                    expect(transformerB.receivedTransforms.first?.0).to(equal(transformedEvent))
                }
                
                it("only calls the second transformer once after resolution") {
                    guard let (event, callback) = transformerA.receivedTransforms.first else {
                        throw TestFailure("PRECONDITION: Transformer A didn't receive an event")
                    }
                    let transformedEvent = event.applying(sessionReplay: "A")
                    callback(.continue(transformedEvent))
                    callback(.continue(event.applying(sessionReplay: "B")))
                    callback(.continue(event.applying(sessionReplay: "C")))
                    OperationQueue.callback.waitUntilAllOperationsAreFinished()
                    
                    expect(transformerB.receivedTransforms).to(haveCount(1))
                    expect(transformerB.receivedTransforms.first?.0).to(equal(transformedEvent))
                }
                
                it("eventually resolves through timeouts if none of the transforms are called") {
                    var result: Transformable?
                    processor.addCallback { result = $0 }
                    expect(result as? TransformableEvent).toEventually(equal(event))
                }
                
                it("resolves through completion of the transforms") {
                    var result: Transformable?
                    processor.addCallback { result = $0 }
                    
                    for transformer in [transformerA, transformerB, transformerC] {
                        guard let (event, callback) = transformer!.receivedTransforms.first else {
                            throw TestFailure("PRECONDITION: Transformer \(transformer!.name) didn't receive an event")
                        }
                        let transformedEvent = event.applying(sessionReplay: transformer!.name)
                        callback(.continue(transformedEvent))
                        OperationQueue.callback.waitUntilAllOperationsAreFinished()
                    }
                    
                    expect((result as? TransformableEvent)?.sessionReplays).toEventually(equal(["A", "B", "C"]))
                }
            }
            
            context("without transformers") {
                
                var event: TransformableEvent!
                var processor: TransformProcessor!
                
                beforeEach {
                    event = TransformableEvent(environmentId: "1", userId: "2", sessionId: "3", timestamp: Date(timeIntervalSinceReferenceDate: 0))
                    processor = TransformProcessor(transformable: event, transformableDescription: "my message", transformers: [])
                }
                        
                it("does not put the event in the executing state") {
                    processor.execute()
                    expect(processor.state.current.executing).to(beFalse())
                }

                it("triggers the callback when added after") {
                    var result: Transformable?
                    processor.execute()
                    processor.addCallback { result = $0 }
                    expect((result as? TransformableEvent)).toEventually(equal(event))
                }

                it("triggers the callback when added before") {
                    var result: Transformable?
                    processor.addCallback { result = $0 }
                    processor.execute()
                    expect((result as? TransformableEvent)).toEventually(equal(event))
                }
            }
        }
    }
}

extension TransformableEvent {
    func applying(sessionReplay: String? = nil, contentsquareProperties: ContentsquareProperties? = nil) -> Self {
        var output = self
        if let sessionReplay = sessionReplay {
            output.sessionReplays.append(sessionReplay)
        }
        if let contentsquareProperties = contentsquareProperties {
            output.contentsquareProperties = contentsquareProperties
        }
        return output
    }
}
