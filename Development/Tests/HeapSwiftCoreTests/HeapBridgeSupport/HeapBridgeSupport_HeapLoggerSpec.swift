import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class HeapBridgeSupport_HeapLoggerSpec: HeapSpec {
    
    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!
        var uploader: CountingUploader!
        var bridgeSupport: HeapBridgeSupport!
        
        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            uploader = CountingUploader()
            bridgeSupport = HeapBridgeSupport(eventConsumer: consumer, uploader: uploader)
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }
        
        func describeMethod(_ method: String, closure: (_ method: String) -> Void) {
            describe("HeapBridgeSupport.\(method)", closure: { closure(method) })
        }
        
        describeMethod("heapLogger_log") { method in
            
            it("does not throw when all options are provided") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])
            }
            
            it("does not throw when source is omitted") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "message": "Message from the log test",
                ])
            }
            
            it("throws when source is not a string") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "message": "Message from the log test",
                    "source": ["foo": "bar"],
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when message is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "source": "test runner",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when message is not a string") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "message": ["foo": "bar"],
                    "source": "test runner",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when message is empty") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "message": "",
                    "source": "test runner",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("does not throw for the error log level") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "error",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])
            }
            
            it("does not throw for the warn log level") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "warn",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])
            }
            
            it("does not throw for the info log level") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "info",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])
            }
            
            it("does not throw for the debug log level") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "debug",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])
            }
            
            it("does not throw for the trace log level") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])
            }
            
            it("throws for an unknown log level") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "quack",
                    "message": "Message from the log test",
                    "source": "test runner",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when log level is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "message": "Message from the log test",
                    "source": "test runner",
                ])).to(throwError(InvocationError.invalidParameters))
            }
        }
        
        describeMethod("heapLogger_setLogLevel") { method in
            
            it("can set the log level to error") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "error",
                ])
                expect(HeapLogger.shared.logLevel).to(equal(.error))
            }
            
            it("can set the log level to warn") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "warn",
                ])
                expect(HeapLogger.shared.logLevel).to(equal(.warn))
            }
            
            it("can set the log level to info") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "info",
                ])
                expect(HeapLogger.shared.logLevel).to(equal(.info))
            }
            
            it("can set the log level to debug") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "debug",
                ])
                expect(HeapLogger.shared.logLevel).to(equal(.debug))
            }
            
            it("can set the log level to trace") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "trace",
                ])
                expect(HeapLogger.shared.logLevel).to(equal(.trace))
            }
            
            it("can set the log level to none") {
                _ = try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "none",
                ])
                expect(HeapLogger.shared.logLevel).to(equal(LogLevel.none))
            }
            
            it("throws when for an unknown log level") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [
                    "logLevel": "quack",
                ])).to(throwError(InvocationError.invalidParameters))
            }
            
            it("throws when log level is omitted") {
                expect(try bridgeSupport.handleInvocation(method: method, arguments: [:])).to(throwError(InvocationError.invalidParameters))
            }
        }
        
        describeMethod("heapLogger_logLevel") { method in
            
            it("gets the error log level") {
                HeapLogger.shared.logLevel = .error
                expect (try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("error"))
            }
            
            it("gets the info log level") {
                HeapLogger.shared.logLevel = .info
                expect (try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("info"))
            }
            
            it("gets the debug log level") {
                HeapLogger.shared.logLevel = .debug
                expect (try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("debug"))
            }
            
            it("gets the trace log level") {
                HeapLogger.shared.logLevel = .trace
                expect (try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("trace"))
            }
            
            it("gets the none log level") {
                HeapLogger.shared.logLevel = .none
                expect (try bridgeSupport.handleInvocation(method: method, arguments: [:]) as! String?).to(equal("none"))
            }
        }
    }
}
