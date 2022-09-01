import Foundation

#if os(iOS) || os(tvOS)

import UIKit

extension UIApplication {
    var currentAppVisibility: Event.AppVisibility {
        switch applicationState {
        case .active: return .foregrounded
        case .inactive: return .foregrounded
        case .background: return .backgrounded
        default: return .unknown
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
        guard Thread.isMainThread else { return .unknown }
        return application?.currentAppVisibility ?? .unknown
    }
}

#elseif os(macOS)

import Cocoa

extension NSApplication {
    var currentAppVisibility: Event.AppVisibility {
        return isActive ? .foregrounded : .backgrounded
    }
}

extension Event.AppVisibility {
    
    static var current: Event.AppVisibility {
        guard Thread.isMainThread else { return .unknown }
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
        default: return .unknown
        }
    }
}

extension Event.AppVisibility {
    
    static var current: Event.AppVisibility {
        guard Thread.isMainThread else { return .unknown }
        return WKExtension.shared().currentAppVisibility
    }
}

#else

extension Event.AppVisibility {
    
    static var current: Event.AppVisibility {
        .unknown
    }
}

#endif
