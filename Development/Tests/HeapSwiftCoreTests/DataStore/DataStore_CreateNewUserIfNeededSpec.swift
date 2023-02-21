import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DataStore_CreateNewUserIfNeededSpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        describe("createUserIfNeeded") {
            
            it("creates a new user") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: nil,
                        needsInitialUpload: true,
                        needsIdentityUpload: false,
                        pendingUserProperties: [:],
                        sessionIds: []
                    )
                ]))
            }
            
            it("sets the identity and marks it for upload if provided") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: Date())
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: "my-user",
                        needsInitialUpload: true,
                        needsIdentityUpload: true,
                        pendingUserProperties: [:],
                        sessionIds: []
                    )
                ]))
            }
            
            it("sets the identity on an existing user if they are not identified") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                expect(dataStore().usersToUpload()).to(haveCount(1), description: "PRECONDITION: Could not create user")

                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: Date())
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: "my-user",
                        needsInitialUpload: true,
                        needsIdentityUpload: true,
                        pendingUserProperties: [:],
                        sessionIds: []
                    )
                ]))
            }
            
            it("doesn't overwrite existing users") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: Date())
                dataStore().setHasSentInitialUser(environmentId: "11", userId: "123")
                dataStore().setHasSentIdentity(environmentId: "11", userId: "123")
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop", value: "val")
                dataStore().createSessionIfNeeded(environmentId: "11", userId: "123", sessionId: "456", timestamp: Date())
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: "my-user",
                        needsInitialUpload: false,
                        needsIdentityUpload: false,
                        pendingUserProperties: ["prop": .init("val")],
                        sessionIds: ["456"]
                    )
                ]), description: "PRECONDITION: Could not configure user")
                
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-other-user", creationDate: Date())
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: "my-user",
                        needsInitialUpload: false,
                        needsIdentityUpload: false,
                        pendingUserProperties: ["prop": .init("val")],
                        sessionIds: ["456"]
                    )
                ]), description: "The user changed")
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        describe("createUserIfNeeded") {
            it("sets the creation date") {
                let creationDate = Date().addingTimeInterval(100)
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: creationDate)
                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select creationDate From Users") { row in
                        expect(row.date(at: 0)).to(beCloseTo(creationDate, within: 1))
                    }
                }
            }
            
            it("does not overwrite the creation date when setting the identity on an existing user") {
                let creationDate = Date().addingTimeInterval(100)
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: creationDate)
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: creationDate.addingTimeInterval(100))
                
                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select creationDate From Users") { row in
                        expect(row.date(at: 0)).to(beCloseTo(creationDate, within: 1))
                    }
                }
            }
            
            it("does not overwrite the creation date when called multiple times for the same user") {
                let creationDate = Date().addingTimeInterval(100)
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: creationDate)
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: creationDate.addingTimeInterval(100))
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: creationDate.addingTimeInterval(200))

                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select creationDate From Users") { row in
                        expect(row.date(at: 0)).to(beCloseTo(creationDate, within: 1))
                    }
                }
            }
        }
    }
}
