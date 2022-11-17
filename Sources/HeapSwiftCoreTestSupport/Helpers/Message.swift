import Foundation
import Nimble
import XCTest
@testable import HeapSwiftCore

extension Message {
    
    /// Loading device info for each test is painfully slow on the iOS simulator and Catalyst.
    private static let testDeviceInfo = DeviceInfo.current(includeCarrier: true)

    private func validateBaseMessage(file: StaticString = #file, line: UInt = #line, user: UserToUpload, id: String?, timestamp: Date?, hasSourceLibrary: Bool, sourceLibrary: LibraryInfo?, eventProperties: [String: Value]?) {

        expect(file: file, line: line, envID).to(equal(user.environmentId), description: "Environment ID does not match")
        expect(file: file, line: line, userID).to(equal(user.userId), description: "User ID does not match")

        if let id = id {
            expect(file: file, line: line, id).to(equal(id), description: "Message ID does not match")
        }

        expect(file: file, line: line, hasTime).to(beTrue())
        if let timestamp = timestamp {
            expect(file: file, line: line, time).to(equal(.init(date: timestamp)))
        }

        if let eventProperties = eventProperties {
            expect(file: file, line: line, properties).to(equal(eventProperties), description: "Event properties do not match")
        }

        expect(file: file, line: line, self.hasSourceLibrary).to(equal(hasSourceLibrary), description: "Source library does not match")
        if let sourceLibrary = sourceLibrary {
            expect(file: file, line: line, self.sourceLibrary).to(equal(sourceLibrary), description: "Source library does not match")
        }

        expect(file: file, line: line, hasApplication).to(beTrue(), description: "Missing application")
        expect(file: file, line: line, application.name).notTo(beEmpty(), description: "Application should have a name")
        expect(file: file, line: line, application.identifier).notTo(beEmpty(), description: "Application should have a model")
        expect(file: file, line: line, application.versionString).notTo(beEmpty(), description: "Application should have a type")

        expect(file: file, line: line, hasDevice).to(beTrue(), description: "Missing device")
        expect(file: file, line: line, device.platform).notTo(beEmpty(), description: "All devices should have a platform")
        expect(file: file, line: line, device.model).notTo(beEmpty(), description: "All devices should have a model")
        expect(file: file, line: line, device.type).notTo(equal(.unknown), description: "All devices should have a type")
        expect(file: file, line: line, device).to(equal(Self.testDeviceInfo), description: "Device should match the current device")

        expect(file: file, line: line, hasBaseLibrary).to(beTrue(), description: "Missing base library")
        expect(file: file, line: line, baseLibrary.name).notTo(beEmpty(), description: "Base library should have a name")
        expect(file: file, line: line, baseLibrary.platform).notTo(beEmpty(), description: "Base library should have a platform")
        expect(file: file, line: line, baseLibrary.version).notTo(beEmpty(), description: "Base library should have a version")
        expect(file: file, line: line, baseLibrary).to(equal(.baseInfo(with: Self.testDeviceInfo)), description: "Base library should match baseInfo(with: .current)")

        expect(file: file, line: line, hasSessionInfo).to(beTrue(), description: "All messages must have session info")
    }

    func expectSessionMessage(file: StaticString = #file, line: UInt = #line, user: UserToUpload, id: String? = nil, timestamp: Date? = nil, eventProperties: [String: Value]? = nil) {

        guard case .some(.session) = kind else {
            XCTFail("Expected a session message, got \(String(describing: kind))", file: file, line: line)
            return
        }

        validateBaseMessage(file: file, line: line, user: user, id: id, timestamp: timestamp, hasSourceLibrary: false, sourceLibrary: nil, eventProperties: eventProperties)

        expect(file: file, line: line, hasSourceLibrary).to(beFalse(), description: "Session messages should never have a source library")
        expect(file: file, line: line, hasPageviewInfo).to(beFalse(), description: "Session messages should never have pageview info")

        expect(file: file, line: line, sessionInfo.id).to(equal(id), description: "Session messages must have an id matching the session info id")
        expect(file: file, line: line, sessionInfo.hasTime).to(beTrue(), description: "Session mesages must have a timestamp matching the session info timestamp")
        expect(file: file, line: line, sessionInfo.time).to(equal(time), description: "Session mesages must have a timestamp matching the session info timestamp")
    }

    func expectPageviewMessage(file: StaticString = #file, line: UInt = #line, user: UserToUpload, timestamp: Date? = nil, hasSourceLibrary: Bool = false, sourceLibrary: LibraryInfo? = nil, eventProperties: [String: Value]? = nil, sessionMessage: Message? = nil) {

        guard case .some(.pageview) = kind else {
            XCTFail("Expected a pageview message, got \(String(describing: kind))", file: file, line: line)
            return
        }

        validateBaseMessage(file: file, line: line, user: user, id: nil, timestamp: timestamp, hasSourceLibrary: hasSourceLibrary, sourceLibrary: sourceLibrary, eventProperties: eventProperties)

        if let sessionMessage = sessionMessage {
            expect(id).notTo(equal(sessionMessage.id), description: "The pageview and session must have different ids")
            expect(sessionInfo).to(equal(sessionMessage.sessionInfo), description: "The pageview must have the same session info as the session message")
        }

        expect(file: file, line: line, hasPageviewInfo).to(beTrue())
        expect(file: file, line: line, pageviewInfo.id).to(equal(id), description: "Pageview messages must have an id matching the pageview info id")
        expect(file: file, line: line, pageviewInfo.hasTime).to(beTrue(), description: "Pageview mesages must have a timestamp matching the pageview info timestamp")
        expect(file: file, line: line, pageviewInfo.time).to(equal(time), description: "Pageview mesages must have a timestamp matching the pageview info timestamp")
    }

    @discardableResult
    func expectEventMessage(file: StaticString = #file, line: UInt = #line, user: UserToUpload, timestamp: Date? = nil, hasSourceLibrary: Bool = false, sourceLibrary: LibraryInfo? = nil, eventProperties: [String: Value]? = nil, pageviewMessage: Message? = nil) -> Event? {

        guard case let .some(.event(event)) = kind else {
            XCTFail("Expected a event message, got \(String(describing: kind))", file: file, line: line)
            return nil
        }

        validateBaseMessage(file: file, line: line, user: user, id: nil, timestamp: timestamp, hasSourceLibrary: hasSourceLibrary, sourceLibrary: sourceLibrary, eventProperties: eventProperties)

        expect(file: file, line: line, hasPageviewInfo).to(beTrue(), description: "The event must have pageview info")

        if let pageviewMessage = pageviewMessage {
            expect(id).notTo(equal(pageviewMessage.id), description: "The event and pageview must have different ids")
            expect(sessionInfo).to(equal(pageviewMessage.sessionInfo), description: "The event must have the same session info as the pageview message")
            expect(pageviewInfo).to(equal(pageviewMessage.pageviewInfo), description: "The event must have the same pageview info as the pageview message")
        }

        return event
    }

    func assertEventMessage(file: StaticString = #file, line: UInt = #line, user: UserToUpload, timestamp: Date? = nil, hasSourceLibrary: Bool = false, sourceLibrary: LibraryInfo? = nil, eventProperties: [String: Value]? = nil, pageviewMessage: Message? = nil) throws -> Event {
        guard let event = expectEventMessage(file: file, line: line, user: user, timestamp: timestamp, hasSourceLibrary: hasSourceLibrary, sourceLibrary: sourceLibrary, eventProperties: eventProperties, pageviewMessage: pageviewMessage) else {
            throw TestEnded()
        }
        return event
    }

}

extension Sequence where Element == Message {

    func assertAllSessionInfosMatch(file: StaticString = #file, line: UInt = #line) throws {
        let sessions = Set(self.map(\.sessionInfo))
        if sessions.count != 1 {
            throw TestFailure("Expected a single `sessionInfo`, got \(sessions)", file: file, line: line)
        }
    }

    func assertAllPageviewInfosMatch(file: StaticString = #file, line: UInt = #line) throws {
        let pageviews = Set(self.map(\.pageviewInfo))
        if pageviews.count != 1 {
            throw TestFailure("Expected a single `sessionInfo`, got \(pageviews)", file: file, line: line)
        }
    }

    func expectStartOfSessionWithSynthesizedPageview(file: StaticString = #file, line: UInt = #line, user: UserToUpload, sessionId: String? = nil, sessionTimestamp: Date? = nil, eventProperties: [String: Value]? = nil) {

        let firstMessages = Array(prefix(2))

        guard firstMessages.count == 2 else {
            XCTFail("Expected the session to have at least two messages", file: file, line: line)
            return
        }

        firstMessages[0].expectSessionMessage(file: file, line: line, user: user, id: sessionId, timestamp: sessionTimestamp, eventProperties: eventProperties)
        firstMessages[1].expectPageviewMessage(file: file, line: line, user: user, timestamp: sessionTimestamp, hasSourceLibrary: false, eventProperties: eventProperties, sessionMessage: firstMessages[0])
    }
}
