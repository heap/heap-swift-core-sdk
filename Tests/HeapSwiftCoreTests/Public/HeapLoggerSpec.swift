import Foundation
import Quick
import Nimble
import XCTest
@testable import HeapSwiftCore

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
            let debugMessage = "This is a debug message"
            let devMessage = "This is a dev message"
            let prodMessage = "This is a prod message"
            let criticalMessage = "This is a critical message"
        
            beforeEach {
                logChannel = TestLogChannel()
                heapLogger = HeapLogger()
                heapLogger.logChannel = logChannel
            }
            
            it("logs nothing when logLevel is set to none") {
                
                heapLogger.logLevel = .none
                
                heapLogger.logDebug(debugMessage)
                heapLogger.logDev(devMessage)
                heapLogger.logProd(prodMessage)
                heapLogger.logCritical(criticalMessage)
                
                expect(logChannel.loggedMessages).to(beEmpty())
            }
            
            it("logs correct messages when logLevel is set to critical") {
                
                heapLogger.logLevel = .critical
                let expectedLogs = [LoggedMessage(logLevel: .critical,  message: criticalMessage)]
                
                heapLogger.logDebug(debugMessage)
                heapLogger.logDev(devMessage)
                heapLogger.logProd(prodMessage)
                heapLogger.logCritical(criticalMessage)
                
                expect(logChannel.loggedMessages).to(equal(expectedLogs))
            }
            
            it("logs correct messages when logLevel is set to prod") {
                
                heapLogger.logLevel = .prod
                let expectedLogs = [LoggedMessage(logLevel: .prod,      message: prodMessage),
                                    LoggedMessage(logLevel: .critical,  message: criticalMessage)]
                
                
                heapLogger.logDebug(debugMessage)
                heapLogger.logDev(devMessage)
                heapLogger.logProd(prodMessage)
                heapLogger.logCritical(criticalMessage)
                
                expect(logChannel.loggedMessages).to(equal(expectedLogs))
            }
            
            it("logs correct messages when logLevel is set to dev") {
                
                heapLogger.logLevel = .dev
                let expectedLogs = [LoggedMessage(logLevel: .dev,       message: devMessage),
                                    LoggedMessage(logLevel: .prod,      message: prodMessage),
                                    LoggedMessage(logLevel: .critical,  message: criticalMessage)]
                
                heapLogger.logDebug(debugMessage)
                heapLogger.logDev(devMessage)
                heapLogger.logProd(prodMessage)
                heapLogger.logCritical(criticalMessage)
                
                expect(logChannel.loggedMessages).to(equal(expectedLogs))
            }
            
            it("logs correct messages when logLevel is set to debug") {
                
                heapLogger.logLevel = .debug
                let expectedLogs = [LoggedMessage(logLevel: .debug,     message: debugMessage),
                                    LoggedMessage(logLevel: .dev,       message: devMessage),
                                    LoggedMessage(logLevel: .prod,      message: prodMessage),
                                    LoggedMessage(logLevel: .critical,  message: criticalMessage)]
                
                heapLogger.logDebug(debugMessage)
                heapLogger.logDev(devMessage)
                heapLogger.logProd(prodMessage)
                heapLogger.logCritical(criticalMessage)
                
                expect(logChannel.loggedMessages).to(equal(expectedLogs))
            }
        }
    }
}
