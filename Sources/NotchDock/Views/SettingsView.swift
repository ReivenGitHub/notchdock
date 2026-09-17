import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var state: PanelState
    @EnvironmentObject private var media: MediaService
    @EnvironmentObject private var displays: DisplayService
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
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Dev")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            }.padding(24)
            TabView {
                Form {
                    Section("Your notch") {
                        Toggle("Blend into the hardware notch when idle", isOn: $preferences.hideWhenIdle)
                        Text("No extra bar when idle. Timer or music activity appears beside the camera. Displays without a notch keep a small handle.")
                            .font(.caption).foregroundStyle(.secondary)
                        Toggle("Expand on hover", isOn: $preferences.expandOnHover)
                        Picker("Display", selection: $preferences.displayTarget) {
                            Text("Automatic · prefer a notched display").tag("automatic")
                            Text("Primary display").tag("primary")
                            ForEach(displays.choices) { choice in Text(choice.name).tag(choice.id) }
                            if preferences.displayTarget.hasPrefix("display:") && !displays.choices.contains(where: { $0.id == preferences.displayTarget }) {
                                Text("Saved display · disconnected").tag(preferences.displayTarget)
                            }
                        }
                        Text("A disconnected display falls back to Automatic and is restored when reconnected.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("Keyboard") { ShortcutRecorder() }
                    Section("Startup") {
                        Toggle("Launch at login", isOn: Binding(get: { launchAtLogin }, set: setLaunchAtLogin)).disabled(changingLogin)
                        if let loginError { Text(loginError).font(.caption).foregroundStyle(.orange) }
                    }
                }.formStyle(.grouped).tabItem { Label("Notch", systemImage: "rectangle.topthird.inset.filled") }
                Form {
                    Section("Session lengths") {
                        Stepper("Focus: \(preferences.focusMinutes) minutes", value: $preferences.focusMinutes, in: 1...180)
                        Stepper("Short break: \(preferences.shortBreakMinutes) minutes", value: $preferences.shortBreakMinutes, in: 1...60)
                        Stepper("Long break: \(preferences.longBreakMinutes) minutes", value: $preferences.longBreakMinutes, in: 1...60)
                        Text("Changes apply to the next session. Running and paused timers keep their duration.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Restore 25 / 5 / 15 minutes") {
                            preferences.focusMinutes = 25; preferences.shortBreakMinutes = 5; preferences.longBreakMinutes = 15
                        }
                    }
                    Section("When a session finishes") {
                        Toggle("Play a sound", isOn: $preferences.playCompletionSound)
                        Toggle("Open the focus panel", isOn: $preferences.showOnCompletion)
                        Text("Only completed focus sessions count toward today's total. Breaks and canceled sessions do not count.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.formStyle(.grouped).tabItem { Label("Focus", systemImage: "timer") }
                Form {
                    Section("Music") {
                        Toggle("Enable music controls", isOn: $preferences.mediaEnabled)
                        Picker("Player", selection: $preferences.player) {
                            ForEach(PlayerApp.allCases) { player in Text(player.title).tag(player) }
                        }
                        Text("macOS asks for Automation permission for the player you choose. The selected app is checked every 6 seconds while collapsed, and every 2 seconds when expanded. Browser audio is not supported.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("On this Mac") {
                        Text("Files, settings, and focus history stay on this Mac. No accounts, analytics, or clipboard monitoring.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Show saved data in Finder") {
                            if let url = try? LocalStore.location("shelf.json") { NSWorkspace.shared.open(url.deletingLastPathComponent()) }
                        }
                    }
                }.formStyle(.grouped).tabItem { Label("Music & Privacy", systemImage: "music.note") }
            }.padding(.horizontal, 16).padding(.bottom, 16)
        }.frame(width: 540, height: 620).onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
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
