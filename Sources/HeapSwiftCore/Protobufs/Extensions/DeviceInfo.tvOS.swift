#if os(tvOS)
import UIKit

extension DeviceInfo {
    static func current(includeCarrier: Bool) -> DeviceInfo {
        let device = UIDevice.current
        var deviceInfo = DeviceInfo()
        deviceInfo.type = .tv
        deviceInfo.platform = "tvOS \(device.systemVersion)"
        deviceInfo.model = device.model
        if let identifierForVendor = device.identifierForVendor {
            deviceInfo.vendorID = identifierForVendor.uuidString
        }
        if let advertisingIdentifier = getAdvertisingIdentifier() {
            deviceInfo.advertiserID = advertisingIdentifier.uuidString
        }
        return deviceInfo
    }
}
#endif
