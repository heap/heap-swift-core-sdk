import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_DeleteSessionSpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        describe("deleteSession") {
            
            var fakeSession: FakeSession!
            
            beforeEach {
                fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
            }
            
            it("doesn't delete the session if called before the session was created") {
                dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                expect(dataStore().usersToUpload().first?.sessionIds).to(equal(["456"]), description: "The session should be there.")
            }

            it("doesn't delete the messages if called before the session was created") {
                dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max)).to(haveCount(2), description: "The messages should still be there.")
            }

            it("deletes the session") {
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")
                
                expect(dataStore().usersToUpload().first?.sessionIds).to(beEmpty(), description: "The session should have been deleted.")
            }
            
            it("deletes messages for the user") {
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")

                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max)).to(beEmpty(), description: "The messages should have been deleted.")
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        var fakeSession: FakeSession!
        
        beforeEach {
            fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
            dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
            dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
            dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")
        }
        
        describe("deleteSession") {
            it("deletes the session row") {
                expect("Select 1 From Sessions").to(returnNoRows(in: dataStore()))
            }
            
            it("deletes pending message rows") {
                expect("Select 1 From PendingMessages").to(returnNoRows(in: dataStore()))
            }
        }
    }
}
