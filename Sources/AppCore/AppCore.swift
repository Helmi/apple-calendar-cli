import Foundation

public enum AppleCalSchema {
    public static let version = "1.0.0"
}

public enum AppleCalBuildInfo {
    public static let version: String = {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        return "dev"
    }()
}
