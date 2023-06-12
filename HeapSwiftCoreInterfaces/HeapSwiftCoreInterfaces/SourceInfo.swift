import Foundation

@objc(HeapSourceInfo)
public class SourceInfo: NSObject {
    
    @objc
    public let name: String
    
    @objc
    public let version: String
    
    @objc
    public let platform: String
    
    public let properties: [String: HeapPropertyValue]
    
    public init(name: String, version: String, platform: String, properties: [String: HeapPropertyValue] = [:]) {
        self.name = name
        self.version = version
        self.platform = platform
        self.properties = properties
    }
}

extension SourceInfo {
    
    @objc(sourceInfoWithName:version:platform:properties:)
    public static func __sourceInfo(name: String, version: String, platform: String, properties: [String: HeapObjcPropertyValue]) -> SourceInfo {
        .init(name: name, version: version, platform: platform, properties: properties.mapValues(\.heapValue))
    }
    
    @objc(sourceInfoWithName:version:platform:)
    public static func __sourceInfo(name: String, version: String, platform: String) -> SourceInfo {
        .init(name: name, version: version, platform: platform)
    }
    
    @objc(properties)
    public var __objcProperties: [String: String] {
        properties.mapValues(\.heapValue)
    }
}
