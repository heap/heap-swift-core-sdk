import Foundation

extension OperationQueue {
    
    private static func createSqliteDataStoreQueue() -> OperationQueue {
        let queue = OperationQueue()
        queue.name = "io.heap.SqliteDataStore"
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    static let sqliteDataStoreQueue = createSqliteDataStoreQueue()
}

extension Operation {
    static func forSqlite(connection: SqliteConnection, block: @escaping (_ connection: SqliteConnection) throws -> Void) -> Operation {
        BlockOperation {
            do {
                try block(connection)
            } catch {
                // TODO: Need logging spec.
                print("Error occurred executing query: \(error)")
            }
        }
    }
}

class SqliteDataStore: DataStoreProtocol {
    
    private let connection: SqliteConnection
    
    func performOnSqliteQueue(waitUntilFinished: Bool = false, block: @escaping (_ connection: SqliteConnection) throws -> Void) {
        OperationQueue.sqliteDataStoreQueue.addOperations([
            .forSqlite(connection: connection, block: block),
        ], waitUntilFinished: waitUntilFinished)
    }
    
    init(databaseUrl: URL) {
        connection = SqliteConnection(at: databaseUrl)
        
        performOnSqliteQueue { connection in
            
            try connection.connect()
            
            // Sqlite does not enforce foreign keys by default.
            // See https://www.sqlite.org/foreignkeys.html#fk_enable
            try connection.perform(query: "PRAGMA foreign_keys = ON;")
            
            try connection.perform(query: """
Create Table If Not Exists Users
(
    environmentId Text,
    userId Text,
    identity Text,
    creationDate Integer,

    hasSentUser Integer Default 0,
    hasSentIdentity Integer Default 0,

    Primary Key (environmentId, userId)
);
""")
            
            try connection.perform(query: """
Create Table If Not Exists Sessions
(
    environmentId Text,
    userId Text,
    sessionId Text,

    lastEventDate Integer,

    Primary Key (environmentId, userId, sessionId),
    Foreign Key (environmentId, userId)
        References Users (environmentId, userId)
            On Delete Cascade
            On Update No Action
);
""")
            
            try connection.perform(query: """
Create Table If Not Exists PendingMessages
(
    sequenceNumber Integer Primary Key AutoIncrement,

    environmentId Text,
    userId Text,
    sessionId Text,
    payload Blob,

    Foreign Key (environmentId, userId, sessionId)
        References Sessions (environmentId, userId, sessionId)
            On Delete Cascade
            On Update No Action
);
""")
            
            try connection.perform(query: """
Create Table If Not Exists UserProperties
(
    environmentId Text,
    userId Text,
    name Text,
    value Text,
    hasBeenSent Integer Default 0,

    Primary Key (environmentId, userId, name),
    Foreign Key (environmentId, userId)
        References Users (environmentId, userId)
            On Delete Cascade
            On Update No Action
);
""")
        }
    }

    func createNewUserIfNeeded(environmentId: String, userId: String, identity: String?, creationDate: Date) {
        performOnSqliteQueue { connection in
            try connection.perform(query: """
Insert Into Users (environmentId, userId, identity, creationDate) Values (?1, ?2, ?3, ?4)
On Conflict (environmentId, userId) Do Update
    Set identity = excluded.identity
    Where
        identity Is Null
        And hasSentIdentity = 0;
""", parameters: [environmentId, userId, identity, creationDate])
        }
    }

    func setIdentityIfNull(environmentId: String, userId: String, identity: String) {
        performOnSqliteQueue { connection in
            try connection.perform(query: """
Update Users
Set identity = ?1
    Where
        environmentId = ?2
        And userId = ?3
        And identity Is Null
        And hasSentIdentity = 0;
""", parameters: [identity, environmentId, userId])
        }
    }

    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String) {
        performOnSqliteQueue { connection in
            try connection.perform(query: """
Insert Into UserProperties (environmentId, userId, name, value) Values (?1, ?2, ?3, ?4)
On Conflict (environmentId, userId, name) Do Update
    Set value = ?4,
        hasBeenSent = 0
    Where
        value <> excluded.value;
""", parameters: [environmentId, userId, name, value])
        }
    }

    func createSessionIfNeeded(with message: Message) {
        performOnSqliteQueue { connection in
            
            let environmentId = message.envID
            let userId = message.userID
            let sessionId = message.sessionInfo.id
            let lastEventDate = message.time.date
            let payload = try message.serializedData()
            
            try connection.perform(query: """
Insert Into Sessions (environmentId, userId, sessionId, lastEventDate) Values (?1, ?2, ?3, ?4);
""", parameters: [environmentId, userId, sessionId, lastEventDate])
            
            try connection.perform(query: """
Insert Into PendingMessages (environmentId, userId, sessionId, payload) Values (?1, ?2, ?3, ?4);
""", parameters: [environmentId, userId, sessionId, payload])
        }
    }

    func insertPendingMessage(_ message: Message) {
        performOnSqliteQueue { connection in
            
            let environmentId = message.envID
            let userId = message.userID
            let sessionId = message.sessionInfo.id
            let lastEventDate = message.time.date
            let payload = try message.serializedData()
            
            try connection.perform(query: """
Insert Into PendingMessages (environmentId, userId, sessionId, payload) Values (?1, ?2, ?3, ?4);
""", parameters: [environmentId, userId, sessionId, payload])
            
            try connection.perform(query: """
Update Sessions
Set lastEventDate = ?4
Where
    environmentId = ?1
    And userId = ?2
    And sessionId = ?3
    And lastEventDate < ?4;
""", parameters: [environmentId, userId, sessionId, lastEventDate])
        }
    }

    func usersToUpload() -> [UserToUpload] {
        var usersToUpload: [UserToUpload] = []
        
        performOnSqliteQueue(waitUntilFinished: true) { connection in
            try connection.perform(
                query: "Select environmentId, userId, identity, hasSentUser, hasSentIdentity From Users",
                rowCallback: { row in
                    if let environmentId = row.string(at: 0),
                       let userId = row.string(at: 1) {
                        let identity = row.string(at: 2)
                        let hasSentUser = row.bool(at: 3)
                        let hasSentIdentity = row.bool(at: 4)
                        
                        usersToUpload.append(.init(
                            environmentId: environmentId,
                            userId: userId,
                            identity: identity,
                            needsInitialUpload: !hasSentUser,
                            needsIdentityUpload: !hasSentIdentity && identity != nil
                        ))
                    }
                })
            
            try connection.perform(query: "Select environmentId, userId, name, value From UserProperties Where hasBeenSent = 0", rowCallback: { row in
                
                if let environmentId = row.string(at: 0),
                   let userId = row.string(at: 1),
                   let name = row.string(at: 2),
                   let value = row.string(at: 3) {
                    
                    // The number of users should be small so I'm not optimizing lookups.
                    usersToUpload
                        .first(where: { $0.environmentId == environmentId && $0.userId == userId })?
                        .pendingUserProperties[name] = value
                }
            })
            
            try connection.perform(query: "Select environmentId, userId, sessionId From Sessions", rowCallback: { row in
                
                if let environmentId = row.string(at: 0),
                   let userId = row.string(at: 1),
                   let sessionId = row.string(at: 2) {
                    
                    // The number of users should be small so I'm not optimizing lookups.
                    usersToUpload
                        .first(where: { $0.environmentId == environmentId && $0.userId == userId })?
                        .sessionIds.append(sessionId)
                }
            })
        }
        
        return usersToUpload
    }

    func getPendingEncodedMessages(environmentId: String, userId: String, sessionId: String, messageLimit: Int, byteLimit: Int) -> [(identifier: MessageIdentifier, payload: Data)] {
        
        var pendingMessages: [(identifier: MessageIdentifier, payload: Data)] = []
        var byteCount = 0
        
        performOnSqliteQueue(waitUntilFinished: true) { connection in
            try connection.perform(
                query: """
Select sequenceNumber, payload
From PendingMessages
Where
    environmentId = ?1
    And userId = ?2
    And sessionId = ?3
Order By 1
Limit ?4;
""",
                parameters: [environmentId, userId, sessionId, messageLimit],
                rowCallback: { row in
                    let identifier = row.int(at: 0)
                    if let payload = row.data(at: 1) {
                        
                        if byteCount > 0 && byteCount + payload.count > byteLimit {
                            throw NSError(domain: "", code: 0) // Stop processing.  Could use something better.
                        }
                        
                        pendingMessages.append((identifier: identifier, payload: payload))
                        byteCount += payload.count
                    }
                })
        }
        
        return pendingMessages
    }

    func setHasSentInitialUser(environmentId: String, userId: String) {
    }

    func setHasSentIdentity(environmentId: String, userId: String) {
    }

    func setHasSentUserProperty(environmentId: String, userId: String, name: String, value: String) {
        performOnSqliteQueue { connection in
            try connection.perform(query: """
Update UserProperties
Set hasBeenSent = 1
Where
    environmentId = ?1
    And userId = ?2
    And name = ?3
    And value = ?4;
""", parameters: [environmentId, userId, name, value])
        }
    }

    func deleteSentMessages(_ identifiers: Set<MessageIdentifier>) {
        performOnSqliteQueue { connection in
            // It may be faster here to do concatenation but I'm averse to SQL string building.
            for identifier in identifiers {
                try connection.perform(query: "Delete From PendingMessages Where sequenceNumber = ?1", parameters: [identifier])
            }
        }
        
    }

    func deleteUser(environmentId: String, userId: String) {
    }

    func deleteSession(environmentId: String, userId: String, sessionId: String) {
        
        // The foreign key causes the messages to be deleted as well.
        
        performOnSqliteQueue { connection in
            try connection.perform(query: """
Delete From Sessions
Where
    environmentId = ?1
    And userId = ?2
    And sessionId = ?3;
""", parameters: [environmentId, userId, sessionId])
        }
    }

    func pruneOldData(activeEnvironmentId: String, activeUserId: String, activeSessionId: String, minLastMessageDate: Date, minUserCreationDate: Date) {
    }

    func deleteDatabase(complete: @escaping (Result<Void, Error>) -> Void) {
        performOnSqliteQueue { connection in
            connection.close()
            do {
                try FileManager.default.removeItem(at: connection.databaseUrl)
                complete(.success(()))
            } catch {
                complete(.failure(error))
            }
        }
    }
    
    deinit {
        performOnSqliteQueue { connection in
            connection.close()
        }
    }
}
