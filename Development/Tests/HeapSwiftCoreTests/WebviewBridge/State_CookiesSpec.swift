import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class State_CookiesSpec: HeapSpec {
    
    override func spec() {
        describe("State.toHeapJsCookie") {
            
            var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
            var restoreState: StateRestorer!
            
            beforeEach {
                (_, consumer, _, _, restoreState) = prepareEventConsumerWithCountingDelegates()
                consumer.startRecording("11", with: [ .startSessionImmediately: true ])
            }
            
            afterEach {
                restoreState()
            }
            
            it("uses domain and path from cookies") {
                
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(
                    domain: ".foo.bar",
                    path: "/my/path",
                    secure: true
                ))
                
                expect(cookie1?.domain).to(equal(".foo.bar"))
                expect(cookie1?.path).to(equal("/my/path"))
            }
            
            it("applies the true security setting") {
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(
                    domain: ".foo.bar",
                    path: "/my/path",
                    secure: true
                ))
                
                expect(cookie1?.isSecure).to(beTrue())
            }
            
            it("applies the false security setting") {
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(
                    domain: ".foo.bar",
                    path: "/my/path",
                    secure: false
                ))
                
                expect(cookie1?.isSecure).to(beFalse())
            }
            
            // SameSite is only available for macOS 10.15 and above.
            if #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *) {
                
                it("uses SameSite=None on secure cookies") {
                    let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(
                        domain: ".foo.bar",
                        secure: true
                    ))
                    
                    // This is a weird behavior of `sameSitePolicy`. There's no enum for `None`
                    // but it is stored in the cookie.
                    expect(cookie1?.sameSitePolicy).to(beNil())
                    expect(cookie1?.description).to(contain("sameSite:none"))
                }
                
                it("uses SameSite=Lax on insecure cookies") {
                    let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(
                        domain: ".foo.bar",
                        secure: false
                    ))
                    
                    expect(cookie1?.sameSitePolicy).to(equal(.sameSiteLax))
                }
            }
            
            it("sets a long-lived cookie") {
                let timestamp = Date()
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(
                    domain: ".foo.bar",
                    path: "/my/path",
                    secure: false
                ), timestamp: timestamp)
                
                expect(cookie1?.isSessionOnly).to(beFalse())
                expect(cookie1?.expiresDate).to(beCloseTo(timestamp.addingTimeInterval(60 * 60 * 24 * 365), within: 60 * 60))
            }
            
            it("applies the right cookie name") {
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(domain: ".foo.bar"))
                
                expect(cookie1?.name).to(equal("_hp2_wv_id.11"))
            }
            
            it("stores the state in the cookie for an unidentified user") {
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(domain: ".foo.bar"))
                
                guard
                    let data = cookie1?.value.removingPercentEncoding?.data(using: .utf8),
                    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    throw TestFailure("Could not read \(cookie1?.value ?? "nil") as JSON")
                }
                
                expect(object["userId"] as? String).to(equal(consumer.userId))
                expect(object["sessionId"] as? String).to(equal(consumer.sessionId))
                expect(object["identity"] as? NSObject).to(equal(NSNull()))
            }
            
            it("stores the state in the cookie for an identified user") {
                consumer.identify("me")
                let cookie1 = consumer.stateManager.current?.toHeapJsCookie(settings: .init(domain: ".foo.bar"))
                
                guard
                    let data = cookie1?.value.removingPercentEncoding?.data(using: .utf8),
                    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    throw TestFailure("Could not read \(cookie1?.value ?? "nil") as JSON")
                }
                
                expect(object["userId"] as? String).to(equal(consumer.userId))
                expect(object["sessionId"] as? String).to(equal(consumer.sessionId))
                expect(object["identity"] as? String).to(equal("me"))
            }
        }
    }
}
