import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_GetUsersToUploadSpec: DataStoreSpec {
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("usersToUpload") {
            
            // NOTE: `usersToUpload` is tested extensively in other specs as it acts as an output
            // for the various mutating functions.
            
            it("doesn't return anything if there's no users") {
                expect(dataStore().usersToUpload()).to(beEmpty())
            }
            
            it("returns a each user that was created") {
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "345", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "12", userId: "123", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "12", userId: "345", identity: nil, creationDate: Date())
                
                expect(dataStore().usersToUpload()).to(haveCount(5), description: "Each user should be there")
            }
            
            it("stops returning users after they are deleted") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "234", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "345", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "12", userId: "123", identity: nil, creationDate: Date())
                dataStore().createNewUserIfNeeded(environmentId: "12", userId: "345", identity: nil, creationDate: Date())
                
                dataStore().deleteUser(environmentId: "11", userId: "123")
                expect(dataStore().usersToUpload()).to(haveCount(4), description: "A user should have been deleted")

                dataStore().deleteUser(environmentId: "11", userId: "234")
                expect(dataStore().usersToUpload()).to(haveCount(3), description: "A user should have been deleted")
            }
        }
    }
}
