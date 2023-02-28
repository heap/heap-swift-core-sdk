#if os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
import Foundation
import IOKit
#endif

#if os(macOS)
extension DeviceInfo {
    static func current(with options: [Option: Any], includeCarrier: Bool) -> DeviceInfo {
        var deviceInfo = DeviceInfo()
        deviceInfo.type = .desktop
        deviceInfo.platform = getPlatform()
        deviceInfo.setIfNotNil(\.model, getMacModel())
        deviceInfo.setIfNotNil(\.advertiserID, getAdvertisingIdentifier(with: options))
        return deviceInfo
    }
    
    private static func getPlatform() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = version.patchVersion > 0 ? "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)" : "\(version.majorVersion).\(version.minorVersion)"
        return "macOS \(versionString)"
    }
}
#endif

extension DeviceInfo {

    static func getMacModel() -> String? {
        
#if os(macOS) || (os(iOS) && targetEnvironment(macCatalyst))
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(service) }
    
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            return modelData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> String? in
                guard let baseAddress = pointer.bindMemory(to: CChar.self).baseAddress else { return nil }
                return String(cString: baseAddress)
            }
        }
#endif
        
        return nil
    }
}
