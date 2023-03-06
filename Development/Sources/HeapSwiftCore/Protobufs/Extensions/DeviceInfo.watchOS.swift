#if os(watchOS)
import WatchKit

extension DeviceInfo {
    static func current(with settings: FieldSettings, includeCarrier: Bool) -> DeviceInfo {
        let device = WKInterfaceDevice.current()
        
        var deviceInfo = DeviceInfo()
        deviceInfo.type = .watch
        deviceInfo.platform = "watchOS \(device.systemVersion)"
        if #available(watchOS 6.2, *) {
            deviceInfo.setIfNotNil(\.vendorID, device.identifierForVendor?.uuidString)
        }
        deviceInfo.model = device.model
        deviceInfo.setIfNotNil(\.advertiserID, getAdvertisingIdentifier(with: settings))
        return deviceInfo
    }
}
#endif
