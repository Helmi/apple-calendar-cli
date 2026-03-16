import Foundation

public enum ACalSchema {
    public static let version = "1.0.0"
}

/// Input length limits — prevents opaque EventKit failures from oversized fields.
public enum ACalLimits {
    public static let maxTitleLength = 1024
    public static let maxNotesLength = 10000
    public static let maxLocationLength = 1024
    public static let maxURLLength = 2048

    /// Validates common string fields and throws a clear error on overflow.
    public static func validateEventFields(
        title: String? = nil,
        notes: String? = nil,
        location: String? = nil,
        url: String? = nil
    ) throws {
        if let title, title.count > maxTitleLength {
            throw ACalError.validation("Title exceeds maximum length of \(maxTitleLength) characters.")
        }
        if let notes, notes.count > maxNotesLength {
            throw ACalError.validation("Notes exceed maximum length of \(maxNotesLength) characters.")
        }
        if let location, location.count > maxLocationLength {
            throw ACalError.validation("Location exceeds maximum length of \(maxLocationLength) characters.")
        }
        if let url, url.count > maxURLLength {
            throw ACalError.validation("URL exceeds maximum length of \(maxURLLength) characters.")
        }
    }
}

public enum ACalBuildInfo {
    /// Binary release version (SemVer). Keep this independent from ACalSchema.version.
    public static let releaseVersion = "0.2.1"

    public static let version: String = {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, !version.isEmpty {
            return version
        }
        return releaseVersion
    }()
}
