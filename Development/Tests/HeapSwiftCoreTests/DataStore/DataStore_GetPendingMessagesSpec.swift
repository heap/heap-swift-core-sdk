import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DataStore_GetPendingMessagesSpec: DataStoreSpec {
    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("getPendingEncodedMessages") {
            
            var fakeSession: FakeSession!
            
            beforeEach {
                fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
            }
            
            it("doesn't return anything if there's no session") {
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max))
                    .to(beEmpty(), description: "There shouldn't be any messages")
            }
            
            it("returns message in order") {
                // This is a duplicate of a `insertPendingMessages` test.
                
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                var messages = [
                    try fakeSession.sessionMessage.serializedData(),
                    try fakeSession.pageviewMessage.serializedData(),
                ]
                
                for i in 0..<10 {
                    let eventMessage = fakeSession.customEventMessage(name: "event-\(i)")
                    dataStore().insertPendingMessage(eventMessage)
                    messages.append(try eventMessage.serializedData())
                }
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload)).to(equal(messages), description: "The messages should have been inserted in order")
            }
            
            it("returns messages in order, even if some were inserted after deletion") {
                // Sqlite has the option to reuse identifiers and may insert data into the index where
                // previously freed data was living.  Let's just confirm we have the right order here.
                
                // Create a bunch of messages to be delete.
                
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                for i in 0..<100 {
                    let eventMessage = fakeSession.customEventMessage(name: "event-\(i)")
                    dataStore().insertPendingMessage(eventMessage)
                }
                
                // Get all of their identifiers.
                
                let firstIdentifiers = dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.identifier)
                
                // Create 100 more messages.

                var preservedMessages: [Data] = []

                for i in 100..<200 {
                    let eventMessage = fakeSession.customEventMessage(name: "event-\(i)")
                    dataStore().insertPendingMessage(eventMessage)
                    preservedMessages.append(try eventMessage.serializedData())
                }
                
                // Delete all but the 100 latest messages.
                
                dataStore().deleteSentMessages(Set(firstIdentifiers))
                
                // Create 100 more messages. There's now freed identifier empty memory.
                
                for i in 200..<300 {
                    let eventMessage = fakeSession.customEventMessage(name: "event-\(i)")
                    dataStore().insertPendingMessage(eventMessage)
                    preservedMessages.append(try eventMessage.serializedData())
                }
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.payload))
                    .to(satisfyAllOf([
                        haveCount(200),
                        equal(preservedMessages),
                    ]), description: "There should be 200 messages in order")
            }
            
            context("the messages in queue exceed the byte count limit") {
                
                beforeEach {
                    dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                    dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                    dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "event"))
                }
                
                it("returns messages only up to the byte limit") {
                    
                    // Enough for the first two messages, but not three.
                    let byteLimit = try fakeSession.sessionMessage.serializedData().count + fakeSession.pageviewMessage.serializedData().count + 1
                    
                    expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: byteLimit))
                        .to(haveCount(2), description: "Only the first two messages should have fit")
                }
                
                it("returns one message if the first message exceeds the limit") {
                    expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: 1))
                        .to(haveCount(1), description: "Exactly one message should have been returned")
                }
            }
            
            context("the messages in queue exceed the message count limit") {
                
                beforeEach {
                    dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                    dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                    dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "event"))
                }
                
                it("returns messages only up to the count limit") {
                    expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: 2, byteLimit: .max))
                        .to(haveCount(2), description: "Exactly two messages should have been returned")
                }
            }
        }
    }
}
