import AppCore
import ArgumentParser
import Darwin
import Diagnostics
import EventKitAdapter
import Formatting
import Foundation

@main
struct AppleCal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applecal",
        abstract: "A CLI for working with Apple Calendar.",
        discussion: """
        Start with one of the top-level command groups:
          - doctor
          - auth
          - calendars
          - events
          - completion
          - schema

        Use `applecal <command> --help` for details and examples.
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
        } catch let appleCalError as AppleCalError {
            writeToStandardError("Error [\(appleCalError.code.rawValue)]: \(appleCalError.message.text)")
            Darwin.exit(appleCalError.exitCode.rawValue)
        } catch {
            if exitCode(for: error) == .validationFailure {
                writeToStandardError(message(for: error))
                Darwin.exit(AppleCalProcessExitCode.invalidUsage.rawValue)
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

        var appCoreValue: AppleCalOutputFormat {
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

    var resolvedFormat: AppleCalOutputFormat {
        if let format {
            return format.appCoreValue
        }

        return isatty(fileno(stdout)) == 1 ? .table : .json
    }
}

enum CLI {
    static let store: any CalendarStore = {
        let mode = ProcessInfo.processInfo.environment["APPLECAL_STORE"]?.lowercased()
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
            let payload = AppleCalEnvelope<T>.success(data, command: command)
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
            throw AppleCalError.validation("Unknown timezone '\(value)'.")
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
            throw AppleCalError.validation("Invalid --repeat value '\(repeatFrequency)'.")
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

struct DoctorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Run environment and permission diagnostics."
    )

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let report = DoctorReport()
        try CLI.printSuccess(command: "doctor", data: report, options: output) {
            CLI.keyValueTable([
                ("binaryVersion", report.binaryVersion),
                ("macOSVersion", report.macOSVersion),
                ("eventKitAvailable", String(report.eventKitAvailable)),
                ("authorization", report.authorization.rawValue)
            ])
        }
    }
}

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
        let authorization: AppleCalAuthorizationState
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
        let authorization: AppleCalAuthorizationState
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

struct CalendarsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "Inspect available calendars.",
        subcommands: [
            CalendarsListCommand.self,
            CalendarsGetCommand.self
        ]
    )

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

struct CalendarsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List calendars available to the current user."
    )

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let calendars = try CLI.store.listCalendars()
        try CLI.printSuccess(command: "calendars list", data: calendars, options: output) {
            OutputPrinter.renderTable(
                headers: ["id", "title", "source", "color", "writable"],
                rows: calendars.map {
                    [$0.id, $0.title, $0.source, $0.colorHex, String($0.writable)]
                }
            )
        }
    }
}

struct CalendarsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one calendar by id or exact name."
    )

    @Option(name: .long, help: "Calendar identifier.")
    var id: String?

    @Option(name: .long, help: "Calendar exact title.")
    var name: String?

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        guard id != nil || name != nil else {
            throw AppleCalError.validation("Provide --id or --name.")
        }

        let calendar = try CLI.store.getCalendar(id: id, name: name)
        try CLI.printSuccess(command: "calendars get", data: calendar, options: output) {
            CLI.keyValueTable([
                ("id", calendar.id),
                ("title", calendar.title),
                ("source", calendar.source),
                ("color", calendar.colorHex),
                ("writable", String(calendar.writable))
            ])
        }
    }
}

struct EventsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "events",
        abstract: "Read and mutate calendar events.",
        subcommands: [
            EventsListCommand.self,
            EventsGetCommand.self,
            EventsSearchCommand.self,
            EventsCreateCommand.self,
            EventsUpdateCommand.self,
            EventsDeleteCommand.self
        ]
    )

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

struct EventsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List events in a date range."
    )

    @Option(name: .long, help: "Range start in ISO-8601 or YYYY-MM-DD.")
    var from: String

    @Option(name: .long, help: "Range end in ISO-8601 or YYYY-MM-DD.")
    var to: String

    @Option(name: .long, parsing: .upToNextOption, help: "Calendar ids or names.")
    var calendar: [String] = []

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let start = try DateCodec.parse(from)
        let end = try DateCodec.parse(to)
        let calendarIDs = try CLI.resolveCalendarIDs(calendar)
        let events = try CLI.store.listEvents(from: start, to: end, calendarIDs: calendarIDs)

        try CLI.printSuccess(command: "events list", data: events, options: output) {
            OutputPrinter.renderTable(
                headers: ["id", "title", "start", "end", "calendar"],
                rows: events.map { [$0.id, $0.title, $0.start, $0.end, $0.calendarId] }
            )
        }
    }
}

struct EventsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one event by identifier."
    )

    @Option(name: .long, help: "Local event identifier.")
    var id: String?

    @Option(name: .long, help: "External event identifier fallback.")
    var externalId: String?

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        guard id != nil || externalId != nil else {
            throw AppleCalError.validation("Provide --id or --external-id.")
        }

        let event = try CLI.store.getEvent(id: id, externalID: externalId)

        try CLI.printSuccess(command: "events get", data: event, options: output) {
            CLI.keyValueTable([
                ("id", event.id),
                ("externalId", event.externalId),
                ("calendarId", event.calendarId),
                ("title", event.title),
                ("start", event.start),
                ("end", event.end),
                ("allDay", String(event.allDay)),
                ("recurrence", event.recurrence?.rrule ?? event.recurrence?.frequency.rawValue ?? "none"),
                ("revision", String(event.revision))
            ])
        }
    }
}

struct EventsSearchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search events by text and optional filters."
    )

    @Option(name: .long, help: "Text query for title/location/notes.")
    var query: String

    @Option(name: .long, help: "Range start in ISO-8601 or YYYY-MM-DD.")
    var from: String

    @Option(name: .long, help: "Range end in ISO-8601 or YYYY-MM-DD.")
    var to: String

    @Option(name: .long, parsing: .upToNextOption, help: "Calendar ids or names.")
    var calendar: [String] = []

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let start = try DateCodec.parse(from)
        let end = try DateCodec.parse(to)
        let calendarIDs = try CLI.resolveCalendarIDs(calendar)
        let events = try CLI.store.searchEvents(query: query, from: start, to: end, calendarIDs: calendarIDs)

        try CLI.printSuccess(command: "events search", data: events, options: output) {
            OutputPrinter.renderTable(
                headers: ["id", "title", "start", "calendar"],
                rows: events.map { [$0.id, $0.title, $0.start, $0.calendarId] }
            )
        }
    }
}

struct EventsCreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new event."
    )

    @Option(name: .long, help: "Calendar id or exact name.")
    var calendar: String

    @Option(name: .long, help: "Event title.")
    var title: String

    @Option(name: .long, help: "Start date-time in ISO-8601 or YYYY-MM-DD.")
    var start: String

    @Option(name: .long, help: "End date-time in ISO-8601 or YYYY-MM-DD.")
    var end: String

    @Option(name: .long, help: "Timezone identifier (e.g. Europe/Berlin).")
    var timezone: String?

    @Flag(name: .long, help: "Create as all-day event.")
    var allDay = false

    @Option(name: .long) var location: String?
    @Option(name: .long) var notes: String?
    @Option(name: .long) var url: String?

    @Option(name: .customLong("repeat"), help: "Recurrence frequency: daily|weekly|monthly|yearly.")
    var repeatFrequency: String?

    @Option(name: .long, help: "Recurrence interval.")
    var interval: Int?

    @Option(name: .long, help: "Comma-separated weekdays (mon,tue,...).")
    var byday: String?

    @Option(name: .long, help: "Recurrence until (ISO date/time).")
    var until: String?

    @Option(name: .long, help: "Recurrence count.")
    var count: Int?

    @Option(name: .long, help: "Advanced RRULE string.")
    var rrule: String?

    @Option(
        name: .long,
        parsing: .unconditionalSingleValue,
        help: "Alarm offsets in minutes relative to start, usually negative."
    )
    var alarmMinutes: [Int] = []

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let resolvedCalendar: CalendarRecord
        if let byID = try? CLI.store.getCalendar(id: calendar, name: nil) {
            resolvedCalendar = byID
        } else {
            resolvedCalendar = try CLI.store.getCalendar(id: nil, name: calendar)
        }

        let resolvedTimeZone = try CLI.parseTimezone(timezone)
        let startDate = try DateCodec.parse(start, defaultTimeZone: resolvedTimeZone)
        let endDate = try DateCodec.parse(end, defaultTimeZone: resolvedTimeZone)
        let recurrence = try RecurrenceParser.parse(flags: CLI.recurrenceFlags(
            repeat: repeatFrequency,
            interval: interval,
            byDay: byday,
            until: until,
            count: count,
            rrule: rrule
        ))

        let alarms = alarmMinutes.map { AlarmRecord(relativeMinutes: $0) }

        let event = try CLI.store.createEvent(input: EventCreateInput(
            calendarId: resolvedCalendar.id,
            title: title,
            start: startDate,
            end: endDate,
            timezone: resolvedTimeZone,
            allDay: allDay,
            location: location,
            notes: notes,
            url: url.flatMap(URL.init(string:)),
            recurrence: recurrence,
            alarms: alarms
        ))

        try CLI.printSuccess(command: "events create", data: event, options: output) {
            CLI.keyValueTable([
                ("id", event.id),
                ("calendarId", event.calendarId),
                ("title", event.title),
                ("start", event.start),
                ("end", event.end),
                ("recurrence", event.recurrence?.rrule ?? event.recurrence?.frequency.rawValue ?? "none")
            ])
        }
    }
}

struct EventsUpdateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an existing event."
    )

    @Option(name: .long, help: "Event identifier.")
    var id: String

    @Option(name: .long) var title: String?
    @Option(name: .long) var start: String?
    @Option(name: .long) var end: String?
    @Option(name: .long) var timezone: String?
    @Option(name: .long) var location: String?
    @Option(name: .long) var notes: String?
    @Option(name: .long) var url: String?
    @Option(name: .customLong("all-day"), help: "Set true/false to toggle all-day mode.")
    var allDay: Bool?

    @Option(name: .long, help: "Occurrence start for recurring instance edits.")
    var occurrenceStart: String?

    @Option(name: .long, help: "Update scope: this, future, all.")
    var scope: String = "all"

    @Option(name: .long, help: "Expected current revision for optimistic concurrency.")
    var expectedRevision: Int?

    @Option(name: .customLong("repeat"), help: "Recurrence frequency: daily|weekly|monthly|yearly.")
    var repeatFrequency: String?

    @Option(name: .long) var interval: Int?
    @Option(name: .long) var byday: String?
    @Option(name: .long) var until: String?
    @Option(name: .long) var count: Int?
    @Option(name: .long) var rrule: String?
    @Flag(name: .long) var clearRecurrence = false

    @Option(name: .long, parsing: .unconditionalSingleValue)
    var alarmMinutes: [Int] = []

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let timezoneObject = try CLI.parseTimezone(timezone)
        let scopeValue = EventDeleteScope(rawValue: scope.lowercased())
        guard let scopeValue else {
            throw AppleCalError.validation("Invalid --scope value '\(scope)'. Use this|future|all.")
        }

        let recurrence = try RecurrenceParser.parse(flags: CLI.recurrenceFlags(
            repeat: repeatFrequency,
            interval: interval,
            byDay: byday,
            until: until,
            count: count,
            rrule: rrule
        ))

        if [title, start, end, location, notes, url].allSatisfy({ $0 == nil }),
           allDay == nil,
           recurrence == nil,
           !clearRecurrence,
           alarmMinutes.isEmpty
        {
            throw AppleCalError.validation("No update fields were provided.")
        }

        let occurrence = try occurrenceStart.map { try DateCodec.parse($0) }

        let event = try CLI.store.updateEvent(
            id: id,
            occurrenceStart: occurrence,
            scope: scopeValue,
            input: EventUpdateInput(
                title: title,
                start: start.map { try DateCodec.parse($0, defaultTimeZone: timezoneObject) },
                end: end.map { try DateCodec.parse($0, defaultTimeZone: timezoneObject) },
                timezone: timezone != nil ? timezoneObject : nil,
                allDay: allDay,
                location: location,
                notes: notes,
                url: url.flatMap(URL.init(string:)),
                recurrence: recurrence,
                clearRecurrence: clearRecurrence,
                alarms: alarmMinutes.isEmpty ? nil : alarmMinutes.map { AlarmRecord(relativeMinutes: $0) },
                expectedRevision: expectedRevision
            )
        )

        try CLI.printSuccess(command: "events update", data: event, options: output) {
            CLI.keyValueTable([
                ("id", event.id),
                ("title", event.title),
                ("start", event.start),
                ("end", event.end),
                ("revision", String(event.revision))
            ])
        }
    }
}

struct EventsDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an event or recurring occurrence scope."
    )

    @Option(name: .long, help: "Event identifier.")
    var id: String

    @Option(name: .long, help: "Occurrence start when scope is this/future.")
    var occurrenceStart: String?

    @Option(name: .long, help: "Delete scope: this, future, all.")
    var scope: String = "all"

    @Option(name: .long, help: "Expected current revision for optimistic concurrency.")
    var expectedRevision: Int?

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        guard let scopeValue = EventDeleteScope(rawValue: scope.lowercased()) else {
            throw AppleCalError.validation("Invalid --scope value '\(scope)'. Use this|future|all.")
        }

        let payload = try CLI.store.deleteEvent(
            id: id,
            input: EventDeleteInput(
                occurrenceStart: occurrenceStart.map { try DateCodec.parse($0) },
                scope: scopeValue,
                expectedRevision: expectedRevision
            )
        )

        try CLI.printSuccess(command: "events delete", data: payload, options: output) {
            CLI.keyValueTable(payload.sorted(by: { $0.key < $1.key }))
        }
    }
}

struct CompletionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completion",
        abstract: "Generate shell completion scripts.",
        subcommands: [
            CompletionBashCommand.self,
            CompletionZshCommand.self,
            CompletionFishCommand.self
        ]
    )

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

struct CompletionBashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bash",
        abstract: "Generate completion script for Bash."
    )

    mutating func run() throws {
        Swift.print(AppleCal.completionScript(for: .bash))
    }
}

struct CompletionZshCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "zsh", abstract: "Generate completion script for Zsh.")

    mutating func run() throws {
        Swift.print(AppleCal.completionScript(for: .zsh))
    }
}

struct CompletionFishCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fish",
        abstract: "Generate completion script for Fish."
    )

    mutating func run() throws {
        Swift.print(AppleCal.completionScript(for: .fish))
    }
}

struct SchemaCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schema",
        abstract: "Print CLI schema and command contract metadata."
    )

    struct CommandSpec: Codable, Sendable {
        let name: String
        let summary: String
    }

    struct SchemaPayload: Codable, Sendable {
        let schemaVersion: String
        let commands: [CommandSpec]
    }

    mutating func run() throws {
        let payload = SchemaPayload(
            schemaVersion: AppleCalSchema.version,
            commands: [
                CommandSpec(name: "doctor", summary: "Run diagnostics"),
                CommandSpec(name: "auth status", summary: "Show authorization status"),
                CommandSpec(name: "auth grant", summary: "Request full calendar access"),
                CommandSpec(name: "auth reset", summary: "Show TCC reset guidance"),
                CommandSpec(name: "calendars list", summary: "List calendars"),
                CommandSpec(name: "calendars get", summary: "Get one calendar"),
                CommandSpec(name: "events list", summary: "List events in range"),
                CommandSpec(name: "events get", summary: "Get event by id"),
                CommandSpec(name: "events search", summary: "Search events"),
                CommandSpec(name: "events create", summary: "Create event"),
                CommandSpec(name: "events update", summary: "Update event"),
                CommandSpec(name: "events delete", summary: "Delete event"),
                CommandSpec(name: "completion bash|zsh|fish", summary: "Generate shell completion"),
                CommandSpec(name: "schema", summary: "Print schema contract")
            ]
        )

        let envelope = AppleCalEnvelope<SchemaPayload>.success(payload, command: "schema")
        try Swift.print(OutputPrinter.renderJSON(envelope, pretty: true))
    }
}
