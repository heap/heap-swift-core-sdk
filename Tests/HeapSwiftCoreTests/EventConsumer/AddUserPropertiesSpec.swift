import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class EventConsumer_AddUserPropertiesSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.addUserProperties") {

            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore>!

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(dataStore: dataStore)
            }
            
            it("doesn't do anything before `startRecording` is called") {
                
                consumer.addUserProperties(["a": 1])
                consumer.startRecording("11")
                
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                
                expect(user.pendingUserProperties).to(equal([:]), description: "Method shouldn't do anything before startRecording")
            }
            
            it("doesn't do anything after `stopRecording` is called") {
                
                consumer.startRecording("11")
                consumer.stopRecording()
                consumer.addUserProperties(["a": 1])
                consumer.startRecording("11")
                
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                
                expect(user.pendingUserProperties).to(equal([:]), description: "Method shouldn't do anything before startRecording")
            }
            
            it("adds properties to the user for upload") {
                consumer.startRecording("11")
                consumer.addUserProperties([
                    "a": 1,
                    "b": "test",
                    "c": -1,
                    "d": true,
                    "e": false,
                    "f": 100.5,
                ])

                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                
                expect(user.pendingUserProperties).to(equal([
                    "a": "1",
                    "b": "test",
                    "c": "-1",
                    "d": "true",
                    "e": "false",
                    "f": "100.5",
                ]), description: "The properties should all have been persisted to the uploadable data store")
            }
        }
    }
}
