import Foundation
import OSLog

@objc(HeapLogLevel)
public enum LogLevel: Int, Comparable {

    /// Heap will not print any log messages.
    case none = 0
    
    /// Heap will only print the most critical log messages, such as when the SDK encounters an error and needs to shutdown.
    case critical = 1
    
    /// Heap will print messages that are useful in a production environment, such as when recording starts/stops, when a
    /// batch of events is successfully sent, or when a new session has begun.
    ///
    /// This level is recommended for production environments so that developers can see Heap lifecycle
    /// messages in their own logging environment.
    ///
    /// This level also includes `critical` messages.
    ///
    case prod = 2
    
    /// Heap will print messages that the implementing developer might find helpful. Messages might include things such as
    /// invalid environment ID value, truncated event names, or attempting to track an event before recording has started.
    ///
    /// This level is recommended for implementing developers during the development process to help with debugging
    /// normal installation and tracking issues.
    ///
    /// This level also includes `critical` and `prod` messages.
    case dev = 3
    
    /// Heap will print message that help the Heap team diagnose SDK issues. Heap support might ask the implementing
    /// developers to enable this log level to gain better insight into issues developers are encounter when implementing the Heap SDK.
    ///
    /// Full event details are also printed at this level.
    ///
    /// This level is recommended when gathering information to send to Heap support personnel. Heap support might also ask
    /// that this level be turned on to help debug installation and tracking issues that require extra investigation.
    ///
    /// This level also includes `critical`, `prod`, and `dev` messages.
    case debug = 4
    

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}


/// Logging Interface
///
/// The  interface used to route log messages from a source to a specific output
/// location, such as logz.io,  The default mplementation prints logs via os_log.
///
/// Can be implemented by client apps to redirect Heap Swift Core SDK logs through
/// a different logging implementation.
///
public protocol LogChannel {
    func printLog(logLevel: LogLevel, message: () -> String, source: String?, file: String, line: UInt)
}


class DefaultLogChannel: LogChannel {
    
    let log: OSLog
    
    init() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            log = OSLog(subsystem: bundleIdentifier, category: "Heap")
        } else {
            log = .default // This should never happen but fall back to the default log.
        }
    }
    
    
    /// Logs a single message from a source.
    ///
    /// - Parameters:
    ///   - logLevel: The ``LogLevel`` associated with this message.
    ///   - message: The message to print.
    ///   - source: The source this log message originates from.
    ///   - file: The file this log message originates from.
    ///   - line: The line this log message originates from.

    func printLog(logLevel: LogLevel, message: () -> String, source: String?, file: String, line: UInt) {
        
        let source = source.map({ "[\($0)] " }) ?? ""
        
        switch logLevel {
        case .debug where log.isEnabled(type: .debug):
            os_log(.debug, log: log, "%s[DEBUG] %s\n    File: %s\n    Line: %lld", source, message(), file, UInt64(line))
        case .dev where log.isEnabled(type: .default):
            os_log(.default, log: log, "%s[DEV] %s\n", source, message())
        case .prod where log.isEnabled(type: .default):
            os_log(.default, log: log, "%s%s\n", source, message())
        case .critical where log.isEnabled(type: .error):
            os_log(.error, log: log, "%s%s\n", source, message())
        default:
            break
        }
    }
}

/// Central logging class for all log messages that are printed from the Heap SDK.
/// All log messages and exceptions must go through this logger to respect client
/// defined log levels.
@objc
public class HeapLogger: NSObject {

    /// The shared HeapLogger instance.
    @objc(sharedInstance)
    public static let shared = HeapLogger()
    
    /// The level of logging to be performed by the HeapLogger.
    @objc
    public var logLevel: LogLevel = LogLevel.prod
    
    /// The logging channel to route all logs,
    public var logChannel: LogChannel = DefaultLogChannel()

       
    /// Logs Critical Level Messages
    ///
    /// Heap will only print the most critical log messages, such as when the SDK encounters an error
    /// and needs to shutdown.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func logCritical(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if(logLevel >= LogLevel.critical) {
            logChannel.printLog(logLevel: LogLevel.critical,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
        // TODO: These messages should also go to logz.
    }
#else
    public func logCritical(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if(logLevel >= LogLevel.critical) {
            logChannel.printLog(logLevel: LogLevel.critical,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
        // TODO: These messages should also go to logz.
    }
#endif

    /// Logs Production Level Messages
    ///
    /// Heap will print messages that are useful in a production environment, such as when recording starts/stops,
    /// when a batch of events is successfully sent, or when a new session has begun.
    ///
    /// This level is recommended for production environments so that developers can see Heap lifecycle
    /// messages in their own logging environment.
    ///
    /// This level also includes critical messages.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func logProd(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if(logLevel >= LogLevel.prod) {
            logChannel.printLog(logLevel: LogLevel.prod,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func logProd(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if(logLevel >= LogLevel.prod) {
            logChannel.printLog(logLevel: LogLevel.prod,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif


    /// Logs Developer Level Messages
    ///
    /// Heap will print messages that the implementing developer might find helpful.
    /// Messages might include things such as invalid environment ID value, truncated event names,
    /// or attempting to track an event before recording has started.
    ///
    /// This level is recommended for implementing developers during the development process to help with
    /// debugging normal installation and tracking issues.
    ///
    /// This level also includes critical and prod messages.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func logDev(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if(logLevel >= LogLevel.dev) {
            logChannel.printLog(logLevel: LogLevel.dev,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func logDev(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if(logLevel >= LogLevel.dev) {
            logChannel.printLog(logLevel: LogLevel.dev,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif

    /// Logs Debug Level Messages
    ///
    /// Heap will print message that help the Heap team diagnose SDK issues.
    /// Heap support might ask the implementing developers to enable this log level to gain better insight into issues
    /// developers are encounter when implementing the Heap SDK.
    ///
    /// Full event details are also printed at this level.
    ///
    /// This level is recommended when gathering information to send to Heap support personnel.
    /// Heap support might also ask that this level be turned on to help debug installation and tracking issues
    /// that require extra investigation.
    ///
    /// This level also includes critical, prod, and dev messages.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func logDebug(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if(logLevel >= LogLevel.debug) {
            logChannel.printLog(logLevel: LogLevel.debug,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func logDebug(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if(logLevel >= LogLevel.debug) {
            logChannel.printLog(logLevel: LogLevel.debug,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif

}
