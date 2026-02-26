import AppCore
import EventKitAdapter
import Foundation

public struct DoctorReport: Codable, Sendable {
    public let binaryVersion: String
    public let macOSVersion: String
    public let eventKitAvailable: Bool
    public let authorization: AppleCalAuthorizationState

    public init(
        binaryVersion: String = AppleCalBuildInfo.version,
        macOSVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        eventKitAvailable: Bool = EventKitAdapter.eventKitAvailable(),
        authorization: AppleCalAuthorizationState = EventKitAdapter.currentAuthorizationState()
    ) {
        self.binaryVersion = binaryVersion
        self.macOSVersion = macOSVersion
        self.eventKitAvailable = eventKitAvailable
        self.authorization = authorization
    }
}

public enum AuthResetGuidance {
    public static func steps(bundleIdentifier: String = "applecal") -> [String] {
        [
            "Quit terminals and agents currently using applecal.",
            "Reset Calendar privacy permissions with: tccutil reset Calendar \(bundleIdentifier)",
            "Re-run `applecal auth grant` and approve access when prompted.",
            "Validate with `applecal auth status --format json`."
        ]
    }
}
