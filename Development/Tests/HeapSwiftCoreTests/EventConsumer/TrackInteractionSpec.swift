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
        
        func node(_ interactionNode: InteractionNode) -> ElementNode { interactionNode.node(with: .default) }
        
        beforeEach {
            
            testNode = InteractionNode(nodeName: "TestNode")
            testNodesA = (0..<10).map({ InteractionNode(nodeName: "A-\($0)") })
            testNodesB = (0..<10).map({ InteractionNode(nodeName: "B-\($0)") })
            testNodesC = (0..<10).map({ InteractionNode(nodeName: "C-\($0)") })
            testNodesD = (0..<10).map({ InteractionNode(nodeName: "D-\($0)") })
            
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)

            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
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
            
            // TODO: it("starts a session if Heap is recording but the first session has not started")
            
            it("starts a new session if the session has expired") {
                
                consumer.startRecording("11", with: [:])
                let (sessionTimestamp, originalSessionId) = consumer.ensureSessionExistsUsingTrack()
                
                consumer.trackInteraction(interaction: .touch, nodes: testNodesA, timestamp: sessionTimestamp.addingTimeInterval(3000))
                expect(consumer.activeOrExpiredSessionId).notTo(equal(originalSessionId))
            }
            
            context("Heap is recording") {
                
                var sessionTimestamp: Date!
                var originalSessionId: String?
                var pageview: Pageview!
                
                beforeEach {
                    sessionTimestamp = Date()
                    consumer.startRecording("11", timestamp: sessionTimestamp)
                    pageview = consumer.trackPageview(.with({ $0.title = "page 1" }), timestamp: sessionTimestamp)
                    originalSessionId = consumer.activeOrExpiredSessionId
                }
                
                it("tracks interactions") {
                    
                    consumer.trackInteraction(interaction: .custom("custom"),   nodes: testNodesA,  callbackName:"callbackA", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .touch,              nodes: testNodesB,  callbackName:"callbackB", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .change,             nodes: testNodesC,  callbackName:"callbackC", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .click,              nodes: testNodesD,  callbackName:"callbackD", timestamp: sessionTimestamp, pageview: pageview)
                    consumer.trackInteraction(interaction: .custom("empty"),    nodes: [],          callbackName:nil,         timestamp: sessionTimestamp, pageview: pageview)
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    
                    
                    let messages = try dataStore.assertExactPendingMessagesCount(for: user, sessionId: originalSessionId, count: 8)
                    messages[3].expectInteractionEventMessage(user: user, interaction: .custom("custom"),   nodes: testNodesA.map(node),  callbackName: "callbackA", pageviewMessage: messages[2])
                    messages[4].expectInteractionEventMessage(user: user, interaction: .builtin(.touch),    nodes: testNodesB.map(node),  callbackName: "callbackB", pageviewMessage: messages[2])
                    messages[5].expectInteractionEventMessage(user: user, interaction: .builtin(.change),   nodes: testNodesC.map(node),  callbackName: "callbackC", pageviewMessage: messages[2])
                    messages[6].expectInteractionEventMessage(user: user, interaction: .builtin(.click),    nodes: testNodesD.map(node),  callbackName: "callbackD", pageviewMessage: messages[2])
                    messages[7].expectInteractionEventMessage(user: user, interaction: .custom("empty"),    nodes: [],                    callbackName: nil,         pageviewMessage: messages[2])
                }
                
                it("adds interaction events to pending messages only when ready") {
                    
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
                    messages[3].expectInteractionEventMessage(user: user, interaction: .builtin(.click),  nodes: testNodesD.map(node), callbackName: "callbackD", pageviewMessage: messages[2])
                }
                
                it ("preserves node data") {
                    
                    // Populate Test Node Data
                    testNode.nodeText = "fooText"
                    testNode.nodeId = "fooID"
                    testNode.nodeHtmlClass = "a b c"
                    testNode.href = "/example.html"
                    testNode.accessibilityLabel = "fooAL"
                    testNode.referencingPropertyName = "A.b"
                    testNode.attributes = ["fooAttributeKey": "fooAttributeValue"]
                    
                    consumer.trackInteraction(interaction: .click, nodes: [testNode])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    guard
                        let node = try dataStore.getPendingMessages(for: user, sessionId: originalSessionId).last?.event.interaction.nodes.first
                    else { throw TestFailure("PRECONDITION: Could not get node") }
                    
                    expect(node.nodeName).to(equal("TestNode"))
                    expect(node.nodeText).to(equal("fooText"))
                    expect(node.nodeID).to(equal("fooID"))
                    expect(node.nodeHtmlClass).to(equal("a b c"))
                    expect(node.href).to(equal("/example.html"))
                    expect(node.accessibilityLabel).to(equal("fooAL"))
                    expect(node.referencingPropertyName).to(equal("A.b"))
                    
                    expect(node.attributes["fooAttributeKey"]).to(equal(.init(value: "fooAttributeValue")))
                }
                
                it("truncates nodeText") {
                    let value = String(repeating: "あ", count: 65)
                    let expectedValue = String(repeating: "あ", count: 64)
                    testNode.nodeText = value
                    
                    consumer.trackInteraction(interaction: .click, nodes: [testNode])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    guard
                        let node = try dataStore.getPendingMessages(for: user, sessionId: originalSessionId).last?.event.interaction.nodes.first
                    else { throw TestFailure("PRECONDITION: Could not get node") }
                    
                    expect(node.nodeText).to(equal(expectedValue))
                }
                
                it("truncates accessibilityLabel") {
                    let value = String(repeating: "あ", count: 65)
                    let expectedValue = String(repeating: "あ", count: 64)
                    testNode.accessibilityLabel = value
                    
                    consumer.trackInteraction(interaction: .click, nodes: [testNode])
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    guard
                        let node = try dataStore.getPendingMessages(for: user, sessionId: originalSessionId).last?.event.interaction.nodes.first
                    else { throw TestFailure("PRECONDITION: Could not get node") }
                    
                    expect(node.accessibilityLabel).to(equal(expectedValue))
                }
            }
            
            context("field options are set") {
                
                beforeEach {
                    testNode.nodeText = "fooText"
                    testNode.accessibilityLabel = "fooAL"
                    testNode.referencingPropertyName = "A.b"
                }
                
                func track(nodes: [InteractionNode], with options: [Option: Any]) throws -> [ElementNode] {
                    
                    consumer.startRecording("11", with: options)
                    consumer.trackInteraction(interaction: .click, nodes: nodes)
                    
                    let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                    guard let interaction = try dataStore.getPendingMessagesInOnlySession(for: user).last?.event.interaction,
                          interaction.kind == .builtin(.click),
                          interaction.nodes.count > 0
                    else { throw TestFailure("PRECONDITION: Could not get nodes for last event.") }
                    
                    return interaction.nodes
                }
                
                func trackTestNode(with options: [Option: Any]) throws -> ElementNode {
                    try track(nodes: [testNode], with: options)[0]
                }
                
                it("erases accessibilityLabel on commit given option disableInteractionAccessibilityLabelCapture") {
                    
                    let node = try trackTestNode(with: [
                        .disableInteractionAccessibilityLabelCapture: true,
                    ])
                    
                    expect(node.hasAccessibilityLabel).to(beFalse())
                    expect(node.hasNodeText).to(beTrue())
                    expect(node.hasReferencingPropertyName).to(beTrue())
                }
                
                it("erases nodeText on commit given option disableInteractionTextCapture") {
                    
                    let node = try trackTestNode(with: [
                        .disableInteractionTextCapture: true,
                    ])
                    
                    expect(node.hasNodeText).to(beFalse())
                    expect(node.hasAccessibilityLabel).to(beTrue())
                    expect(node.hasReferencingPropertyName).to(beTrue())
                }
                
                it("erases referencingPropertyName on commit given option disableInteractionReferencingPropertyCapture") {
                    
                    let node = try trackTestNode(with: [
                        .disableInteractionReferencingPropertyCapture: true,
                    ])
                    
                    expect(node.hasReferencingPropertyName).to(beFalse())
                    expect(node.hasNodeText).to(beTrue())
                    expect(node.hasAccessibilityLabel).to(beTrue())
                }
                
                it("limits node hierarchy to 30 if no option is given") {
                    
                    let testNodes = (0..<100).map { InteractionNode(nodeName: "TestNode_\($0)") }
                    let nodes = try track(nodes: testNodes, with: [:])
                    expect(nodes).to(haveCount(30))
                }
                
                it("limits node hierarchy to the given limit") {
                    
                    let testNodes = (0..<100).map { InteractionNode(nodeName: "TestNode_\($0)") }
                    let nodes = try track(nodes: testNodes, with: [
                        .interactionHierarchyCaptureLimit: 9,
                    ])
                    expect(nodes).to(haveCount(9))
                }
            }
        }
    }
}

