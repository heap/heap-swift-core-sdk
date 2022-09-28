import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_SetIdentityIfNullSpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("setIdentityIfNull") {
            
            it("doesn't do anything if there is no user") {
                dataStore().setIdentityIfNull(environmentId: "11", userId: "123", identity: "my-user")
                expect(dataStore().usersToUpload()).to(beEmpty(), description: "A user should not have been created")
            }
            
            it("sets the identity and marks it for upload") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().setIdentityIfNull(environmentId: "11", userId: "123", identity: "my-user")
                
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
            
            it("does not set the identity if already set") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: "my-user", creationDate: Date())
                dataStore().setHasSentIdentity(environmentId: "11", userId: "123")
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: "my-user",
                        needsInitialUpload: true,
                        needsIdentityUpload: false,
                        pendingUserProperties: [:],
                        sessionIds: []
                    )
                ]), description: "PRECONDITION: Could not configure user")
                
                dataStore().setIdentityIfNull(environmentId: "11", userId: "123", identity: "my-other-user")
                
                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: "my-user",
                        needsInitialUpload: true,
                        needsIdentityUpload: false,
                        pendingUserProperties: [:],
                        sessionIds: []
                    )
                ]), description: "User changed")
            }
        }
    }
}
