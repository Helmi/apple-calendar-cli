import Foundation

public final class InMemoryCalendarStore: CalendarStore, @unchecked Sendable {
    public static let shared = InMemoryCalendarStore()

    private var calendars: [CalendarRecord]
    private var eventsByID: [String: EventRecord]

    public init(
        calendars: [CalendarRecord] = [
            CalendarRecord(id: "cal-default", title: "Default", source: "Local", colorHex: "#3478F6", writable: true),
            CalendarRecord(id: "cal-work", title: "Work", source: "iCloud", colorHex: "#34C759", writable: true)
        ],
        events: [EventRecord] = []
    ) {
        self.calendars = calendars
        eventsByID = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })
    }

    public func listCalendars() throws -> [CalendarRecord] {
        calendars.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func getCalendar(id: String?, name: String?) throws -> CalendarRecord {
        if let id, let calendar = calendars.first(where: { $0.id == id }) {
            return calendar
        }

        if let name, let calendar = calendars.first(where: { $0.title == name }) {
            return calendar
        }

        throw AppleCalError.notFound("Calendar not found.", details: ["id": id ?? "", "name": name ?? ""])
    }

    public func listEvents(from start: Date, to end: Date, calendarIDs: Set<String>) throws -> [EventRecord] {
        let chunks = try DateRangeChunker.chunkedRanges(from: start, to: end)
        var all: [EventRecord] = []

        for (chunkStart, chunkEnd) in chunks {
            let subset = eventsByID.values.filter { event in
                guard let eventStart = try? DateCodec.parse(event.start),
                      let eventEnd = try? DateCodec.parse(event.end)
                else {
                    return false
                }
                if !calendarIDs.isEmpty, !calendarIDs.contains(event.calendarId) {
                    return false
                }
                return eventStart < chunkEnd && eventEnd > chunkStart
            }
            all.append(contentsOf: subset)
        }

        let unique = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
        return unique.values.sorted { $0.start < $1.start }
    }

    public func getEvent(id: String?, externalID: String?) throws -> EventRecord {
        if let id, let event = eventsByID[id] {
            return event
        }

        if let externalID, let event = eventsByID.values.first(where: { $0.externalId == externalID }) {
            return event
        }

        throw AppleCalError.notFound("Event not found.", details: ["id": id ?? "", "externalId": externalID ?? ""])
    }

    public func searchEvents(
        query: String,
        from start: Date,
        to end: Date,
        calendarIDs: Set<String>
    ) throws -> [EventRecord] {
        let base = try listEvents(from: start, to: end, calendarIDs: calendarIDs)
        let needle = query.lowercased()
        return base.filter { event in
            event.title.lowercased().contains(needle)
                || (event.location?.lowercased().contains(needle) ?? false)
                || (event.notes?.lowercased().contains(needle) ?? false)
        }
    }

    public func createEvent(input: EventCreateInput) throws -> EventRecord {
        guard calendars.contains(where: { $0.id == input.calendarId }) else {
            throw AppleCalError.notFound("Calendar '\(input.calendarId)' does not exist.")
        }
        guard input.end > input.start else {
            throw AppleCalError.validation("Event end must be after start.")
        }

        let id = "evt-\(UUID().uuidString.lowercased())"
        let externalId = "ext-\(UUID().uuidString.lowercased())"
        let event = EventRecord(
            id: id,
            externalId: externalId,
            calendarId: input.calendarId,
            title: input.title,
            location: input.location,
            notes: input.notes,
            url: input.url?.absoluteString,
            start: DateCodec.iso8601String(from: input.start),
            end: DateCodec.iso8601String(from: input.end),
            timezone: input.timezone.identifier,
            allDay: input.allDay,
            recurrence: input.recurrence,
            alarms: input.alarms,
            occurrenceStart: nil,
            seriesMasterId: input.recurrence == nil ? nil : id,
            revision: 1
        )
        eventsByID[id] = event
        return event
    }

    public func updateEvent(
        id: String,
        occurrenceStart: Date?,
        scope: EventDeleteScope,
        input: EventUpdateInput
    ) throws -> EventRecord {
        guard var event = eventsByID[id] else {
            throw AppleCalError.notFound("Event '\(id)' was not found.")
        }

        if let expectedRevision = input.expectedRevision, expectedRevision != event.revision {
            throw AppleCalError.conflict(
                "Event revision mismatch.",
                details: ["expected": String(expectedRevision), "current": String(event.revision)]
            )
        }

        if let title = input.title {
            event.title = title
        }

        if let start = input.start {
            event.start = DateCodec.iso8601String(from: start)
        }

        if let end = input.end {
            event.end = DateCodec.iso8601String(from: end)
        }

        if let timezone = input.timezone {
            event.timezone = timezone.identifier
        }

        if let allDay = input.allDay {
            event.allDay = allDay
        }

        if let location = input.location {
            event.location = location
        }

        if let notes = input.notes {
            event.notes = notes
        }

        if let url = input.url {
            event.url = url.absoluteString
        }

        if input.clearRecurrence {
            event.recurrence = nil
        } else if let recurrence = input.recurrence {
            event.recurrence = recurrence
        }

        if let alarms = input.alarms {
            event.alarms = alarms
        }

        if let start = occurrenceStart {
            event.occurrenceStart = DateCodec.iso8601String(from: start)
            if scope != .all {
                event.seriesMasterId = id
            }
        }

        guard let parsedStart = try? DateCodec.parse(event.start), let parsedEnd = try? DateCodec.parse(event.end),
              parsedEnd > parsedStart
        else {
            throw AppleCalError.validation("Updated event time range is invalid.")
        }

        event.revision += 1
        eventsByID[id] = event
        return event
    }

    public func deleteEvent(id: String, input: EventDeleteInput) throws -> [String: String] {
        guard let event = eventsByID[id] else {
            throw AppleCalError.notFound("Event '\(id)' was not found.")
        }

        if let expectedRevision = input.expectedRevision, expectedRevision != event.revision {
            throw AppleCalError.conflict(
                "Event revision mismatch.",
                details: ["expected": String(expectedRevision), "current": String(event.revision)]
            )
        }

        if input.scope != .all, input.occurrenceStart == nil {
            throw AppleCalError.validation("--occurrence-start is required when scope is this or future.")
        }

        eventsByID.removeValue(forKey: id)

        return [
            "id": id,
            "scope": input.scope.rawValue,
            "status": "deleted"
        ]
    }
}
