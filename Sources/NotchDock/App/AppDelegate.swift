import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let state = PanelState()
    private let shelf = ShelfStore()
    private let focus = FocusStore()
    private let battery = BatteryService()
    private lazy var media = MediaService(preferences: preferences)
    private var panelController: PanelController?
    private var hotKey: HotKeyController?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        state.showSettings = { [weak self] in self?.openSettings() }
        panelController = PanelController(state: state, preferences: preferences, media: media, shelf: shelf, focus: focus, battery: battery)
        hotKey = HotKeyController { [weak self] in self?.panelController?.toggle() }
        state.shortcutAvailable = hotKey?.registered ?? false
        focus.onCompletion = { [weak self] in
            guard let self else { return }
            if self.preferences.playCompletionSound { NSSound(named: "Glass")?.play() }
            self.panelController?.focusFinished()
        }
        installMenu()
        if !UserDefaults.standard.bool(forKey: "hasLaunched") {
            UserDefaults.standard.set(true, forKey: "hasLaunched")
            state.pinned = true
            panelController?.expand()
        }
    }
    private func installMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "NotchDock")
        if item.button?.image == nil { item.button?.title = "ND" }
        item.button?.toolTip = "NotchDock"
        let menu = NSMenu()
        let title = NSMenuItem(title: "NotchDock", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        addItem("Show / Hide NotchDock", action: #selector(togglePanel), to: menu)
        addItem("Add Files…", action: #selector(addFiles), to: menu)
        addItem("Settings…", action: #selector(openSettings), to: menu, key: ",")
        menu.addItem(.separator())
        addItem("Quit NotchDock", action: #selector(quit), to: menu, key: "q")
        item.menu = menu
        statusItem = item
    }
    private func addItem(_ title: String, action: Selector, to menu: NSMenu, key: String = "") {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }
    @objc private func togglePanel() { panelController?.toggle() }
    @objc private func addFiles() {
        state.beginInteraction()
        state.tab = .shelf
        panelController?.expand()
        shelf.chooseFiles()
        state.endInteraction()
    }
    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 580),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "NotchDock Settings"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView()
                .environmentObject(preferences).environmentObject(state).environmentObject(media))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { hotKey?.stop(); panelController?.stop() }
}
