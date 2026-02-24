import ArgumentParser

@main
struct AppleCal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applecal",
        abstract: "A CLI for working with Apple Calendar.",
        discussion: """
        Start with one of the top-level command groups:
          - doctor
          - auth
          - calendars
          - events
          - completion
          - schema

        Use `applecal <command> --help` for details and examples.
        """,
        subcommands: [
            DoctorCommand.self,
            AuthCommand.self,
            CalendarsCommand.self,
            EventsCommand.self,
            CompletionCommand.self,
            SchemaCommand.self,
        ]
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal")
    }
}

private enum Placeholder {
    static func printNotImplemented(_ commandPath: String) {
        Swift.print("\(commandPath): not implemented yet (command skeleton only).")
    }
}

struct DoctorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Run environment and permission diagnostics.",
        discussion: """
        Examples:
          applecal doctor
          applecal doctor --help
        """
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal doctor")
    }
}

struct AuthCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Inspect and manage Calendar authorization.",
        subcommands: [
            AuthStatusCommand.self,
            AuthGrantCommand.self,
            AuthResetCommand.self,
        ]
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal auth")
    }
}

struct AuthStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show current Calendar authorization status."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal auth status")
    }
}

struct AuthGrantCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "grant",
        abstract: "Request Calendar access permission."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal auth grant")
    }
}

struct AuthResetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Reset cached authorization state and guidance."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal auth reset")
    }
}

struct CalendarsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "Inspect available calendars.",
        subcommands: [
            CalendarsListCommand.self,
            CalendarsGetCommand.self,
        ]
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal calendars")
    }
}

struct CalendarsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List calendars available to the current user."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal calendars list")
    }
}

struct CalendarsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one calendar by id or exact name."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal calendars get")
    }
}

struct EventsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "events",
        abstract: "Read and mutate calendar events.",
        subcommands: [
            EventsListCommand.self,
            EventsGetCommand.self,
            EventsSearchCommand.self,
            EventsCreateCommand.self,
            EventsUpdateCommand.self,
            EventsDeleteCommand.self,
        ]
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events")
    }
}

struct EventsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List events in a date range."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events list")
    }
}

struct EventsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one event by identifier."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events get")
    }
}

struct EventsSearchCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search events by text and optional filters."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events search")
    }
}

struct EventsCreateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new event."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events create")
    }
}

struct EventsUpdateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update an existing event."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events update")
    }
}

struct EventsDeleteCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete an event or recurring occurrence scope."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal events delete")
    }
}

struct CompletionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completion",
        abstract: "Generate shell completion scripts.",
        subcommands: [
            CompletionBashCommand.self,
            CompletionZshCommand.self,
            CompletionFishCommand.self,
        ]
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal completion")
    }
}

struct CompletionBashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bash",
        abstract: "Generate completion script for Bash."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal completion bash")
    }
}

struct CompletionZshCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "zsh",
        abstract: "Generate completion script for Zsh."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal completion zsh")
    }
}

struct CompletionFishCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fish",
        abstract: "Generate completion script for Fish."
    )

    mutating func run() throws {
        Placeholder.printNotImplemented("applecal completion fish")
    }
}

struct SchemaCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schema",
        abstract: "Print CLI schema and command contract metadata."
    )

    mutating func run() throws {
        Swift.print("""
        {
          "schemaVersion": "0.1.0",
          "status": "placeholder",
          "commands": [
            "doctor",
            "auth status|grant|reset",
            "calendars list|get",
            "events list|get|search|create|update|delete",
            "completion bash|zsh|fish",
            "schema"
          ]
        }
        """)
    }
}
