import Foundation

public protocol CalendarStore: Sendable {
    func listCalendars() throws -> [CalendarRecord]
    func getCalendar(id: String?, name: String?) throws -> CalendarRecord
    func listEvents(from start: Date, to end: Date, calendarIDs: Set<String>) throws -> [EventRecord]
    func getEvent(id: String?, externalID: String?) throws -> EventRecord
    func searchEvents(query: String, from start: Date, to end: Date, calendarIDs: Set<String>) throws -> [EventRecord]
    func createEvent(input: EventCreateInput) throws -> EventRecord
    func updateEvent(id: String, occurrenceStart: Date?, scope: EventDeleteScope, input: EventUpdateInput) throws -> EventRecord
    func deleteEvent(id: String, input: EventDeleteInput) throws -> [String: String]
}
