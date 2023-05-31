#if os(iOS)

import UIKit
import CoreTelephony

extension DeviceInfo {
    
    /// Returns the specific model name of the current device.
    ///
    /// `UIDevice.model` only provides a generic model name (e.g., "iPhone"). This method, on the other hand,
    /// utilizes `sysctlbyname` to retrieve the detailed hardware identifier (e.g., "iPhone10,3" for iPhone X).
    /// If `sysctlbyname` fails, the function returns `nil`.
    var detailedModelName: String? {
        var size: Int = 0
        guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0 else { return nil }
        var machine = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.machine", &machine, &size, nil, 0) == 0 else { return nil }
        return String(cString: machine)
    }
    
    static func current(with settings: FieldSettings, includeCarrier: Bool) -> DeviceInfo {
        let device = UIDevice.current
        var deviceInfo = DeviceInfo()
        deviceInfo.type = getDeviceType(device)
        deviceInfo.platform = getPlatform(device)
        deviceInfo.model = getMacModel() ?? deviceInfo.detailedModelName ?? device.model
        if includeCarrier,
           let carrier = getCarrier() {
            deviceInfo.carrier = carrier
        }
        deviceInfo.setIfNotNil(\.vendorID, device.identifierForVendor?.uuidString)
        deviceInfo.setIfNotNil(\.advertiserID, getAdvertisingIdentifier(with: settings))
        
        return deviceInfo
    }
    
    private static func getCarrier() -> String? {
#if targetEnvironment(macCatalyst)
        return nil
#else
        let info = CTTelephonyNetworkInfo()
        guard let radioKeys = info.serviceCurrentRadioAccessTechnology?.keys,
              let carrier = info.serviceSubscriberCellularProviders?.first(where: {
                  radioKeys.contains($0.key) && $0.value.carrierName != nil
              })?.value
        else { return nil }
        
        return carrier.carrierName
#endif
    }
    
    private static func getPlatform(_ device: UIDevice) -> String {
#if targetEnvironment(macCatalyst)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = version.patchVersion > 0 ? "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)" : "\(version.majorVersion).\(version.minorVersion)"
        return "macOS \(versionString) (Catalyst \(device.systemVersion))"
#else
        return "iOS \(device.systemVersion)"
#endif
    }
    
    private static func getDeviceType(_ device: UIDevice) -> DeviceInfo.DeviceType {
#if targetEnvironment(macCatalyst)
        return .desktop
#else
        switch device.userInterfaceIdiom {
        case .mac: return .desktop
        case .carPlay: return .automotive
        case .pad: return .tablet
        case .phone: return .mobile
        case .tv: return .tv
        default: return .unknownUnspecified
        }
#endif
    }
}
#endif
