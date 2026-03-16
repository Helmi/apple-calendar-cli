import Foundation

public enum ACalOutputFormat: String, Codable, CaseIterable, Sendable {
    case json
    case table
}

public struct ACalEnvelopeMeta: Codable, Sendable {
    public let schemaVersion: String
    public let timestamp: String
    public let command: String

    public init(command: String, timestamp: Date = Date()) {
        schemaVersion = ACalSchema.version
        self.command = command
        self.timestamp = DateCodec.iso8601String(from: timestamp)
    }
}

public struct ACalEnvelopeError: Codable, Sendable {
    public let code: ACalMachineErrorCode
    public let message: String
    public let details: [String: String]

    public init(error: ACalError) {
        code = error.code
        message = error.message.text
        details = error.details
    }
}

public struct ACalEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let ok: Bool
    public let data: T?
    public let error: ACalEnvelopeError?
    public let meta: ACalEnvelopeMeta

    public static func success(_ data: T, command: String) -> ACalEnvelope<T> {
        ACalEnvelope(ok: true, data: data, error: nil, meta: ACalEnvelopeMeta(command: command))
    }

    public static func failure(_ error: ACalError, command: String) -> ACalEnvelope<T> {
        ACalEnvelope(
            ok: false,
            data: nil,
            error: ACalEnvelopeError(error: error),
            meta: ACalEnvelopeMeta(command: command)
        )
    }
}
