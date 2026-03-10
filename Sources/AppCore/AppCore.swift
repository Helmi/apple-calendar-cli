import Foundation

public enum ACalSchema {
    public static let version = "1.0.0"
}

public enum ACalBuildInfo {
    /// Binary release version (SemVer). Keep this independent from ACalSchema.version.
    public static let releaseVersion = "0.2.0"

    public static let version: String = {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        return releaseVersion
    }()
}
