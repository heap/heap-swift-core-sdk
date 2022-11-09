#if os(iOS)

import UIKit
import CoreTelephony

extension DeviceInfo {
    static func current(includeCarrier: Bool) -> DeviceInfo {
        let device = UIDevice.current
        var deviceInfo = DeviceInfo()
        deviceInfo.type = getDeviceType(device)
        deviceInfo.platform = getPlatform(device)
        deviceInfo.model = getMacModel() ?? device.model
        if includeCarrier,
           let carrier = getCarrier() {
            deviceInfo.carrier = carrier
        }
        deviceInfo.setIfNotNil(\.vendorID, device.identifierForVendor?.uuidString)
        deviceInfo.setIfNotNil(\.advertiserID, getAdvertisingIdentifier()?.uuidString)
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
        default: return .unknown
        }
#endif
    }
}
#endif
