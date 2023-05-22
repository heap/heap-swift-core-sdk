import Foundation

struct Version {
    /// Major version.
    static let major = 0
    
    /// Minor version.
    static let minor = 2

    /// Revision number.
    static let revision = 1

    /// Optional pre-release version
    static let prerelease: String? = nil

    /// String form of the version number.
    public static var versionString: String {
        if let prerelease = prerelease {
            return "\(major).\(minor).\(revision)-\(prerelease)"
        } else {
            return "\(major).\(minor).\(revision)"
        }
    }
}
