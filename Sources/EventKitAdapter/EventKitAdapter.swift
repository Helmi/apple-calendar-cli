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
        var granted = false
        var requestError: Error?
        let semaphore = DispatchSemaphore(value: 0)

        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { allowed, error in
                granted = allowed
                requestError = error
                semaphore.signal()
            }
        } else {
            store.requestAccess(to: .event) { allowed, error in
                granted = allowed
                requestError = error
                semaphore.signal()
            }
        }

        semaphore.wait()

        if let requestError {
            throw AppleCalError(
                code: .eventKitFailure,
                message: AppleCalUserMessage("EventKit authorization request failed."),
                details: ["cause": String(describing: requestError)]
            )
        }

        return granted ? .fullAccess : .denied
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
