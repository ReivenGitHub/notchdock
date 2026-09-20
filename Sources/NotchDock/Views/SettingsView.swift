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
                        Toggle("Use the smallest handle on displays without a notch", isOn: $preferences.hideWhenIdle)
                        Text("On a MacBook with a hardware notch, nothing is drawn beside the camera while NotchDock is closed—even during media playback or a timer. Move the pointer below the notch to open it.")
                            .font(.caption).foregroundStyle(.secondary)
                        Toggle("Expand on hover", isOn: $preferences.expandOnHover)
                        Text("When unpinned, the panel closes shortly after the pointer leaves the complete interface. Pin it only when you want it to remain open.")
                            .font(.caption).foregroundStyle(.secondary)
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
                    Section("Media") {
                        Toggle("Enable media detection and controls", isOn: $preferences.mediaEnabled)
                        Picker("Source", selection: $preferences.player) {
                            ForEach(PlayerApp.allCases) { player in Text(player.title).tag(player) }
                        }
                        Text("Automatic checks running Apple Music, Spotify, Chrome, and Safari, then shows the active source. The selected source is checked every 6 seconds while collapsed and every 2 seconds when expanded.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("For YouTube controls and exact playback state, enable Allow JavaScript from Apple Events in Chrome or Safari’s Developer menu. macOS also asks for Automation permission. Only YouTube tabs are inspected.")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("Album covers appear in Overview while the panel is open. Music supplies local artwork; Spotify and YouTube covers use player-provided image URLs and are cached in memory only.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("Mirror") {
                        Text("Camera access is requested when you open Mirror. Leaving its tab, closing the panel, or putting the Mac to sleep stops the camera. No photos, recordings, or microphone access.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Section("On this Mac") {
                        Text("Files, settings, and focus history stay on this Mac. No accounts, analytics, or clipboard monitoring.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Show saved data in Finder") {
                            if let url = try? LocalStore.location("shelf.json") { NSWorkspace.shared.open(url.deletingLastPathComponent()) }
                        }
                    }
                }.formStyle(.grouped).tabItem { Label("Media & Privacy", systemImage: "play.rectangle") }
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
