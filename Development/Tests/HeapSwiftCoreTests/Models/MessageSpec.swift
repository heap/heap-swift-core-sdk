import Quick
import Nimble
import Foundation
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class MessageSpec: QuickSpec {
    
    override func spec() {
        
        func verifyBaseStateInformation(for message: Message, with state: State) {
            expect(message.envID).to(equal(state.environment.envID))
            expect(message.userID).to(equal(state.environment.userID))
            expect(message.baseLibrary).to(equal(state.sdkInfo.libraryInfo))
            expect(message.application).to(equal(state.sdkInfo.applicationInfo))
            expect(message.device).to(equal(state.sdkInfo.deviceInfo))
            expect(message.sessionInfo).to(equal(state.sessionInfo))
        }

        var state: State!
        
        beforeEach {
            state = .init(environmentId: "11", userId: "123", sessionId: "456")
            state.environment.properties = ["key":.init(value: "value")]
        }
        
        describe("Message.init(forSessionIn:)") {
            
            var message: Message!
            
            beforeEach {
                message = Message(forSessionIn: state)
            }
            
            it("sets common event properties from state") {
                verifyBaseStateInformation(for: message, with: state)
            }

            it("creates a session message") {
                expect(message.id).to(equal(state.sessionInfo.id))
                expect(message.time).to(equal(state.sessionInfo.time))
                expect(message.kind).to(equal(.session(.init())))
            }
            
            it("does not set event properties") {
                let message = Message(forSessionIn: state)
                expect(message.properties).to(beEmpty())
            }
        }
        
        describe("Message.init(forPageviewWith:)") {
            
            var message: Message!
            var pageviewInfo: PageviewInfo!
            var sourceLibrary: LibraryInfo!
            
            beforeEach {
                pageviewInfo = .init()
                pageviewInfo.id = "111"
                pageviewInfo.time = .init(date: .init(timeIntervalSinceNow: 0))
                sourceLibrary = .init()
                sourceLibrary.name = "heap-test-library"
                message = Message(forPageviewWith: pageviewInfo, sourceLibrary: sourceLibrary, in: state)
            }
            
            it("sets common event properties from state") {
                verifyBaseStateInformation(for: message, with: state)
            }
            
            it("creates a pageview message with properties") {
                expect(message.id).to(equal(pageviewInfo.id))
                expect(message.time).to(equal(pageviewInfo.time))
                expect(message.sourceLibrary).to(equal(sourceLibrary))
                expect(message.kind).to(equal(.pageview(.init())))
                expect(message.properties).to(equal(state.environment.properties))
            }
        }
        
        describe("Message.init(forPartialEventAt:)") {
            
            var message: Message!
            var sourceLibrary: LibraryInfo!
            var date: Date!
            
            beforeEach {
                date = .init(timeIntervalSince1970: 1000)
                sourceLibrary = .init()
                sourceLibrary.name = "heap-test-library"
                message = Message(forPartialEventAt: date, sourceLibrary: sourceLibrary, in: state)
            }
            
            it("sets common event properties from state") {
                verifyBaseStateInformation(for: message, with: state)
            }
            
            it("creates a partial event message with properties") {
                expect(message.id).toNot(beEmpty())
                expect(message.time.seconds).to(equal(Int64(date.timeIntervalSince1970)))
                expect(message.sourceLibrary).to(equal(sourceLibrary))
                expect(message.kind).to(equal(.event(.init())))
                expect(message.properties).to(equal(state.environment.properties))
            }
        }
        
        describe("Message.init(forVersionChangeEventAt:)") {
            
            var applicationInfo: ApplicationInfo!
            var message: Message!
            var sourceLibrary: LibraryInfo!
            var date: Date!
            
            beforeEach {
                date = .init(timeIntervalSince1970: 1000)
                sourceLibrary = .init()
                sourceLibrary.name = "heap-test-library"
                applicationInfo = SDKInfo.withoutAdvertiserId.applicationInfo
                message = Message(forVersionChangeEventAt: date, sourceLibrary: sourceLibrary, in: state, previousVersion: applicationInfo)
            }
            
            it("sets common event properties from state") {
                verifyBaseStateInformation(for: message, with: state)
            }
            
            it("sets partial event state information") {
                                
                expect(message.id).toNot(beEmpty())
                expect(message.time.seconds).to(equal(Int64(date.timeIntervalSince1970)))
                expect(message.sourceLibrary).to(equal(sourceLibrary))
                expect(message.properties).to(equal(state.environment.properties))
            }
            
            it("creates a version change event message") {
    
                let versionChange = VersionChange.with {
                    $0.previousVersion = applicationInfo
                    $0.currentVersion = applicationInfo
                }
                
                expect(message.pageviewInfo).to(equal(state.unattributedPageviewInfo))
                expect(message.event.kind).to(equal(.versionChange(versionChange)))
                expect(message.event.appVisibilityState).to(equal(.current))
            }
        }
    }

}
