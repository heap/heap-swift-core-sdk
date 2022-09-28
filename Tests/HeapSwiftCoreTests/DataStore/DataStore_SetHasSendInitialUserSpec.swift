import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_SetHasSendInitialUserSpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("setHasSentInitialUser") {
            
            it("doesn't do anything if there is no user") {
                dataStore().setHasSentInitialUser(environmentId: "11", userId: "123")
                expect(dataStore().usersToUpload()).to(beEmpty(), description: "A user should not have been created")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                expect(dataStore().usersToUpload().first?.needsInitialUpload).to(beTrue(), description: "The user should require an upload")
            }
            
            it("marks the user as having received its initial upload") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().setHasSentInitialUser(environmentId: "11", userId: "123")

                expect(dataStore().usersToUpload()).to(equal([
                    .init(
                        environmentId: "11",
                        userId: "123",
                        identity: nil,
                        needsInitialUpload: false,
                        needsIdentityUpload: false,
                        pendingUserProperties: [:],
                        sessionIds: []
                    )
                ]))
            }
        }
    }
}
