import AppCore
import ArgumentParser
import Formatting
import Foundation

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
            throw ACalError.validation("Provide --id or --external-id.")
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
            throw ACalError.validation("Invalid --scope value '\(scope)'. Use this|future|all.")
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
            throw ACalError.validation("No update fields were provided.")
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
            throw ACalError.validation("Invalid --scope value '\(scope)'. Use this|future|all.")
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
