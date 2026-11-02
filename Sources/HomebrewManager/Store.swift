import Foundation
import Observation

private struct Info: Decodable {
    struct Formula: Decodable {
        struct Inst: Decodable {
            let version: String, time: Double?, installed_on_request: Bool?
        }
        struct Versions: Decodable { let stable: String? }
        let name: String, desc: String?, installed: [Inst], versions: Versions
        let homepage: String?, license: String?, tap: String?, caveats: String?, dependencies: [String]?
    }
    struct Cask: Decodable {
        let token: String, desc: String?, installed: String?, version: String
        let name: [String]?, homepage: String?, tap: String?, caveats: String?
        let installed_time: Double?, auto_updates: Bool?
    }
    let formulae: [Formula], casks: [Cask]
}

private struct Outdated: Decodable {
    struct Item: Decodable { let name: String }
    let formulae: [Item], casks: [Item]
}

@MainActor @Observable
final class Store {
    var pkgs: [Pkg] = []
    var busy: String?
    var error: String?

    func refresh() async {
        await run("Loading packages…") {
            async let infoJSON = brew(["info", "--json=v2", "--installed"])
            async let outJSON = brew(["outdated", "--json=v2"])
            let info = try JSONDecoder().decode(Info.self, from: Data(try await infoJSON.utf8))
            let out = try JSONDecoder().decode(Outdated.self, from: Data(try await outJSON.utf8))
            let old = Set(out.formulae.map(\.name) + out.casks.map(\.name))
            var usedBy: [String: [String]] = [:]
            for f in info.formulae { for d in f.dependencies ?? [] { usedBy[d, default: []].append(f.name) } }
            let f = info.formulae.map { f in
                let inst = f.installed.last
                return Pkg(name: f.name, installed: inst?.version ?? "?", latest: f.versions.stable ?? "",
                           isCask: false, desc: f.desc ?? "", outdated: old.contains(f.name),
                           homepage: f.homepage, license: f.license, tap: f.tap, caveats: f.caveats,
                           deps: f.dependencies ?? [], usedBy: usedBy[f.name] ?? [],
                           installedAt: inst?.time.map { Date(timeIntervalSince1970: $0) },
                           onRequest: inst?.installed_on_request)
            }
            let c = info.casks.map { c in
                Pkg(name: c.token, installed: c.installed ?? "?", latest: c.version,
                    isCask: true, desc: c.desc ?? "", outdated: old.contains(c.token),
                    displayName: c.name?.first, homepage: c.homepage, tap: c.tap, caveats: c.caveats,
                    installedAt: c.installed_time.map { Date(timeIntervalSince1970: $0) },
                    autoUpdates: c.auto_updates)
            }
            self.pkgs = (f + c).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    func act(_ verb: String, _ p: Pkg?) async {
        var args = [verb]
        if let p { args += (p.isCask ? ["--cask"] : []) + [p.name] }
        let ok = await run("brew \(args.joined(separator: " "))…") { _ = try await brew(args) }
        if ok || p == nil { await refresh() }
    }

    @discardableResult
    private func run(_ label: String, _ body: () async throws -> Void) async -> Bool {
        busy = label
        defer { busy = nil }
        do { try await body(); return true } catch { self.error = error.localizedDescription; return false }
    }
}
