import Foundation

public enum AppleCalSchema {
    public static let version = "1.0.0"
}

public enum AppleCalBuildInfo {
    /// Binary release version (SemVer). Keep this independent from AppleCalSchema.version.
    public static let releaseVersion = "0.1.0"

    public static let version: String = {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        return releaseVersion
    }()
}
