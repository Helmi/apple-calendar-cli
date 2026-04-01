import AppCore
import EventKitAdapter
import Foundation

public struct DoctorReport: Codable, Sendable {
    public let binaryVersion: String
    public let macOSVersion: String
    public let eventKitAvailable: Bool
    public let authorization: ACalAuthorizationState

    public init(
        binaryVersion: String = ACalBuildInfo.version,
        macOSVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
        eventKitAvailable: Bool = EventKitAdapter.eventKitAvailable(),
        authorization: ACalAuthorizationState = EventKitAdapter.currentAuthorizationState()
    ) {
        self.binaryVersion = binaryVersion
        self.macOSVersion = macOSVersion
        self.eventKitAvailable = eventKitAvailable
        self.authorization = authorization
    }
}

public enum AuthResetGuidance {
    public static func steps() -> [String] {
        [
            "Quit terminals and agents currently using acal.",
            "Reset Calendar privacy permissions with: tccutil reset Calendar",
            "Re-run `acal auth grant` and approve access when prompted.",
            "Validate with `acal auth status --format json`.",
        ]
    }
}
