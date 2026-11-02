import Foundation

struct BrewError: LocalizedError {
    let errorDescription: String?
}

let brewPath = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    .first { FileManager.default.isExecutableFile(atPath: $0) }

func brew(_ args: [String]) async throws -> String {
    guard let brewPath else { throw BrewError(errorDescription: "Homebrew not found.") }
    return try await Task.detached {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: brewPath)
        p.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        env["HOMEBREW_NO_ENV_HINTS"] = "1"
        p.environment = env
        let out = Pipe(), err = Pipe()
        p.standardOutput = out
        p.standardError = err
        try p.run()
        // Read stderr concurrently so a full pipe can't deadlock stdout.
        async let errData = Task.detached { err.fileHandleForReading.readDataToEndOfFile() }.value
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        let errText = String(decoding: await errData, as: UTF8.self)
        p.waitUntilExit()
        guard p.terminationStatus == 0 else {
            throw BrewError(errorDescription: errText.isEmpty ? "brew exited \(p.terminationStatus)" : errText)
        }
        return String(decoding: outData, as: UTF8.self)
    }.value
}
