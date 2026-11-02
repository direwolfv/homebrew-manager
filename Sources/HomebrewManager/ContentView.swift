import SwiftUI

struct ContentView: View {
    @State private var store = Store()
    @State private var search = ""
    @State private var filter: Filter? = .all
    @State private var confirmUninstall: Pkg?
    @State private var selection: Pkg.ID?
    @State private var showInfo = false
    @AppStorage("theme") private var theme = Theme.system

    private var current: Filter { filter ?? .all }
    private var outdatedCount: Int { store.pkgs.filter(\.outdated).count }

    private var shown: [Pkg] {
        store.pkgs.filter {
            current.matches($0) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
                || $0.desc.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if current == .cache { CacheView().navigationTitle(Filter.cache.rawValue) } else { packages }
        }
        .disabled(store.busy != nil)
        .overlay {
            if let busy = store.busy {
                ProgressView(busy).padding().background(.regularMaterial, in: .rect(cornerRadius: 10))
            }
        }
        .confirmationDialog("Uninstall \(confirmUninstall?.name ?? "")?",
                            isPresented: .init(get: { confirmUninstall != nil }, set: { if !$0 { confirmUninstall = nil } }),
                            presenting: confirmUninstall) { p in
            Button("Uninstall", role: .destructive) { Task { await store.act("uninstall", p) } }
        }
        .alert("brew failed", isPresented: .init(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
        } message: { Text(store.error ?? "") }
        .onChange(of: theme, initial: true) { NSApp.appearance = theme.appearance }
        .frame(minWidth: 900, minHeight: 520)
        .task { await store.refresh() }
    }

    private var sidebar: some View {
        List(selection: $filter) {
            Section("Library") {
                ForEach(Filter.library, id: \.self) { f in
                    Label(f.rawValue, systemImage: f.icon)
                        .badge(store.pkgs.filter(f.matches).count)
                        .padding(.vertical, 3)
                }
            }
            Section("Maintenance") {
                Label(Filter.cache.rawValue, systemImage: Filter.cache.icon).padding(.vertical, 3).tag(Filter.cache)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("Appearance").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Picker("Appearance", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { t in
                        Label(t.rawValue.capitalized, systemImage: t.icon).labelStyle(.iconOnly).tag(t)
                    }
                }
                .pickerStyle(.segmented).labelsHidden().fixedSize()
            }
            .padding(12)
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 230)
    }

    private var packages: some View {
        List(selection: $selection) {
            ForEach(shown) { p in
                PkgRow(p: p, upgrade: { Task { await store.act("upgrade", p) } }, uninstall: { confirmUninstall = p })
                    .contextMenu {
                        Button("Upgrade") { Task { await store.act("upgrade", p) } }.disabled(!p.outdated)
                        Button("Uninstall…", role: .destructive) { confirmUninstall = p }
                    }
            }
        }
        .overlay {
            if shown.isEmpty && store.busy == nil {
                if !search.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else if current == .outdated {
                    ContentUnavailableView("You're all up to date", systemImage: "checkmark.circle",
                                           description: Text("Nothing to upgrade."))
                }
            }
        }
        .inspector(isPresented: $showInfo) {
            InfoView(p: store.pkgs.first { $0.id == selection })
                .inspectorColumnWidth(min: 260, ideal: 300, max: 400)
        }
        // Clicking empty list space (or switching sections) deselects, which closes the panel.
        .onChange(of: selection) { showInfo = selection != nil }
        .onChange(of: filter) { selection = nil }
        .searchable(text: $search)
        .navigationTitle(current.rawValue)
        .navigationSubtitle("\(shown.count) shown · "
            + (outdatedCount > 0 ? "\(outdatedCount) updates available" : "everything up to date"))
        .toolbar {
            ToolbarItemGroup {
                Button("Update", systemImage: "arrow.clockwise") { Task { await store.act("update", nil) } }
                    .labelStyle(.titleAndIcon)
                    .help("brew update: fetch latest package definitions")
                Button("Upgrade All", systemImage: "arrow.up") { Task { await store.act("upgrade", nil) } }
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.borderedProminent)
                    .disabled(outdatedCount == 0)
                Button("Info", systemImage: "info.circle") { showInfo.toggle() }
                    .help("Show package details")
            }
        }
    }
}
