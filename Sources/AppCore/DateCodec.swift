import Foundation

public enum DateCodec {
    // Cached formatters — safe for single-threaded CLI use.
    // nonisolated(unsafe) suppresses Swift 6 concurrency warnings for static lets.
    nonisolated(unsafe) private static let fractionalFormatter = makeISO8601Formatter(fractionalSeconds: true)
    nonisolated(unsafe) private static let standardFormatter = makeISO8601Formatter(fractionalSeconds: false)
    private static let dateOnlyFormatter = makeDateOnlyFormatter()

    private static func makeISO8601Formatter(fractionalSeconds: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractionalSeconds
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        return formatter
    }

    private static func makeDateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    public static func parse(_ value: String, defaultTimeZone: TimeZone = .current) throws -> Date {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ACalError.validation("Date/time cannot be empty.")
        }

        if let parsed = fractionalFormatter.date(from: trimmed) ?? standardFormatter.date(from: trimmed) {
            return parsed
        }

        if let day = dateOnlyFormatter.date(from: trimmed) {
            let calendar = Calendar(identifier: .gregorian)
            let components = calendar.dateComponents(in: defaultTimeZone, from: day)
            guard let converted = calendar.date(from: DateComponents(
                timeZone: defaultTimeZone,
                year: components.year,
                month: components.month,
                day: components.day,
                hour: 0,
                minute: 0,
                second: 0
            )) else {
                throw ACalError.validation("Could not convert date '\(value)' to the configured timezone.")
            }
            return converted
        }

        throw ACalError.validation(
            "Unsupported date format '\(value)'. Use ISO-8601 date-time or YYYY-MM-DD."
        )
    }

    public static func iso8601String(from date: Date) -> String {
        standardFormatter.string(from: date)
    }
}
