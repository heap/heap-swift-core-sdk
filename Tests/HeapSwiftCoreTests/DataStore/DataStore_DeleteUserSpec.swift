import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_DeleteUserSpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        describe("deleteUser") {
            
            it("doesn't delete the user if called before the user was created") {
                dataStore().deleteUser(environmentId: "11", userId: "123")
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                
                expect(dataStore().usersToUpload()).to(haveCount(1), description: "The user should be there.")
            }
            
            it("deletes the user") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().deleteUser(environmentId: "11", userId: "123")
                
                expect(dataStore().usersToUpload()).to(beEmpty(), description: "The user should have been deleted.")
            }
            
            it("deletes messages for the user") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: Date())
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().deleteUser(environmentId: "11", userId: "123")
                
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
            dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
            dataStore().deleteUser(environmentId: "11", userId: "123")
        }
        
        describe("deleteUser") {
            it("deletes the user row") {
                expect("Select 1 From Users").to(returnNoRows(in: dataStore()))
            }
            
            it("deletes the session row") {
                expect("Select 1 From Sessions").to(returnNoRows(in: dataStore()))
            }
            
            it("deletes pending message rows") {
                expect("Select 1 From PendingMessages").to(returnNoRows(in: dataStore()))
            }
            
            it("deletes user property rows") {
                expect("Select 1 From UserProperties").to(returnNoRows(in: dataStore()))
            }
        }
    }
}
