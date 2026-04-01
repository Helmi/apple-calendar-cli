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

    struct MCPToolSpec: Codable, Sendable {
        let name: String
        let summary: String
    }

    struct SchemaPayload: Codable, Sendable {
        let schemaVersion: String
        let commands: [CommandSpec]
        let mcpTools: [MCPToolSpec]
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
                CommandSpec(name: "mcp", summary: "Start MCP server on stdio"),
                CommandSpec(name: "completion bash|zsh|fish", summary: "Generate shell completion"),
                CommandSpec(name: "schema", summary: "Print schema contract")
            ],
            mcpTools: [
                MCPToolSpec(name: "auth_status", summary: "Check calendar access authorization"),
                MCPToolSpec(name: "auth_grant", summary: "Request calendar access permission"),
                MCPToolSpec(name: "list_calendars", summary: "List all calendars"),
                MCPToolSpec(name: "get_calendar", summary: "Get calendar by id or name"),
                MCPToolSpec(name: "list_events", summary: "List events in date range"),
                MCPToolSpec(name: "get_event", summary: "Get event by id"),
                MCPToolSpec(name: "search_events", summary: "Search events by text"),
                MCPToolSpec(name: "create_event", summary: "Create a new event"),
                MCPToolSpec(name: "update_event", summary: "Update an existing event"),
                MCPToolSpec(name: "delete_event", summary: "Delete an event")
            ]
        )

        let envelope = ACalEnvelope<SchemaPayload>.success(payload, command: "schema")
        try Swift.print(OutputPrinter.renderJSON(envelope, pretty: true))
    }
}
