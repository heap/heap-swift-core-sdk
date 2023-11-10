import Foundation
import HeapSwiftCoreInterfaces

public enum InvocationError: Error {
    case unknownMethod
    case invalidParameters
}

public protocol HeapBridgeSupportDelegate: AnyObject {
    func sendInvocation(_ invocation: HeapBridgeSupport.Invocation)
}

public class HeapBridgeSupport
{
    let pageviewStore = BridgedPageviewStore()
    let callbackStore = CallbackStore()
    
    let eventConsumer: any HeapProtocol
    let uploader: any UploaderProtocol
    
    public weak var delegate: (any HeapBridgeSupportDelegate)?
    var delegateTimeout: TimeInterval = 5
    
    init(eventConsumer: any HeapProtocol, uploader: any UploaderProtocol)
    {
        self.eventConsumer = eventConsumer
        self.uploader = uploader
    }

    public func detachListeners() {
        eventConsumer.removeRuntimeBridge(self)
    }
    
    public convenience init() {
        self.init(eventConsumer: Heap.shared.consumer, uploader: Heap.shared.uploader)
    }
    
    public static var shared: HeapBridgeSupport = .init()
    
    public func handleInvocation(method: String, arguments: [String: Any]) throws -> JSONEncodable? {
        
        switch method {
        case "startRecording":
            return try startRecording(arguments: arguments)
        case "stopRecording":
            return try stopRecording()
        case "track":
            return try track(arguments: arguments)
        case "trackPageview":
            return try trackPageview(arguments: arguments)
        case "trackInteraction":
            return try trackInteraction(arguments: arguments)
        case "identify":
            return try identify(arguments: arguments)
        case "resetIdentity":
            return try resetIdentity()
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
            return try sessionId()
        case "fetchSessionId":
            return try fetchSessionId(arguments: arguments)
            
        case "heapLogger_log":
            return try heapLogger_log(arguments: arguments)
        case "heapLogger_logLevel":
            return heapLogger_logLevel()
        case "heapLogger_setLogLevel":
            return try heapLogger_setLogLevel(arguments: arguments)
            
        case "attachRuntimeBridge":
            guard delegate != nil else { return false }
            eventConsumer.addRuntimeBridge(self)
            return true
            
        default:
            HeapLogger.shared.debug("HeapBridgeSupport received an unknown method invocation: \(method).")
            throw InvocationError.unknownMethod
        }
    }
    
    public func handleResult(callbackId: String, data: Any?, error: String?) {
        callbackStore.dispatch(callbackId: callbackId, data: data, error: error)
    }
    
    func startRecording(arguments: [String: Any]) throws -> JSONEncodable? {
        // Reminder: any change in the logic here should also be applied to startRecording in Heap.swift
        let environmentId = try getRequiredString(named: "environmentId", from: arguments, message: "HeapBridgeSupport.startRecording received an invalid environmentId and will not complete the bridged method call.")
        let options = try getOptionalOptionsDictionary(from: arguments)
        eventConsumer.startRecording(environmentId, with: options)
        uploader.startScheduledUploads(with: .init(with: options))
        return nil
    }
    
    func stopRecording() throws -> JSONEncodable? {
        eventConsumer.stopRecording()
        return nil
    }
    
    func track(arguments: [String: Any]) throws -> JSONEncodable? {
        let event = try getRequiredString(named: "event", from: arguments, message: "HeapBridgeSupport.track received an invalid event name and will not complete the bridged method call.")
        let timestamp = try getOptionalTimestamp(arguments, methodName: "track")
        let sourceInfo = try getOptionalSourceLibrary(arguments, methodName: "track")
        let properties = try getOptionalParameterDictionary(named: "properties", from: arguments, message: "HeapBridgeSupport.track received invalid properties and will not complete the bridged method call.")
        let pageview = try getOptionalPageview(from: arguments, methodName: "track")
        eventConsumer.track(event, properties: properties, timestamp: timestamp, sourceInfo: sourceInfo, pageview: pageview)
        return nil
    }
    
    func trackPageview(arguments: [String: Any]) throws -> JSONEncodable? {
        
        let pageviewKey = UUID().uuidString
        let properties = try getPageviewProperties(from: arguments, methodName: "trackPageview")
        let timestamp = try getOptionalTimestamp(arguments, methodName: "trackPageview")
        let sourceInfo = try getOptionalSourceLibrary(arguments, methodName: "trackPageview")
        
        let deadKeys = try getOptionalArrayOfStrings(named: "deadKeys", from: arguments, message: "HeapBridgeSupport.trackPageview received an invalid list of dead keys and will not complete the bridged method call.")
        
        let removedKeys = pageviewStore.remove(deadKeys)
        
        let pageview = eventConsumer.trackPageview(properties, timestamp: timestamp, sourceInfo: sourceInfo, bridge: self, userInfo: pageviewKey)
        
        guard let pageview = pageview else {
            return [
                "removedKeys": removedKeys,
            ]
        }
        
        let additionalRemovedKeys = pageviewStore.add(pageview, at: pageviewKey)
        
        return [
            "pageviewKey": AnyJSONEncodable(wrapped: pageviewKey),
            "sessionId": AnyJSONEncodable(wrapped: pageview.sessionId),
            "removedKeys": AnyJSONEncodable(wrapped: removedKeys + additionalRemovedKeys),
        ]
    }
    
    func trackInteraction(arguments: [String: Any]) throws -> JSONEncodable? {
        let interaction = try getRequiredInteraction(from: arguments, methodName: "trackInteraction")
        let nodes = try getRequiredInteractionNodes(from: arguments, methodName: "trackInteraction")
        let callbackName = try getOptionalString(named: "callbackName", from: arguments, message: "HeapBridgeSupport.trackInteraction received an invalid callback name and will not complete the bridged method call.")
        let timestamp = try getOptionalTimestamp(arguments, methodName: "trackInteraction")
        let sourceInfo = try getOptionalSourceLibrary(arguments, methodName: "trackInteraction")
        let pageview = try getOptionalPageview(from: arguments, methodName: "trackInteraction")
        eventConsumer.trackInteraction(interaction: interaction, nodes: nodes, callbackName: callbackName, timestamp: timestamp, sourceInfo: sourceInfo, pageview: pageview)
        return nil
    }
    
    func identify(arguments: [String: Any]) throws -> JSONEncodable? {
        let identity = try getRequiredString(named: "identity", from: arguments, message: "HeapBridgeSupport.identify received an invalid identity and will not complete the bridged method call.")
        eventConsumer.identify(identity)
        return nil
    }
    
    func resetIdentity() throws -> JSONEncodable? {
        eventConsumer.resetIdentity()
        return nil
    }
    
    func addUserProperties(arguments: [String: Any]) throws -> JSONEncodable? {
        let properties = try getOptionalParameterDictionary(named: "properties", from: arguments, message: "HeapBridgeSupport.addUserProperties received invalid properties and will not complete the bridged method call.")
        eventConsumer.addUserProperties(properties)
        return nil
    }
    
    func addEventProperties(arguments: [String: Any]) throws -> JSONEncodable? {
        let properties = try getOptionalParameterDictionary(named: "properties", from: arguments, message: "HeapBridgeSupport.addEventProperties received invalid properties and will not complete the bridged method call.")
        eventConsumer.addEventProperties(properties)
        return nil
    }
    
    func removeEventProperty(arguments: [String: Any]) throws -> JSONEncodable? {
        let name = try getRequiredString(named: "name", from: arguments, message: "HeapBridgeSupport.removeEventProperty received an invalid property name and will not complete the bridged method call.")
        eventConsumer.removeEventProperty(name)
        return nil
    }
    
    func clearEventProperties() -> JSONEncodable? {
        eventConsumer.clearEventProperties()
        return nil
    }
    
    func userId() -> JSONEncodable? {
        eventConsumer.userId
    }
    
    func identity() -> JSONEncodable? {
        eventConsumer.identity
    }
    
    func sessionId() throws -> JSONEncodable? {
        return eventConsumer.sessionId
    }
    
    func fetchSessionId(arguments: [String: Any]) throws -> JSONEncodable? {
        return eventConsumer.fetchSessionId()
    }

    func heapLogger_log(arguments: [String: Any]) throws -> JSONEncodable? {
        let logLevel = try getRequiredLogLevel(arguments, methodName: "heapLogger_log")
        let message = try getRequiredString(named: "message", from: arguments, message: "HeapBridgeSupport.heapLogger_log received an invalid message and wil not complete the bridged method call.")
        let source = try getOptionalString(named: "source", from: arguments, message: "HeapBridgeSupport.heapLogger_log received an invalid message and wil not complete the bridged method call.")
        switch logLevel
        {
        case .error: HeapLogger.shared.error(message, source: source)
        case .warn: HeapLogger.shared.warn(message, source: source)
        case .info: HeapLogger.shared.info(message, source: source)
        case .debug: HeapLogger.shared.debug(message, source: source)
        case .trace: HeapLogger.shared.trace(message, source: source)
        case .none: break // Let's not bother throwing here.
            
        @unknown default:
            // This is not technically possible since we always link to the same or older versions, but we'll apply a safe default.
            break
        }
        return nil
    }
    
    func heapLogger_logLevel() -> JSONEncodable? {
        switch HeapLogger.shared.logLevel {
        case .error: return "error"
        case .warn: return "warn"
        case .info: return "info"
        case .debug: return "debug"
        case .trace: return "trace"
        case .none: return "none"
        @unknown default:
            // This is not technically possible since we always link to the same or older versions, but we'll apply a safe default.
            return "none"
        }
    }
    
    func heapLogger_setLogLevel(arguments: [String: Any]) throws -> JSONEncodable? {
        HeapLogger.shared.logLevel = try getRequiredLogLevel(arguments, methodName: "heapLogger_log")
        return nil
    }
}

extension HeapBridgeSupport {
    
    func getOptionalString(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> String? {
        guard let rawString = arguments[name] else {
            return nil
        }
        
        guard let value = rawString as? String else {
            HeapLogger.shared.debug(message())
            throw InvocationError.invalidParameters
        }
        return value
    }
    
    func getRequiredString(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> String {
        guard let value = try getOptionalString(named: name, from: arguments, message: message()), !value.isEmpty else {
            HeapLogger.shared.debug(message())
            throw InvocationError.invalidParameters
        }
        return value
    }
    
    func getRequiredLogLevel(_ arguments: [String: Any], methodName: String) throws -> LogLevel {
        let value = try getRequiredString(named: "logLevel", from: arguments, message: "HeapBridgeSupport.\(methodName) received an invalid log level and will not complete the bridged method call.")
        switch value {
        case "error": return .error
        case "warn": return .warn
        case "info": return .info
        case "debug": return .debug
        case "trace": return .trace
        case "none": return .none
        default:
            HeapLogger.shared.debug("HeapBridgeSupport.\(methodName) received an invalid log level and will not complete the bridged method call.")
            throw InvocationError.invalidParameters
        }
    }
    
    func getOptionalTimestamp(_ arguments: [String: Any], methodName: String) throws -> Date {
        guard let rawTimestamp = arguments["javascriptEpochTimestamp"] else {
            return Date()
        }
        
        guard let timestamp = rawTimestamp as? Double else {
            HeapLogger.shared.debug("HeapBridgeSupport.\(methodName) received an invalid timestamp and will not complete the bridged method call.")
            throw InvocationError.invalidParameters
        }
        
        return Date(timeIntervalSince1970: timestamp / 1000)
    }
    
    func getOptionalUrl(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> URL? {
        guard let string = try getOptionalString(named: name, from: arguments, message: message()) else { return nil }
        
        guard let url = URL(string: string) else {
            HeapLogger.shared.debug(message())
            throw InvocationError.invalidParameters
        }
        
        return url
    }
    
    func getOptionalPageview(from arguments: [String: Any], methodName: String) throws -> Pageview? {
        guard let pageviewKey = try getOptionalString(named: "pageviewKey", from: arguments, message: "HeapBridgeSupport.\(methodName) received an invalid pageview key and will not complete the bridged method call.") else { return nil }
        
        if pageviewKey == "none" {
            return Pageview.none
        }
        
        guard let pageview = pageviewStore.get(pageviewKey) else {
            HeapLogger.shared.trace("The passed in pageview key \(pageviewKey) does not exist. It may have been culled.")
            return nil
        }
        
        return pageview
    }
    
    func getRequiredInteraction(from arguments: [String: Any], methodName: String) throws -> Interaction {
        guard let rawValue = arguments["interaction"] else {
            HeapLogger.shared.debug("HeapBridgeSupport.\(methodName) received an event without an interaction type and will not complete the bridged method call.")
            throw InvocationError.invalidParameters
        }
        
        if let builtinName = rawValue as? String {
            switch builtinName {
            case "unspecified": return .unspecified
            case "click": return .click
            case "touch": return .touch
            case "change": return .change
            case "submit": return .submit
            default:
                HeapLogger.shared.debug("HeapBridgeSupport.\(methodName) received an an unknown interaction type, \(builtinName), and will not complete the bridged method call.")
                throw InvocationError.invalidParameters
            }
        }
        
        if let rawDictionary = rawValue as? [String: Any] {
            if let name = rawDictionary["custom"] as? String {
                return .custom(name)
            }
            
            if let value = rawDictionary["builtin"] as? Int {
                return .builtin(value)
            }
        }
        
        HeapLogger.shared.debug("HeapBridgeSupport.\(methodName) received an an invalid interaction type and will not complete the bridged method call.")
        throw InvocationError.invalidParameters
    }
    
    func getRequiredInteractionNodes(from arguments: [String: Any], methodName: String) throws -> [InteractionNode] {
        
        guard
            let rawArray = arguments["nodes"] as? [Any],
            !rawArray.isEmpty
        else {
            HeapLogger.shared.debug("HeapBridgeSupport.\(methodName) received an event without a list of nodes and will not complete the bridged method call.")
            throw InvocationError.invalidParameters
        }
        
        return try rawArray.map(getInteractionNode(_:))
        
        func message() -> String { "HeapBridgeSupport.\(methodName) received an invalid list of nodes and will not complete the bridged method call." }
        
        func getInteractionNode(_ rawNode: Any) throws -> InteractionNode {
            guard let rawObject = rawNode as? [String: Any] else {
                HeapLogger.shared.debug(message())
                throw InvocationError.invalidParameters
            }
            
            var node = InteractionNode(nodeName: try getRequiredString(named: "nodeName", from: rawObject, message: message()))
            node.nodeText = try getOptionalString(named: "nodeText", from: rawObject, message: message())
            node.nodeHtmlClass = try getOptionalString(named: "nodeHtmlClass", from: rawObject, message: message())
            node.nodeId = try getOptionalString(named: "nodeId", from: rawObject, message: message())
            node.href = try getOptionalString(named: "href", from: rawObject, message: message())
            node.accessibilityLabel = try getOptionalString(named: "accessibilityLabel", from: rawObject, message: message())
            node.referencingPropertyName = try getOptionalString(named: "referencingPropertyName", from: rawObject, message: message())
            node.attributes = try getOptionalParameterDictionary(named: "attributes", from: rawObject, message: message())
            return node
        }
    }
    
    func getOptionalArrayOfStrings(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> [String] {
        guard let rawArray = arguments[name] else {
            return []
        }
        
        guard let value = rawArray as? [String] else {
            HeapLogger.shared.debug(message())
            throw InvocationError.invalidParameters
        }
        return value
    }
    
    func getOptionalSourceLibrary(_ arguments: [String: Any], methodName: String) throws -> SourceInfo? {
        func errorMessage() -> String {
            "HeapBridgeSupport.\(methodName) received an invalid sourceLibrary and will not complete the bridged method call."
        }
        
        guard let rawDictionary = arguments["sourceLibrary"] else { return nil }
        guard let sourceLibrary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.debug(errorMessage())
            throw InvocationError.invalidParameters
        }
        
        return .init(
            name: try getRequiredString(named: "name", from: sourceLibrary, message: errorMessage()),
            version: try getRequiredString(named: "version", from: sourceLibrary, message: errorMessage()),
            platform: try getRequiredString(named: "platform", from: sourceLibrary, message: errorMessage()),
            properties: try getOptionalParameterDictionary(named: "properties", from: sourceLibrary, message: errorMessage())
        )
    }
    
    func getOptionalParameterDictionary(named name: String, from arguments: [String: Any], message: @autoclosure () -> String) throws -> [String: HeapPropertyValue] {
        guard let rawDictionary = arguments[name] else { return [:] }
        guard let dictionary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.debug(message())
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
                HeapLogger.shared.debug("Omitting unsupported property type: \(type(of: value))")
                return nil
            }
        }
    }
    
    func getOptionalOptionsDictionary(from arguments: [String: Any]) throws -> [Option: Any] {
        
        guard let rawDictionary = arguments["options"] else { return [:] }
        guard let dictionary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.debug("HeapBridgeSupport.startRecording received an invalid options parameter.")
            throw InvocationError.invalidParameters
        }
        
        let keysAndValues: [(Option, Any)] = dictionary.compactMap { (key, value) in
            
            guard let option = Option.named(key) else {
                HeapLogger.shared.debug("HeapBridgeSupport.startRecording received an unknown option, \(key). It will be ignored.")
                return nil
            }
            
            return (option, value)
        }
        
        return [Option: Any].init(keysAndValues, uniquingKeysWith: { $1 })
    }
    
    func getPageviewProperties(from arguments: [String: Any], methodName: String) throws -> PageviewProperties {
        
        func errorMessage() -> String {
            "HeapBridgeSupport.\(methodName) received an invalid properties and will not complete the bridged method call."
        }
        
        guard let rawDictionary = arguments["properties"],
              let dictionary = rawDictionary as? [String: Any] else {
            HeapLogger.shared.debug(errorMessage())
            throw InvocationError.invalidParameters
        }
        
        return try .with {
            $0.componentOrClassName = try getOptionalString(named: "componentOrClassName", from: dictionary, message: errorMessage())
            $0.title = try getOptionalString(named: "title", from: dictionary, message: errorMessage())
            $0.url = try getOptionalUrl(named: "url", from: dictionary, message: errorMessage())
            $0.sourceProperties = try getOptionalParameterDictionary(named: "sourceProperties", from: dictionary, message: errorMessage())
        }
    }
}

extension HeapBridgeSupport: RuntimeBridge {
    
    func invokeOnBridge(method: String, arguments: [String: AnyJSONEncodable], complete: @escaping Callback) {
        
        guard let delegate = delegate else {
            complete(.failure(.init(message: "No delegate")))
            return
        }
        
        let callbackId = callbackStore.add(timeout: delegateTimeout, callback: complete)
        
        delegate.sendInvocation(.init(method: method, arguments: arguments.mapValues({ $0._toHeapJSON() }), callbackId: callbackId))
    }
    
    // TODO: Package all of these as invocations, send to the delegate, and wait for a response.
    
    public func didStartRecording(options: [Option : Any], complete: @escaping () -> Void) {
        invokeOnBridge(method: "didStartRecording", arguments: ["options": options.toJsonEncodable()]) { _ in
            complete()
        }
    }
    
    public func didStopRecording(complete: @escaping () -> Void) {
        invokeOnBridge(method: "didStopRecording", arguments: [:]) { _ in
            complete()
        }
    }
    
    public func sessionDidStart(sessionId: String, timestamp: Date, foregrounded: Bool, complete: @escaping () -> Void) {
        invokeOnBridge(method: "sessionDidStart", arguments: [
            "sessionId": AnyJSONEncodable(wrapped: sessionId),
            "javascriptEpochTimestamp": AnyJSONEncodable(wrapped: timestamp.timeIntervalSince1970 * 1000),
            "foregrounded": AnyJSONEncodable(wrapped: foregrounded),
        ]) { _ in
            complete()
        }
    }
    
    public func applicationDidEnterForeground(timestamp: Date, complete: @escaping () -> Void) {
        invokeOnBridge(method: "applicationDidEnterForeground", arguments: [
            "javascriptEpochTimestamp": AnyJSONEncodable(wrapped: timestamp.timeIntervalSince1970 * 1000),
        ]) { _ in
            complete()
        }
    }
    
    public func applicationDidEnterBackground(timestamp: Date, complete: @escaping () -> Void) {
        invokeOnBridge(method: "applicationDidEnterBackground", arguments: [
            "javascriptEpochTimestamp": AnyJSONEncodable(wrapped: timestamp.timeIntervalSince1970 * 1000),
        ]) { _ in
            complete()
        }
    }
    
    public func reissuePageview(_ pageview: HeapSwiftCoreInterfaces.Pageview, sessionId: String, timestamp: Date, complete: @escaping (HeapSwiftCoreInterfaces.Pageview?) -> Void) {
        
        guard let pageviewKey = pageviewStore.key(for: pageview) else {
            complete(nil)
            return
        }
        
        invokeOnBridge(method: "reissuePageview", arguments: [
            "pageviewKey": AnyJSONEncodable(wrapped: pageviewKey),
            "sessionId": AnyJSONEncodable(wrapped: sessionId),
            "javascriptEpochTimestamp": AnyJSONEncodable(wrapped: timestamp.timeIntervalSince1970 * 1000),
        ]) { result in
            let pageview: Pageview?
            switch result {
            case .success(let value):
                if let pageviewKey = value as? String,
                   let foundPageview = self.pageviewStore.get(pageviewKey) {
                    pageview = foundPageview
                } else {
                    HeapLogger.shared.trace("HeapBridgeSupport.reissuePageview returned an unknown pageview key.")
                    pageview = nil
                }
            case .failure(let error):
                HeapLogger.shared.trace("HeapBridgeSupport.reissuePageview failed: \(error.message)")
                pageview = nil
            }
            complete(pageview)
        }
    }
}

extension Dictionary where Key == Option, Value == Any {
    
    func jsonEncodable(at key: Option) -> AnyJSONEncodable? {
        switch key.type {
        case .string: return string(at: key).map(AnyJSONEncodable.init(wrapped:))
        case .boolean: return boolean(at: key).map(AnyJSONEncodable.init(wrapped:))
        case .timeInterval: return timeInterval(at: key).map(AnyJSONEncodable.init(wrapped:))
        case .integer: return integer(at: key).map(AnyJSONEncodable.init(wrapped:))
        case .url: return url(at: key).map(\.absoluteString).map(AnyJSONEncodable.init(wrapped:))
        default: return nil
        }
    }
    
    func toJsonEncodable() -> AnyJSONEncodable {
        AnyJSONEncodable(wrapped: [String: AnyJSONEncodable](compactMap({ (key, value) -> (String, AnyJSONEncodable)? in
            guard let value = jsonEncodable(at: key) else { return nil }
            return (key.name, value)
        }), uniquingKeysWith: { (l, r) in l }))
    }
}
