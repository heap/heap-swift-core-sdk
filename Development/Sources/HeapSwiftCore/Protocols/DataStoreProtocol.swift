import Foundation;

final class UserToUpload {
    let environmentId: String
    let userId: String
    let identity: String?

    var needsInitialUpload: Bool
    var needsIdentityUpload: Bool

    var pendingUserProperties: [String: String]
    var sessionIds: [String]
    
    init(environmentId: String,
         userId: String,
         identity: String?,
         needsInitialUpload: Bool,
         needsIdentityUpload: Bool,
         pendingUserProperties: [String: String] = [:],
         sessionIds: [String] = []) {
        self.environmentId = environmentId
        self.userId = userId
        self.identity = identity
        self.needsInitialUpload = needsInitialUpload
        self.needsIdentityUpload = needsIdentityUpload
        self.pendingUserProperties = pendingUserProperties
        self.sessionIds = sessionIds
    }
}

extension UserToUpload: Equatable {
    static func == (lhs: UserToUpload, rhs: UserToUpload) -> Bool {
        lhs.environmentId == rhs.environmentId &&
        lhs.userId == rhs.userId &&
        lhs.identity == rhs.identity &&
        lhs.needsInitialUpload == rhs.needsInitialUpload &&
        lhs.needsIdentityUpload == rhs.needsIdentityUpload &&
        lhs.pendingUserProperties == rhs.pendingUserProperties &&
        lhs.sessionIds == rhs.sessionIds
    }
}

extension UserToUpload: CustomDebugStringConvertible {
    var debugDescription: String {
        return """
Environment ID:          \(environmentId)
User ID:                 \(userId)
Identity:                \(identity ?? "")

Needs Initial Upload:    \(needsInitialUpload)
Needs Identity Upload:   \(needsIdentityUpload)

Session ID(s):           \(sessionIds.joined(separator: ", "))
Pending User Properties: \(pendingUserProperties)
"""
    }
}

typealias MessageIdentifier = Int

struct DataStoreSettings {
    var messageByteLimit: Int

    static let `default` = DataStoreSettings(
        
        // Collectors are only able to write a message downstream if the size is less than 0.8MB
        // 1024 * 1024 * 0.75 bytes
        messageByteLimit: 786_432
    )
}

protocol DataStoreProtocol {
    
    var dataStoreSettings: DataStoreSettings { get }

    func createNewUserIfNeeded(environmentId: String, userId: String, identity: String?, creationDate: Date)
    func setIdentityIfNull(environmentId: String, userId: String, identity: String)
    func insertOrUpdateUserProperty(environmentId: String, userId: String, name: String, value: String)
    
    func createSessionWithoutMessageIfNeeded(environmentId: String, userId: String, sessionId: String, lastEventDate: Date)
    func createSessionIfNeeded(with message: Message)
    func insertPendingMessage(_ message: Message)

    func usersToUpload() -> [UserToUpload]
    func getPendingEncodedMessages(environmentId: String, userId: String, sessionId: String, messageLimit: Int, byteLimit: Int) -> [(identifier: MessageIdentifier, payload: Data)]

    func setHasSentInitialUser(environmentId: String, userId: String)
    func setHasSentIdentity(environmentId: String, userId: String)
    func setHasSentUserProperty(environmentId: String, userId: String, name: String, value: String)

    func deleteSentMessages(_ identifiers: Set<MessageIdentifier>)
    func deleteUser(environmentId: String, userId: String)
    func deleteSession(environmentId: String, userId: String, sessionId: String)

    func pruneOldData(activeEnvironmentId: String, activeUserId: String, activeSessionId: String, minLastMessageDate: Date, minUserCreationDate: Date)
}

extension DataStoreSettings {
    
    func isWithinMessageSizeLimit(_ serializedMessage: Data) -> Bool {
        let messageSize = serializedMessage.count
        if messageSize > messageByteLimit {
            HeapLogger.shared.warn("An event was dropped because it was too large.")
            HeapLogger.shared.trace("The message size (\(messageSize) bytes) exceeded the maximum allowed size (\(messageByteLimit) bytes)")
            return false
        }
        return true
    }
}
