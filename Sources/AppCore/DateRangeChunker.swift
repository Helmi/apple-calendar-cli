import Foundation

public enum DateRangeChunker {
    private static let fourYearsInSeconds: TimeInterval = 60 * 60 * 24 * 365 * 4

    public static func chunkedRanges(from start: Date, to end: Date) throws -> [(Date, Date)] {
        guard start < end else {
            throw ACalError.validation("--from must be earlier than --to.")
        }

        var ranges: [(Date, Date)] = []
        var cursor = start
        while cursor < end {
            let next = min(cursor.addingTimeInterval(fourYearsInSeconds), end)
            ranges.append((cursor, next))
            cursor = next
        }
        return ranges
    }
}
