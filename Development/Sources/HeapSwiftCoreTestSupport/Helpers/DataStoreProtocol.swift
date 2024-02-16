import Foundation
@testable import HeapSwiftCore

struct SessionMessages {
    let sessionMessage: Message?
    let initialPageviewMessage: Message?
    let versionChangeMessage: Message?
    let postStartMessages: [Message]
}

extension DataStoreProtocol {

    func getPendingMessages(for user: UserToUpload, sessionId: String?, messageLimit: Int = .max, file: StaticString = #file, line: UInt = #line) throws -> [Message] {

        guard let sessionId = sessionId, user.sessionIds.contains(sessionId) else {
            throw TestFailure("User does not have session \(String(describing: sessionId)).  Found \(user.sessionIds).")
        }

        return try getPendingEncodedMessages(environmentId: user.environmentId, userId: user.userId, sessionId: sessionId, messageLimit: messageLimit, byteLimit: .max).map({
            try Message(serializedData: $0.payload)
        })
    }

    func getPendingMessagesInOnlySession(for user: UserToUpload, messageLimit: Int = .max, file: StaticString = #file, line: UInt = #line) throws -> [Message] {
        guard user.sessionIds.count == 1 else {
            throw TestFailure("Expected a single session but found \(user.sessionIds)", file: file, line: line)
        }
        return try getPendingMessages(for: user, sessionId: user.sessionIds[0], messageLimit: messageLimit)
    }
    
    @discardableResult
    func assertExactPendingMessagesCountInOnlySession(for user: UserToUpload, count: Int, file: StaticString = #file, line: UInt = #line) throws -> [Message] {
        let messages = try getPendingMessagesInOnlySession(for: user, file: file, line: line)
        guard messages.count == count else {
            throw TestFailure("Expected exactly \(count) messages, but got \(messages.count)", file: file, line: line)
        }
        return messages
    }
    
    func getAllMessages() throws -> [Message] {
        try usersToUpload().flatMap { user in
            try user.sessionIds.flatMap { sessionId in
                try getPendingMessages(for: user, sessionId: sessionId)
            }
        }
    }
    
    @discardableResult
    func assertExactPendingMessagesCount(for user: UserToUpload, sessionId: String?, count: Int, file: StaticString = #file, line: UInt = #line) throws -> [Message] {

        let messages = try getPendingMessages(for: user, sessionId: sessionId, file: file, line: line)
        guard messages.count == count else {
            throw TestFailure("Expected exactly \(count) messages, but got \(messages.count)", file: file, line: line)
        }
        return messages
    }
    
    @discardableResult
    func assertOnlySession(hasPostStartMessageCount count: Int, file: StaticString = #file, line: UInt = #line) throws -> SessionMessages {
        
        let users = usersToUpload().filter({ !$0.sessionIds.isEmpty })
        
        guard users.count == 1 else {
            throw TestFailure("Expected a single user with sessions but found \(users.map(\.userId))", file: file, line: line)
        }
        
        return try assertOnlySession(for: users[0], hasPostStartMessageCount: count, file: file, line: line)
    }
    
    @discardableResult
    func assertOnlySession(for user: UserToUpload, hasPostStartMessageCount count: Int, file: StaticString = #file, line: UInt = #line) throws -> SessionMessages {
        guard user.sessionIds.count == 1 else {
            throw TestFailure("Expected a single session but found \(user.sessionIds)", file: file, line: line)
        }
        return try assertSession(for: user, sessionId: user.sessionIds[0], hasPostStartMessageCount: count, file: file, line: line)
    }
    
    @discardableResult
    func assertSession(for user: UserToUpload, sessionId: String?, hasPostStartMessageCount count: Int, file: StaticString = #file, line: UInt = #line) throws -> SessionMessages {
        
        var messages = try getPendingMessages(for: user, sessionId: sessionId, file: file, line: line)
        
        var sessionMessage: Message?
        let initialPageviewMessage: Message?
        let versionChangeMessage: Message?
        
        if case .session(_) = messages.first?.kind {
            sessionMessage = messages.removeFirst()
        } else {
            sessionMessage = nil
        }
        
        if let message = messages.first,
           case .pageview(_) = message.kind,
           !message.pageviewInfo.hasComponentOrClassName,
           !message.pageviewInfo.hasTitle,
           !message.pageviewInfo.hasURL {
            initialPageviewMessage = messages.removeFirst()
        } else {
            initialPageviewMessage = nil
        }
        
        if case .versionChange(_) = messages.first?.event.kind {
            versionChangeMessage = messages.removeFirst()
        } else {
            versionChangeMessage = nil
        }
        
        guard messages.count == count else {
            throw TestFailure("Expected exactly \(count) messages after session start messages, but got \(messages.count)", file: file, line: line)
        }
        
        return .init(sessionMessage: sessionMessage, initialPageviewMessage: initialPageviewMessage, versionChangeMessage: versionChangeMessage, postStartMessages: messages)
    }
    
    @discardableResult
    func assertOnlyOneUserToUpload(message: String? = nil, file: StaticString = #file, line: UInt = #line) throws -> UserToUpload {

        let users = usersToUpload()

        guard users.count == 1 else {
            throw TestFailure(message ?? "Expected a single user but got \(users.count)", file: file, line: line)
        }

        return users[0]
    }
    
    @discardableResult
    func assertUserToUploadExists(with userId: String, message: String? = nil, file: StaticString = #file, line: UInt = #line) throws -> UserToUpload {

        let users = usersToUpload()

        guard let user = users.first(where: { $0.userId == userId }) else {
            throw TestFailure(message ?? "Expected to find a user with id \(userId) but got \(users.map(\.userId))", file: file, line: line)
        }

        return user
    }
    
    func createSessionIfNeeded(environmentId: String, userId: String, sessionId: String, timestamp: Date, includePageview: Bool = false, includeEvent: Bool = false) {
        
        let fakeSession = FakeSession(environmentId: environmentId, userId: userId, sessionId: sessionId, timestamp: timestamp)
        
        createSessionIfNeeded(with: fakeSession.sessionMessage)
        if includePageview {
            insertPendingMessage(fakeSession.pageviewMessage)
        }
        
        if includeEvent {
            insertPendingMessage(fakeSession.customEventMessage(name: "my-event"))
        }
    }
}
