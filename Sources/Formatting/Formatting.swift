import AppCore
import Foundation

public enum OutputPrinter {
    public static func renderJSON<T: Codable>(_ value: T, pretty: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw AppleCalError(code: .internalError, message: "Failed to encode JSON output.")
        }
        return string
    }

    public static func renderTable(headers: [String], rows: [[String]]) -> String {
        guard !headers.isEmpty else { return "" }
        var widths = headers.map { $0.count }

        for row in rows {
            for (index, value) in row.enumerated() where index < widths.count {
                widths[index] = max(widths[index], value.count)
            }
        }

        func renderRow(_ values: [String]) -> String {
            values.enumerated().map { index, value in
                let width = widths[index]
                let padding = String(repeating: " ", count: max(0, width - value.count))
                return value + padding
            }.joined(separator: "  ")
        }

        let separator = widths.map { String(repeating: "-", count: $0) }.joined(separator: "  ")
        var lines = [renderRow(headers), separator]
        lines.append(contentsOf: rows.map(renderRow))
        return lines.joined(separator: "\n")
    }
}
