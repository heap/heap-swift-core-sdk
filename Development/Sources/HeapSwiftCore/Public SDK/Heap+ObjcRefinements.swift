import Foundation

@objc
public protocol HeapObjcPropertyValue: NSObjectProtocol {
    var heapValue: String { get }
}

extension NSString: HeapObjcPropertyValue, HeapPropertyValue {
    public var heapValue: String { return self as String }
}

extension NSNumber: HeapObjcPropertyValue, HeapPropertyValue {
    public var heapValue: String {
        if CFGetTypeID(self) == CFBooleanGetTypeID() {
            return self.boolValue ? "true" : "false"
        }
        return self.stringValue
    }
}

public extension Heap {
    
    @objc(startRecording:)
    func __startRecording(_ environmentId: String) {
        startRecording(environmentId)
    }
    
    @objc(track:)
    func __track(_ event: String) {
        track(event)
    }
    
    @objc(track:properties:)
    func __track(_ event: String, properties: [String: HeapObjcPropertyValue]) {
        track(event, properties: properties.mapValues(\.heapValue))
    }
    
    @objc(addUserProperties:)
    func __addUserProperties(_ properties: [String: HeapObjcPropertyValue]) {
        addUserProperties(properties.mapValues(\.heapValue))
    }

    @objc(addEventProperties:)
    func __addEventProperties(_ properties: [String: HeapObjcPropertyValue]) {
        addEventProperties(properties.mapValues(\.heapValue))
    }
}
