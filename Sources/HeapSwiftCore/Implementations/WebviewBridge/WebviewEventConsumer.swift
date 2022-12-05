#if canImport(WebKit)

import WebKit

enum InvocationError: Error {
    case unknownMethod
    case invalidParameters
}

class WebviewEventConsumer {
    
    let eventConsumer: any EventConsumerProtocol
    
    init(eventConsumer: any EventConsumerProtocol) {
        self.eventConsumer = eventConsumer
    }
    
    func handleInvocation(method: String, arguments: [String: Any]) throws -> JSON {
        
        switch method {
        case "startRecording":
            return try startRecording(arguments: arguments)
        case "stopRecording":
            return try stopRecording(arguments: arguments)
        case "track":
            return try track(arguments: arguments)
        case "trackPageview":
            return try trackPageview(arguments: arguments)
        case "identify":
            return try identify(arguments: arguments)
        case "resetIdentity":
            return try resetIdentity(arguments: arguments)
        case "addUserProperties":
            return try addUserProperties(arguments: arguments)
        case "addEventProperties":
            return try addEventProperties(arguments: arguments)
        case "removeEventProperty":
            return try removeEventProperty(arguments: arguments)
        case "clearEventProperties":
            return clearEventProperties()
        case "userId":
            return userId()
        case "identity":
            return identity()
        case "sessionId":
            return try sessionId(arguments: arguments)
        default:
            HeapLogger.shared.logDev("Web view received an unknown method invocation: \(method).")
            throw InvocationError.unknownMethod
        }
    }
    
    func startRecording(arguments: [String: Any]) throws -> JSON {
        let environmentId = try getRequiredString(named: "environmentId", from: arguments, message: "Web view sent invalid environmentId to Heap.startRecording.")
        let options = try getOptionalOptionsDictionary(from: arguments)
        let timestamp = try getOptionalTimestamp(arguments)
        eventConsumer.startRecording(environmentId, with: options, timestamp: timestamp)
        return .null
    }
    
    func stopRecording(arguments: [String: Any]) throws -> JSON {
        let timestamp = try getOptionalTimestamp(arguments)
        eventConsumer.stopRecording(timestamp: timestamp)
        return .null
    }
    
    func track(arguments: [String: Any]) throws -> JSON {
        let event = try getRequiredString(named: "event", from: arguments, message: "Web view sent invalid event name to Heap.track.")
        let timestamp = try getOptionalTimestamp(arguments)
        let sourceInfo = try getOptionalSourceLibrary(arguments)
        let properties = try getOptionalParameterDictionary(named: "properties", from: arguments, message: "Web view sent invalid properties to Heap.track.")
        eventConsumer.track(event, properties: properties, timestamp: timestamp, sourceInfo: sourceInfo, pageview: nil)
        return .null
    }
    
    func trackPageview(arguments: [String: Any]) throws -> JSON {
        HeapLogger.shared.logDev("trackPageview for web views is not yet implemented.")
        throw InvocationError.unknownMethod
    }
    
    func identify(arguments: [String: Any]) throws -> JSON {
        let event = try getRequiredString(named: "identity", from: arguments, message: "Web view sent an invalid identity to Heap.identify.")
        let timestamp = try getOptionalTimestamp(arguments)
        eventConsumer.identify(event, timestamp: timestamp)
        return .null
    }
    
    func resetIdentity(arguments: [String: Any]) throws -> JSON {
        let timestamp = try getOptionalTimestamp(arguments)
        eventConsumer.resetIdentity(timestamp: timestamp)
        return .null
    }
    
    func addUserProperties(arguments: [String: Any]) throws -> JSON {
        let properties = try getOptionalParameterDictionary(named: "properties", from: arguments, message: "Web view sent invalid properties to Heap.addUserProperties.")
        eventConsumer.addUserProperties(properties)
        return .null
    }
    
    func addEventProperties(arguments: [String: Any]) throws -> JSON {
        let properties = try getOptionalParameterDictionary(named: "properties", from: arguments, message: "Web view sent invalid properties to Heap.addEventProperties.")
        eventConsumer.addEventProperties(properties)
        return .null
    }
    
    func removeEventProperty(arguments: [String: Any]) throws -> JSON {
        let name = try getRequiredString(named: "name", from: arguments, message: "Web view sent invalid name to Heap.removeEventProperty.")
        eventConsumer.removeEventProperty(name)
        return .null
    }
    
    func clearEventProperties() -> JSON {
        eventConsumer.clearEventProperties()
        return .null
    }
    
    func userId() -> JSON {
        if let userId = eventConsumer.userId {
            return .string(userId)
        } else {
            return .null
        }
    }
    
    func identity() -> JSON {
        if let identity = eventConsumer.identity {
            return .string(identity)
        } else {
            return .null
        }
    }
    
    func sessionId(arguments: [String: Any]) throws -> JSON {
        let timestamp = try getOptionalTimestamp(arguments)
        if let sessionId = eventConsumer.getSessionId(timestamp: timestamp) {
            return .string(sessionId)
        } else {
            return .null
        }
    }
}

extension WebviewEventConsumer {
    
    func getRequiredString(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> String {
        guard let value = arguments[name] as? String, !value.isEmpty else {
            HeapLogger.shared.logDev(message())
            throw InvocationError.invalidParameters
        }
        return value
    }
    
    func getOptionalTimestamp(_ arguments: [String: Any]) throws -> Date {
        guard let rawTimestamp = arguments["javascriptEpochTimestamp"] else {
            return Date()
        }
        
        guard let timestamp = rawTimestamp as? Double else {
            HeapLogger.shared.logDev("Web view sent invalid timestamp to Heap.track.")
            throw InvocationError.invalidParameters
        }
        
        return Date(timeIntervalSince1970: timestamp / 1000)
    }
    
    func getOptionalSourceLibrary(_ arguments: [String: Any]) throws -> SourceInfo? {
        guard let rawDictionary = arguments["sourceLibrary"] else { return nil }
        guard let sourceLibrary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.logDev("Web view sent invalid sourceLibrary to Heap.track.")
            throw InvocationError.invalidParameters
        }

        
        return .init(
            name: try getRequiredString(named: "name", from: sourceLibrary, message: "Web view sent invalid sourceLibrary to Heap.track."),
            version: try getRequiredString(named: "version", from: sourceLibrary, message: "Web view sent invalid sourceLibrary to Heap.track."),
            platform: try getRequiredString(named: "platform", from: sourceLibrary, message: "Web view sent invalid sourceLibrary to Heap.track."),
            properties: try getOptionalParameterDictionary(named: "properties", from: sourceLibrary, message: "Web view sent invalid sourceLibrary to Heap.track.")
        )
    }
    
    func getOptionalParameterDictionary(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> [String: HeapPropertyValue] {
        guard let rawDictionary = arguments[name] else { return [:] }
        guard let dictionary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.logDev(message())
            throw InvocationError.invalidParameters
        }
        
        return dictionary.compactMapValues { value in
            if let value = value as? String {
                return value
            } else if let value = value as? Bool {
                return value
            } else if let value = value as? Int {
                return value
            } else if let value = value as? Double {
                return value
            } else {
                HeapLogger.shared.logDev("Omitting unsupported property type: \(type(of: value))")
                return nil
            }
        }
    }
    
    func getOptionalOptionsDictionary(from arguments: [String: Any]) throws -> [Option: Any] {
        
        guard let rawDictionary = arguments["options"] else { return [:] }
        guard let dictionary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.logDev("Web view sent an invalid options parameter to Heap.startRecording.")
            throw InvocationError.invalidParameters
        }
        
        let keysAndValues: [(Option, Any)] = dictionary.compactMap { (key, value) in
            
            guard let option = Option.named(key) else {
                HeapLogger.shared.logDev("Web view sent an unknown option, \(key), to Heap.startRecording. It will be ignored.")
                return nil
            }
            
            return (option, value)
        }
        
        return [Option: Any].init(keysAndValues, uniquingKeysWith: { $1 })
    }
}

#endif
