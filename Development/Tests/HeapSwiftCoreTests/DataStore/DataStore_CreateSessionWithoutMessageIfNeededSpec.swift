import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DataStore_CreateSessionWithoutMessageIfNeededSpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("createSessionWithoutMessageIfNeeded") {
            
            it("doesn't create a session if there is no user") {
                dataStore().createSessionWithoutMessageIfNeeded(environmentId: "11", userId: "123", sessionId: "456", lastEventDate: Date())
                expect(dataStore().usersToUpload()).to(beEmpty(), description: "A user should not have been created")
            }
            
            it("creates a session if none exists") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionWithoutMessageIfNeeded(environmentId: "11", userId: "123", sessionId: "456", lastEventDate: Date())
                expect(dataStore().usersToUpload().first?.sessionIds).to(equal(["456"]), description: "The session should have been created")
            }
            
            it("inserts a session message for the new session") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionWithoutMessageIfNeeded(environmentId: "11", userId: "123", sessionId: "456", lastEventDate: Date())

                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max)).to(beEmpty())
            }
            
            it("allows messages to be inserted") {
                
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                let timestamp = fakeSession.sessionMessage.time.date
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore().createSessionWithoutMessageIfNeeded(environmentId: "11", userId: "123", sessionId: "456", lastEventDate: Date())

                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                let encodedMessage = try fakeSession.pageviewMessage.serializedData()

                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload))
                    .to(equal([encodedMessage]), description: "The encoded message should have been inserted into the session")
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        describe("createSessionWithoutMessageIfNeeded") {
            it("doesn't insert a session if there is no user") {
                dataStore().createSessionWithoutMessageIfNeeded(environmentId: "11", userId: "123", sessionId: "456", lastEventDate: Date())
                
                expect("Select 1 From Sessions").to(returnNoRows(in: dataStore()))
            }
        }
    }
}
