import Foundation
@testable import HeapSwiftCore

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

class InMemoryDataStore: DataStoreProtocol {

    var identifier = 0

    func nextIdentifier() -> Int {
        identifier += 1
        return identifier
    }

    var environmentStates: [String: EnvironmentState] = [:]

    func loadState(for environmentId: String) -> EnvironmentState {

        if let state = environmentStates[environmentId] {
            return state
        }

        var state = EnvironmentState()
        state.envID = environmentId
        return state
    }

    func save(_ environmentState: EnvironmentState) {
        environmentStates[environmentState.envID] = environmentState
    }

    var environments: [String: InMemoryEnvironment] = [:]

    func with(environmentId: String, _ block: (inout InMemoryEnvironment) throws -> Void) rethrows {
        var environment = environments[environmentId] ?? InMemoryEnvironment(id: environmentId)
        try block(&environment)
        environments[environmentId] = environment
    }

    func with(environmentId: String, userId: String, _ block: (inout InMemoryUser) throws -> Void) throws {
        try with(environmentId: environmentId) {

            guard var user = $0.users[userId] else {
                throw InMemoryError.userNotFound
            }

            try block(&user)
            $0.users[userId] = user
        }
    }

    func with(environmentId: String, userId: String, sessionId: String, _ block: (inout InMemorySession) throws -> Void) throws {
        try with(environmentId: environmentId, userId: userId) {

            guard var session = $0.sessions[sessionId] else {
                throw InMemoryError.sessionNotFound
            }

            try block(&session)
            $0.sessions[sessionId] = session
        }
    }

    func createNewUserIfNeeded(environmentId: String, userId: String, identity: String?, creationDate: Date) {
        with(environmentId: environmentId) {
            if $0.users[userId] == nil {
                $0.users[userId] = .init(id: userId, identity: identity, creationDate: creationDate)
            }
        }
    }

    func setIdentityIfNull(environmentId: String, userId: String, identity: String) {
        do {
            try with(environmentId: environmentId, userId: userId) {
                if $0.identity == nil {
                    $0.identity = identity
                }
            }
        } catch {
            NSLog("Unexpected error in setIdentityIfNull: \(error)")
        }
    }

    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String) {
        do {
            try with(environmentId: environmentId, userId: userId) {
                if $0.userProperties[name]?.value != value {
                    $0.userProperties[name] = (value, false)
                }
            }
        } catch {
            NSLog("Unexpected error in insertOrUpdateUserProperty: \(error)")
        }
    }

    func createSessionIfNeeded(with message: Message) {

        do {
            let data = try message.serializedData()
            let sessionId = message.sessionInfo.id

            try with(environmentId: message.envID, userId: message.userID, {
                if $0.sessions[sessionId] == nil {
                    $0.sessions[sessionId] = .init(id: sessionId, lastEventDate: message.time.date, messages: [(nextIdentifier(), data)])
                }
            })
        } catch {
            NSLog("Error in createSessionIfNeeded: \(error)")
        }
    }

    func insertPendingMessage(_ message: Message) {

        do {
            let data = try message.serializedData()

            try with(environmentId: message.envID, userId: message.userID, sessionId: message.sessionInfo.id) {
                $0.messages.append((nextIdentifier(), data))
            }
        } catch {
            NSLog("Error in insertPendingMessage: \(error)")
        }
    }

    func usersToUpload() -> [UserToUpload] {
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

    func getPendingEncodedMessages(environmentId: String, userId: String, sessionId: String, messageLimit: Int, byteLimit: Int) -> [(MessageIdentifier, Data)] {

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
            NSLog("Error in getPendingEncodedMessages: \(error)")
        }

        return messages
    }

    func setHasSentInitialUser(environmentId: String, userId: String) {
        do {
            try with(environmentId: environmentId, userId: userId) {
                $0.hasUserBeenSent = true
            }
        } catch {
            NSLog("Error in setHasSentInitialUser: \(error)")
        }
    }

    func setHasSentIdentity(environmentId: String, userId: String) {
        do {
            try with(environmentId: environmentId, userId: userId) {
                $0.hasIdentityBeenSent = true
            }
        } catch {
            NSLog("Error in setHasSentIdentity: \(error)")
        }
    }

    func setHasSentUserProperty(environmentId: String, userId: String, name: String, value: String) {
        do {
            try with(environmentId: environmentId, userId: userId) {
                if $0.userProperties[name]?.value == value {
                    $0.userProperties[name] = (value, true)
                }
            }
        } catch {
            NSLog("Error in setHasSentUserProperty: \(error)")
        }
    }

    func deleteSentMessages(_ identifiers: Set<MessageIdentifier>) {

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

    func deleteUser(environmentId: String, userId: String) {
        with(environmentId: environmentId) {
            $0.users[userId] = nil
        }
    }

    func deleteSession(environmentId: String, userId: String, sessionId: String) {
        do {
            try with(environmentId: environmentId, userId: userId) {
                $0.sessions[sessionId] = nil
            }
        } catch {
            NSLog("Error in setHasSentInitialUser: \(error)")
        }
    }

    func pruneOldData(activeEnvironmentId: String, activeUserId: String, activeSessionId: String, minLastMessageDate: Date, minUserCreationDate: Date, currentDate: Date) {

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

                    if user.creationDate < minUserCreationDate {
                        return nil
                    }
                }

                return user
            })
            return environment
        })
    }
}
