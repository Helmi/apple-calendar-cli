import AppCore
import ArgumentParser
import Formatting

struct CalendarsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "calendars",
        abstract: "Inspect available calendars.",
        subcommands: [
            CalendarsListCommand.self,
            CalendarsGetCommand.self
        ]
    )

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

struct CalendarsListCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List calendars available to the current user."
    )

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let calendars = try CLI.store.listCalendars()
        try CLI.printSuccess(command: "calendars list", data: calendars, options: output) {
            OutputPrinter.renderTable(
                headers: ["id", "title", "source", "color", "writable"],
                rows: calendars.map {
                    [$0.id, $0.title, $0.source, $0.colorHex, String($0.writable)]
                }
            )
        }
    }
}

struct CalendarsGetCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get one calendar by id or exact name."
    )

    @Option(name: .long, help: "Calendar identifier.")
    var id: String?

    @Option(name: .long, help: "Calendar exact title.")
    var name: String?

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        guard id != nil || name != nil else {
            throw ACalError.validation("Provide --id or --name.")
        }

        let calendar = try CLI.store.getCalendar(id: id, name: name)
        try CLI.printSuccess(command: "calendars get", data: calendar, options: output) {
            CLI.keyValueTable([
                ("id", calendar.id),
                ("title", calendar.title),
                ("source", calendar.source),
                ("color", calendar.colorHex),
                ("writable", String(calendar.writable))
            ])
        }
    }
}
