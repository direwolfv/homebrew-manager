import AppKit
import SwiftUI

/// Homebrew's download cache plus what `brew cleanup` would remove (old versions, stale downloads).
struct CacheView: View {
    @State private var path = ""
    @State private var size: Int64?
    @State private var removable: [String] = []
    @State private var summary = ""
    @State private var busy: String?
    @State private var error: String?
    @State private var confirmEmpty = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Location").foregroundStyle(.secondary)
                    HStack {
                        Text(path).textSelection(.enabled).lineLimit(1).truncationMode(.middle)
                        Button("Show in Finder", systemImage: "folder") {
                            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                        }
                        .labelStyle(.iconOnly).buttonStyle(.borderless).disabled(path.isEmpty)
                    }
                }
                GridRow {
                    Text("Size").foregroundStyle(.secondary)
                    Text(size.map { $0.formatted(.byteCount(style: .file)) } ?? "…").monospacedDigit()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Clean Up would remove · \(removable.count)")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                if removable.isEmpty {
                    Text(busy == nil ? "Nothing to clean up." : "…").foregroundStyle(.secondary)
                } else {
                    List(removable, id: \.self) { Text($0).font(.caption.monospaced()).textSelection(.enabled) }
                        .listStyle(.bordered)
                }
                if !summary.isEmpty { Text(summary).font(.callout) }
            }

            if let error { Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }

            HStack {
                if let busy { ProgressView().controlSize(.small); Text(busy).foregroundStyle(.secondary) }
                Spacer()
                Button("Empty Cache…", role: .destructive) { confirmEmpty = true }
                    .help("brew cleanup -s --prune=all: scrub the cache, including downloads for the latest versions")
                Button("Clean Up") { Task { await run("Cleaning up…", ["cleanup"]) } }
                    .help("brew cleanup: remove old versions and stale downloads")
                    .buttonStyle(.borderedProminent)
                    .disabled(removable.isEmpty)
            }
            .disabled(busy != nil)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .confirmationDialog("Empty the Homebrew cache?", isPresented: $confirmEmpty) {
            Button("Empty Cache", role: .destructive) { Task { await run("Emptying cache…", ["cleanup", "-s", "--prune=all"]) } }
        } message: {
            Text("Removes every cached download, including for the latest versions. Downloads for installed packages are kept.")
        }
        .task { await load() }
    }

    private func load() async {
        busy = "Checking…"
        defer { busy = nil }
        do {
            path = try await brew(["--cache"]).trimmingCharacters(in: .whitespacesAndNewlines)
            async let bytes = Task.detached { [path] in diskUsage(path) }.value
            let lines = try await brew(["cleanup", "-n"]).split(separator: "\n").map(String.init)
            removable = lines.compactMap { $0.hasPrefix("Would remove: ") ? String($0.dropFirst(14)) : nil }
            summary = lines.first { $0.contains("would free") }?.replacingOccurrences(of: "==> ", with: "") ?? ""
            size = await bytes
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func run(_ label: String, _ args: [String]) async {
        busy = label
        error = nil
        do { _ = try await brew(args) } catch { self.error = error.localizedDescription }
        busy = nil
        await load()
    }
}

/// Bytes on disk under `path`, like `du -s`.
func diskUsage(_ path: String) -> Int64 {
    let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey]
    guard let e = FileManager.default.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: keys)
    else { return 0 }
    var total: Int64 = 0
    for case let url as URL in e {
        total += Int64((try? url.resourceValues(forKeys: Set(keys)))?.totalFileAllocatedSize ?? 0)
    }
    return total
}
