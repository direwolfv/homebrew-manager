import AppKit

struct Pkg: Identifiable, Hashable {
    let name: String, installed: String, latest: String, isCask: Bool, desc: String
    var outdated: Bool
    var displayName: String?
    var homepage: String?, license: String?, tap: String?, caveats: String?
    var deps: [String] = [], usedBy: [String] = []
    var installedAt: Date?
    var onRequest: Bool?, autoUpdates: Bool?
    var id: String { (isCask ? "cask:" : "formula:") + name }
    var kind: String { isCask ? "Cask" : "Formula" }
}

enum Filter: String, CaseIterable {
    case all = "All packages", outdated = "Updates", formulae = "Formulae", casks = "Casks", cache = "Cache"
    static let library: [Filter] = [.all, .outdated, .formulae, .casks]
    var icon: String {
        switch self {
        case .all: "shippingbox"
        case .outdated: "arrow.up.circle"
        case .formulae: "terminal"
        case .casks: "macwindow"
        case .cache: "internaldrive"
        }
    }
    func matches(_ p: Pkg) -> Bool {
        switch self {
        case .all: true
        case .outdated: p.outdated
        case .formulae: !p.isCask
        case .casks: p.isCask
        case .cache: false
        }
    }
}

enum Theme: String, CaseIterable {
    case system, light, dark
    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
    var appearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
