import AppCore
import ArgumentParser
import Diagnostics

struct DoctorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Run environment and permission diagnostics."
    )

    @OptionGroup var output: GlobalOutputOptions

    mutating func run() throws {
        let report = DoctorReport()
        try CLI.printSuccess(command: "doctor", data: report, options: output) {
            CLI.keyValueTable([
                ("binaryVersion", report.binaryVersion),
                ("macOSVersion", report.macOSVersion),
                ("eventKitAvailable", String(report.eventKitAvailable)),
                ("authorization", report.authorization.rawValue)
            ])
        }
    }
}
