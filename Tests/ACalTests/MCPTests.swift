@testable import App
@testable import AppCore
import XCTest

final class MCPTests: XCTestCase {
    // MARK: - Auth Status

    func testAuthStatusReturnsJSON() throws {
        let json = try MCPToolHandler.authStatus()
        XCTAssertTrue(json.contains("\"state\""))
        XCTAssertTrue(json.contains("\"hint\""))
    }

    // MARK: - List Calendars

    func testListCalendarsReturnsAllCalendars() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.listCalendars(store: store)
        let calendars = try JSONDecoder().decode([CalendarRecord].self, from: Data(json.utf8))
        XCTAssertEqual(calendars.count, 2)
        XCTAssertTrue(calendars.contains(where: { $0.title == "Default" }))
        XCTAssertTrue(calendars.contains(where: { $0.title == "Work" }))
    }

    // MARK: - Get Calendar

    func testGetCalendarByID() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.getCalendar(id: "cal-default", name: nil, store: store)
        let calendar = try JSONDecoder().decode(CalendarRecord.self, from: Data(json.utf8))
        XCTAssertEqual(calendar.id, "cal-default")
        XCTAssertEqual(calendar.title, "Default")
    }

    func testGetCalendarByName() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.getCalendar(id: nil, name: "Work", store: store)
        let calendar = try JSONDecoder().decode(CalendarRecord.self, from: Data(json.utf8))
        XCTAssertEqual(calendar.title, "Work")
    }

    func testGetCalendarMissingBothParams() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.getCalendar(id: nil, name: nil, store: store)) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .validationFailed)
        }
    }

    func testGetCalendarNotFound() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.getCalendar(id: "nonexistent", name: nil, store: store)) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .notFound)
        }
    }

    // MARK: - List Events

    func testListEventsHappyPath() throws {
        let store = InMemoryCalendarStore()
        _ = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default",
            title: "Test Event",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T10:00:00Z"),
            timezone: .current,
            allDay: false
        ))

        let json = try MCPToolHandler.listEvents(
            from: "2026-04-01", to: "2026-04-02", calendars: [], limit: 50, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Test Event")
    }

    func testListEventsRespectsLimit() throws {
        let store = InMemoryCalendarStore()
        for i in 1 ... 10 {
            _ = try store.createEvent(input: EventCreateInput(
                calendarId: "cal-default",
                title: "Event \(i)",
                start: DateCodec.parse("2026-04-01T0\(i):00:00Z"),
                end: DateCodec.parse("2026-04-01T0\(i):30:00Z"),
                timezone: .current,
                allDay: false
            ))
        }

        let json = try MCPToolHandler.listEvents(
            from: "2026-04-01", to: "2026-04-02", calendars: [], limit: 3, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 3)
    }

    func testListEventsEmptyRange() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.listEvents(
            from: "2026-04-01", to: "2026-04-02", calendars: [], limit: 50, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 0)
    }

    func testListEventsInvalidDate() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.listEvents(
            from: "not-a-date", to: "2026-04-02", calendars: [], limit: 50, store: store
        ))
    }

    func testListEventsWithCalendarFilter() throws {
        let store = InMemoryCalendarStore()
        _ = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Default Event",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T10:00:00Z"),
            timezone: .current, allDay: false
        ))
        _ = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-work", title: "Work Event",
            start: DateCodec.parse("2026-04-01T11:00:00Z"),
            end: DateCodec.parse("2026-04-01T12:00:00Z"),
            timezone: .current, allDay: false
        ))

        let json = try MCPToolHandler.listEvents(
            from: "2026-04-01", to: "2026-04-02", calendars: ["cal-work"], limit: 50, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Work Event")
    }

    // MARK: - Get Event

    func testGetEventByID() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Find Me",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T10:00:00Z"),
            timezone: .current, allDay: false
        ))

        let json = try MCPToolHandler.getEvent(id: created.id, externalId: nil, store: store)
        let event = try JSONDecoder().decode(EventRecord.self, from: Data(json.utf8))
        XCTAssertEqual(event.title, "Find Me")
    }

    func testGetEventMissingBothParams() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.getEvent(id: nil, externalId: nil, store: store)) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .validationFailed)
        }
    }

    func testGetEventNotFound() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.getEvent(id: "nonexistent", externalId: nil, store: store)) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .notFound)
        }
    }

    // MARK: - Search Events

    func testSearchEventsHappyPath() throws {
        let store = InMemoryCalendarStore()
        _ = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Team Standup",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T09:30:00Z"),
            timezone: .current, allDay: false
        ))
        _ = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Lunch Break",
            start: DateCodec.parse("2026-04-01T12:00:00Z"),
            end: DateCodec.parse("2026-04-01T13:00:00Z"),
            timezone: .current, allDay: false
        ))

        let json = try MCPToolHandler.searchEvents(
            query: "Standup", from: "2026-04-01", to: "2026-04-02",
            calendars: [], limit: 50, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "Team Standup")
    }

    func testSearchEventsNoResults() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.searchEvents(
            query: "nonexistent", from: "2026-04-01", to: "2026-04-02",
            calendars: [], limit: 50, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 0)
    }

    func testSearchEventsRespectsLimit() throws {
        let store = InMemoryCalendarStore()
        for i in 1 ... 5 {
            _ = try store.createEvent(input: EventCreateInput(
                calendarId: "cal-default", title: "Meeting \(i)",
                start: DateCodec.parse("2026-04-01T0\(i):00:00Z"),
                end: DateCodec.parse("2026-04-01T0\(i):30:00Z"),
                timezone: .current, allDay: false
            ))
        }

        let json = try MCPToolHandler.searchEvents(
            query: "Meeting", from: "2026-04-01", to: "2026-04-02",
            calendars: [], limit: 2, store: store
        )
        let events = try JSONDecoder().decode([EventRecord].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 2)
    }

    // MARK: - Create Event

    func testCreateEventRequiredFieldsOnly() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.createEvent(
            calendar: "cal-default", title: "New Event",
            start: "2026-04-01T09:00:00Z", end: "2026-04-01T10:00:00Z",
            timezone: nil, allDay: nil, location: nil, notes: nil, url: nil,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            alarmMinutes: [],
            store: store
        )
        let event = try JSONDecoder().decode(EventRecord.self, from: Data(json.utf8))
        XCTAssertEqual(event.title, "New Event")
        XCTAssertFalse(event.id.isEmpty)
    }

    func testCreateEventWithAllOptionalFields() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.createEvent(
            calendar: "cal-work", title: "Full Event",
            start: "2026-04-01T09:00:00Z", end: "2026-04-01T10:00:00Z",
            timezone: "Europe/Berlin", allDay: false,
            location: "Office", notes: "Important meeting", url: "https://example.com",
            repeatFrequency: "weekly", interval: 1, byday: "mon,wed,fri",
            until: nil, count: 10, rrule: nil,
            alarmMinutes: [-10, -5],
            store: store
        )
        let event = try JSONDecoder().decode(EventRecord.self, from: Data(json.utf8))
        XCTAssertEqual(event.title, "Full Event")
        XCTAssertEqual(event.location, "Office")
        XCTAssertEqual(event.notes, "Important meeting")
        XCTAssertEqual(event.recurrence?.frequency, .weekly)
        XCTAssertEqual(event.alarms.count, 2)
    }

    func testCreateEventInvalidCalendar() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.createEvent(
            calendar: "nonexistent", title: "Event",
            start: "2026-04-01T09:00:00Z", end: "2026-04-01T10:00:00Z",
            timezone: nil, allDay: nil, location: nil, notes: nil, url: nil,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            alarmMinutes: [],
            store: store
        )) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .notFound)
        }
    }

    // MARK: - Update Event

    func testUpdateEventTitle() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Original",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T10:00:00Z"),
            timezone: .current, allDay: false
        ))

        let json = try MCPToolHandler.updateEvent(
            id: created.id, title: "Updated", start: nil, end: nil,
            timezone: nil, allDay: nil, location: nil, notes: nil, url: nil,
            occurrenceStart: nil, scope: "all", expectedRevision: created.revision,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            clearRecurrence: false, alarmMinutes: [],
            store: store
        )
        let event = try JSONDecoder().decode(EventRecord.self, from: Data(json.utf8))
        XCTAssertEqual(event.title, "Updated")
        XCTAssertEqual(event.revision, created.revision + 1)
    }

    func testUpdateEventRevisionConflict() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Conflict Test",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T10:00:00Z"),
            timezone: .current, allDay: false
        ))

        XCTAssertThrowsError(try MCPToolHandler.updateEvent(
            id: created.id, title: "New", start: nil, end: nil,
            timezone: nil, allDay: nil, location: nil, notes: nil, url: nil,
            occurrenceStart: nil, scope: "all", expectedRevision: 999,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            clearRecurrence: false, alarmMinutes: [],
            store: store
        )) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .conflict)
        }
    }

    func testUpdateEventNotFound() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.updateEvent(
            id: "nonexistent", title: "New", start: nil, end: nil,
            timezone: nil, allDay: nil, location: nil, notes: nil, url: nil,
            occurrenceStart: nil, scope: "all", expectedRevision: nil,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            clearRecurrence: false, alarmMinutes: [],
            store: store
        )) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .notFound)
        }
    }

    func testUpdateEventNoFields() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.updateEvent(
            id: "any-id", title: nil, start: nil, end: nil,
            timezone: nil, allDay: nil, location: nil, notes: nil, url: nil,
            occurrenceStart: nil, scope: "all", expectedRevision: nil,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            clearRecurrence: false, alarmMinutes: [],
            store: store
        )) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .validationFailed)
        }
    }

    // MARK: - Delete Event

    func testDeleteEventHappyPath() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default", title: "Delete Me",
            start: DateCodec.parse("2026-04-01T09:00:00Z"),
            end: DateCodec.parse("2026-04-01T10:00:00Z"),
            timezone: .current, allDay: false
        ))

        let json = try MCPToolHandler.deleteEvent(
            id: created.id, occurrenceStart: nil, scope: "all",
            expectedRevision: nil, store: store
        )
        let payload = try JSONDecoder().decode([String: String].self, from: Data(json.utf8))
        XCTAssertEqual(payload["status"], "deleted")

        XCTAssertThrowsError(try store.getEvent(id: created.id, externalID: nil))
    }

    func testDeleteEventNotFound() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.deleteEvent(
            id: "nonexistent", occurrenceStart: nil, scope: "all",
            expectedRevision: nil, store: store
        )) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .notFound)
        }
    }

    func testDeleteEventInvalidScope() {
        let store = InMemoryCalendarStore()
        XCTAssertThrowsError(try MCPToolHandler.deleteEvent(
            id: "any", occurrenceStart: nil, scope: "invalid",
            expectedRevision: nil, store: store
        )) { error in
            guard let acalError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(acalError.code, .validationFailed)
        }
    }

    // MARK: - Full CRUD Flow

    func testFullCRUDFlowViaMCPHandlers() throws {
        let store = InMemoryCalendarStore()

        // Create
        let createJSON = try MCPToolHandler.createEvent(
            calendar: "cal-work", title: "MCP Event",
            start: "2026-04-01T14:00:00Z", end: "2026-04-01T15:00:00Z",
            timezone: nil, allDay: nil, location: "Room A", notes: nil, url: nil,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            alarmMinutes: [-10],
            store: store
        )
        let created = try JSONDecoder().decode(EventRecord.self, from: Data(createJSON.utf8))
        XCTAssertEqual(created.title, "MCP Event")

        // Get
        let getJSON = try MCPToolHandler.getEvent(id: created.id, externalId: nil, store: store)
        let fetched = try JSONDecoder().decode(EventRecord.self, from: Data(getJSON.utf8))
        XCTAssertEqual(fetched.title, "MCP Event")
        XCTAssertEqual(fetched.location, "Room A")

        // Update
        let updateJSON = try MCPToolHandler.updateEvent(
            id: created.id, title: "MCP Event (Updated)", start: nil, end: nil,
            timezone: nil, allDay: nil, location: "Room B", notes: nil, url: nil,
            occurrenceStart: nil, scope: "all", expectedRevision: created.revision,
            repeatFrequency: nil, interval: nil, byday: nil, until: nil, count: nil, rrule: nil,
            clearRecurrence: false, alarmMinutes: [],
            store: store
        )
        let updated = try JSONDecoder().decode(EventRecord.self, from: Data(updateJSON.utf8))
        XCTAssertEqual(updated.title, "MCP Event (Updated)")
        XCTAssertEqual(updated.location, "Room B")

        // Delete
        let deleteJSON = try MCPToolHandler.deleteEvent(
            id: created.id, occurrenceStart: nil, scope: "all",
            expectedRevision: nil, store: store
        )
        let deletePayload = try JSONDecoder().decode([String: String].self, from: Data(deleteJSON.utf8))
        XCTAssertEqual(deletePayload["status"], "deleted")

        // Verify deleted
        XCTAssertThrowsError(try store.getEvent(id: created.id, externalID: nil))
    }

    // MARK: - JSON Output Format

    func testOutputIsRawJSONNotEnvelope() throws {
        let store = InMemoryCalendarStore()
        let json = try MCPToolHandler.listCalendars(store: store)
        // Should be a raw array, NOT wrapped in {ok: true, data: [...]}
        XCTAssertTrue(json.hasPrefix("["))
        XCTAssertFalse(json.contains("\"ok\""))
        XCTAssertFalse(json.contains("\"meta\""))
    }

    // MARK: - Tool Definitions

    func testAllToolDefinitionsHaveDescriptions() {
        for tool in MCPToolDefinitions.all {
            XCTAssertFalse(tool.name.isEmpty, "Tool name should not be empty")
            XCTAssertNotNil(tool.description, "Tool \(tool.name) should have a description")
            XCTAssertFalse(tool.description?.isEmpty ?? true, "Tool \(tool.name) description should not be empty")
        }
    }

    func testToolCount() {
        XCTAssertEqual(MCPToolDefinitions.all.count, 10)
    }
}
