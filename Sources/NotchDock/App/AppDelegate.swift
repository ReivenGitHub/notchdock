import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let preferences = Preferences()
    private let state = PanelState()
    private let shelf = ShelfStore()
    private let airDrop = AirDropService()
    private let mirror = MirrorService()
    private lazy var focus = FocusStore(preferences: preferences)
    private let displays = DisplayService()
    private let battery = BatteryService()
    private lazy var media = MediaService(preferences: preferences)
    private var panelController: PanelController?
    private var hotKey: HotKeyController?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        state.showSettings = { [weak self] in self?.openSettings() }
        panelController = PanelController(state: state, preferences: preferences, media: media,
                                          shelf: shelf, focus: focus, battery: battery, displays: displays,
                                          airDrop: airDrop, mirror: mirror)
        airDrop.beginInteraction = { [weak self] in self?.state.beginInteraction() }
        airDrop.endInteraction = { [weak self] in self?.state.endInteraction() }
        hotKey = HotKeyController { [weak self] in self?.panelController?.toggle() }
        preferences.$shortcut.combineLatest(state.$recordingShortcut).sink { [weak self] binding, recording in
            guard let self else { return }
            self.hotKey?.configure(recording ? nil : binding)
            self.state.shortcutAvailable = binding == nil || (self.hotKey?.registered ?? false)
        }.store(in: &subscriptions)
        preferences.$focusMinutes.combineLatest(preferences.$shortBreakMinutes, preferences.$longBreakMinutes)
            .dropFirst().sink { [weak self] _ in
                DispatchQueue.main.async { self?.focus.updateIdleDuration() }
            }.store(in: &subscriptions)
        focus.onCompletion = { [weak self] in
            guard let self else { return }
            if self.preferences.playCompletionSound { NSSound(named: "Glass")?.play() }
            if self.preferences.showOnCompletion { self.panelController?.focusFinished() }
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
        addItem("AirDrop Files…", action: #selector(airDropFiles), to: menu)
        addItem("Open Mirror", action: #selector(openMirror), to: menu)
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
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 620),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "NotchDock Settings"
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: SettingsView()
                .environmentObject(preferences).environmentObject(state).environmentObject(media).environmentObject(displays))
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
    @objc private func airDropFiles() {
        state.tab = .shelf
        panelController?.expand()
        airDrop.chooseFiles()
    }
    @objc private func openMirror() { state.tab = .mirror; panelController?.expand() }
    @objc private func quit() { NSApp.terminate(nil) }
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === settingsWindow { state.recordingShortcut = false }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) {
        mirror.shutdown(); media.stop()
        hotKey?.stop(); panelController?.stop(); displays.stop(); subscriptions.removeAll()
    }
}
