import AppKit
import Combine
import Foundation

struct NowPlaying {
    var title = "Nothing playing"
    var artist = "Open your music app to begin."
    var album = ""
    var playing = false
    var position: Double = 0
    var duration: Double = 0
    var hasTrack = false
    var progress: Double { duration > 0 ? min(1, max(0, position / duration)) : 0 }
}
private enum ScriptResult { case success(String), failure(String) }

/// Runs only application-owned scripts, without a shell, off the UI thread.
private final class AppleScriptBridge {
    private let queue = DispatchQueue(label: "app.notchdock.music", qos: .utility)
    func run(_ source: String) async -> ScriptResult {
        await withCheckedContinuation { continuation in
            queue.async {
                let task = Process()
                let pipe = Pipe()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                task.arguments = ["-e", source]
                task.standardOutput = pipe
                task.standardError = pipe
                do { try task.run() }
                catch { continuation.resume(returning: .failure("The music helper could not start.")); return }
                let timeout = DispatchWorkItem { if task.isRunning { task.terminate() } }
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 12, execute: timeout)
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                timeout.cancel()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""
                if task.terminationStatus == 0 { continuation.resume(returning: .success(output)) }
                else if output.contains("-1743") {
                    continuation.resume(returning: .failure("Allow NotchDock in System Settings → Privacy & Security → Automation, then retry."))
                } else {
                    continuation.resume(returning: .failure("Music is unavailable. Open the selected app, start a track, and retry."))
                }
            }
        }
    }
}

@MainActor
final class MediaService: ObservableObject {
    enum Command: String { case playPause = "playpause", previous = "previous track", next = "next track" }
    @Published private(set) var track = NowPlaying()
    @Published private(set) var error: String?
    @Published private(set) var busy = false
    private let preferences: Preferences
    private let bridge = AppleScriptBridge()
    private var poller: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    private var panelVisible = false
    private var runningRequest = false
    private var connectionVersion = 0

    init(preferences: Preferences) {
        self.preferences = preferences
        selectionObserver = preferences.$player.combineLatest(preferences.$mediaEnabled)
            .dropFirst().sink { [weak self] _, _ in
                // @Published emits before mutation. Read preferences on the next main turn.
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.connectionVersion += 1
                    self.track = NowPlaying()
                    self.error = nil
                    if self.panelVisible { self.refresh() }
                }
            }
        poller = Timer.publish(every: 2, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, self.panelVisible, self.error == nil else { return }
            self.refresh()
        }
    }
    func setVisible(_ visible: Bool) { panelVisible = visible; if visible { refresh() } }
    func enable() { preferences.mediaEnabled = true; error = nil; refresh() }
    func retry() { error = nil; refresh() }
    func openPlayer() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: preferences.player.bundleID) else {
            error = "\(preferences.player.title) is not installed. Select another player in Settings."
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
    }
    func send(_ command: Command) {
        guard preferences.mediaEnabled, !busy else { return }
        let player = preferences.player
        guard isRunning(player) else { openPlayer(); return }
        busy = true
        let version = connectionVersion
        Task {
            let result = await bridge.run(Self.script(player: player, body: command.rawValue))
            busy = false
            guard version == connectionVersion else { return }
            if case .failure(let message) = result { error = message }
            else { error = nil; refresh() }
        }
    }
    func refresh() {
        guard preferences.mediaEnabled, !runningRequest, !busy else { return }
        let player = preferences.player
        guard isRunning(player) else { track = NowPlaying(artist: "Open \(player.title) to begin."); return }
        runningRequest = true
        let version = connectionVersion
        let duration = player == .spotify ? "((duration of current track) / 1000)" : "(duration of current track)"
        let body = """
        if player state is stopped then return "stopped"
        set separator to ASCII character 31
        return (player state as string) & separator & (name of current track as string) & separator & (artist of current track as string) & separator & (album of current track as string) & separator & (player position as string) & separator & (\(duration) as string)
        """
        Task {
            let result = await bridge.run(Self.script(player: player, body: body))
            runningRequest = false
            guard version == connectionVersion, preferences.mediaEnabled else { return }
            switch result {
            case .failure(let message): error = message
            case .success(let output):
                error = nil
                let fields = output.components(separatedBy: "\u{1F}")
                guard fields.count == 6 else { track = NowPlaying(); return }
                track = NowPlaying(title: fields[1], artist: fields[2], album: fields[3], playing: fields[0] == "playing",
                                   position: Self.number(fields[4]), duration: Self.number(fields[5]), hasTrack: true)
            }
        }
    }
    private func isRunning(_ player: PlayerApp) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: player.bundleID).isEmpty
    }
    private static func number(_ string: String) -> Double {
        let value = Double(string.replacingOccurrences(of: ",", with: ".")) ?? 0
        return value.isFinite ? max(0, value) : 0
    }
    private static func script(player: PlayerApp, body: String) -> String {
        """
        with timeout of 5 seconds
            tell application id "\(player.bundleID)"
                \(body)
            end tell
        end timeout
        """
    }
}
