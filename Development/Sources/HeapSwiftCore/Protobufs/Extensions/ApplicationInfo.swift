import Foundation

extension ApplicationInfo {
    static var current: ApplicationInfo {

        var applicationInfo = ApplicationInfo()

        if let infoDictionary = Bundle.main.infoDictionary {
            applicationInfo.setIfNotNil(\.name, infoDictionary["CFBundleName"] as? String)
            applicationInfo.setIfNotNil(\.identifier, infoDictionary["CFBundleIdentifier"] as? String)
            applicationInfo.setIfNotNil(\.versionString, infoDictionary["CFBundleShortVersionString"] as? String)
        }

        return applicationInfo
    }
}
