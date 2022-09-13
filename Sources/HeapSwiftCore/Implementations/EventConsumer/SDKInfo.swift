struct SDKInfo {
    
    let applicationInfo: ApplicationInfo
    let deviceInfo: DeviceInfo
    let libraryInfo: LibraryInfo
    
    static var current: SDKInfo {
        let deviceInfo = DeviceInfo.current(includeCarrier: true)
        return .init(applicationInfo: .current, deviceInfo: deviceInfo, libraryInfo: .baseInfo(with: deviceInfo))
    }
    
    static let shared = current
}
