import Foundation;

struct UserToUpload {
    let environmentId: String
    let userId: String
    let identity: String?

    let needsInitialUpload: Bool
    let needsIdentityUpload: Bool

    let pendingUserProperties: [String: String]
    let sessionIds: [String]
}

typealias MessageIdentifier = Int

protocol DataStoreProtocol {

    func loadState(for environmentId: String) -> EnvironmentState
    func save(_ environmentState: EnvironmentState)

    func createNewUserIfNeeded(environmentId: String, userId: String, identity: String?, creationDate: Date)
    func setIdentityIfNull(environmentId: String, userId: String, identity: String)
    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String)
    
    func createSessionIfNeeded(with message: Message)
    func insertPendingMessage(_ message: Message)

    func usersToUpload() -> [UserToUpload]
    func getPendingEncodedMessages(environmentId: String, userId: String, sessionId: String, messageLimit: Int, byteLimit: Int) -> [(MessageIdentifier, Data)]

    func setHasSentInitialUser(environmentId: String, userId: String)
    func setHasSentIdentity(environmentId: String, userId: String)
    func setHasSentUserProperty(environmentId: String, userId: String, name: String, value: String)

    func deleteSentMessages(_ identifiers: Set<MessageIdentifier>)
    func deleteUser(environmentId: String, userId: String)
    func deleteSession(environmentId: String, userId: String, sessionId: String)

    func pruneOldData(activeEnvironmentId: String, activeUserId: String, activeSessionId: String, minLastMessageDate: Date, minUserCreationDate: Date, currentDate: Date)
}
