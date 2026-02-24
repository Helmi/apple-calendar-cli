import Foundation

public enum AppleCalOutputFormat: String, Codable, CaseIterable, Sendable {
    case json
    case table
}

public struct AppleCalEnvelopeMeta: Codable, Sendable {
    public let schemaVersion: String
    public let timestamp: String
    public let command: String

    public init(command: String, timestamp: Date = Date()) {
        schemaVersion = AppleCalSchema.version
        self.command = command
        self.timestamp = DateCodec.iso8601String(from: timestamp)
    }
}

public struct AppleCalEnvelopeError: Codable, Sendable {
    public let code: AppleCalMachineErrorCode
    public let message: String
    public let details: [String: String]

    public init(error: AppleCalError) {
        code = error.code
        message = error.message.text
        details = error.details
    }
}

public struct AppleCalEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let ok: Bool
    public let data: T?
    public let error: AppleCalEnvelopeError?
    public let meta: AppleCalEnvelopeMeta

    public static func success(_ data: T, command: String) -> AppleCalEnvelope<T> {
        AppleCalEnvelope(ok: true, data: data, error: nil, meta: AppleCalEnvelopeMeta(command: command))
    }

    public static func failure(_ error: AppleCalError, command: String) -> AppleCalEnvelope<T> {
        AppleCalEnvelope(ok: false, data: nil, error: AppleCalEnvelopeError(error: error), meta: AppleCalEnvelopeMeta(command: command))
    }
}
