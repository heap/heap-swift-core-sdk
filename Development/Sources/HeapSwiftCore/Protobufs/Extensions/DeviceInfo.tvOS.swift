#if os(tvOS)
import UIKit

extension DeviceInfo {
    static func current(with settings: FieldSettings, includeCarrier: Bool) -> DeviceInfo {
        let device = UIDevice.current
        var deviceInfo = DeviceInfo()
        deviceInfo.type = .tv
        deviceInfo.platform = "tvOS \(device.systemVersion)"
        deviceInfo.model = device.model
        deviceInfo.setIfNotNil(\.vendorID, device.identifierForVendor?.uuidString)
        deviceInfo.setIfNotNil(\.advertiserID, getAdvertisingIdentifier(with: settings))
        return deviceInfo
    }
}
#endif
