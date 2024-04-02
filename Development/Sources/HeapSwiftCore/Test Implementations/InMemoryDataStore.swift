import Foundation
import HeapSwiftCoreInterfaces

enum InMemoryError: Error {
    case userNotFound
    case sessionNotFound
}

struct InMemoryEnvironment {
    let id: String
    var users: [String: InMemoryUser] = [:]
}

struct InMemoryUser {
    let id: String
    var identity: String?
    let creationDate: Date
    var hasUserBeenSent: Bool = false
    var hasIdentityBeenSent: Bool = false

    var userProperties: [String: (value: String, uploaded: Bool)] = [:]

    var sessions: [String: InMemorySession] = [:]
}

struct InMemorySession {
    let id: String
    var lastEventDate: Date
    var messages: [(identifier: Int, payload: Data)] = []
}

class InMemoryDataStore: StateStoreProtocol, DataStoreProtocol {

    var identifier = 0
    let dataStoreSettings: DataStoreSettings
        
    init(settings: DataStoreSettings = .default) {
        dataStoreSettings = settings
    }
    
    func nextIdentifier() -> Int {
        identifier += 1
        return identifier
    }

    var environmentStates: [String: EnvironmentState] = [:]

    func loadState(for environmentId: String) -> EnvironmentState {
        OperationQueue.inMemoryDataStore.addOperationAndWait { [self] in
            if let state = environmentStates[environmentId] {
                return state
            }
            
            var state = EnvironmentState()
            state.envID = environmentId
            return state
        }
    }

    func save(_ environmentState: EnvironmentState) {
        OperationQueue.inMemoryDataStore.addOperation {
            self.environmentStates[environmentState.envID] = environmentState
        }
    }

    var environments: [String: InMemoryEnvironment] = [:]

    private func with(environmentId: String, _ block: (inout InMemoryEnvironment) throws -> Void) rethrows {
        var environment = environments[environmentId] ?? InMemoryEnvironment(id: environmentId)
        try block(&environment)
        environments[environmentId] = environment
    }

    private func with(environmentId: String, userId: String, _ block: (inout InMemoryUser) throws -> Void) throws {
        try with(environmentId: environmentId) {

            guard var user = $0.users[userId] else {
                throw InMemoryError.userNotFound
            }

            try block(&user)
            $0.users[userId] = user
        }
    }

    private func with(environmentId: String, userId: String, sessionId: String, _ block: (inout InMemorySession) throws -> Void) throws {
        try with(environmentId: environmentId, userId: userId) {

            guard var session = $0.sessions[sessionId] else {
                throw InMemoryError.sessionNotFound
            }

            try block(&session)
            $0.sessions[sessionId] = session
        }
    }

    func createNewUserIfNeeded(environmentId: String, userId: String, identity: String?, creationDate: Date) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            with(environmentId: environmentId) {
                if $0.users[userId] == nil {
                    $0.users[userId] = .init(id: userId, identity: identity, creationDate: creationDate)
                } else if identity != nil && $0.users[userId]?.identity == nil {
                    $0.users[userId]?.identity = identity
                }
            }}
    }

    func setIdentityIfNull(environmentId: String, userId: String, identity: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId) {
                    if $0.identity == nil {
                        $0.identity = identity
                    }
                }
            } catch {
                HeapLogger.shared.error("Unexpected error in setIdentityIfNull: \(error)")
            }
        }
    }

    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId) {
                    if $0.userProperties[name]?.value != value {
                        $0.userProperties[name] = (value, false)
                    }
                }
            } catch {
                HeapLogger.shared.error("Unexpected error in insertOrUpdateUserProperty: \(error)")
            }
        }
    }
    
    func createSessionWithoutMessageIfNeeded(environmentId: String, userId: String, sessionId: String, lastEventDate: Date) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId, {
                    if $0.sessions[sessionId] == nil {
                        $0.sessions[sessionId] = .init(id: sessionId, lastEventDate: lastEventDate, messages: [])
                    }
                })
            } catch {
                HeapLogger.shared.error("Error in createSessionIfNeeded: \(error)")
            }
        }
    }
    
    func createSessionIfNeeded(with message: Message) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                let sessionId = message.sessionInfo.id
                var sessionInserted = false
                
                try with(environmentId: message.envID, userId: message.userID, {
                    if $0.sessions[sessionId] == nil {
                        $0.sessions[sessionId] = .init(id: sessionId, lastEventDate: message.time.date, messages: [])
                        sessionInserted = true
                    }
                })
                
                let data = try message.serializedData()
                guard sessionInserted && self.dataStoreSettings.isWithinMessageSizeLimit(data) else { return }
                
                try with(environmentId: message.envID, userId: message.userID, sessionId: message.sessionInfo.id) {
                    $0.messages.append((nextIdentifier(), data))
                }
            } catch {
                HeapLogger.shared.error("Error in createSessionIfNeeded: \(error)")
            }
        }
    }

    func insertPendingMessage(_ message: Message) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                let data = try message.serializedData()
                guard self.dataStoreSettings.isWithinMessageSizeLimit(data) else { return }
                
                try with(environmentId: message.envID, userId: message.userID, sessionId: message.sessionInfo.id) {
                    $0.messages.append((nextIdentifier(), data))
                }
            } catch {
                HeapLogger.shared.error("Error in insertPendingMessage: \(error)")
            }
        }
    }

    func usersToUpload() -> [UserToUpload] {
        OperationQueue.inMemoryDataStore.addOperationAndWait { [self] in
            environments.flatMap({ (environmentId, environment) in
                environment.users.map({ (userId, user) in
                    UserToUpload(environmentId: environmentId,
                                 userId: userId,
                                 identity: user.identity,
                                 needsInitialUpload: !user.hasUserBeenSent,
                                 needsIdentityUpload: !user.hasIdentityBeenSent && user.identity != nil,
                                 pendingUserProperties: user.userProperties.compactMapValues({ !$0.uploaded ? $0.value : nil}),
                                 sessionIds: Array(user.sessions.keys))
                })
            })
        }
    }

    func getPendingEncodedMessages(environmentId: String, userId: String, sessionId: String, messageLimit: Int, byteLimit: Int) -> [(identifier: MessageIdentifier, payload: Data)] {
        OperationQueue.inMemoryDataStore.addOperationAndWait { [self] in
            var messages: [(MessageIdentifier, Data)] = []
            
            do {
                try with(environmentId: environmentId, userId: userId, sessionId: sessionId) {
                    
                    var byteCount = 0
                    
                    messages = $0.messages.prefix(messageLimit).prefix(while: {
                        let first = byteCount == 0
                        byteCount += $0.payload.count
                        return first || byteCount < byteLimit
                    })
                }
            } catch {
                HeapLogger.shared.error("Error in getPendingEncodedMessages: \(error)")
            }
            
            return messages
        }
    }

    func setHasSentInitialUser(environmentId: String, userId: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId) {
                    $0.hasUserBeenSent = true
                }
            } catch {
                HeapLogger.shared.error("Error in setHasSentInitialUser: \(error)")
            }
        }
    }

    func setHasSentIdentity(environmentId: String, userId: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId) {
                    if $0.identity != nil {
                        $0.hasIdentityBeenSent = true
                    }
                }
            } catch {
                HeapLogger.shared.error("Error in setHasSentIdentity: \(error)")
            }
        }
    }

    func setHasSentUserProperty(environmentId: String, userId: String, name: String, value: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId) {
                    if $0.userProperties[name]?.value == value {
                        $0.userProperties[name] = (value, true)
                    }
                }
            } catch {
                HeapLogger.shared.error("Error in setHasSentUserProperty: \(error)")
            }
        }
    }

    func deleteSentMessages(_ identifiers: Set<MessageIdentifier>) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            environments = environments.mapValues({ environment in
                var environment = environment
                environment.users = environment.users.mapValues({ user in
                    var user = user
                    user.sessions = user.sessions.mapValues({ session in
                        var session = session
                        session.messages = session.messages.filter({ (identifier, index) in
                            !identifiers.contains(identifier)
                        })
                        return session
                    })
                    return user
                })
                return environment
            })
        }
    }

    func deleteUser(environmentId: String, userId: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            with(environmentId: environmentId) {
                $0.users[userId] = nil
            }
        }
    }

    func deleteSession(environmentId: String, userId: String, sessionId: String) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            do {
                try with(environmentId: environmentId, userId: userId) {
                    $0.sessions[sessionId] = nil
                }
            } catch {
                HeapLogger.shared.error("Error in setHasSentInitialUser: \(error)")
            }
        }
    }

    func pruneOldData(activeEnvironmentId: String, activeUserId: String, activeSessionId: String, minLastMessageDate: Date, minUserCreationDate: Date) {
        OperationQueue.inMemoryDataStore.addOperation { [self] in
            environments = environments.mapValues({ environment in
                var environment = environment
                environment.users = environment.users.compactMapValues({ user in
                    let isActiveUser = environment.id == activeEnvironmentId && user.id == activeUserId
                    var user = user
                    
                    user.sessions = user.sessions.filter({ (sessionId, session) in
                        if isActiveUser && sessionId == activeSessionId { return true }
                        return session.lastEventDate >= minLastMessageDate && session.messages.count > 0
                    })
                    
                    if !isActiveUser {
                        
                        if user.sessions.count == 0 && user.hasUserBeenSent && (user.identity == nil || user.hasIdentityBeenSent) && user.userProperties.filter({ !$0.value.uploaded }).count == 0 {
                            return nil
                        }
                        
                        if user.creationDate < minUserCreationDate && (user.sessions.count == 0 || !user.hasUserBeenSent) {
                            return nil
                        }
                    }
                    
                    return user
                })
                return environment
            })
        }
    }
}
