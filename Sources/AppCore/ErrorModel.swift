import Foundation

public enum ACalMachineErrorCode: String, Codable, Sendable {
    case invalidArguments = "INVALID_ARGUMENTS"
    case permissionDenied = "PERMISSION_DENIED"
    case notFound = "NOT_FOUND"
    case conflict = "CONFLICT"
    case validationFailed = "VALIDATION_FAILED"
    case eventKitFailure = "EVENTKIT_FAILURE"
    case internalError = "INTERNAL_ERROR"

    public var defaultMessage: ACalUserMessage {
        switch self {
        case .invalidArguments:
            return ACalUserMessage("Invalid command usage.")
        case .permissionDenied:
            return ACalUserMessage("Full calendar access not granted.")
        case .notFound:
            return ACalUserMessage("Requested calendar item was not found.")
        case .conflict:
            return ACalUserMessage("Operation conflicts with current state.")
        case .validationFailed:
            return ACalUserMessage("Input validation failed.")
        case .eventKitFailure:
            return ACalUserMessage("Calendar subsystem returned an error.")
        case .internalError:
            return ACalUserMessage("An internal error occurred.")
        }
    }

    public var mappedExitCode: ACalProcessExitCode {
        switch self {
        case .invalidArguments:
            return .invalidUsage
        case .permissionDenied:
            return .permissionDenied
        case .notFound:
            return .notFound
        case .conflict, .validationFailed:
            return .conflictOrValidationFailure
        case .eventKitFailure:
            return .eventKitFailure
        case .internalError:
            return .failure
        }
    }
}

public struct ACalUserMessage: Codable, Equatable, ExpressibleByStringLiteral, Sendable {
    public let text: String

    public init(_ text: String) {
        self.text = text
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

public enum ACalProcessExitCode: Int32, Codable, Sendable {
    case success = 0
    case failure = 1
    case invalidUsage = 2
    case permissionDenied = 3
    case notFound = 4
    case conflictOrValidationFailure = 5
    case eventKitFailure = 10
}

public struct ACalError: Error, Sendable {
    public let code: ACalMachineErrorCode
    public let message: ACalUserMessage
    public let exitCode: ACalProcessExitCode
    public let details: [String: String]

    public init(
        code: ACalMachineErrorCode,
        message: ACalUserMessage? = nil,
        details: [String: String] = [:],
        exitCode: ACalProcessExitCode? = nil
    ) {
        self.code = code
        self.message = message ?? code.defaultMessage
        self.details = details
        self.exitCode = exitCode ?? code.mappedExitCode
    }

    public static func invalidArguments(_ message: String) -> ACalError {
        ACalError(code: .invalidArguments, message: ACalUserMessage(message))
    }

    public static func validation(_ message: String, details: [String: String] = [:]) -> ACalError {
        ACalError(code: .validationFailed, message: ACalUserMessage(message), details: details)
    }

    public static func notFound(_ message: String, details: [String: String] = [:]) -> ACalError {
        ACalError(code: .notFound, message: ACalUserMessage(message), details: details)
    }

    public static func conflict(_ message: String, details: [String: String] = [:]) -> ACalError {
        ACalError(code: .conflict, message: ACalUserMessage(message), details: details)
    }
}
