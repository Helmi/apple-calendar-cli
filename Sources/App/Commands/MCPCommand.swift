import AppCore
import ArgumentParser
import EventKitAdapter
import Foundation
import MCP

struct MCPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp",
        abstract: "Start an MCP server on stdio for AI assistant integration.",
        discussion: """
        Exposes calendar operations as MCP tools over stdio using the
        Model Context Protocol (MCP). Compatible with any MCP client.
        """
    )

    mutating func run() async throws {
        let server = Server(
            name: "acal",
            version: ACalBuildInfo.releaseVersion,
            capabilities: .init(tools: .init())
        )

        await server.withMethodHandler(ListTools.self) { _ in
            .init(tools: MCPToolDefinitions.all)
        }

        await server.withMethodHandler(CallTool.self) { params in
            do {
                let args = params.arguments ?? [:]
                let json: String
                switch params.name {
                case "auth_status":
                    json = try MCPToolHandler.authStatus()
                case "auth_grant":
                    json = try MCPToolHandler.authGrant()
                case "list_calendars":
                    json = try MCPToolHandler.listCalendars()
                case "get_calendar":
                    json = try MCPToolHandler.getCalendar(
                        id: args["id"]?.stringValue,
                        name: args["name"]?.stringValue
                    )
                case "list_events":
                    guard let from = args["from"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'from'.")
                    }
                    guard let to = args["to"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'to'.")
                    }
                    json = try MCPToolHandler.listEvents(
                        from: from,
                        to: to,
                        calendars: MCPArgExtract.stringArray(args["calendar"]),
                        limit: MCPArgExtract.int(args["limit"]) ?? 50
                    )
                case "get_event":
                    json = try MCPToolHandler.getEvent(
                        id: args["id"]?.stringValue,
                        externalId: args["externalId"]?.stringValue
                    )
                case "search_events":
                    guard let query = args["query"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'query'.")
                    }
                    guard let from = args["from"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'from'.")
                    }
                    guard let to = args["to"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'to'.")
                    }
                    json = try MCPToolHandler.searchEvents(
                        query: query,
                        from: from,
                        to: to,
                        calendars: MCPArgExtract.stringArray(args["calendar"]),
                        limit: MCPArgExtract.int(args["limit"]) ?? 50
                    )
                case "create_event":
                    guard let calendar = args["calendar"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'calendar'.")
                    }
                    guard let title = args["title"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'title'.")
                    }
                    guard let start = args["start"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'start'.")
                    }
                    guard let end = args["end"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'end'.")
                    }
                    json = try MCPToolHandler.createEvent(
                        calendar: calendar,
                        title: title,
                        start: start,
                        end: end,
                        timezone: args["timezone"]?.stringValue,
                        allDay: MCPArgExtract.bool(args["allDay"]),
                        location: args["location"]?.stringValue,
                        notes: args["notes"]?.stringValue,
                        url: args["url"]?.stringValue,
                        repeatFrequency: args["repeat"]?.stringValue,
                        interval: MCPArgExtract.int(args["interval"]),
                        byday: args["byday"]?.stringValue,
                        until: args["until"]?.stringValue,
                        count: MCPArgExtract.int(args["count"]),
                        rrule: args["rrule"]?.stringValue,
                        alarmMinutes: MCPArgExtract.intArray(args["alarmMinutes"])
                    )
                case "update_event":
                    guard let id = args["id"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'id'.")
                    }
                    json = try MCPToolHandler.updateEvent(
                        id: id,
                        title: args["title"]?.stringValue,
                        start: args["start"]?.stringValue,
                        end: args["end"]?.stringValue,
                        timezone: args["timezone"]?.stringValue,
                        allDay: MCPArgExtract.bool(args["allDay"]),
                        location: args["location"]?.stringValue,
                        notes: args["notes"]?.stringValue,
                        url: args["url"]?.stringValue,
                        occurrenceStart: args["occurrenceStart"]?.stringValue,
                        scope: args["scope"]?.stringValue ?? "all",
                        expectedRevision: MCPArgExtract.int(args["expectedRevision"]),
                        repeatFrequency: args["repeat"]?.stringValue,
                        interval: MCPArgExtract.int(args["interval"]),
                        byday: args["byday"]?.stringValue,
                        until: args["until"]?.stringValue,
                        count: MCPArgExtract.int(args["count"]),
                        rrule: args["rrule"]?.stringValue,
                        clearRecurrence: MCPArgExtract.bool(args["clearRecurrence"]) ?? false,
                        alarmMinutes: MCPArgExtract.intArray(args["alarmMinutes"])
                    )
                case "delete_event":
                    guard let id = args["id"]?.stringValue else {
                        throw ACalError.validation("Missing required parameter 'id'.")
                    }
                    json = try MCPToolHandler.deleteEvent(
                        id: id,
                        occurrenceStart: args["occurrenceStart"]?.stringValue,
                        scope: args["scope"]?.stringValue ?? "all",
                        expectedRevision: MCPArgExtract.int(args["expectedRevision"])
                    )
                default:
                    return .init(
                        content: [.text(text: "Unknown tool '\(params.name)'.", annotations: nil, _meta: nil)],
                        isError: true
                    )
                }
                return .init(content: [.text(text: json, annotations: nil, _meta: nil)], isError: false)
            } catch let error as ACalError {
                return .init(
                    content: [.text(
                        text: "Error [\(error.code.rawValue)]: \(error.message.text)",
                        annotations: nil,
                        _meta: nil
                    )],
                    isError: true
                )
            } catch {
                return .init(
                    content: [.text(
                        text: "Internal error: \(error.localizedDescription)",
                        annotations: nil,
                        _meta: nil
                    )],
                    isError: true
                )
            }
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
        await server.waitUntilCompleted()
    }
}

// MARK: - Argument Extraction Helpers

enum MCPArgExtract {
    static func int(_ value: Value?) -> Int? {
        switch value {
        case let .int(num): return num
        case let .double(num):
            guard num.isFinite, num >= Double(Int.min), num <= Double(Int.max) else { return nil }
            return Int(exactly: num.rounded())
        case let .string(str): return Int(str)
        default: return nil
        }
    }

    static func bool(_ value: Value?) -> Bool? {
        switch value {
        case let .bool(flag): return flag
        case let .string(str) where str == "true" || str == "false":
            return str == "true"
        default: return nil
        }
    }

    static func stringArray(_ value: Value?) -> [String] {
        switch value {
        case let .array(items): return items.compactMap(\.stringValue)
        default: return []
        }
    }

    static func intArray(_ value: Value?) -> [Int] {
        switch value {
        case let .array(items): return items.compactMap { MCPArgExtract.int($0) }
        default: return []
        }
    }
}

// MARK: - Tool Handlers (testable, MCP-independent)

enum MCPToolHandler {
    static func authStatus() throws -> String {
        let state = EventKitAdapter.currentAuthorizationState()
        let payload: [String: String] = [
            "state": state.rawValue,
            "hasWriteAccess": String(state.hasWriteAccess),
            "hint": state == .fullAccess
                ? "Calendar access is granted."
                : "Calendar access is not granted. Call auth_grant to request it."
        ]
        return try toJSON(payload)
    }

    static func authGrant() throws -> String {
        let state = try EventKitAdapter.requestFullAccess()
        let payload: [String: String] = [
            "state": state.rawValue,
            "granted": String(state == .fullAccess),
            "hint": state == .fullAccess
                ? "Calendar access granted."
                : "Access was not granted. If no dialog appeared, run 'acal auth grant' in a terminal first. "
                + "macOS only shows permission dialogs from terminal applications."
        ]
        return try toJSON(payload)
    }

    static func listCalendars(store: any CalendarStore = CLI.store) throws -> String {
        let calendars = try store.listCalendars()
        return try toJSON(calendars)
    }

    static func getCalendar(
        id: String?,
        name: String?,
        store: any CalendarStore = CLI.store
    ) throws -> String {
        guard id != nil || name != nil else {
            throw ACalError.validation("Provide 'id' or 'name'.")
        }
        let calendar = try store.getCalendar(id: id, name: name)
        return try toJSON(calendar)
    }

    static func listEvents(
        from: String,
        to: String,
        calendars: [String],
        limit: Int,
        store: any CalendarStore = CLI.store
    ) throws -> String {
        guard limit > 0 else {
            throw ACalError.validation("'limit' must be a positive integer.")
        }
        let start = try DateCodec.parse(from)
        let end = try DateCodec.parse(to)
        let calendarIDs = try resolveCalendarIDs(calendars, store: store)
        var events = try store.listEvents(from: start, to: end, calendarIDs: calendarIDs)
        if events.count > limit {
            events = Array(events.prefix(limit))
        }
        return try toJSON(events)
    }

    static func getEvent(
        id: String?,
        externalId: String?,
        store: any CalendarStore = CLI.store
    ) throws -> String {
        guard id != nil || externalId != nil else {
            throw ACalError.validation("Provide 'id' or 'externalId'.")
        }
        let event = try store.getEvent(id: id, externalID: externalId)
        return try toJSON(event)
    }

    static func searchEvents(
        query: String,
        from: String,
        to: String,
        calendars: [String],
        limit: Int,
        store: any CalendarStore = CLI.store
    ) throws -> String {
        guard limit > 0 else {
            throw ACalError.validation("'limit' must be a positive integer.")
        }
        let start = try DateCodec.parse(from)
        let end = try DateCodec.parse(to)
        let calendarIDs = try resolveCalendarIDs(calendars, store: store)
        var events = try store.searchEvents(
            query: query, from: start, to: end, calendarIDs: calendarIDs
        )
        if events.count > limit {
            events = Array(events.prefix(limit))
        }
        return try toJSON(events)
    }

    static func createEvent(
        calendar: String,
        title: String,
        start: String,
        end: String,
        timezone: String?,
        allDay: Bool?,
        location: String?,
        notes: String?,
        url: String?,
        repeatFrequency: String?,
        interval: Int?,
        byday: String?,
        until: String?,
        count: Int?,
        rrule: String?,
        alarmMinutes: [Int],
        store: any CalendarStore = CLI.store
    ) throws -> String {
        let resolvedCalendar: CalendarRecord
        if let byID = try? store.getCalendar(id: calendar, name: nil) {
            resolvedCalendar = byID
        } else {
            resolvedCalendar = try store.getCalendar(id: nil, name: calendar)
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

        let event = try store.createEvent(input: EventCreateInput(
            calendarId: resolvedCalendar.id,
            title: title,
            start: startDate,
            end: endDate,
            timezone: resolvedTimeZone,
            allDay: allDay ?? false,
            location: location,
            notes: notes,
            url: url.flatMap(URL.init(string:)),
            recurrence: recurrence,
            alarms: alarms
        ))
        return try toJSON(event)
    }

    static func updateEvent(
        id: String,
        title: String?,
        start: String?,
        end: String?,
        timezone: String?,
        allDay: Bool?,
        location: String?,
        notes: String?,
        url: String?,
        occurrenceStart: String?,
        scope: String,
        expectedRevision: Int?,
        repeatFrequency: String?,
        interval: Int?,
        byday: String?,
        until: String?,
        count: Int?,
        rrule: String?,
        clearRecurrence: Bool,
        alarmMinutes: [Int],
        store: any CalendarStore = CLI.store
    ) throws -> String {
        let timezoneObject = try CLI.parseTimezone(timezone)
        guard let scopeValue = EventDeleteScope(rawValue: scope.lowercased()) else {
            throw ACalError.validation("Invalid scope '\(scope)'. Use this|future|all.")
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

        let event = try store.updateEvent(
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
        return try toJSON(event)
    }

    static func deleteEvent(
        id: String,
        occurrenceStart: String?,
        scope: String,
        expectedRevision: Int?,
        store: any CalendarStore = CLI.store
    ) throws -> String {
        guard let scopeValue = EventDeleteScope(rawValue: scope.lowercased()) else {
            throw ACalError.validation("Invalid scope '\(scope)'. Use this|future|all.")
        }

        let payload = try store.deleteEvent(
            id: id,
            input: EventDeleteInput(
                occurrenceStart: occurrenceStart.map { try DateCodec.parse($0) },
                scope: scopeValue,
                expectedRevision: expectedRevision
            )
        )
        return try toJSON(payload)
    }

    // MARK: - Calendar Resolution

    private static func resolveCalendarIDs(_ values: [String], store: any CalendarStore) throws -> Set<String> {
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

    // MARK: - JSON Serialization

    static func toJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ACalError.validation("Failed to encode response as JSON.")
        }
        return string
    }
}

// MARK: - Tool Definitions

enum MCPToolDefinitions {
    static let all: [Tool] = [
        authStatusTool,
        authGrantTool,
        listCalendarsTool,
        getCalendarTool,
        listEventsTool,
        getEventTool,
        searchEventsTool,
        createEventTool,
        updateEventTool,
        deleteEventTool
    ]

    static let authStatusTool = Tool(
        name: "auth_status",
        description: "Check calendar access authorization state.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    )

    static let authGrantTool = Tool(
        name: "auth_grant",
        description: "Request calendar access permission. Triggers the macOS permission dialog.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    )

    static let listCalendarsTool = Tool(
        name: "list_calendars",
        // swiftlint:disable:next line_length
        description: "List all available calendars. Returns array of calendars with id, title, source (e.g. iCloud, Local), color, and writable status.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:])
        ])
    )

    static let getCalendarTool = Tool(
        name: "get_calendar",
        description: "Get a specific calendar by ID or name. Provide at least one of 'id' or 'name'.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "id": .object([
                    "type": .string("string"),
                    "description": .string("Calendar identifier")
                ]),
                "name": .object([
                    "type": .string("string"),
                    "description": .string("Calendar exact title")
                ])
            ])
        ])
    )

    static let listEventsTool = Tool(
        name: "list_events",
        // swiftlint:disable:next line_length
        description: "List events in a date range. Returns events sorted by start time. Use 'limit' to control how many results are returned (default 50).",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "from": .object([
                    "type": .string("string"),
                    "description": .string("Range start in ISO-8601 (2026-03-01T09:00:00Z) or YYYY-MM-DD")
                ]),
                "to": .object([
                    "type": .string("string"),
                    "description": .string("Range end in ISO-8601 or YYYY-MM-DD")
                ]),
                "calendar": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("Filter by calendar IDs or names")
                ]),
                "limit": .object([
                    "type": .string("integer"),
                    "description": .string("Maximum results to return (default: 50)")
                ])
            ]),
            "required": .array([.string("from"), .string("to")])
        ])
    )

    static let getEventTool = Tool(
        name: "get_event",
        description: "Get a single event by ID or external ID. Provide at least one of 'id' or 'externalId'.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "id": .object([
                    "type": .string("string"),
                    "description": .string("Local event identifier")
                ]),
                "externalId": .object([
                    "type": .string("string"),
                    "description": .string("External event identifier")
                ])
            ])
        ])
    )

    static let searchEventsTool = Tool(
        name: "search_events",
        // swiftlint:disable:next line_length
        description: "Search events by text query within a date range. Matches against title, location, and notes. Use 'limit' to control results (default 50).",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string"),
                    "description": .string("Text to search for in title, location, and notes")
                ]),
                "from": .object([
                    "type": .string("string"),
                    "description": .string("Range start in ISO-8601 or YYYY-MM-DD")
                ]),
                "to": .object([
                    "type": .string("string"),
                    "description": .string("Range end in ISO-8601 or YYYY-MM-DD")
                ]),
                "calendar": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("Filter by calendar IDs or names")
                ]),
                "limit": .object([
                    "type": .string("integer"),
                    "description": .string("Maximum results to return (default: 50)")
                ])
            ]),
            "required": .array([.string("query"), .string("from"), .string("to")])
        ])
    )

    static let createEventTool = Tool(
        name: "create_event",
        description: "Create a new calendar event. Returns the created event with its assigned ID and revision number.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "calendar": .object([
                    "type": .string("string"),
                    "description": .string("Calendar ID or exact name")
                ]),
                "title": .object([
                    "type": .string("string"),
                    "description": .string("Event title")
                ]),
                "start": .object([
                    "type": .string("string"),
                    "description": .string("Start date-time in ISO-8601 or YYYY-MM-DD")
                ]),
                "end": .object([
                    "type": .string("string"),
                    "description": .string("End date-time in ISO-8601 or YYYY-MM-DD")
                ]),
                "timezone": .object([
                    "type": .string("string"),
                    "description": .string("Timezone identifier (e.g. America/New_York, Europe/Berlin)")
                ]),
                "allDay": .object([
                    "type": .string("boolean"),
                    "description": .string("Create as all-day event")
                ]),
                "location": .object([
                    "type": .string("string"),
                    "description": .string("Event location")
                ]),
                "notes": .object([
                    "type": .string("string"),
                    "description": .string("Event notes/description")
                ]),
                "url": .object([
                    "type": .string("string"),
                    "description": .string("URL associated with the event")
                ]),
                "repeat": .object([
                    "type": .string("string"),
                    "description": .string("Recurrence frequency: daily, weekly, monthly, yearly"),
                    "enum": .array([.string("daily"), .string("weekly"), .string("monthly"), .string("yearly")])
                ]),
                "interval": .object([
                    "type": .string("integer"),
                    "description": .string("Recurrence interval (e.g. 2 for every 2 weeks)")
                ]),
                "byday": .object([
                    "type": .string("string"),
                    "description": .string("Comma-separated weekdays for recurrence (mon,tue,wed,thu,fri,sat,sun)")
                ]),
                "until": .object([
                    "type": .string("string"),
                    "description": .string("Recurrence end date in ISO-8601 or YYYY-MM-DD")
                ]),
                "count": .object([
                    "type": .string("integer"),
                    "description": .string("Number of recurrence occurrences")
                ]),
                "rrule": .object([
                    "type": .string("string"),
                    "description": .string("Advanced RRULE string (overrides repeat/interval/byday/until/count)")
                ]),
                "alarmMinutes": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Alarm offsets in minutes relative to start (negative = before, e.g. -10)")
                ])
            ]),
            "required": .array([.string("calendar"), .string("title"), .string("start"), .string("end")])
        ])
    )

    static let updateEventTool = Tool(
        name: "update_event",
        // swiftlint:disable:next line_length
        description: "Update an existing event. Only provide fields you want to change. Use 'expectedRevision' for optimistic concurrency (get it from get_event). For recurring events, use 'scope' to control which occurrences are affected.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "id": .object([
                    "type": .string("string"),
                    "description": .string("Event identifier (required)")
                ]),
                "title": .object(["type": .string("string"), "description": .string("New title")]),
                "start": .object(["type": .string("string"), "description": .string("New start date-time")]),
                "end": .object(["type": .string("string"), "description": .string("New end date-time")]),
                "timezone": .object(["type": .string("string"), "description": .string("New timezone identifier")]),
                "allDay": .object(["type": .string("boolean"), "description": .string("Set all-day mode")]),
                "location": .object(["type": .string("string"), "description": .string("New location")]),
                "notes": .object(["type": .string("string"), "description": .string("New notes")]),
                "url": .object(["type": .string("string"), "description": .string("New URL")]),
                "occurrenceStart": .object([
                    "type": .string("string"),
                    "description": .string("For recurring events: the specific occurrence to edit (ISO-8601)")
                ]),
                "scope": .object([
                    "type": .string("string"),
                    "description": .string("Edit scope for recurring events: this, future, or all (default: all)"),
                    "enum": .array([.string("this"), .string("future"), .string("all")])
                ]),
                "expectedRevision": .object([
                    "type": .string("integer"),
                    "description": .string("Expected current revision for optimistic concurrency check")
                ]),
                "repeat": .object([
                    "type": .string("string"),
                    "description": .string("Set recurrence: daily, weekly, monthly, yearly")
                ]),
                "interval": .object(["type": .string("integer"), "description": .string("Recurrence interval")]),
                "byday": .object(["type": .string("string"), "description": .string("Comma-separated weekdays")]),
                "until": .object(["type": .string("string"), "description": .string("Recurrence end date")]),
                "count": .object(["type": .string("integer"), "description": .string("Recurrence occurrence count")]),
                "rrule": .object(["type": .string("string"), "description": .string("Advanced RRULE string")]),
                "clearRecurrence": .object([
                    "type": .string("boolean"),
                    "description": .string("Remove recurrence from event")
                ]),
                "alarmMinutes": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("integer")]),
                    "description": .string("Replace alarms with these offsets in minutes")
                ])
            ]),
            "required": .array([.string("id")])
        ])
    )

    static let deleteEventTool = Tool(
        name: "delete_event",
        // swiftlint:disable:next line_length
        description: "Delete an event. For recurring events, use 'scope' to control deletion. Use 'expectedRevision' for safe concurrent access.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "id": .object([
                    "type": .string("string"),
                    "description": .string("Event identifier (required)")
                ]),
                "occurrenceStart": .object([
                    "type": .string("string"),
                    "description": .string("For recurring events: the specific occurrence (ISO-8601)")
                ]),
                "scope": .object([
                    "type": .string("string"),
                    "description": .string("Delete scope: this, future, or all (default: all)"),
                    "enum": .array([.string("this"), .string("future"), .string("all")])
                ]),
                "expectedRevision": .object([
                    "type": .string("integer"),
                    "description": .string("Expected revision for optimistic concurrency")
                ])
            ]),
            "required": .array([.string("id")])
        ])
    )
}
