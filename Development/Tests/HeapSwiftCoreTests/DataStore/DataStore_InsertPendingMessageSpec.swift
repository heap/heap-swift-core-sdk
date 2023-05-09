import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class DataStore_InsertPendingMessageSpec: DataStoreSpec {

    override func spec<DataStore>(dataStore: @escaping () -> DataStore) where DataStore : DataStoreProtocol {
        
        describe("insertPendingMessage") {
            
            it("doesn't insert a session if there isn't one") {
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                expect(dataStore().usersToUpload()).toNot(beEmpty(), description: "PRECONDITION: The user wasn't created")
                
                dataStore().insertPendingMessage(.init(forSessionIn: .init(environmentId: "11", userId: "123", sessionId: "456")))
                expect(dataStore().usersToUpload().flatMap(\.sessionIds)).to(beEmpty(), description: "A session should not have been created")
            }
            
            it("inserts a message in the queue") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                dataStore().insertPendingMessage(fakeSession.pageviewMessage)
                
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.1)).to(haveCount(2), description: "The message should have been inserted into the session")
            }
            
            it("inserts messages in order") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: Date())
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
            
            it("doesn't insert messages in the queue that exceed the byte limit") {
                let fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
                let timestamp = fakeSession.sessionMessage.time.date
                dataStore().createNewUserIfNeeded(environmentId: "11", userId: "123", identity: nil, creationDate: timestamp)
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                
                // Compute the number of properties that can fit under the limit
                let targetSizeInBytes = dataStore().dataStoreSettings.messageByteLimit
                let maxKeySize = 512
                let maxValueSize = 1024
                let skeletonSize = try fakeSession.customEventMessage(name: "skeleton-event",
                                                                      properties: [:],
                                                                      timestamp: timestamp).serializedData().count
                
                let value = Value(value: String(repeating: "v", count: maxValueSize))
                let propertySize = try fakeSession.customEventMessage(name: "property-event",
                                                                      properties: [String(repeating: "k", count: maxKeySize):value],
                                                                      timestamp: timestamp).serializedData().count - skeletonSize
                
                let totalProperties = (targetSizeInBytes - skeletonSize) / (propertySize)
                
                
                // Create those properties
                var properties: [String: Value] = [:]
                
                for i in 0..<totalProperties {
                    let identifierSize = "\(i)".count
                    let keyBase = String(repeating: "k", count: maxKeySize - identifierSize)
                    let key = "\(keyBase)\(i)"
                    properties[key] = value
                }
                
                // This message should be within the size limits and get added
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event-under",
                                                                                properties: properties,
                                                                                timestamp: timestamp))
                
                // Session + first pending message
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.1)).to(haveCount(2))
                
                // Add overflow key
                properties[String(repeating: "o", count: maxKeySize)] = value
                
                // This message should be too big to add
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event-over",
                                                                                properties: properties,
                                                                                timestamp: timestamp))
                
                // Session + first pending message (second excluded)
                expect(dataStore().getPendingEncodedMessages(environmentId: "11", userId: "123", sessionId: "456", messageLimit: .max, byteLimit: .max).map(\.1)).to(haveCount(2))
            }
        }
    }
    
    override func sqliteSpec(dataStore: @escaping () -> SqliteDataStore) {
        
        var fakeSession: FakeSession! = nil

        beforeEach {
            fakeSession = FakeSession(environmentId: "11", userId: "123", sessionId: "456")
        }
        
        describe("insertPendingMessage") {
            it("doesn't insert a session if there isn't one") {
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
                
                expect("Select 1 From Sessions").to(returnNoRows(in: dataStore()))
            }
            
            it("doesn't insert a message if there is no session") {
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
                
                expect("Select 1 From PendingMessages").to(returnNoRows(in: dataStore()))
            }
            
            it("advances the session last message date if the message time is greater") {
                let sessionTimestamp = fakeSession.sessionMessage.time.date
                let eventTimestamp = sessionTimestamp.addingTimeInterval(100)
                
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event", timestamp: eventTimestamp))
                
                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select lastEventDate From Sessions") { row in
                        expect(row.date(at: 0)).to(beCloseTo(eventTimestamp, within: 1))
                    }
                }
            }
            
            it("doesn't advance the session last message date if the message time is less") {
                let sessionTimestamp = fakeSession.sessionMessage.time.date
                let eventTimestamp = sessionTimestamp.addingTimeInterval(-100)
                
                dataStore().createSessionIfNeeded(with: fakeSession.sessionMessage)
                dataStore().insertPendingMessage(fakeSession.customEventMessage(name: "my-event", timestamp: eventTimestamp))
                
                dataStore().performOnSqliteQueue(waitUntilFinished: true) { connection in
                    try connection.perform(query: "Select lastEventDate From Sessions") { row in
                        expect(row.date(at: 0)).to(beCloseTo(sessionTimestamp, within: 1))
                    }
                }
            }
        }
    }
}
