import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_SetHasSentUserPropertySpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("insertOrUpdateUserProperty") {
            
            it("doesn't mark a property as sent if called before the property exists") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().setHasSentUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "hello", value: "world")

                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal([
                    "foo": "bar",
                    "hello": "world",
                ]), description: "The property should still be pending")
            }
            
            it("doesn't mark a property as sent if the value is different") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "hello", value: "world")
                dataStore().setHasSentUserProperty(environmentId: "11", userId: "123", name: "foo", value: "something else")
                
                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal([
                    "foo": "bar",
                    "hello": "world",
                ]), description: "The property should still be pending")
            }
            
            it("marks the property as sent") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "hello", value: "world")
                dataStore().setHasSentUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                
                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal([
                    "hello": "world",
                ]), description: "The property should have been sent")
            }
        }
    }
}
