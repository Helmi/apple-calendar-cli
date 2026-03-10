@testable import App
@testable import AppCore
import Darwin
@testable import Diagnostics
@testable import EventKitAdapter
@testable import Formatting
import XCTest

final class ACalTests: XCTestCase {
    func testMachineCodeMapsToExpectedExitCode() {
        XCTAssertEqual(ACalMachineErrorCode.invalidArguments.mappedExitCode, .invalidUsage)
        XCTAssertEqual(ACalMachineErrorCode.permissionDenied.mappedExitCode, .permissionDenied)
        XCTAssertEqual(ACalMachineErrorCode.notFound.mappedExitCode, .notFound)
        XCTAssertEqual(ACalMachineErrorCode.validationFailed.mappedExitCode, .conflictOrValidationFailure)
        XCTAssertEqual(ACalMachineErrorCode.eventKitFailure.mappedExitCode, .eventKitFailure)
    }

    func testEnvelopeIncludesSchemaVersion() throws {
        let payload = ["result": "ok"]
        let envelope = ACalEnvelope.success(payload, command: "test")
        let json = try OutputPrinter.renderJSON(envelope, pretty: false)
        XCTAssertTrue(json.contains("\"schemaVersion\":\"1.0.0\""))
        XCTAssertTrue(json.contains("\"ok\":true"))
    }

    func testRecurrenceParserFromFlags() throws {
        let recurrence = try RecurrenceParser.parse(flags: RecurrenceFlags(
            frequency: .weekly,
            interval: 2,
            byDay: "mon,wed,fri",
            until: "2026-12-31",
            count: nil,
            rrule: nil
        ))

        XCTAssertEqual(recurrence?.frequency, .weekly)
        XCTAssertEqual(recurrence?.interval, 2)
        XCTAssertEqual(recurrence?.byDay, [.mon, .wed, .fri])
        XCTAssertEqual(recurrence?.until, "2026-12-31")
    }

    func testAdvancedRRuleParser() throws {
        let recurrence = try RecurrenceParser
            .parse(flags: RecurrenceFlags(rrule: "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,FR;COUNT=3"))
        XCTAssertEqual(recurrence?.frequency, .weekly)
        XCTAssertEqual(recurrence?.byDay, [.mon, .fri])
        XCTAssertEqual(recurrence?.count, 3)
        XCTAssertEqual(recurrence?.rrule, "FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,FR;COUNT=3")
    }

    func testDateRangeChunkerRespectsFourYearWindow() throws {
        let start = try DateCodec.parse("2020-01-01")
        let end = try DateCodec.parse("2030-01-01")
        let chunks = try DateRangeChunker.chunkedRanges(from: start, to: end)

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks.first?.0, start)
        XCTAssertEqual(chunks.last?.1, end)
    }

    func testCRUDFlowWithRecurrenceAndAlarms() throws {
        let store = InMemoryCalendarStore()
        let start = try DateCodec.parse("2026-03-02T09:00:00+01:00")
        let end = try DateCodec.parse("2026-03-02T09:30:00+01:00")

        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-work",
            title: "Standup",
            start: start,
            end: end,
            timezone: XCTUnwrap(TimeZone(identifier: "Europe/Berlin")),
            allDay: false,
            location: "Zoom",
            notes: "Daily sync",
            recurrence: RecurrenceRuleRecord(frequency: .weekly, interval: 1, byDay: [.mon, .tue, .wed, .thu, .fri]),
            alarms: [AlarmRecord(relativeMinutes: -10)]
        ))

        XCTAssertEqual(created.title, "Standup")
        XCTAssertEqual(created.alarms.first?.relativeMinutes, -10)
        XCTAssertEqual(created.recurrence?.frequency, .weekly)

        let updated = try store.updateEvent(
            id: created.id,
            occurrenceStart: DateCodec.parse("2026-03-09T09:00:00+01:00"),
            scope: .this,
            input: EventUpdateInput(
                title: "Standup (moved)",
                start: DateCodec.parse("2026-03-09T10:00:00+01:00"),
                end: DateCodec.parse("2026-03-09T10:30:00+01:00"),
                expectedRevision: created.revision
            )
        )

        XCTAssertEqual(updated.title, "Standup (moved)")
        XCTAssertEqual(updated.revision, created.revision + 1)
        XCTAssertNotNil(updated.occurrenceStart)

        let deletePayload = try store.deleteEvent(id: created.id, input: EventDeleteInput(
            occurrenceStart: DateCodec.parse("2026-03-09T10:00:00+01:00"),
            scope: .future,
            expectedRevision: updated.revision
        ))

        XCTAssertEqual(deletePayload["status"], "deleted")
        XCTAssertThrowsError(try store.getEvent(id: created.id, externalID: nil))
    }

    func testOptimisticConcurrencyGuardrails() throws {
        let store = InMemoryCalendarStore()
        let created = try store.createEvent(input: EventCreateInput(
            calendarId: "cal-default",
            title: "Conflict check",
            start: DateCodec.parse("2026-02-24T10:00:00+01:00"),
            end: DateCodec.parse("2026-02-24T11:00:00+01:00"),
            timezone: .current,
            allDay: false
        ))

        XCTAssertThrowsError(try store.updateEvent(
            id: created.id,
            occurrenceStart: nil,
            scope: .all,
            input: EventUpdateInput(title: "New", expectedRevision: created.revision + 10)
        )) { error in
            guard let appleError = error as? ACalError else {
                return XCTFail("Expected ACalError")
            }
            XCTAssertEqual(appleError.code, .conflict)
        }
    }

    func testPermissionScenariosViaEnvironmentOverrides() {
        withEnv("ACAL_AUTH_STATE", value: "not_determined") {
            XCTAssertEqual(EventKitAdapter.currentAuthorizationState(), .notDetermined)
        }

        withEnv("ACAL_AUTH_STATE", value: "denied") {
            XCTAssertEqual(EventKitAdapter.currentAuthorizationState(), .denied)
        }

        withEnv("ACAL_AUTH_STATE", value: "full_access") {
            XCTAssertEqual(EventKitAdapter.currentAuthorizationState(), .fullAccess)
        }
    }

    func testGrantFlowCanBeSimulatedForIntegrationTests() throws {
        try withThrowingEnv("ACAL_AUTH_GRANT_RESULT", value: "denied") {
            XCTAssertEqual(try EventKitAdapter.requestFullAccess(), .denied)
        }

        try withThrowingEnv("ACAL_AUTH_GRANT_RESULT", value: "full_access") {
            XCTAssertEqual(try EventKitAdapter.requestFullAccess(), .fullAccess)
        }
    }

    func testHelpSnapshotContainsCommandTree() {
        let help = ACal.helpMessage()
        let normalized = help
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let expectedFragments = [
            "OVERVIEW: A CLI for working with macOS Calendar.",
            "USAGE: acal <subcommand>",
            "SUBCOMMANDS:",
            "doctor",
            "auth",
            "calendars",
            "events",
            "completion",
            "schema"
        ]

        for fragment in expectedFragments {
            XCTAssertTrue(normalized.contains(where: { $0.contains(fragment) }), "Missing help fragment: \(fragment)")
        }
    }

    func testDoctorReportContainsAuthState() {
        withEnv("ACAL_AUTH_STATE", value: "restricted") {
            let report = DoctorReport()
            XCTAssertEqual(report.authorization, .restricted)
            XCTAssertTrue(report.eventKitAvailable)
        }
    }

    private func withEnv(_ key: String, value: String, body: () -> Void) {
        let previous = getenv(key).map { String(cString: $0) }
        setenv(key, value, 1)
        body()
        if let previous {
            setenv(key, previous, 1)
        } else {
            unsetenv(key)
        }
    }

    private func withThrowingEnv(_ key: String, value: String, body: () throws -> Void) throws {
        let previous = getenv(key).map { String(cString: $0) }
        setenv(key, value, 1)
        defer {
            if let previous {
                setenv(key, previous, 1)
            } else {
                unsetenv(key)
            }
        }
        try body()
    }
}
