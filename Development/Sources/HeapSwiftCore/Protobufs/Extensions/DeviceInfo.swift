import Foundation

extension DeviceInfo {
    static func getAdvertisingIdentifier(with settings: FieldSettings) -> String? {
        guard
            settings.captureAdvertiserId,
            let ASIdentifierManager = NSClassFromString("ASIdentifierManager"),
            let advertisingIdentifier = ASIdentifierManager.value(forKeyPath: "sharedManager.advertisingIdentifier") as? UUID
        else { return nil }
        
        return advertisingIdentifier.uuidString
    }
}
