import Foundation

struct Version {
    /// Major version.
    static let major = 0
    
    /// Minor version.
    static let minor = 0

    /// Revision number.
    static let revision = 0

    /// Optional pre-release version
    static let prerelease: String? = "alpha.0"

    /// String form of the version number.
    public static var versionString: String {
        if let prerelease = prerelease {
            return "\(major).\(minor).\(revision)-\(prerelease)"
        } else {
            return "\(major).\(minor).\(revision)"
        }
    }
}
