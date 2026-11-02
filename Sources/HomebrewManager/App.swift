import AppKit
import SwiftUI

@main
struct HomebrewManagerApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    init() {
        // Running from SwiftPM (no .app bundle): become a regular foreground app.
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
            .commands {
                CommandGroup(replacing: .appInfo) {
                    Button("About Homebrew Manager") { Task { await showAbout() } }
                }
            }
    }
}

// Single-window app: closing the window quits, so launching again always opens a window
// instead of activating a windowless process.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// Standard panel: name, icon, version and copyright come from Info.plist (see build.sh).
@MainActor func showAbout() async {
    let small = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    let brewVersion = (try? await brew(["--version"]))?.split(separator: "\n").first.map(String.init) ?? "Homebrew not found"
    let credits = NSMutableAttributedString(
        string: "\(brewVersion)\n\(brewPath ?? "")\n\n",
        attributes: [.font: small, .foregroundColor: NSColor.secondaryLabelColor])
    credits.append(NSAttributedString(string: "github.com/direwolfv/homebrew-manager", attributes: [
        .font: small,
        .link: URL(string: "https://github.com/direwolfv/homebrew-manager")!,
    ]))
    credits.append(NSAttributedString(
        string: "\n\nPersonal tool. Not affiliated with or endorsed by Homebrew.",
        attributes: [.font: small, .foregroundColor: NSColor.secondaryLabelColor]))
    let centered = NSMutableParagraphStyle()
    centered.alignment = .center
    credits.addAttribute(.paragraphStyle, value: centered, range: NSRange(location: 0, length: credits.length))
    NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    NSApp.activate()
}
