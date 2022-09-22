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
        References Users (environmentId, userId, sessionId)
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
        And hasSentIdentity = 0
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
        And hasSentIdentity = 0
""", parameters: [identity, environmentId, userId])
        }
    }

    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String) {
    }

    func createSessionIfNeeded(with message: Message) {
    }

    func insertPendingMessage(_ message: Message) {
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
            // TODO: Fetch properties and sessions.
        }
        
        return usersToUpload
    }

    func getPendingEncodedMessages(environmentId: String, userId: String, sessionId: String, messageLimit: Int, byteLimit: Int) -> [(MessageIdentifier, Data)] {
        return []
    }

    func setHasSentInitialUser(environmentId: String, userId: String) {
    }

    func setHasSentIdentity(environmentId: String, userId: String) {
    }

    func setHasSentUserProperty(environmentId: String, userId: String, name: String, value: String) {
    }

    func deleteSentMessages(_ identifiers: Set<MessageIdentifier>) {
    }

    func deleteUser(environmentId: String, userId: String) {
    }

    func deleteSession(environmentId: String, userId: String, sessionId: String) {
    }

    func pruneOldData(activeEnvironmentId: String, activeUserId: String, activeSessionId: String, minLastMessageDate: Date, minUserCreationDate: Date, currentDate: Date) {
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
