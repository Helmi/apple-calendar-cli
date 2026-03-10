import Foundation

public enum ACalAuthorizationState: String, Codable, Sendable, CaseIterable {
    case notDetermined = "not_determined"
    case denied
    case restricted
    case writeOnly = "write_only"
    case fullAccess = "full_access"

    public var hasWriteAccess: Bool {
        self == .fullAccess || self == .writeOnly
    }
}

public struct CalendarRecord: Codable, Sendable, Equatable {
    public let id: String
    public var title: String
    public var source: String
    public var colorHex: String
    public var writable: Bool

    public init(id: String, title: String, source: String, colorHex: String, writable: Bool) {
        self.id = id
        self.title = title
        self.source = source
        self.colorHex = colorHex
        self.writable = writable
    }
}

public enum RecurrenceFrequency: String, Codable, Sendable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
}

public enum Weekday: String, Codable, Sendable, CaseIterable {
    case mon, tue, wed, thu, fri, sat, sun
}

public struct RecurrenceRuleRecord: Codable, Sendable, Equatable {
    public var frequency: RecurrenceFrequency
    public var interval: Int
    public var byDay: [Weekday]
    public var until: String?
    public var count: Int?
    public var rrule: String?

    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        byDay: [Weekday] = [],
        until: String? = nil,
        count: Int? = nil,
        rrule: String? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.byDay = byDay
        self.until = until
        self.count = count
        self.rrule = rrule
    }
}

public struct AlarmRecord: Codable, Sendable, Equatable {
    public var relativeMinutes: Int

    public init(relativeMinutes: Int) {
        self.relativeMinutes = relativeMinutes
    }
}

public struct EventRecord: Codable, Sendable, Equatable {
    public let id: String
    public let externalId: String
    public var calendarId: String
    public var title: String
    public var location: String?
    public var notes: String?
    public var url: String?
    public var start: String
    public var end: String
    public var timezone: String
    public var allDay: Bool
    public var recurrence: RecurrenceRuleRecord?
    public var alarms: [AlarmRecord]
    public var occurrenceStart: String?
    public var seriesMasterId: String?
    public var revision: Int

    public init(
        id: String,
        externalId: String,
        calendarId: String,
        title: String,
        location: String? = nil,
        notes: String? = nil,
        url: String? = nil,
        start: String,
        end: String,
        timezone: String,
        allDay: Bool,
        recurrence: RecurrenceRuleRecord? = nil,
        alarms: [AlarmRecord] = [],
        occurrenceStart: String? = nil,
        seriesMasterId: String? = nil,
        revision: Int = 1
    ) {
        self.id = id
        self.externalId = externalId
        self.calendarId = calendarId
        self.title = title
        self.location = location
        self.notes = notes
        self.url = url
        self.start = start
        self.end = end
        self.timezone = timezone
        self.allDay = allDay
        self.recurrence = recurrence
        self.alarms = alarms
        self.occurrenceStart = occurrenceStart
        self.seriesMasterId = seriesMasterId
        self.revision = revision
    }
}

public struct EventCreateInput: Sendable {
    public var calendarId: String
    public var title: String
    public var start: Date
    public var end: Date
    public var timezone: TimeZone
    public var allDay: Bool
    public var location: String?
    public var notes: String?
    public var url: URL?
    public var recurrence: RecurrenceRuleRecord?
    public var alarms: [AlarmRecord]

    public init(
        calendarId: String,
        title: String,
        start: Date,
        end: Date,
        timezone: TimeZone,
        allDay: Bool,
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        recurrence: RecurrenceRuleRecord? = nil,
        alarms: [AlarmRecord] = []
    ) {
        self.calendarId = calendarId
        self.title = title
        self.start = start
        self.end = end
        self.timezone = timezone
        self.allDay = allDay
        self.location = location
        self.notes = notes
        self.url = url
        self.recurrence = recurrence
        self.alarms = alarms
    }
}

public struct EventUpdateInput: Sendable {
    public var title: String?
    public var start: Date?
    public var end: Date?
    public var timezone: TimeZone?
    public var allDay: Bool?
    public var location: String?
    public var notes: String?
    public var url: URL?
    public var recurrence: RecurrenceRuleRecord?
    public var clearRecurrence: Bool
    public var alarms: [AlarmRecord]?
    public var expectedRevision: Int?

    public init(
        title: String? = nil,
        start: Date? = nil,
        end: Date? = nil,
        timezone: TimeZone? = nil,
        allDay: Bool? = nil,
        location: String? = nil,
        notes: String? = nil,
        url: URL? = nil,
        recurrence: RecurrenceRuleRecord? = nil,
        clearRecurrence: Bool = false,
        alarms: [AlarmRecord]? = nil,
        expectedRevision: Int? = nil
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.timezone = timezone
        self.allDay = allDay
        self.location = location
        self.notes = notes
        self.url = url
        self.recurrence = recurrence
        self.clearRecurrence = clearRecurrence
        self.alarms = alarms
        self.expectedRevision = expectedRevision
    }
}

public enum EventDeleteScope: String, Codable, Sendable, CaseIterable {
    case this
    case future
    case all
}

public struct EventDeleteInput: Sendable {
    public var occurrenceStart: Date?
    public var scope: EventDeleteScope
    public var expectedRevision: Int?

    public init(occurrenceStart: Date? = nil, scope: EventDeleteScope, expectedRevision: Int? = nil) {
        self.occurrenceStart = occurrenceStart
        self.scope = scope
        self.expectedRevision = expectedRevision
    }
}
