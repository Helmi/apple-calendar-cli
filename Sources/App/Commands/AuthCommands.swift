import AppCore
import ArgumentParser
import Diagnostics
import EventKitAdapter

struct AuthCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Inspect and manage Calendar authorization.",
        subcommands: [
            AuthStatusCommand.self,
            AuthGrantCommand.self,
            AuthResetCommand.self
        ]
    )

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

struct AuthStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show current Calendar authorization status."
    )

    @OptionGroup var output: GlobalOutputOptions

    struct Payload: Codable, Sendable {
        let authorization: ACalAuthorizationState
        let writable: Bool
    }

    mutating func run() throws {
        let state = EventKitAdapter.currentAuthorizationState()
        let payload = Payload(authorization: state, writable: state.hasWriteAccess)

        try CLI.printSuccess(command: "auth status", data: payload, options: output) {
            CLI.keyValueTable([
                ("authorization", payload.authorization.rawValue),
                ("writable", String(payload.writable))
            ])
        }
    }
}

struct AuthGrantCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "grant",
        abstract: "Request Calendar access permission."
    )

    @OptionGroup var output: GlobalOutputOptions

    struct Payload: Codable, Sendable {
        let authorization: ACalAuthorizationState
        let granted: Bool
    }

    mutating func run() throws {
        let state = try EventKitAdapter.requestFullAccess()
        let payload = Payload(authorization: state, granted: state == .fullAccess)

        try CLI.printSuccess(command: "auth grant", data: payload, options: output) {
            CLI.keyValueTable([
                ("authorization", payload.authorization.rawValue),
                ("granted", String(payload.granted))
            ])
        }
    }
}

struct AuthResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Print safe remediation steps when TCC state is broken."
    )

    @OptionGroup var output: GlobalOutputOptions

    struct Payload: Codable, Sendable {
        let steps: [String]
    }

    mutating func run() throws {
        let payload = Payload(steps: AuthResetGuidance.steps())

        try CLI.printSuccess(command: "auth reset", data: payload, options: output) {
            payload.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        }
    }
}
