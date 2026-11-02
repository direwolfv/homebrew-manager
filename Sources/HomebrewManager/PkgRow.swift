import SwiftUI

struct PkgRow: View {
    let p: Pkg
    let upgrade: () -> Void
    let uninstall: () -> Void
    @State private var hover = false

    private func count(_ icon: String, _ n: Int, _ tip: String) -> some View {
        HStack(spacing: 3) { Image(systemName: icon); Text("\(n)") }
            .help(tip)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tip)
    }

    var body: some View {
        HStack(spacing: 14) {
            PkgIcon(p: p, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(p.name).font(.system(size: 14, weight: .semibold))
                    if p.onRequest == false {
                        Text("dependency")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(.quaternary, in: .capsule)
                            .help("Installed as a dependency, not requested directly")
                    }
                }
                Text(p.desc).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 10) {
                if !p.deps.isEmpty {
                    count("shippingbox", p.deps.count, "Depends on: " + p.deps.joined(separator: ", "))
                }
                if !p.usedBy.isEmpty {
                    count("arrow.turn.up.left", p.usedBy.count, "Used by: " + p.usedBy.joined(separator: ", "))
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 70, alignment: .trailing)
            HStack(spacing: 8) {
                Text(p.installed)
                if p.outdated {
                    Image(systemName: "arrow.right").font(.caption2)
                    Text(p.latest).fontWeight(.semibold).foregroundStyle(.orange)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.orange.opacity(0.15), in: .capsule)
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                if p.outdated {
                    Button("Upgrade", action: upgrade).buttonStyle(.bordered).controlSize(.small)
                }
                Button(action: uninstall) { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                    .help("Uninstall")
                    .accessibilityLabel("Uninstall \(p.name)")
                    .opacity(hover ? 1 : 0)
            }
            .frame(width: 110, alignment: .trailing)
        }
        .frame(minHeight: 60)
        .contentShape(.rect)
        .onHover { hover = $0 }
    }
}

struct PkgIcon: View {
    let p: Pkg
    let size: CGFloat

    var body: some View {
        let tint: Color = p.isCask ? .blue : .green
        Image(systemName: p.isCask ? "macwindow" : "terminal")
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14), in: .rect(cornerRadius: size / 4))
            .help(p.kind)
            .accessibilityLabel(p.kind)
    }
}
