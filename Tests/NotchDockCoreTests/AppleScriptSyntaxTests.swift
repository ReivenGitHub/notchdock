import Foundation
import XCTest
@testable import NotchDockCore

final class AppleScriptSyntaxTests: XCTestCase {
    func testMusicMetadataAndArtworkScriptsCompileWithoutExecution() throws {
        #if os(macOS)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("NotchDock-Script-Test-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: folder) }
        for (index, source) in [MediaScripts.metadata(spotify: false), MediaScripts.musicArtwork].enumerated() {
            let script = folder.appendingPathComponent("script-\(index).applescript")
            try source.write(to: script, atomically: true, encoding: .utf8)
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osacompile")
            process.arguments = ["-o", folder.appendingPathComponent("compiled-\(index).scpt").path, script.path]
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            let output = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            XCTAssertEqual(process.terminationStatus, 0, String(data: output, encoding: .utf8) ?? "Script compile failed")
        }
        #else
        throw XCTSkip("Music's scripting dictionary requires macOS; this check never executes the scripts.")
        #endif
    }
}
