import Foundation
@testable import HeapSwiftCore

struct FakeSession {
    let state: State
    let sessionMessage: Message
    let pageviewMessage: Message
    
    init(environmentId: String, userId: String, sessionId: String, timestamp: Date = Date()) {
        state = State(environmentId: environmentId, userId: userId, sessionId: sessionId, timestamp: timestamp)
        sessionMessage = .init(forSessionIn: state)
        pageviewMessage = .init(forPageviewWith: state.unattributedPageviewInfo, sourceLibrary: nil, in: state)
    }
    
    func customEventMessage(name: String, properties: [String: Value] = [:], timestamp: Date? = nil) -> Message {
        var event = Message(forPartialEventAt: timestamp ?? sessionMessage.time.date, sourceLibrary: nil, in: state)
        event.pageviewInfo = state.lastPageviewInfo
        event.event.custom = .init(name: name, properties: properties)
        return event
    }
}
