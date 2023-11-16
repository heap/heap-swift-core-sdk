import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupport_LogChannelSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var uploader: CountingUploader!
        var bridgeSupport: HeapBridgeSupport!
        var delegate: CountingHeapBridgeSupportDelegate!
        var logger: HeapLogger!
        var logChannel: TestLogChannel!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            uploader = CountingUploader()
            logger = HeapLogger()
            logChannel = TestLogChannel()
            logger.logChannel = logChannel
            bridgeSupport = HeapBridgeSupport(eventConsumer: consumer, uploader: uploader, logger: logger)
            delegate = .init()
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
            bridgeSupport.detachListeners()
            bridgeSupport.callbackStore.cancelAllSync()
        }
        
        func expectInvocation(file: StaticString = #file, line: UInt = #line, _ invocation: HeapBridgeSupport.Invocation?, toBeLogWith logLevel: String, message: String, source: String?) {
            
            expect(file: file, line: line, invocation).notTo(beNil())
            guard let invocation = invocation else { return }
            
            expect(file: file, line: line, invocation.method).to(equal("heapLogger_log"))
            expect(file: file, line: line, invocation.callbackId).toNot(beNil())
            expect(file: file, line: line, invocation.arguments).to(equal([
                "logLevel": .string(logLevel),
                "message": .string(message),
                "source": source.map({ .string($0) }) ?? .null,
            ]))
        }
        
        context("when unattached") {
            describe("HeapBridgeSupport.attachLogChannel") {
            
                it("does not set the log channel when delegate is null") {
                    let result = try bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                    expect(result as? Bool).to(equal(false))
                    expect(logger.logChannel as? TestLogChannel).toNot(beNil())
                }
                
                it("sets the log channel when the delegate is set") {
                    bridgeSupport.delegate = delegate
                    let result = try bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                    expect(result as? Bool).to(equal(true))
                    expect(logger.logChannel as? HeapBridgeSupport).toNot(beNil())
                }
                
                it("logs to the original log channel when attaching") {
                    bridgeSupport.delegate = delegate
                    logger.logLevel = .trace
                    _ = try bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                    expect(logChannel.loggedMessages).to(equal([
                        .init(logLevel: .info, message: "Attaching HeapLogger to HeapBridgeSupport. Messages will appear in the target framework."),
                        .init(logLevel: .debug, message: "Disabling log messages about HeapBridgeSupport to prevent recursive logging."),
                    ]))
                }
                
                it("logs to the console when attaching") {
                    bridgeSupport.delegate = delegate
                    _ = try bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                    
                    expect(delegate.invocations).to(haveCount(1))
                    
                    expectInvocation(delegate.invocations.first,
                                     toBeLogWith: "info",
                                     message: "Heap logger has been attached to the console.",
                                     source: nil)
                }
            }
            
            describe("HeapBridgeSupport.detachListeners") {
                it("does not affect the log channel") {
                    bridgeSupport.detachListeners()
                    expect(logger.logChannel as? TestLogChannel).toNot(beNil())
                }
            }
        }
        
        context("when attached") {
            beforeEach {
                logger.logLevel = .trace
                bridgeSupport.delegate = delegate
                _ = try! bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                logChannel.loggedMessages.removeAll()
                delegate.invocations.removeAll()
            }
            
            describe("HeapBridgeSupport.attachLogChannel") {
                
                it("returns false") {
                    let result = try bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                    expect(result as? Bool).to(equal(false))
                }
                
                it("does not log") {
                    _ = try bridgeSupport.handleInvocation(method: "attachLogChannel", arguments: [:])
                    expect(logChannel.loggedMessages).to(beEmpty())
                    expect(delegate.invocations).to(beEmpty())
                }
            }
            
            describe("HeapBridgeSupport.heapLogger_log") {
                it("logs error messages") {
                    logger.error("Test")
                    expectInvocation(delegate.invocations.first, toBeLogWith: "error", message: "Test", source: nil)
                }
                
                it("logs warn messages") {
                    logger.warn("Test")
                    expectInvocation(delegate.invocations.first, toBeLogWith: "warn", message: "Test", source: nil)
                }
                
                it("logs info messages") {
                    logger.info("Test")
                    expectInvocation(delegate.invocations.first, toBeLogWith: "info", message: "Test", source: nil)
                }
                
                it("logs debug messages") {
                    logger.debug("Test")
                    expectInvocation(delegate.invocations.first, toBeLogWith: "debug", message: "Test", source: nil)
                }
                
                it("logs trace messages") {
                    logger.trace("Test")
                    expectInvocation(delegate.invocations.first, toBeLogWith: "trace", message: "Test", source: nil)
                }
                
                it("sends source when provided") {
                    logger.info("Test", source: "My source")
                    expectInvocation(delegate.invocations.first, toBeLogWith: "info", message: "Test", source: "My source")
                }
                
                it("sends bridged logs right back to the bridge") {
                    _ = try bridgeSupport.handleInvocation(method: "heapLogger_log", arguments: [
                        "logLevel": "error",
                        "message": "Hello",
                        "source": "My source",
                    ])
                    expectInvocation(delegate.invocations.first, toBeLogWith: "error", message: "Hello", source: "My source")
                }
            }
            
            describe("HeapBridgeSupport.handleInvocation") {
                it("does not print errors to the log") {
                    _ = try? bridgeSupport.handleInvocation(method: "startRecording", arguments: [:])
                    _ = try? bridgeSupport.handleInvocation(method: "track", arguments: [:])
                    _ = try? bridgeSupport.handleInvocation(method: "trackPageview", arguments: [:])
                    _ = try? bridgeSupport.handleInvocation(method: "trackInteraction", arguments: [:])
                    _ = try? bridgeSupport.handleInvocation(method: "identify", arguments: [:])
                    _ = try? bridgeSupport.handleInvocation(method: "addUserProperties", arguments: ["properties": 123])
                    _ = try? bridgeSupport.handleInvocation(method: "addEventProperties", arguments: ["properties": 123])
                    _ = try? bridgeSupport.handleInvocation(method: "removeEventProperty", arguments: [:])
                    _ = try? bridgeSupport.handleInvocation(method: "heapLogger_log", arguments: [:])
                    expect(delegate.invocations).to(beEmpty())
                }
            }
            
            describe("HeapBridgeSupport.detachListeners") {
                it("restores the log channel") {
                    bridgeSupport.detachListeners()
                    expect(logger.logChannel as? TestLogChannel).toNot(beNil())
                }
                
                it("does not restore the log channel if it was overridden somewhere else") {
                    class MyLogChannel: LogChannel {
                        func printLog(logLevel: HeapSwiftCoreInterfaces.LogLevel, message: () -> String, source: String?, file: String, line: UInt) {
                        }
                    }
                    
                    logger.logChannel = MyLogChannel()
                    bridgeSupport.detachListeners()
                    expect(logger.logChannel as? MyLogChannel).toNot(beNil())
                }
            }
        }
    }
}
