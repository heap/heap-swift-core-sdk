import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_SetHasSentIdentitySpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("setHasSentIdentity") {
            
            it("doesn't do anything if called before the identity is set") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().setHasSentIdentity(environmentId: "11", userId: "123")
                dataStore().setIdentityIfNull(environmentId: "11", userId: "123", identity: "my-user")
                
                expect(dataStore().usersToUpload().first?.needsIdentityUpload).to(beTrue(), description: "The identity should require an upload")
            }
            
            it("marks the user as having received its initial upload") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().setIdentityIfNull(environmentId: "11", userId: "123", identity: "my-user")
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
                ]))
            }
        }
    }
}
