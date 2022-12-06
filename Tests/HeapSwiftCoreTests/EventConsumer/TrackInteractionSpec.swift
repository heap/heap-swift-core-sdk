import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_TrackInteractionSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var testNode: InteractionNode!
        var testNodesA: [InteractionNode] = []
        var testNodesB: [InteractionNode] = []
        var testNodesC: [InteractionNode] = []
        var testNodesD: [InteractionNode] = []
        
        beforeEach {
            
            testNode = InteractionNode(nodeName: "TestNode")
            testNodesA = (0..<10).map({ InteractionNode(nodeName: "A-\($0)") })
            testNodesB = (0..<10).map({ InteractionNode(nodeName: "B-\($0)") })
            testNodesC = (0..<10).map({ InteractionNode(nodeName: "C-\($0)") })
            testNodesD = (0..<10).map({ InteractionNode(nodeName: "D-\($0)") })
            
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)

            HeapLogger.shared.logLevel = .debug
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .prod
        }
        
        describe("EventConsumer.trackInteraction") {
            
            it("doesn't track an interaction before `startRecording` is called") {
                
                for _ in 1...10 {
                    consumer.trackInteraction(interaction: .touch, nodes: [testNode])
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 2)
            }
            
            it("doesn't track an interaction after `stopRecording` is called") {
                
                consumer.startRecording("11")
                consumer.stopRecording()

                for _ in 1...10 {
                    consumer.trackInteraction(interaction: .touch, nodes: [testNode])
                }
                
                consumer.startRecording("11")

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                for sessionId in user.sessionIds {
                    try dataStore.assertExactPendingMessagesCount(for: user, sessionId: sessionId, count: 2)
                }
            }

            context("Heap is recording") {

                var sessionTimestamp: Date!
                var originalSessionId: String?
                var pageview: Pageview!
                
                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", timestamp: sessionTimestamp)
                    originalSessionId = consumer.activeOrExpiredSessionId
                    pageview = consumer.trackPageview(.with({ $0.title = "page 1" }), timestamp: sessionTimestamp)
                }
                
                it ("tracks interactions") {

                    consumer.trackInteraction(interaction: .custom("custom"),   nodes: testNodesA,  callbackName:"callbackA", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .touch,              nodes: testNodesB,  callbackName:"callbackB", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .change,             nodes: testNodesC,  callbackName:"callbackC", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .click,              nodes: testNodesD,  callbackName:"callbackD", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .custom("empty"),    nodes: [],          callbackName:nil,         timestamp: sessionTimestamp, pageview: pageview)
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")

                    let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: originalSessionId, count: 8)
                    messages[3].expectInteractionEventMessage(user: user, interaction: .custom("custom"),   nodes: testNodesA.map(\.node),  callbackName: "callbackA", pageviewMessage: messages[2])
                    messages[4].expectInteractionEventMessage(user: user, interaction: .builtin(.touch),    nodes: testNodesB.map(\.node),  callbackName: "callbackB", pageviewMessage: messages[2])
                    messages[5].expectInteractionEventMessage(user: user, interaction: .builtin(.change),   nodes: testNodesC.map(\.node),  callbackName: "callbackC", pageviewMessage: messages[2])
                    messages[6].expectInteractionEventMessage(user: user, interaction: .builtin(.click),    nodes: testNodesD.map(\.node),  callbackName: "callbackD", pageviewMessage: messages[2])
                    messages[7].expectInteractionEventMessage(user: user, interaction: .custom("empty"),    nodes: [],                      callbackName: nil,         pageviewMessage: messages[2])
                }
                
                it ("adds interaction events to pending messages only when ready") {

                    guard let interactionEvent = consumer.uncommittedInteractionEvent(timestamp: sessionTimestamp, sourceInfo: nil, pageview: pageview)
                    else { throw TestFailure("Could not create interactionEvent") }
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    try dataStore.assertExactPendingMessagesCount(for: user, sessionId: originalSessionId, count: 3)
                    
                    // Not yet ready for commit
                    interactionEvent.kind = .click
                    interactionEvent.callbackName = "callbackD"
                    interactionEvent.commit()
                    
                    try dataStore.assertExactPendingMessagesCount(for: user, sessionId: originalSessionId, count: 3)
                    
                    // Add nodes, making it ready to commit
                    interactionEvent.nodes = testNodesD
                    interactionEvent.commit()
                    
                    // Test that a duplicate commit does not fire
                    interactionEvent.commit()
                    
                    let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: originalSessionId, count: 4)
                    messages[3].expectInteractionEventMessage(user: user, interaction: .builtin(.click),  nodes: testNodesD.map(\.node), callbackName: "callbackD", pageviewMessage: messages[2])
                }
                
                it ("preserves node data") {
                    guard let interactionEvent = consumer.uncommittedInteractionEvent(timestamp: sessionTimestamp, sourceInfo: nil, pageview: pageview)
                    else { throw TestFailure("Could not create interactionEvent") }

                    // Populate Test Node Data
                    testNode.nodeText = "fooText"
                    testNode.id = "fooID"
                    testNode.accessibilityIdentifier = "fooAID"
                    testNode.accessibilityLabel = "fooAL"
                    testNode.sourceProperties = ["fooPropertyKey": "fooValue"]
                    testNode.attributes = ["fooAttributeKey": "fooAttributeValue"]
                    testNode.boundingBox = CGRect(x: 11, y: 15, width: 55, height: 88)
                       
                    interactionEvent.kind = .click
                    interactionEvent.nodes = [testNode]
                    interactionEvent.commit()
                    
                    expect(testNode.node.nodeName).to(equal("TestNode"))
                    expect(testNode.node.nodeText).to(equal("fooText"))
                    expect(testNode.node.id).to(equal("fooID"))
                    expect(testNode.node.accessibilityIdentifier).to(equal("fooAID"))
                    expect(testNode.node.accessibilityLabel).to(equal("fooAL"))
                    
                    expect(testNode.node.sourceProperties["fooPropertyKey"]).to(equal(.init(value: "fooValue")))
                    expect(testNode.node.attributes["fooAttributeKey"]).to(equal(.init(value: "fooAttributeValue")))
                    expect(testNode.node.boundingBox.position.x).to(equal(11))
                    expect(testNode.node.boundingBox.position.y).to(equal(15))
                    expect(testNode.node.boundingBox.size.width).to(equal(55))
                    expect(testNode.node.boundingBox.size.height).to(equal(88))
                }
            }
        }
    }
}

