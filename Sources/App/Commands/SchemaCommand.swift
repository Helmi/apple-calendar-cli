import AppCore
import ArgumentParser
import Formatting

struct SchemaCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schema",
        abstract: "Print CLI schema and command contract metadata."
    )

    struct CommandSpec: Codable, Sendable {
        let name: String
        let summary: String
    }

    struct SchemaPayload: Codable, Sendable {
        let schemaVersion: String
        let commands: [CommandSpec]
    }

    mutating func run() throws {
        let payload = SchemaPayload(
            schemaVersion: ACalSchema.version,
            commands: [
                CommandSpec(name: "doctor", summary: "Run diagnostics"),
                CommandSpec(name: "auth status", summary: "Show authorization status"),
                CommandSpec(name: "auth grant", summary: "Request full calendar access"),
                CommandSpec(name: "auth reset", summary: "Show TCC reset guidance"),
                CommandSpec(name: "calendars list", summary: "List calendars"),
                CommandSpec(name: "calendars get", summary: "Get one calendar"),
                CommandSpec(name: "events list", summary: "List events in range"),
                CommandSpec(name: "events get", summary: "Get event by id"),
                CommandSpec(name: "events search", summary: "Search events"),
                CommandSpec(name: "events create", summary: "Create event"),
                CommandSpec(name: "events update", summary: "Update event"),
                CommandSpec(name: "events delete", summary: "Delete event"),
                CommandSpec(name: "completion bash|zsh|fish", summary: "Generate shell completion"),
                CommandSpec(name: "schema", summary: "Print schema contract")
            ]
        )

        let envelope = ACalEnvelope<SchemaPayload>.success(payload, command: "schema")
        try Swift.print(OutputPrinter.renderJSON(envelope, pretty: true))
    }
}
