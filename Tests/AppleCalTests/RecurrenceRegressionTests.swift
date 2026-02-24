import XCTest
@testable import AppCore

final class RecurrenceRegressionTests: XCTestCase {
    func testSingleOccurrenceEditCapturesOccurrenceAnchor() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-work",
            title: "Recurring",
            start: try DateCodec.parse("2026-03-01T09:00:00+01:00"),
            end: try DateCodec.parse("2026-03-01T09:30:00+01:00"),
            timezone: TimeZone(identifier: "Europe/Berlin")!,
            allDay: false,
            recurrence: RecurrenceRuleRecord(frequency: .weekly, interval: 1, byDay: [.mon])
        ))

        let updated = try store.updateEvent(
            id: created.id,
            occurrenceStart: try DateCodec.parse("2026-03-08T09:00:00+01:00"),
            scope: .this,
            input: EventUpdateInput(title: "Single edit", expectedRevision: created.revision)
        )

        XCTAssertEqual(updated.title, "Single edit")
        XCTAssertEqual(updated.occurrenceStart, DateCodec.iso8601String(from: try DateCodec.parse("2026-03-08T09:00:00+01:00")))
    }

    func testFutureEditScopeAccepted() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-work",
            title: "Recurring",
            start: try DateCodec.parse("2026-03-01T09:00:00+01:00"),
            end: try DateCodec.parse("2026-03-01T09:30:00+01:00"),
            timezone: TimeZone(identifier: "Europe/Berlin")!,
            allDay: false,
            recurrence: RecurrenceRuleRecord(frequency: .weekly, interval: 1)
        ))

        let updated = try store.updateEvent(
            id: created.id,
            occurrenceStart: try DateCodec.parse("2026-04-01T09:00:00+02:00"),
            scope: .future,
            input: EventUpdateInput(location: "Room B", expectedRevision: created.revision)
        )

        XCTAssertEqual(updated.location, "Room B")
        XCTAssertEqual(updated.seriesMasterId, created.id)
    }

    func testTimezoneParsingDSTBoundary() throws {
        let berlin = TimeZone(identifier: "Europe/Berlin")!
        let parsed = try DateCodec.parse("2026-03-29", defaultTimeZone: berlin)

        let formatted = DateCodec.iso8601String(from: parsed)
        XCTAssertTrue(formatted.contains("T"))
    }
}
