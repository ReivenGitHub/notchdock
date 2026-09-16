import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var state: PanelState
    @EnvironmentObject private var media: MediaService
    @State private var launchAtLogin = false
    @State private var loginError: String?
    @State private var changingLogin = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "sparkle").font(.system(size: 27)).foregroundStyle(DockTheme.accent)
                    .frame(width: 54, height: 54).background(Color.black, in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 4) {
                    Text("NotchDock").font(.system(size: 22, weight: .semibold))
                    Text("A little space. A clearer day.").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("0.1.0").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            }.padding(24)
            Form {
                Section("Your notch") {
                    Toggle("Expand when the pointer hovers nearby", isOn: $preferences.expandOnHover)
                    Toggle("Prefer the built-in notched display", isOn: $preferences.preferBuiltInDisplay)
                    Text("Otherwise, NotchDock uses the primary display. It also works without a hardware notch.")
                        .font(.caption).foregroundStyle(.secondary)
                    LabeledContent("Toggle panel", value: state.shortcutAvailable ? "⌥⌘Space" : "Shortcut unavailable — use the menu bar")
                }
                Section("Music") {
                    Toggle("Enable music controls", isOn: $preferences.mediaEnabled)
                    Picker("Player", selection: $preferences.player) {
                        ForEach(PlayerApp.allCases) { player in Text(player.title).tag(player) }
                    }
                    Text("macOS asks for Automation permission for the player you choose. Browser audio is not supported.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Daily rhythm") {
                    Toggle("Play a sound when focus finishes", isOn: $preferences.playCompletionSound)
                    Toggle("Launch at login", isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin)).disabled(changingLogin)
                    if let loginError { Text(loginError).font(.caption).foregroundStyle(.orange) }
                }
                Section {
                    Text("Files, settings, and your timer stay on this Mac. No accounts or analytics.").font(.caption).foregroundStyle(.secondary)
                    Button("Show saved data in Finder") {
                        if let url = try? LocalStore.location("shelf.json") { NSWorkspace.shared.open(url.deletingLastPathComponent()) }
                    }
                }
            }.formStyle(.grouped)
        }.frame(width: 480, height: 580).onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
    }
    private func setLaunchAtLogin(_ enabled: Bool) {
        changingLogin = true
        Task { @MainActor in
            defer { changingLogin = false }
            do {
                if enabled { try SMAppService.mainApp.register() }
                else { try await SMAppService.mainApp.unregister() }
                launchAtLogin = SMAppService.mainApp.status == .enabled
                if SMAppService.mainApp.status == .requiresApproval {
                    loginError = "Approve NotchDock in System Settings → General → Login Items."
                    SMAppService.openSystemSettingsLoginItems()
                } else { loginError = nil }
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
                loginError = "Move NotchDock.app to Applications and try again. \(error.localizedDescription)"
            }
        }
    }
}
