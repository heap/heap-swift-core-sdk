import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

final class EventConsumer_AddUserPropertiesSpec: HeapSpec {
    
    override func spec() {
        describe("EventConsumer.addUserProperties") {

            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
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
            
            it("does not truncate properties exactly 1024 characters long") {
                
                consumer.startRecording("11")
                let value = String(repeating: "あ", count: 1024)
                let expectedValue = value
                
                consumer.addUserProperties(["a": value])
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.pendingUserProperties).to(equal(["a": expectedValue]), description: "The property value should have remain unchanged.")
            }
            
            
            it("truncates properties that are more than 1024 characters long") {
                
                consumer.startRecording("11")
                let value = String(repeating: "あ", count: 1030)
                let expectedValue = String(repeating: "あ", count: 1024)
                
                consumer.addUserProperties(["a": value])
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.pendingUserProperties).to(equal(["a": expectedValue]), description: "The property value should have been truncated.")
            }
             
            it("does not partially truncate emoji") {
                
                consumer.startRecording("11")
                let value = String(repeating: "あ", count: 1020).appending("👨‍👨‍👧‍👧")
                let expectedValue = String(repeating: "あ", count: 1020)
                
                consumer.addUserProperties(["a": value])
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.pendingUserProperties).to(equal(["a": expectedValue]), description: "The property value should have been truncated.")
                
            }
            
            it("does not partially truncate diacritics") {
                
                consumer.startRecording("11")
                let value = String(repeating: "あ", count: 1000).appending("A̶̧̨̨̡̡̼̯̯͖̖͔̗̞̣̯̲̰̞̹͎̝̱̪̬̹̰͔̹̫̙̤̞̯͓̖̣͉̻̣̙͉̰̦͔͚̔̍̍̃͌͆̎̊̈̇̽̿̕͜͠͝ͅ")
                let expectedValue = String(repeating: "あ", count: 1000)
                
                consumer.addUserProperties(["a": value])
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.pendingUserProperties).to(equal(["a": expectedValue]), description: "The property value should have been truncated.")
            }
            
            it("does not omit properties where the key is the maximum length") {
                
                consumer.startRecording("11")
                let key = String(repeating: "あ", count: 512)
                
                consumer.addUserProperties([key: "value"])
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.pendingUserProperties[key]).toNot(beNil())
            }
            
            it("omits properties where the key is above the maximum length") {
                
                consumer.startRecording("11")
                let key = String(repeating: "あ", count: 513)
                
                consumer.addUserProperties([key: "value"])
                let user = try dataStore.assertOnlyOneUserToUpload(message: "PRECONDITION: startRecording should have created a user.")
                expect(user.pendingUserProperties[key]).to(beNil())
            }
        }
    }
}
