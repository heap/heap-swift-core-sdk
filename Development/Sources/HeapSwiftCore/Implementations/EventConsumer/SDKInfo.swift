struct SDKInfo {
    
    let applicationInfo: ApplicationInfo
    let deviceInfo: DeviceInfo
    let libraryInfo: LibraryInfo
    
    static func current(with options: [Option: Any]) -> SDKInfo {
        let deviceInfo = DeviceInfo.current(with: options, includeCarrier: true)
        return .init(applicationInfo: .current, deviceInfo: deviceInfo, libraryInfo: .baseInfo(with: deviceInfo))
    }
}
