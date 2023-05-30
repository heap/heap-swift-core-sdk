import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapJSNotificationSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer") {
            
            var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            var restoreState: StateRestorer!
            var notificationCount = 0
            var observer: Any? = nil
            
            beforeEach {
                (_, consumer, _, _, restoreState) = prepareEventConsumerWithCountingDelegates()
                notificationCount = 0
                observer = NotificationCenter.default.addObserver(forName: HeapStateForHeapJSChangedNotification, object: nil, queue: .main, using: { _ in
                    notificationCount += 1
                })
            }
            
            afterEach {
                restoreState()
                NotificationCenter.default.removeObserver(observer!)
            }
            
            it("notifies when the session starts") {
                consumer.startRecording("11", with: [:])
                consumer.track("test")
                
                expect(notificationCount).toEventually(equal(1))
            }
            
            it("notifies when the identy is set") {
                consumer.startRecording("11", with: [:])
                consumer.track("test")
                consumer.identify("me")
                expect(notificationCount).toEventually(equal(2))
            }
            
            it("does not notify when the session doesn't start on a call that could start it") {
                consumer.startRecording("11", with: [:])
                consumer.track("test")
                expect(notificationCount).toEventually(equal(1), description: "PRECONDITION")
                
                consumer.track("test")
                expect(notificationCount).toAlways(equal(1), until: .milliseconds(100))
            }
            
            it("does not notify when the session re-identifying with the same name") {
                consumer.startRecording("11", with: [:])
                consumer.track("test")
                consumer.identify("me")
                expect(notificationCount).toEventually(equal(2), description: "PRECONDITION")
                
                consumer.identify("me")
                expect(notificationCount).toAlways(equal(2), until: .milliseconds(100))
            }
            
            // TODO: These tests can be more exhaustive, but the above should be sufficient to
            // demonstrate behavior. 🤞
        }
    }
}
