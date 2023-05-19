import Foundation

@objc(HeapSourceInfo)
public class SourceInfo: NSObject {
    
    public let name: String
    public let version: String
    public let platform: String
    public let properties: [String: HeapPropertyValue]

    public init(name: String, version: String, platform: String, properties: [String: HeapPropertyValue] = [:]) {
        self.name = name
        self.version = version
        self.platform = platform
        self.properties = properties
    }
}


