import Foundation

extension LibraryInfo {
    static func baseInfo(with deviceInfo: DeviceInfo) -> LibraryInfo {
        var libraryInfo = LibraryInfo()
        libraryInfo.name = "HeapSwiftCore"
        libraryInfo.platform = deviceInfo.platform
        libraryInfo.version = Version.versionString
        return libraryInfo
    }
}
