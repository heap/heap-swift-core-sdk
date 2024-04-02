import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

public func beVersionChange(file: StaticString = #file, line: UInt = #line, _ expected: VersionChange? = nil) -> Nimble.Predicate<CoreSdk_V1_Event.OneOf_Kind> {
    .init { actualExpression in
        
        let msg = ExpectationMessage.expectedActualValueTo("be a version change")
        
        // Let nil into the expression so this works on non-events.
        let actualValue = try actualExpression.evaluate()
        
        switch actualValue {
        case .versionChange(let actualVersionChange):
            if let expected = expected, expected != actualVersionChange {
                return .init(status: .doesNotMatch, message: msg.appended(message: "with value \(expected)"))
            } else {
                return .init(status: .matches, message: msg)
            }
        default:
            return .init(status: .doesNotMatch, message: msg)
        }
    }
}

final class EventConsumer_VersionChangeSpec: HeapSpec {
    
    override func spec() {
        
        var trackTimestamp: Date!
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!

        beforeEach {
            trackTimestamp = Date()
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }

        describe("EventConsumer") {
            
            it("does not start session on startRecording") {
                consumer.startRecording("11")

                expect(consumer.getSessionId()).to(beNil())
                let user = try dataStore.assertOnlyOneUserToUpload()
                expect(user.sessionIds).to(beEmpty())
            }
            
            it("does not track a message on startRecording when resuming a previous session") {
                let environment = dataStore.applyPreviousSession(to: "11", expirationDate: Date().addingTimeInterval(60))
                consumer.startRecording("11", with: [ .resumePreviousSession: true ])

                let user = try dataStore.assertOnlyOneUserToUpload()
                try dataStore.assertSession(for: user, sessionId: environment.sessionInfo.id, hasPostStartMessageCount: 0)
            }
            
            it("sends a version change event when the session is created") {
                consumer.startRecording("11")
                consumer.track("event")
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                
                expect(messages[2].event.kind).to(beVersionChange())
            }
            
            it("sends a version change event when the session is resumed") {
                _ = dataStore.applyPreviousSession(to: "11", expirationDate: Date().addingTimeInterval(60))
                consumer.startRecording("11", with: [ .resumePreviousSession: true ])
                consumer.track("event")
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 2)
                
                expect(messages[0].event.kind).to(beVersionChange())
            }
            
            it("sends a version change event when the session is created with ") {
                consumer.startRecording("11", with: [ .startSessionImmediately: true ])
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                
                expect(messages[2].event.kind).to(beVersionChange())
            }
            
            it("sends a version change event when the session is resumed") {
                _ = dataStore.applyPreviousSession(to: "11", expirationDate: Date().addingTimeInterval(60))
                consumer.startRecording("11", with: [ .resumePreviousSession: true, .startSessionImmediately: true ])
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 1)
                
                expect(messages[0].event.kind).to(beVersionChange())
            }
            
            it("does not send a version change event message if the version has not changed") {
                let applicationInfo = SDKInfo.withoutAdvertiserId.applicationInfo
                _ = dataStore.applyApplicationInfo(to: "11", applicationInfo: applicationInfo)
                consumer.startRecording("11")

                consumer.track("event", timestamp:  trackTimestamp)
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                
                for message in messages {
                    expect(message.event.kind).notTo(beVersionChange())
                }
            }
            
            it("sends a version change event message if there is no previous version recorded") {
                consumer.startRecording("11")

                consumer.track("event", timestamp: trackTimestamp)
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                
                let versionChange = VersionChange.with {
                    $0.currentVersion = SDKInfo.withoutAdvertiserId.applicationInfo
                }
                expect(messages[2].event.kind).to(beVersionChange(versionChange))
                messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
            }
            
            it("sends a version change event message if the app version has changed") {
                var applicationInfo = SDKInfo.withoutAdvertiserId.applicationInfo
                applicationInfo.versionString = "100.0"
                _ = dataStore.applyApplicationInfo(to: "11", applicationInfo: applicationInfo)
                consumer.startRecording("11")
      
                consumer.track("event", timestamp: trackTimestamp)
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                
                let versionChange = VersionChange.with {
                    $0.previousVersion = applicationInfo
                    $0.currentVersion = SDKInfo.withoutAdvertiserId.applicationInfo
                }
                expect(messages[2].event.kind).to(beVersionChange(versionChange))
                messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
            }
            
            it("sends a version change event message if the app name has changed") {
                var applicationInfo = SDKInfo.withoutAdvertiserId.applicationInfo
                applicationInfo.name = "New Name"
                _ = dataStore.applyApplicationInfo(to: "11", applicationInfo: applicationInfo)
                consumer.startRecording("11")
      
                consumer.track("event", timestamp: trackTimestamp)
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                
                let versionChange = VersionChange.with {
                    $0.previousVersion = applicationInfo
                    $0.currentVersion = SDKInfo.withoutAdvertiserId.applicationInfo
                }
                expect(messages[2].event.kind).to(beVersionChange(versionChange))
                messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
            }
            
            it("sends a version change event message if the app identifier has changed") {
                var applicationInfo = SDKInfo.withoutAdvertiserId.applicationInfo
                applicationInfo.identifier = "New Identifier"
                _ = dataStore.applyApplicationInfo(to: "11", applicationInfo: applicationInfo)
                consumer.startRecording("11")
      
                consumer.track("event", timestamp: trackTimestamp)
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 4)
                
                let versionChange = VersionChange.with {
                    $0.previousVersion = applicationInfo
                    $0.currentVersion = SDKInfo.withoutAdvertiserId.applicationInfo
                }
                expect(messages[2].event.kind).to(beVersionChange(versionChange))
                messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
            }
        }
    }
}
