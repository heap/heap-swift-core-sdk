import Foundation
import HeapSwiftCoreInterfaces

struct UploaderSettings {
    var uploadInterval: TimeInterval
    var baseUrl: URL?
    var messageBatchByteLimit: Int
    var messageBatchMessageLimit: Int
    
    static let `default` = UploaderSettings(
        uploadInterval: 15,
        baseUrl: URL(string: "https://c.us.heap-api.com/"),
        messageBatchByteLimit: 1_000_000,
        messageBatchMessageLimit: 200
    )
}

extension UploaderSettings {
    
    init(with options: [Option: Any]) {
        
        let base = Self.default
        
        self.init(
            uploadInterval: options.timeInterval(at: .uploadInterval) ?? base.uploadInterval,
            baseUrl: options.url(at: .baseUrl) ?? base.baseUrl,
            messageBatchByteLimit: options.integer(at: .messageBatchByteLimit) ?? base.messageBatchByteLimit,
            messageBatchMessageLimit: options.integer(at: .messageBatchMessageLimit) ?? base.messageBatchMessageLimit
        )
    }
    
    static func with(_ config: (_ settings: inout Self) -> Void) -> Self {
        var instance = Self.default
        config(&instance)
        return instance
    }
}

struct FieldSettings {
    var captureAdvertiserId: Bool
    var captureVendorId: Bool
    var capturePageviewTitle: Bool
    var captureInteractionText: Bool
    var captureInteractionAccessibilityLabel: Bool
    var maxInteractionNodeCount: Int
    
    static let `default` = FieldSettings(
        captureAdvertiserId: false,
        captureVendorId: false,
        capturePageviewTitle: true,
        captureInteractionText: true,
        captureInteractionAccessibilityLabel: true,
        maxInteractionNodeCount: 30
    )
}

extension FieldSettings {
    
    init(with options: [Option: Any]) {
        
        let base = Self.default
        
        func negated(_ option: Option) -> Bool? {
            options.boolean(at: option).map({ !$0 })
        }
        
        self.init(
            captureAdvertiserId: options.boolean(at: .captureAdvertiserId) ?? base.captureAdvertiserId,
            captureVendorId: options.boolean(at: .captureVendorId) ?? base.captureVendorId,
            capturePageviewTitle: negated(.disablePageviewTitleCapture) ?? base.capturePageviewTitle,
            captureInteractionText: negated(.disableInteractionTextCapture) ?? base.captureInteractionText,
            captureInteractionAccessibilityLabel: negated(.disableInteractionAccessibilityLabelCapture) ?? base.captureInteractionAccessibilityLabel,
            maxInteractionNodeCount: options.integer(at: .interactionHierarchyCaptureLimit) ?? base.maxInteractionNodeCount
        )
    }
    
    static func with(_ config: (_ settings: inout Self) -> Void) -> Self {
        var instance = Self.default
        config(&instance)
        return instance
    }
}

struct BehaviorSettings {
    var startSessionImmediately: Bool
    var clearEventPropertiesOnNewUser: Bool
    var resumePreviousSession: Bool
    
    static let `default` = BehaviorSettings(
        startSessionImmediately: false,
        clearEventPropertiesOnNewUser: false,
        resumePreviousSession: false
    )
}

extension BehaviorSettings {
    
    init(with options: [Option: Any]) {
        
        let base = Self.default
        
        self.init(
            startSessionImmediately: options.boolean(at: .startSessionImmediately) ?? base.startSessionImmediately,
            clearEventPropertiesOnNewUser: options.boolean(at: .clearEventPropertiesOnNewUser) ?? base.clearEventPropertiesOnNewUser,
            resumePreviousSession: options.boolean(at: .resumePreviousSession) ?? base.resumePreviousSession
        )
    }
    
    static func with(_ config: (_ settings: inout Self) -> Void) -> Self {
        var instance = Self.default
        config(&instance)
        return instance
    }
}
