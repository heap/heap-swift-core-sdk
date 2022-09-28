import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore

final class DataStore_InsertOrUpdateUserPropertySpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("insertOrUpdateUserProperty") {
            
            it("doesn't insert the property if the user doesn't exist") {
                // Insert the property, then create the user.  The user shouldn't have the property.
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal([:]), description: "The property should not have been inserted")
            }
            
            it("queues a new property for upload") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal(["foo": "bar"]), description: "The property should have been inserted")
            }
            
            it("overwrites the property if the value if different") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal(["foo": "bar"]), description: "PRECONDITION: The property should have been inserted")
                
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "baz")
                expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal(["foo": "baz"]), description: "The property should have been overwritten")
            }

            
            context("the property has already been sent") {
                beforeEach {
                    dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                    dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                    expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal(["foo": "bar"]), description: "PRECONDITION: The property should have been inserted")
                    dataStore().setHasSentUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                    expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal([:]), description: "PRECONDITION: The property should be marked as sent")
                }
                
                it("does not requeue the same property/value pair again") {
                    dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "bar")
                    expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal([:]), description: "The property should not have been requeued")
                }
                
                it("queues the property again if the value changes") {
                    dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "foo", value: "baz")
                    expect(dataStore().usersToUpload().first?.pendingUserProperties).to(equal(["foo": "baz"]), description: "The property should have been requeued")
                }
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        describe("insertOrUpdateUserProperty") {
            it("doesn't insert a property if there is no user") {
                dataStore().insertOrUpdateUserProperty(environmentId: "11", userId: "123", name: "prop", value: "val")
                
                expect("Select 1 From UserProperties").to(returnNoRows(in: dataStore()))
            }
        }
    }
}
