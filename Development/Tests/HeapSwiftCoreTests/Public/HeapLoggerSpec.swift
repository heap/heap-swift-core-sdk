import Foundation
import Quick
import Nimble
import XCTest
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

struct LoggedMessage: Equatable {
    
    let logLevel: HeapSwiftCore.LogLevel
    let message: String
}

class TestLogChannel: LogChannel {
    
    var loggedMessages: [LoggedMessage] = []
    
    func printLog(logLevel: HeapSwiftCore.LogLevel, message: () -> String, source: String?, file: String, line: UInt) {
    
        if logLevel == .none {
            XCTFail("Function printLog should not be reached when logLevel is set to NONE.")
        }
        loggedMessages.append(LoggedMessage(logLevel: logLevel, message: message()))
    }
}

final class HeapLoggerSpec: QuickSpec {
    
    override func spec() {
        
        describe("HeapLoggerSpec.logLevel") {
            
            var heapLogger: HeapLogger!
            var logChannel: TestLogChannel!
            let traceMessage = LoggedMessage(logLevel: .trace, message: "This is a trace message")
            let debugMessage = LoggedMessage(logLevel: .debug, message: "This is a debug message")
            let infoMessage  = LoggedMessage(logLevel: .info,  message: "This is an info message")
            let warnMessage  = LoggedMessage(logLevel: .warn,  message: "This is a warning message")
            let errorMessage = LoggedMessage(logLevel: .error, message: "This is an error message")
            
            beforeEach {
                logChannel = TestLogChannel()
                heapLogger = HeapLogger()
                heapLogger.logChannel = logChannel
            }
            
            func logAllMessages() {
                heapLogger.error(errorMessage.message)
                heapLogger.warn(warnMessage.message)
                heapLogger.info(infoMessage.message)
                heapLogger.debug(debugMessage.message)
                heapLogger.trace(traceMessage.message)
            }
            
            it("logs nothing when logLevel is set to none") {
                heapLogger.logLevel = .none
                logAllMessages()
                expect(logChannel.loggedMessages).to(beEmpty())
            }
            
            it("logs correct messages when logLevel is set to error") {
                heapLogger.logLevel = .error
                logAllMessages()
                expect(logChannel.loggedMessages).to(equal([errorMessage]))
            }
            
            it("logs correct messages when logLevel is set to warn") {
                heapLogger.logLevel = .warn
                logAllMessages()
                expect(logChannel.loggedMessages).to(equal([errorMessage, warnMessage]))
            }
            
            it("logs correct messages when logLevel is set to info") {
                heapLogger.logLevel = .info
                logAllMessages()
                expect(logChannel.loggedMessages).to(equal([errorMessage, warnMessage, infoMessage]))
            }
            
            it("logs correct messages when logLevel is set to debug") {
                heapLogger.logLevel = .debug
                logAllMessages()
                expect(logChannel.loggedMessages).to(equal([errorMessage, warnMessage, infoMessage, debugMessage]))
            }
            
            it("logs correct messages when logLevel is set to trace") {
                heapLogger.logLevel = .trace
                logAllMessages()
                expect(logChannel.loggedMessages).to(equal([errorMessage, warnMessage, infoMessage, debugMessage, traceMessage]))
            }
        }
    }
}
