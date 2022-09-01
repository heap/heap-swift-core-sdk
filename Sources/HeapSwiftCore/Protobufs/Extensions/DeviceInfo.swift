import Foundation

extension DeviceInfo {
    static func getAdvertisingIdentifier() -> UUID? {
        NSClassFromString("ASIdentifierManager")?.value(forKeyPath: "sharedManager.advertisingIdentifier") as? UUID
    }
}
