import Foundation

class SqliteDataStore: DataStoreProtocol {

    init(databaseUrl: URL? = nil) {
    }

    func loadState(for environmentId: String) -> EnvironmentState {
        var state = EnvironmentState()
        state.envID = environmentId
        return state
    }

    func save(_ environmentState: EnvironmentState) {
    }

    func createNewUserIfNeeded(environmentId: String, userId: String, identity: String?, creationDate: Date) {
    }

    func setIdentityIfNull(environmentId: String, userId: String, identity: String) {
    }

    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String) {
    }

    func createSessionIfNeeded(with message: Message) {
    }

    func insertPendingMessage(_ message: Message) {
    }

    func usersToUpload() -> [UserToUpload] {
        return []
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

    func deleteDatabase(complete: (Result<Void, Error>) -> Void) {
        complete(.success(Void()))
    }
}
