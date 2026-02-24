import Foundation

public enum AppleCalMachineErrorCode: String, Codable, Sendable {
    case invalidArguments = "INVALID_ARGUMENTS"
    case permissionDenied = "PERMISSION_DENIED"
    case notFound = "NOT_FOUND"
    case conflict = "CONFLICT"
    case validationFailed = "VALIDATION_FAILED"
    case eventKitFailure = "EVENTKIT_FAILURE"
    case internalError = "INTERNAL_ERROR"

    public var defaultMessage: AppleCalUserMessage {
        switch self {
        case .invalidArguments:
            return AppleCalUserMessage("Invalid command usage.")
        case .permissionDenied:
            return AppleCalUserMessage("Full calendar access not granted.")
        case .notFound:
            return AppleCalUserMessage("Requested calendar item was not found.")
        case .conflict:
            return AppleCalUserMessage("Operation conflicts with current state.")
        case .validationFailed:
            return AppleCalUserMessage("Input validation failed.")
        case .eventKitFailure:
            return AppleCalUserMessage("Calendar subsystem returned an error.")
        case .internalError:
            return AppleCalUserMessage("An internal error occurred.")
        }
    }

    public var mappedExitCode: AppleCalProcessExitCode {
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

public struct AppleCalUserMessage: Codable, Equatable, ExpressibleByStringLiteral, Sendable {
    public let text: String

    public init(_ text: String) {
        self.text = text
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

public enum AppleCalProcessExitCode: Int32, Codable, Sendable {
    case success = 0
    case failure = 1
    case invalidUsage = 2
    case permissionDenied = 3
    case notFound = 4
    case conflictOrValidationFailure = 5
    case eventKitFailure = 10
}

public struct AppleCalError: Error, Sendable {
    public let code: AppleCalMachineErrorCode
    public let message: AppleCalUserMessage
    public let exitCode: AppleCalProcessExitCode
    public let details: [String: String]

    public init(
        code: AppleCalMachineErrorCode,
        message: AppleCalUserMessage? = nil,
        details: [String: String] = [:],
        exitCode: AppleCalProcessExitCode? = nil
    ) {
        self.code = code
        self.message = message ?? code.defaultMessage
        self.details = details
        self.exitCode = exitCode ?? code.mappedExitCode
    }

    public static func invalidArguments(_ message: String) -> AppleCalError {
        AppleCalError(code: .invalidArguments, message: AppleCalUserMessage(message))
    }

    public static func validation(_ message: String, details: [String: String] = [:]) -> AppleCalError {
        AppleCalError(code: .validationFailed, message: AppleCalUserMessage(message), details: details)
    }

    public static func notFound(_ message: String, details: [String: String] = [:]) -> AppleCalError {
        AppleCalError(code: .notFound, message: AppleCalUserMessage(message), details: details)
    }

    public static func conflict(_ message: String, details: [String: String] = [:]) -> AppleCalError {
        AppleCalError(code: .conflict, message: AppleCalUserMessage(message), details: details)
    }
}
