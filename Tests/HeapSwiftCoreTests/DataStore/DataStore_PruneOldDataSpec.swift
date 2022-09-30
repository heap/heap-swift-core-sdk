import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_PruneOldDataSpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("pruneOldData") {
            
            var deletionDate: Date!
            var keepingDate: Date!
            
            beforeEach {
                let timestamp = Date()
                deletionDate = timestamp.addingTimeInterval(2)
                keepingDate = timestamp.addingTimeInterval(-2)

                let fakeActiveSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456", timestamp: timestamp)
                let fakeInactiveSession = FakeSession(environmentId: "12", userId: "234", sessionId: "567", timestamp: timestamp)
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore().createSessionIfNeeded(with: fakeActiveSession.sessionMessage)
                
                dataStore().createNewUserIfNeeded(environmentId: "12", userId: "234", identity: nil, creationDate: timestamp)
                dataStore().createSessionIfNeeded(with: fakeInactiveSession.sessionMessage)
            }
            
            it("doesn't purge the active session") {
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: keepingDate)
                
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(contain("456"), description: "The active session should not be deleted")
            }
            
            it("doesn't purge sessions with the last event after minLastMessageDate") {
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(contain("567"), description: "Sessions with recent content should not be deleted")
            }
            
            it("purges sessions with the last event before minLastMessageDate") {
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: keepingDate)
                
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).toNot(contain("567"), description: "Old sessions should be deleted")
            }
            
            it("doesn't purge the active session even if it has no messages") {
                let messageIdentifiers = dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.identifier)
                dataStore().deleteSentMessages(Set(messageIdentifiers))
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(contain("456"), description: "The active session should not be deleted")
            }
            
            it("purges sessions with no messages") {
                let messageIdentifiers = dataStore().getPendingEncodedMessages(environmentId: "12", userId: "234", sessionId: "567", messageLimit: .max, byteLimit: .max).map(\.identifier)
                dataStore().deleteSentMessages(Set(messageIdentifiers))
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).toNot(contain("567"), description: "Empty sessions should be deleted")
            }
            
            it("does not delete the active user, even if there's no pending data") {
                dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")
                dataStore().setHasSentInitialUser(environmentId: "11", userId: "123")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: deletionDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("123"), description: "The active user should not have been deleted")
            }
            
            it("does not delete recent users who have a pending identity") {
                dataStore().deleteSession(environmentId: "12", userId: "234", sessionId: "567")
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().setIdentityIfNull(environmentId: "12", userId: "234", identity: "my-user")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("234"), description: "The user should not have been deleted")
            }
            
            it("does not delete recent users who have pending properties") {
                dataStore().deleteSession(environmentId: "12", userId: "234", sessionId: "567")
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().insertOrUpdateUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("234"), description: "The user should not have been deleted")
            }
            
            it("does not delete recent users who have recent pending messages") {
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().insertOrUpdateUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("234"), description: "The user should not have been deleted")
            }
            
            it("purges unidentified users who do not have pending data, regardless of creation date") {
                dataStore().deleteSession(environmentId: "12", userId: "234", sessionId: "567")
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().insertOrUpdateUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                dataStore().setHasSentUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).toNot(contain("234"), description: "The sent user should have been deleted")
            }
            
            it("purges identified users who do not have pending data, regardless of creation date") {
                dataStore().deleteSession(environmentId: "12", userId: "234", sessionId: "567")
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().setIdentityIfNull(environmentId: "12", userId: "234", identity: "my-user")
                dataStore().setHasSentIdentity(environmentId: "12", userId: "234")
                dataStore().insertOrUpdateUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                dataStore().setHasSentUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).toNot(contain("234"), description: "The sent user should have been deleted")
            }
            
            it("purges users who only had pending messages, but the session was older than `minLastMessageDate`") {
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().setIdentityIfNull(environmentId: "12", userId: "234", identity: "my-user")
                dataStore().setHasSentIdentity(environmentId: "12", userId: "234")
                dataStore().insertOrUpdateUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                dataStore().setHasSentUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).toNot(contain("234"), description: "The sent user should have been deleted")
            }
            
            it("purges users who only had an empty session") {
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                dataStore().setIdentityIfNull(environmentId: "12", userId: "234", identity: "my-user")
                dataStore().setHasSentIdentity(environmentId: "12", userId: "234")
                dataStore().insertOrUpdateUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                dataStore().setHasSentUserProperty(environmentId: "12", userId: "234", name: "foo", value: "bar")
                
                let messageIdentifiers = dataStore().getPendingEncodedMessages(environmentId: "12", userId: "234", sessionId: "567", messageLimit: .max, byteLimit: .max).map(\.identifier)
                dataStore().deleteSentMessages(Set(messageIdentifiers))
                
                dump(dataStore().usersToUpload())

                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: keepingDate)
                expect(dataStore().usersToUpload().map(\.userId)).toNot(contain("234"), description: "The sent user should have been deleted")
            }
            
            it("doesn't delete an unset active user that hasn't sent initial data, even if it was created a long time ago") {
                dataStore().deleteSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: deletionDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("123"), description: "The active user should not have been deleted")
            }
            
            it("doesn't delete an unsent active user that has unsent messages, even if it was created a long time ago") {
                dataStore().setHasSentInitialUser(environmentId: "11", userId: "123")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: deletionDate, minUserCreationDate: deletionDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("123"), description: "The active user should not have been deleted")
            }
            
            it("doesn't delete old users with send initial data who have unsent messages") {
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: deletionDate)
                expect(dataStore().usersToUpload().map(\.userId)).to(contain("234"), description: "The active user should not have been deleted")
            }
            
            it("deletes old users who have unsent initial data") {
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: deletionDate)
                expect(dataStore().usersToUpload().map(\.userId)).toNot(contain("234"), description: "The user should have been deleted")
            }
            
            it("deletes old users who have no messages") {
                dataStore().deleteSession(environmentId: "12", userId: "234", sessionId: "567")
                dataStore().setHasSentInitialUser(environmentId: "12", userId: "234")
                
                dataStore().pruneOldData(activeEnvironmentId: "11", activeUserId: "123", activeSessionId: "456", minLastMessageDate: keepingDate, minUserCreationDate: deletionDate)
                expect(dataStore().usersToUpload().map(\.userId)).toNot(contain("234"), description: "The user should have been deleted")
            }
        }
    }
}
