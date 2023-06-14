import Foundation
import HeapSwiftCoreInterfaces

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
    
    @objc(track:properties:sourceInfo:)
    func __track(_ event: String, properties: [String: HeapObjcPropertyValue], sourceInfo: SourceInfo?) {
        track(event, properties: properties.mapValues(\.heapValue), sourceInfo: sourceInfo)
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
