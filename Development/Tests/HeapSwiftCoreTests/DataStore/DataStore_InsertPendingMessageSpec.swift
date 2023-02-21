import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DataStore_InsertPendingMessageSpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("insertPendingMessage") {
            
            it("doesn't insert a session if there isn't one") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                expect(dataStore().usersToUpload()).toNot(beEmpty(), description: "PRECONDITION: The user wasn't created")
                
                dataStore().insertPendingMessage(.init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(beEmpty(), description: "A session should not have been created")
            }
            
            it("inserts a message in the queue") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.1)).to(haveCount(2), description: "The message should have been inserted into the session")
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
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload)).to(equal(messages), description: "The messages should have been inserted in order")
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        var fakeSession: FakeSession! = nil

        beforeEach {
            fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
        }
        
        describe("insertPendingMessage") {
            it("doesn't insert a session if there isn't one") {
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
                
                expect("Select 1 From Sessions").to(returnNoRows(in: dataStore()))
            }
            
            it("doesn't insert a message if there is no session") {
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
                
                expect("Select 1 From PendingMessages").to(returnNoRows(in: dataStore()))
            }
            
            it("advances the session last message date if the message time is greater") {
                let sessionTimestamp = fakeSession.sessionMessage.time.date
                let eventTimestamp = sessionTimestamp.addingTimeInterval(100)
                
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event", timestamp: eventTimestamp))
                
                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select lastEventDate From Sessions") { row in
                        expect(row.date(at: 0)).to(beCloseTo(eventTimestamp, within: 1))
                    }
                }
            }
            
            it("doesn't advance the session last message date if the message time is less") {
                let sessionTimestamp = fakeSession.sessionMessage.time.date
                let eventTimestamp = sessionTimestamp.addingTimeInterval(-100)
                
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event", timestamp: eventTimestamp))
                
                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select lastEventDate From Sessions") { row in
                        expect(row.date(at: 0)).to(beCloseTo(sessionTimestamp, within: 1))
                    }
                }
            }
        }
    }
}
