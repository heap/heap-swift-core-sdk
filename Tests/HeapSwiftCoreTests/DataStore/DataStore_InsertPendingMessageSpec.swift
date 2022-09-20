import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_InsertPendingMessageSpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("insertPendingMessage") {
            
            it("doesn't insert a session if there isn't one") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                expect(dataStore().usersToUpload()).toEventuallyNot(beEmpty(), description: "PRECONDITION: The user wasn't created")
                
                dataStore().insertPendingMessage(.init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).toAlways(beEmpty(), description: "A session should not have been created")
            }
            
            it("inserts a message in the queue") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.1)).toEventually(haveCount(2), description: "The message should have been inserted into the session")
            }
            
            it("inserts messages in order") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                var messages = [
                    try fakeSession.sessionMessage.serializedData(),
                    try fakeSession.pageviewMessage.serializedData(),
                ]
                
                for i in 0..<10 {
                    let eventMessage = fakeSession.customEventMessage(name: "event-\(i)")
                    dataStore().insertPendingMessage(eventMessage)
                    messages.append(try eventMessage.serializedData())
                }
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.1)).toEventually(equal(messages), description: "The messages should have been inserted in order")
            }
        }
    }
}

final class SqliteDataStore_InsertPendingMessageSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: SqliteDataStore! = nil
        var fakeSession: FakeSession! = nil

        beforeEach {
            dataStore = .temporary()
            fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
            dataStore.createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
        }
        
        afterEach {
            dataStore.deleteDatabase(complete: { _ in })
        }
        
        describe("SqliteDataStore.insertPendingMessage") {
            xit("doesn't insert a session if there isn't one") {
                dataStore.insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
                // TODO: Implement
            }
            
            xit("doesn't insert a message if there is no session") {
                dataStore.insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
                // TODO: Implement
            }
            
            xit("advances the session last message date if the message time is greater") {
                dataStore.createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore.insertPendingMessage(fakeSession.customEventMessage(name: "my-event", timestamp: fakeSession.sessionMessage.time.date.addingTimeInterval(100)))
                // TODO: Implement

            }
            
            xit("doesn't advance the session last message date if the message time is less") {
                dataStore.createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore.insertPendingMessage(fakeSession.customEventMessage(name: "my-event", timestamp: fakeSession.sessionMessage.time.date.addingTimeInterval(-100)))
                // TODO: Implement
            }
        }
    }
}
