import ArgumentParser

struct CompletionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completion",
        abstract: "Generate shell completion scripts.",
        subcommands: [
            CompletionBashCommand.self,
            CompletionZshCommand.self,
            CompletionFishCommand.self
        ]
    )

    mutating func run() throws {
        throw CleanExit.helpRequest(self)
    }
}

struct CompletionBashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "bash",
        abstract: "Generate completion script for Bash."
    )

    mutating func run() throws {
        Swift.print(ACal.completionScript(for: .bash))
    }
}

struct CompletionZshCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "zsh", abstract: "Generate completion script for Zsh.")

    mutating func run() throws {
        Swift.print(ACal.completionScript(for: .zsh))
    }
}

struct CompletionFishCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fish",
        abstract: "Generate completion script for Fish."
    )

    mutating func run() throws {
        Swift.print(ACal.completionScript(for: .fish))
    }
}
