import Foundation
import OSLog

@objc(HeapLogLevel)
public enum LogLevel: Int, Comparable {

    /// Heap will not print any log messages.
    case none = 0
    
    /// Heap will only print the most critical log messages, such as when the SDK encounters an error and needs to shutdown.
    case error = 10
    
    /// Heap will print messages that about issues it encounters are useful in a production environment, such as when uploads
    /// fail or data is lost or discarded.
    ///
    /// This level also includes `error` messages.
    case warn = 20
    
    /// Heap will print messages that are useful in a production environment, such as when recording starts/stops, when a
    /// batch of events is successfully sent, or when a new session has begun.
    ///
    /// This level is recommended for production environments so that developers can see Heap lifecycle
    /// messages in their own logging environment.
    ///
    /// This level also includes `error` and `warn` messages.
    ///
    case info = 30
    
    /// Heap will print messages that the implementing developer might find helpful. Messages might include things such as
    /// invalid environment ID value, truncated event names, or attempting to track an event before recording has started.
    ///
    /// This level is recommended for implementing developers during the development process to help with debugging
    /// normal installation and tracking issues.
    ///
    /// This level also includes `error`, `warn`, and `info` messages.
    case debug = 40
    
    /// Heap will print message that help the Heap team diagnose SDK issues. Heap support might ask the implementing
    /// developers to enable this log level to gain better insight into issues developers are encounter when implementing the Heap SDK.
    ///
    /// Full event details are also printed at this level.
    ///
    /// This level is recommended when gathering information to send to Heap support personnel. Heap support might also ask
    /// that this level be turned on to help debug installation and tracking issues that require extra investigation.
    ///
    /// This level also includes `error`, `warn`, `info`, and `debug` messages.
    case trace = 50

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
        case .trace where log.isEnabled(type: .debug):
            os_log(.debug, log: log, "%s[TRACE] %s\n    File: %s\n    Line: %lld", source, message(), file, UInt64(line))
        case .debug where log.isEnabled(type: .default):
            os_log(.default, log: log, "%s[DEBUG] %s\n", source, message())
        case .info where log.isEnabled(type: .default):
            os_log(.default, log: log, "%s[INFO] %s\n", source, message())
        case .warn where log.isEnabled(type: .default):
            os_log(.default, log: log, "%s[WARN] %s\n", source, message())
        case .error where log.isEnabled(type: .error):
            os_log(.error, log: log, "%s[ERROR] %s\n", source, message())
        default:
            break
        }
    }
}

/// DO NOT USE
/// This class is an internal implementation detail of the SDK and should NOT be used
/// directly by developers implementing the SDK. It is public for internal purposes only.
///
/// Please refer to the SDK documentation for the appropriate public classes and methods
/// to use when integrating the SDK into your project.
///
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
    public var logLevel: LogLevel = .info
    
    /// The logging channel to route all logs,
    public var logChannel: LogChannel = DefaultLogChannel()

       
    /// Logs a message at the error log level.
    ///
    /// Use this to alert app developers of major issues encountered in the SDK, typically ones that would require the SDK to
    /// shutdown.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func error(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if logLevel >= .error {
            logChannel.printLog(logLevel: .error,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
        // TODO: These messages should also go to logz.
    }
#else
    public func error(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if logLevel >= .error {
            logChannel.printLog(logLevel: .error,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
        // TODO: These messages should also go to logz.
    }
#endif
    
    /// Logs a message at the warning log level.
    ///
    /// This should be used for infrequent messages to notify app developers of issues that occurred in the SDK that are useful in a
    /// production environment, such as when uploads fail or data is lost or discarded.  These messages are shown by default in
    /// production environments.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func warn(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if logLevel >= .warn {
            logChannel.printLog(logLevel: .warn,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func warn(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if logLevel >= .warn {
            logChannel.printLog(logLevel: .warn,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif
    
    /// Logs a message at the info log level.
    ///
    /// This should be used for infrequent messages to acknowledge that Heap is functioning.  These messages are shown by default in
    /// production environments.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func info(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if logLevel >= .info {
            logChannel.printLog(logLevel: .info,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func info(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if logLevel >= .info {
            logChannel.printLog(logLevel: .info,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif

    /// Logs a message at the debug log level.
    ///
    /// This should be used to confirm that Heap is working on or has completed a task, or to inform of low-level transformations
    /// that may have been done to data (such as truncation).
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func debug(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if logLevel >= .debug {
            logChannel.printLog(logLevel: .debug,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func debug(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if logLevel >= .debug {
            logChannel.printLog(logLevel: .debug,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif

    /// Logs a message at the trace log level.
    ///
    /// This should be used to log messages that are useful in SDK development to isolate and understand issues.  These messages do
    /// not need to be tidy or usable directly by app developers.
    ///
    /// - Parameters:
    ///   - message: The message to be logged. `message` can be used with any string interpolation literal.
    ///   - source: The source this log messages originates from.
    ///   - file: The file this log message originates from (there's usually no need to pass it explicitly as it defaults to `#file`).
    ///   - line: The line this log message originates from (there's usually no need to pass it explicitly as it defaults to `#line`).
#if compiler(>=5.3)
    public func trace(_ message: @autoclosure () -> String, source: String? = nil, file: String = #fileID, line: UInt = #line) {
        if logLevel >= .trace {
            logChannel.printLog(logLevel: .trace,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#else
    public func trace(_ message: @autoclosure () -> String, source: String? = nil, file: String = #file, line: UInt = #line) {
        if logLevel >= .trace {
            logChannel.printLog(logLevel: .trace,
                                message: message,
                                source: source,
                                file: file,
                                line: line)
        }
    }
#endif

}
