import Foundation

public struct RecurrenceFlags: Sendable {
    public var frequency: RecurrenceFrequency?
    public var interval: Int?
    public var byDay: String?
    public var until: String?
    public var count: Int?
    public var rrule: String?

    public init(
        frequency: RecurrenceFrequency? = nil,
        interval: Int? = nil,
        byDay: String? = nil,
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

public enum RecurrenceParser {
    public static func parse(flags: RecurrenceFlags) throws -> RecurrenceRuleRecord? {
        if let rrule = flags.rrule, !rrule.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try parseRRule(rrule)
        }

        guard let frequency = flags.frequency else {
            if flags.interval != nil || flags.byDay != nil || flags.until != nil || flags.count != nil {
                throw AppleCalError.validation("--repeat is required when recurrence flags are used.")
            }
            return nil
        }

        let interval = flags.interval ?? 1
        guard interval > 0 else {
            throw AppleCalError.validation("--interval must be greater than 0.")
        }

        if let count = flags.count, count <= 0 {
            throw AppleCalError.validation("--count must be greater than 0.")
        }

        let byDay = try parseByDay(flags.byDay)

        if flags.until != nil, flags.count != nil {
            throw AppleCalError.validation("Use only one of --until or --count.")
        }

        return RecurrenceRuleRecord(
            frequency: frequency,
            interval: interval,
            byDay: byDay,
            until: flags.until,
            count: flags.count,
            rrule: nil
        )
    }

    public static func parseByDay(_ value: String?) throws -> [Weekday] {
        guard let value else { return [] }
        let values = value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        guard !values.isEmpty else { return [] }

        var unique = Set<Weekday>()
        var ordered: [Weekday] = []
        for item in values {
            guard let weekday = Weekday(rawValue: item) else {
                throw AppleCalError.validation("Invalid weekday '\(item)' in --byday.")
            }
            if unique.insert(weekday).inserted {
                ordered.append(weekday)
            }
        }
        return ordered
    }

    public static func parseRRule(_ value: String) throws -> RecurrenceRuleRecord {
        let normalized = value.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw AppleCalError.validation("RRULE cannot be empty.")
        }

        var frequency: RecurrenceFrequency?
        var interval = 1
        var byDay: [Weekday] = []
        var until: String?
        var count: Int?

        for pair in normalized.split(separator: ";") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let key = parts[0]
            let val = parts[1]

            switch key {
            case "FREQ":
                frequency = RecurrenceFrequency(rawValue: val.lowercased())
            case "INTERVAL":
                if let parsed = Int(val), parsed > 0 {
                    interval = parsed
                } else {
                    throw AppleCalError.validation("Invalid RRULE INTERVAL value '\(val)'.")
                }
            case "BYDAY":
                let map: [String: Weekday] = [
                    "MO": .mon,
                    "TU": .tue,
                    "WE": .wed,
                    "TH": .thu,
                    "FR": .fri,
                    "SA": .sat,
                    "SU": .sun
                ]
                byDay = try val.split(separator: ",").map { token in
                    let key = String(token)
                    guard let day = map[key] else {
                        throw AppleCalError.validation("Invalid RRULE BYDAY value '\(key)'.")
                    }
                    return day
                }
            case "UNTIL":
                until = val
            case "COUNT":
                if let parsed = Int(val), parsed > 0 {
                    count = parsed
                } else {
                    throw AppleCalError.validation("Invalid RRULE COUNT value '\(val)'.")
                }
            default:
                continue
            }
        }

        guard let frequency else {
            throw AppleCalError.validation("RRULE must include FREQ.")
        }

        return RecurrenceRuleRecord(
            frequency: frequency,
            interval: interval,
            byDay: byDay,
            until: until,
            count: count,
            rrule: normalized
        )
    }
}
