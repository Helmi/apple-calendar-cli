import Foundation
import XCTest

final class SkillSmokeTests: XCTestCase {
    func testSkillPackagesContainJSONFirstExamples() throws {
        let files = [
            "skills/openclaw/apple-calendar-cli/SKILL.md",
            "skills/claude-code/apple-calendar-cli/SKILL.md",
            "skills/codex/apple-calendar-cli/SKILL.md",
        ]

        for path in files {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            XCTAssertTrue(content.contains("applecal"), "Missing applecal reference in \(path)")
            XCTAssertTrue(content.contains("--format json") || content.contains("JSON"), "Missing JSON guidance in \(path)")
        }
    }

    func testDemoScriptReferencesCoreLifecycleCommands() throws {
        let content = try String(contentsOfFile: "docs/scripts/demo.sh", encoding: .utf8)
        XCTAssertTrue(content.contains("events create"))
        XCTAssertTrue(content.contains("calendars list"))
        XCTAssertTrue(content.contains("auth status"))
    }
}
