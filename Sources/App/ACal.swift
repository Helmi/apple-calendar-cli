import AppCore
import ArgumentParser
import Darwin
import Diagnostics
import EventKitAdapter
import Formatting
import Foundation

@main
struct ACal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "acal",
        abstract: "A CLI for working with macOS Calendar.",
        discussion: """
        Start with one of the top-level command groups:
          - doctor
          - auth
          - calendars
          - events
          - completion
          - schema

        Use `acal <command> --help` for details and examples.
        """,
        subcommands: [
            DoctorCommand.self,
            AuthCommand.self,
            CalendarsCommand.self,
            EventsCommand.self,
            CompletionCommand.self,
            SchemaCommand.self
        ]
    )

    static func main() {
        do {
            var command = try parseAsRoot()
            try command.run()
        } catch let acalError as ACalError {
            writeToStandardError("Error [\(acalError.code.rawValue)]: \(acalError.message.text)")
            Darwin.exit(acalError.exitCode.rawValue)
        } catch {
            if exitCode(for: error) == .validationFailure {
                writeToStandardError(message(for: error))
                Darwin.exit(ACalProcessExitCode.invalidUsage.rawValue)
            }

            exit(withError: error)
        }
    }

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }

    private static func writeToStandardError(_ value: String) {
        guard !value.isEmpty else { return }

        var message = value
        if !message.hasSuffix("\n") {
            message += "\n"
        }

        fputs(message, stderr)
    }
}

struct GlobalOutputOptions: ParsableArguments {
    enum FormatOption: String, CaseIterable, ExpressibleByArgument {
        case json
        case table

        var appCoreValue: ACalOutputFormat {
            switch self {
            case .json: .json
            case .table: .table
            }
        }
    }

    @Option(name: .long, help: "Output format: json or table. Defaults to json for non-TTY, table for TTY.")
    var format: FormatOption?

    @Option(name: .long, help: "Pretty-print JSON output (true/false).")
    var pretty: Bool = true

    var resolvedFormat: ACalOutputFormat {
        if let format {
            return format.appCoreValue
        }

        return isatty(fileno(stdout)) == 1 ? .table : .json
    }
}

enum CLI {
    static let store: any CalendarStore = {
        let mode = ProcessInfo.processInfo.environment["ACAL_STORE"]?.lowercased()
        if mode == "in_memory" {
            return InMemoryCalendarStore.shared
        }
        return EventKitCalendarStore.shared
    }()

    static func printSuccess<T: Codable & Sendable>(
        command: String,
        data: T,
        options: GlobalOutputOptions,
        tableRenderer: () -> String
    ) throws {
        switch options.resolvedFormat {
        case .json:
            let payload = ACalEnvelope<T>.success(data, command: command)
            try Swift.print(OutputPrinter.renderJSON(payload, pretty: options.pretty))
        case .table:
            Swift.print(tableRenderer())
        }
    }

    static func parseTimezone(_ value: String?) throws -> TimeZone {
        guard let value, !value.isEmpty else {
            return .current
        }

        guard let timezone = TimeZone(identifier: value) else {
            throw ACalError.validation("Unknown timezone '\(value)'.")
        }
        return timezone
    }

    static func resolveCalendarIDs(_ values: [String]) throws -> Set<String> {
        guard !values.isEmpty else { return [] }

        var ids = Set<String>()
        for value in values {
            if let calendar = try? store.getCalendar(id: value, name: nil) {
                ids.insert(calendar.id)
                continue
            }

            let calendar = try store.getCalendar(id: nil, name: value)
            ids.insert(calendar.id)
        }

        return ids
    }

    static func recurrenceFlags(
        repeat repeatFrequency: String?,
        interval: Int?,
        byDay: String?,
        until: String?,
        count: Int?,
        rrule: String?
    ) throws -> RecurrenceFlags {
        let frequency = repeatFrequency.flatMap { RecurrenceFrequency(rawValue: $0.lowercased()) }
        if let repeatFrequency, frequency == nil {
            throw ACalError.validation("Invalid --repeat value '\(repeatFrequency)'.")
        }

        return RecurrenceFlags(
            frequency: frequency,
            interval: interval,
            byDay: byDay,
            until: until,
            count: count,
            rrule: rrule
        )
    }

    static func keyValueTable(_ values: [(String, String)]) -> String {
        OutputPrinter.renderTable(headers: ["field", "value"], rows: values.map { [$0.0, $0.1] })
    }
}
