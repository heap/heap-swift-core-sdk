import Foundation

extension DeviceInfo {
    static func getAdvertisingIdentifier(with options: [Option: Any]) -> String? {
        guard
            options.boolean(at: .captureAdvertiserId) ?? false,
            let ASIdentifierManager = NSClassFromString("ASIdentifierManager"),
            let advertisingIdentifier = ASIdentifierManager.value(forKeyPath: "sharedManager.advertisingIdentifier") as? UUID
        else { return nil }
        
        return advertisingIdentifier.uuidString
    }
}
