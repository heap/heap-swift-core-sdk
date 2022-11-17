import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DataStore_DeleteSentMessagesSpec: DataStoreSpec {
    
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        describe("deleteSentMessages") {
            
            func getMessageIds() -> [MessageIdentifier] {
                dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "", messageLimit: .max, byteLimit: .max).map(\.identifier)
            }
            
            beforeEach {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                for i in 0..<10 {
                    let eventMessage = fakeSession.customEventMessage(name: "event-\(i)")
                    dataStore().insertPendingMessage(eventMessage)
                }
            }
            
            it("doesn't delete anything if called with a non-existant identifier") {
                
                let allIds = getMessageIds()
                let unknownId = (getMessageIds().max() ?? 0) + 1
                
                dataStore().deleteSentMessages([unknownId])
                expect(getMessageIds()).to(equal(allIds), description: "No message should have been deleted")
            }
            
            it("it deletes the passed in message ids") {
                
                let allIds = getMessageIds()
                let midpoint = allIds.count / 2
                let deletedIds = allIds[..<midpoint]
                let intactIds = allIds[midpoint...]
                
                dataStore().deleteSentMessages(Set(deletedIds))
                expect(getMessageIds()).to(equal(Array(intactIds)), description: "Just the ids that were passed in should have been deleted.")
            }
        }
    }
}
