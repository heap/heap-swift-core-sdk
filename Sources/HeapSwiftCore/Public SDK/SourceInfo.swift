import Foundation

@objc(HeapSourceInfo)
public class SourceInfo: NSObject {
    
    public let name: String
    public let version: String
    public let platform: String
    public let properties: [String: Any]

    public init(name: String, version: String, platform: String, properties: [String: Any] = [:]) {
        self.name = name
        self.version = version
        self.platform = platform
        self.properties = properties
    }
}
