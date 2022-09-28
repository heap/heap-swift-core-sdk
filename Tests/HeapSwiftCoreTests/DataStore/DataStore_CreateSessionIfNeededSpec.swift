import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_CreateSessionIfNeededSpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("createSessionIfNeeded") {
            
            it("doesn't create a session if there is no user") {
                dataStore().createSessionIfNeeded(with: .init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                expect(dataStore().usersToUpload()).to(beEmpty(), description: "A user should not have been created")
            }
            
            it("creates a session if none exists") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: .init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                expect(dataStore().usersToUpload().first?.sessionIds).to(equal(["456"]), description: "The session should have been created")
            }
            
            it("inserts a session message for the new session") {
                let message = Message(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456"))
                let encodedMessage = try message.serializedData()
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: message)
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload))
                    .to(equal([encodedMessage]), description: "The encoded message should have been inserted into the session")
            }
            
            it("doesn't create a duplicate session if called multiple times") {
                let message = Message(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456"))
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: message)
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(equal(["456"]), description: "PRECONDITION: THe session wasn't created")
                
                dataStore().createSessionIfNeeded(with: message)
                dataStore().createSessionIfNeeded(with: message)
                dataStore().createSessionIfNeeded(with: message)

                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(equal(["456"]), description: "Only one session should have been created")
            }
            
            it("doesn't create a duplicate messages if called multiple times") {
                let message = Message(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456"))
                let encodedMessage = try message.serializedData()
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: message)
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload))
                    .to(equal([encodedMessage]), description: "PRECONDITION: The encoded message should have been inserted into the session")

                dataStore().createSessionIfNeeded(with: message)
                dataStore().createSessionIfNeeded(with: message)
                dataStore().createSessionIfNeeded(with: message)

                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload))
                    .to(equal([encodedMessage]), description: "No additional messages should have been added")
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        describe("createSessionIfNeeded") {
            it("doesn't insert a session if there is no user") {
                dataStore().createSessionIfNeeded(with: .init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                
                expect("Select 1 From Sessions").to(returnNoRows(in: dataStore()))
            }
            
            it("doesn't insert a message if there is no user") {
                dataStore().createSessionIfNeeded(with: .init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                
                expect("Select 1 From PendingMessages").to(returnNoRows(in: dataStore()))
            }
        }
    }
}
