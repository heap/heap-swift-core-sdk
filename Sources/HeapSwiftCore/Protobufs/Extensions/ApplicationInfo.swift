import Foundation

extension ApplicationInfo {
    static var current: ApplicationInfo {

        var applicationInfo = ApplicationInfo()

        if let infoDictionary = Bundle.main.infoDictionary {

            if let name = infoDictionary["CFBundleName"] as? String {
                applicationInfo.name = name
            }

            if let identifier = infoDictionary["CFBundleIdentifier"] as? String {
                applicationInfo.identifier = identifier
            }

            if let versionString = infoDictionary["CFBundleShortVersionString"] as? String {
                applicationInfo.versionString = versionString
            }

        }

        return applicationInfo
    }
}
