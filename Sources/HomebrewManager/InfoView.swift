import SwiftUI

struct InfoView: View {
    let p: Pkg?

    var body: some View {
        if let p {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        PkgIcon(p: p, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.displayName ?? p.name).font(.title3.weight(.semibold))
                            Text([p.kind, p.tap].compactMap { $0 }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if !p.desc.isEmpty { Text(p.desc) }
                    if let home = p.homepage, let url = URL(string: home) {
                        Link(destination: url) { Label(url.host() ?? home, systemImage: "safari") }
                    }
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                        row("Installed", p.installed)
                        row("Latest", p.latest, highlight: p.outdated)
                        if let d = p.installedAt { row("Installed on", d.formatted(date: .abbreviated, time: .omitted)) }
                        if let r = p.onRequest { row("Installed as", r ? "Requested" : "Dependency") }
                        if let a = p.autoUpdates { row("Auto-updates", a ? "Yes" : "No") }
                        if let l = p.license { row("License", l) }
                    }
                    .font(.callout)
                    list("Dependencies", p.deps)
                    list("Used by", p.usedBy)
                    if let c = p.caveats, !c.isEmpty {
                        section("Caveats") {
                            Text(c.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.caption.monospaced()).textSelection(.enabled)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ContentUnavailableView("No Selection", systemImage: "info.circle",
                                   description: Text("Select a package to see its details."))
        }
    }

    private func row(_ k: String, _ v: String, highlight: Bool = false) -> some View {
        GridRow {
            Text(k).foregroundStyle(.secondary)
            Text(v).foregroundStyle(highlight ? .orange : .primary).fontWeight(highlight ? .semibold : .regular)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder private func list(_ title: String, _ items: [String]) -> some View {
        if !items.isEmpty {
            section("\(title) · \(items.count)") { Text(items.joined(separator: ", ")).font(.callout) }
        }
    }

    private func section(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }
}
