import Foundation
import HeapSwiftCoreInterfaces

final public class ConcretePageview: Pageview {
    internal let sessionInfo: SessionInfo
    internal let pageviewInfo: PageviewInfo
    internal let sourceLibrary: LibraryInfo?
    internal weak var bridge: RuntimeBridge?
    internal let isFromBridge: Bool
    
    internal init(
        sessionInfo: SessionInfo,
        pageviewInfo: PageviewInfo,
        sourceLibrary: LibraryInfo?,
        bridge: RuntimeBridge?,
        properties: PageviewProperties,
        timestamp: Date,
        sourceInfo: SourceInfo?,
        userInfo: Any?
    ) {
        self.sessionInfo = sessionInfo
        self.pageviewInfo = pageviewInfo
        self.sourceLibrary = sourceLibrary
        self.bridge = bridge
        self.isFromBridge = bridge != nil
        super.init(sessionId: sessionInfo.id, properties: properties, timestamp: timestamp, sourceInfo: sourceInfo, userInfo: userInfo)
    }
}
