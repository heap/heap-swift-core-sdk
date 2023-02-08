import Foundation

#if canImport(UIKit) && !os(watchOS)

import UIKit

extension UIApplication {
    var currentAppVisibility: Event.AppVisibility {
        switch applicationState {
        case .active: return .foregrounded
        case .inactive: return .foregrounded
        case .background: return .backgrounded
        default: return .unknownUnspecified
        }
    }

    static var sharedWithExtensionCheck: UIApplication? {
        guard Bundle.main.bundleURL.pathExtension != "appex" else { return nil }
        return UIApplication.value(forKey: "sharedApplication") as? UIApplication
    }
}

extension Event.AppVisibility {
    
    private static let application = UIApplication.sharedWithExtensionCheck
    
    static var current: Event.AppVisibility {
        guard Thread.isMainThread else { return .unknownUnspecified }
        return application?.currentAppVisibility ?? .unknownUnspecified
    }
}

#elseif canImport(AppKit)

import Cocoa

extension NSApplication {
    var currentAppVisibility: Event.AppVisibility {
        return isActive ? .foregrounded : .backgrounded
    }
}

extension Event.AppVisibility {
    
    static var current: Event.AppVisibility {
        guard Thread.isMainThread else { return .unknownUnspecified }
        return NSApplication.shared.currentAppVisibility
    }
}

#elseif os(watchOS)

import WatchKit

extension WKExtension {
    
    var currentAppVisibility: Event.AppVisibility {
        switch applicationState {
        case .active: return .foregrounded
        case .inactive: return .foregrounded
        case .background: return .backgrounded
        default: return .unknownUnspecified
        }
    }
}

extension Event.AppVisibility {
    
    static var current: Event.AppVisibility {
        guard Thread.isMainThread else { return .unknownUnspecified }
        return WKExtension.shared().currentAppVisibility
    }
}

#else

extension Event.AppVisibility {
    
    static var current: Event.AppVisibility {
        .unknownUnspecified
    }
}

#endif
