import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

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
            
            it("does not send a version change event message if the version has not changed") {
                let applicationInfo = SDKInfo.withoutAdvertiserId.applicationInfo
                _ = dataStore.applyApplicationInfo(to: "11", applicationInfo: applicationInfo)
                consumer.startRecording("11")

                consumer.track("event", timestamp:  trackTimestamp)
                
                let user = try dataStore.assertOnlyOneUserToUpload()
                let messages = try dataStore.assertExactPendingMessagesCountInOnlySession(for: user, count: 3)
                
                for message in messages {
                    if case .versionChange(_) = message.event.kind {
                        throw TestFailure("Unexpected version change event message found.")
                    }
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
                expect(messages[2].event.kind).to(equal(.versionChange(versionChange)))
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
                expect(messages[2].event.kind).to(equal(.versionChange(versionChange)))
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
                expect(messages[2].event.kind).to(equal(.versionChange(versionChange)))
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
                expect(messages[2].event.kind).to(equal(.versionChange(versionChange)))
                messages[2].expectEventMessage(user: user, timestamp: trackTimestamp, eventProperties: consumer.eventProperties, pageviewMessage: messages[1])
            }
        }
    }
}
