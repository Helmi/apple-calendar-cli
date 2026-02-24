import ArgumentParser

@main
struct AppleCal: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applecal",
        abstract: "A CLI for working with Apple Calendar."
    )

    mutating func run() throws {}
}
