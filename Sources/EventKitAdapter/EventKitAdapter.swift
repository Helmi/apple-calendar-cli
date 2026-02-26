import AppCore
import EventKit
import Foundation

public enum EventKitAdapter {
    public static func eventKitAvailable() -> Bool {
        true
    }

    public static func currentAuthorizationState() -> AppleCalAuthorizationState {
        if let override = ProcessInfo.processInfo.environment["APPLECAL_AUTH_STATE"],
           let overridden = AppleCalAuthorizationState(rawValue: override)
        {
            return overridden
        }

        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .fullAccess:
            return .fullAccess
        case .writeOnly:
            return .writeOnly
        @unknown default:
            return .restricted
        }
    }

    public static func requestFullAccess() throws -> AppleCalAuthorizationState {
        if let simulated = ProcessInfo.processInfo.environment["APPLECAL_AUTH_GRANT_RESULT"],
           let state = AppleCalAuthorizationState(rawValue: simulated)
        {
            return state
        }

        let store = EKEventStore()
        let box = AuthorizationResultBox()
        let semaphore = DispatchSemaphore(value: 0)

        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { allowed, error in
                box.granted = allowed
                box.error = error
                semaphore.signal()
            }
        } else {
            store.requestAccess(to: .event) { allowed, error in
                box.granted = allowed
                box.error = error
                semaphore.signal()
            }
        }

        semaphore.wait()

        if let requestError = box.error {
            throw AppleCalError(
                code: .eventKitFailure,
                message: AppleCalUserMessage("EventKit authorization request failed."),
                details: ["cause": String(describing: requestError)]
            )
        }

        return box.granted ? .fullAccess : .denied
    }

    public static func makeEKRecurrenceRule(from record: RecurrenceRuleRecord) -> EKRecurrenceRule {
        let frequency: EKRecurrenceFrequency
        switch record.frequency {
        case .daily:
            frequency = .daily
        case .weekly:
            frequency = .weekly
        case .monthly:
            frequency = .monthly
        case .yearly:
            frequency = .yearly
        }

        let daysOfWeek: [EKRecurrenceDayOfWeek] = record.byDay.compactMap { weekday in
            switch weekday {
            case .sun:
                return EKRecurrenceDayOfWeek(.sunday)
            case .mon:
                return EKRecurrenceDayOfWeek(.monday)
            case .tue:
                return EKRecurrenceDayOfWeek(.tuesday)
            case .wed:
                return EKRecurrenceDayOfWeek(.wednesday)
            case .thu:
                return EKRecurrenceDayOfWeek(.thursday)
            case .fri:
                return EKRecurrenceDayOfWeek(.friday)
            case .sat:
                return EKRecurrenceDayOfWeek(.saturday)
            }
        }

        let end: EKRecurrenceEnd?
        if let count = record.count {
            end = EKRecurrenceEnd(occurrenceCount: count)
        } else if let until = record.until,
                  let untilDate = try? DateCodec.parse(until)
        {
            end = EKRecurrenceEnd(end: untilDate)
        } else {
            end = nil
        }

        return EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: record.interval,
            daysOfTheWeek: daysOfWeek.isEmpty ? nil : daysOfWeek,
            daysOfTheMonth: nil,
            monthsOfTheYear: nil,
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: nil,
            end: end
        )
    }
}

public final class EventKitCalendarStore: CalendarStore, @unchecked Sendable {
    public static let shared = EventKitCalendarStore()

    private let store = EKEventStore()
    private let queue = DispatchQueue(label: "applecal.eventkit.store")

    public init() {}

    public func listCalendars() throws -> [CalendarRecord] {
        try queue.sync {
            try ensureReadAccess()
            return store.calendars(for: .event)
                .map { calendar in
                    CalendarRecord(
                        id: calendar.calendarIdentifier,
                        title: calendar.title,
                        source: calendar.source.title,
                        colorHex: calendar.cgColor?.hexString ?? "#000000",
                        writable: calendar.allowsContentModifications
                    )
                }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    public func getCalendar(id: String?, name: String?) throws -> CalendarRecord {
        let calendars = try listCalendars()

        if let id, let calendar = calendars.first(where: { $0.id == id }) {
            return calendar
        }

        if let name, let calendar = calendars.first(where: { $0.title == name }) {
            return calendar
        }

        throw AppleCalError.notFound("Calendar not found.", details: ["id": id ?? "", "name": name ?? ""])
    }

    public func listEvents(from start: Date, to end: Date, calendarIDs: Set<String>) throws -> [EventRecord] {
        try queue.sync {
            try ensureReadAccess()

            var all: [EKEvent] = []
            let calendars = store.calendars(for: .event).filter { calendar in
                calendarIDs.isEmpty || calendarIDs.contains(calendar.calendarIdentifier)
            }

            for (chunkStart, chunkEnd) in try DateRangeChunker.chunkedRanges(from: start, to: end) {
                let predicate = store.predicateForEvents(withStart: chunkStart, end: chunkEnd, calendars: calendars)
                all.append(contentsOf: store.events(matching: predicate))
            }

            let deduped = Dictionary(uniqueKeysWithValues: all.map { ($0.calendarItemIdentifier, $0) })
            return deduped.values
                .map(serialize(event:))
                .sorted { $0.start < $1.start }
        }
    }

    public func getEvent(id: String?, externalID: String?) throws -> EventRecord {
        try queue.sync {
            try ensureReadAccess()

            if let id,
               let item = store.calendarItem(withIdentifier: id) as? EKEvent
            {
                return serialize(event: item)
            }

            guard let externalID else {
                throw AppleCalError.notFound(
                    "Event not found.",
                    details: ["id": id ?? "", "externalId": externalID ?? ""]
                )
            }

            let now = Date()
            let from = now.addingTimeInterval(-60 * 60 * 24 * 365)
            let to = now.addingTimeInterval(60 * 60 * 24 * 365 * 2)
            let events = try listEvents(from: from, to: to, calendarIDs: [])
            if let match = events.first(where: { $0.externalId == externalID }) {
                return match
            }

            throw AppleCalError.notFound("Event not found.", details: ["id": id ?? "", "externalId": externalID])
        }
    }

    public func searchEvents(
        query: String,
        from start: Date,
        to end: Date,
        calendarIDs: Set<String>
    ) throws -> [EventRecord] {
        let events = try listEvents(from: start, to: end, calendarIDs: calendarIDs)
        let needle = query.lowercased()
        return events.filter { event in
            event.title.lowercased().contains(needle)
                || (event.location?.lowercased().contains(needle) ?? false)
                || (event.notes?.lowercased().contains(needle) ?? false)
        }
    }

    public func createEvent(input: EventCreateInput) throws -> EventRecord {
        try queue.sync {
            try ensureWriteAccess()

            guard let calendar = store.calendar(withIdentifier: input.calendarId) else {
                throw AppleCalError.notFound("Calendar '\(input.calendarId)' does not exist.")
            }

            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = input.title
            event.location = input.location
            event.notes = input.notes
            event.url = input.url
            event.timeZone = input.timezone
            event.startDate = input.start
            event.endDate = input.end
            event.isAllDay = input.allDay

            if let recurrence = input.recurrence {
                event.recurrenceRules = [EventKitAdapter.makeEKRecurrenceRule(from: recurrence)]
            }

            if !input.alarms.isEmpty {
                event.alarms = input.alarms.map { alarm in
                    EKAlarm(relativeOffset: TimeInterval(alarm.relativeMinutes * 60))
                }
            }

            try store.save(event, span: .thisEvent, commit: true)
            return serialize(event: event)
        }
    }

    public func updateEvent(
        id: String,
        occurrenceStart: Date?,
        scope: EventDeleteScope,
        input: EventUpdateInput
    ) throws -> EventRecord {
        try queue.sync {
            try ensureWriteAccess()

            guard let event = store.calendarItem(withIdentifier: id) as? EKEvent else {
                throw AppleCalError.notFound("Event '\(id)' was not found.")
            }

            let currentRevision = revision(for: event)
            if let expectedRevision = input.expectedRevision, expectedRevision != currentRevision {
                throw AppleCalError.conflict(
                    "Event revision mismatch.",
                    details: ["expected": String(expectedRevision), "current": String(currentRevision)]
                )
            }

            if let title = input.title { event.title = title }
            if let start = input.start { event.startDate = start }
            if let end = input.end { event.endDate = end }
            if let timezone = input.timezone { event.timeZone = timezone }
            if let allDay = input.allDay { event.isAllDay = allDay }
            if let location = input.location { event.location = location }
            if let notes = input.notes { event.notes = notes }
            if let url = input.url { event.url = url }

            if input.clearRecurrence {
                event.recurrenceRules = nil
            } else if let recurrence = input.recurrence {
                event.recurrenceRules = [EventKitAdapter.makeEKRecurrenceRule(from: recurrence)]
            }

            if let alarms = input.alarms {
                event.alarms = alarms.map { EKAlarm(relativeOffset: TimeInterval($0.relativeMinutes * 60)) }
            }

            let span = eventSpan(for: scope)
            try store.save(event, span: span, commit: true)
            var record = serialize(event: event)
            if let occurrenceStart {
                record.occurrenceStart = DateCodec.iso8601String(from: occurrenceStart)
            }
            return record
        }
    }

    public func deleteEvent(id: String, input: EventDeleteInput) throws -> [String: String] {
        try queue.sync {
            try ensureWriteAccess()

            guard let event = store.calendarItem(withIdentifier: id) as? EKEvent else {
                throw AppleCalError.notFound("Event '\(id)' was not found.")
            }

            let currentRevision = revision(for: event)
            if let expectedRevision = input.expectedRevision, expectedRevision != currentRevision {
                throw AppleCalError.conflict(
                    "Event revision mismatch.",
                    details: ["expected": String(expectedRevision), "current": String(currentRevision)]
                )
            }

            if input.scope != .all, input.occurrenceStart == nil {
                throw AppleCalError.validation("--occurrence-start is required when scope is this or future.")
            }

            try store.remove(event, span: eventSpan(for: input.scope), commit: true)
            return ["id": id, "scope": input.scope.rawValue, "status": "deleted"]
        }
    }

    private func ensureReadAccess() throws {
        let state = EventKitAdapter.currentAuthorizationState()
        guard state == .fullAccess else {
            throw AppleCalError(code: .permissionDenied, message: "Read access requires full calendar permission.")
        }
    }

    private func ensureWriteAccess() throws {
        let state = EventKitAdapter.currentAuthorizationState()
        guard state == .fullAccess else {
            throw AppleCalError(code: .permissionDenied, message: "Write access requires full calendar permission.")
        }
    }

    private func eventSpan(for scope: EventDeleteScope) -> EKSpan {
        switch scope {
        case .this:
            return .thisEvent
        case .future, .all:
            return .futureEvents
        }
    }

    private func revision(for event: EKEvent) -> Int {
        Int(event.lastModifiedDate?.timeIntervalSince1970 ?? 0)
    }

    private func serialize(event: EKEvent) -> EventRecord {
        let recurrence = event.recurrenceRules?.first.flatMap { rule -> RecurrenceRuleRecord? in
            let frequency: RecurrenceFrequency
            switch rule.frequency {
            case .daily:
                frequency = .daily
            case .weekly:
                frequency = .weekly
            case .monthly:
                frequency = .monthly
            case .yearly:
                frequency = .yearly
            @unknown default:
                frequency = .weekly
            }

            let byDay: [Weekday] = (rule.daysOfTheWeek ?? []).compactMap { day in
                switch day.dayOfTheWeek {
                case .sunday:
                    return .sun
                case .monday:
                    return .mon
                case .tuesday:
                    return .tue
                case .wednesday:
                    return .wed
                case .thursday:
                    return .thu
                case .friday:
                    return .fri
                case .saturday:
                    return .sat
                @unknown default:
                    return nil
                }
            }

            return RecurrenceRuleRecord(
                frequency: frequency,
                interval: Int(rule.interval),
                byDay: byDay,
                until: rule.recurrenceEnd?.endDate.map(DateCodec.iso8601String(from:)),
                count: Int(rule.recurrenceEnd?.occurrenceCount ?? 0) == 0 ? nil :
                    Int(rule.recurrenceEnd?.occurrenceCount ?? 0),
                rrule: nil
            )
        }

        let alarms = (event.alarms ?? []).map { alarm in
            AlarmRecord(relativeMinutes: Int(alarm.relativeOffset / 60))
        }

        return EventRecord(
            id: event.calendarItemIdentifier,
            externalId: event.calendarItemExternalIdentifier,
            calendarId: event.calendar.calendarIdentifier,
            title: event.title,
            location: event.location,
            notes: event.notes,
            url: event.url?.absoluteString,
            start: DateCodec.iso8601String(from: event.startDate),
            end: DateCodec.iso8601String(from: event.endDate),
            timezone: event.timeZone?.identifier ?? TimeZone.current.identifier,
            allDay: event.isAllDay,
            recurrence: recurrence,
            alarms: alarms,
            occurrenceStart: nil,
            seriesMasterId: event.hasRecurrenceRules ? event.calendarItemIdentifier : nil,
            revision: revision(for: event)
        )
    }
}

private final class AuthorizationResultBox: @unchecked Sendable {
    var granted = false
    var error: Error?
}

private extension CGColor {
    var hexString: String {
        guard let components else { return "#000000" }
        let values: [CGFloat]
        switch components.count {
        case 2:
            values = [components[0], components[0], components[0], components[1]]
        case 4:
            values = components
        default:
            values = [0, 0, 0, 1]
        }

        let red = Int((values[0] * 255).rounded())
        let green = Int((values[1] * 255).rounded())
        let blue = Int((values[2] * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
