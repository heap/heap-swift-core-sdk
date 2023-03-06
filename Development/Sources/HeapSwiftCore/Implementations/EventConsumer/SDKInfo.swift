struct SDKInfo {
    
    let applicationInfo: ApplicationInfo
    let deviceInfo: DeviceInfo
    let libraryInfo: LibraryInfo
    
    static func current(with settings: FieldSettings) -> SDKInfo {
        let deviceInfo = DeviceInfo.current(with: settings, includeCarrier: true)
        return .init(applicationInfo: .current, deviceInfo: deviceInfo, libraryInfo: .baseInfo(with: deviceInfo))
    }
}
