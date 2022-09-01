#if os(watchOS)
import WatchKit

extension DeviceInfo {
    static func current(includeCarrier: Bool) -> DeviceInfo {
        let device = WKInterfaceDevice.current()
        
        var deviceInfo = DeviceInfo()
        deviceInfo.type = .watch
        deviceInfo.platform = "watchOS \(device.systemVersion)"
        if #available(watchOS 6.2, *) {
            if let identifierForVendor = device.identifierForVendor {
                deviceInfo.vendorID = identifierForVendor.uuidString
            }
        }
        deviceInfo.model = device.model
        if let advertisingIdentifier = getAdvertisingIdentifier() {
            deviceInfo.advertiserID = advertisingIdentifier.uuidString
        }
        return deviceInfo
    }
}
#endif
