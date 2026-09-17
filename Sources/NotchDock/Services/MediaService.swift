import AppKit
import Combine
import Foundation
import NotchDockCore

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
enum ScriptResult { case success(String), failure(String) }

/// Runs only application-owned scripts, without a shell, off the UI thread.
final class AppleScriptBridge {
    private let queue = DispatchQueue(label: "app.notchdock.music", qos: .utility)
    func run(_ source: String, arguments: [String] = []) async -> ScriptResult {
        await withCheckedContinuation { continuation in
            queue.async {
                let task = Process()
                let pipe = Pipe()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                task.arguments = ["-e", source] + arguments
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
    @Published private(set) var artwork: NSImage?
    @Published private(set) var artworkLoading = false
    private let preferences: Preferences
    private let bridge = AppleScriptBridge()
    private lazy var artworkLoader = ArtworkLoader(bridge: bridge)
    private var artworkRequest = ArtworkRequest()
    private var artworkTask: Task<Void, Never>?
    private var nextArtworkAttempt = Date.distantPast
    private var poller: AnyCancellable?
    private var selectionObserver: AnyCancellable?
    private var panelVisible = false
    private var runningRequest = false
    private var connectionVersion = 0
    private var backgroundTicks = 0

    init(preferences: Preferences) {
        self.preferences = preferences
        selectionObserver = preferences.$player.combineLatest(preferences.$mediaEnabled)
            .dropFirst().sink { [weak self] _, _ in
                // @Published emits before mutation. Read preferences on the next main turn.
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.connectionVersion += 1
                    self.track = NowPlaying()
                    self.clearArtwork()
                    self.artworkLoader.clearCache()
                    self.error = nil
                    self.refresh()
                }
            }
        poller = Timer.publish(every: 2, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self, self.preferences.mediaEnabled, self.error == nil else { return }
            // Lightweight background checks keep compact activity in sync without opening the player.
            self.backgroundTicks += 1
            guard self.panelVisible || self.backgroundTicks >= 3 else { return }
            self.backgroundTicks = 0
            self.refresh()
        }
    }
    func setVisible(_ visible: Bool) { panelVisible = visible; if visible { refresh() } }
    func enable() { preferences.mediaEnabled = true; error = nil; refresh() }
    func retry() { error = nil; reloadArtwork(); refresh() }
    func reloadArtwork() {
        clearArtwork()
        artworkLoader.clearCache()
        refresh()
    }
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
            if case .failure(let message) = result { error = message; track = NowPlaying(); clearArtwork() }
            else { error = nil; refresh() }
        }
    }
    func refresh() {
        guard preferences.mediaEnabled, !runningRequest, !busy else { return }
        let player = preferences.player
        guard isRunning(player) else {
            track = NowPlaying(artist: "Open \(player.title) to begin.")
            clearArtwork()
            return
        }
        runningRequest = true
        let version = connectionVersion
        let source = MediaScripts.metadata(spotify: player == .spotify)
        Task {
            let result = await bridge.run(source)
            runningRequest = false
            guard version == connectionVersion, preferences.mediaEnabled else { return }
            switch result {
            case .failure(let message): error = message; track = NowPlaying(); clearArtwork()
            case .success(let output):
                error = nil
                guard let metadata = PlaybackMetadata(scriptOutput: output) else {
                    track = NowPlaying(); clearArtwork(); return
                }
                track = NowPlaying(title: metadata.title, artist: metadata.artist, album: metadata.album, playing: metadata.playing,
                                   position: metadata.position, duration: metadata.duration, hasTrack: true)
                updateArtwork(metadata, player: player)
            }
        }
    }
    private func isRunning(_ player: PlayerApp) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: player.bundleID).isEmpty
    }
    private func updateArtwork(_ metadata: PlaybackMetadata, player: PlayerApp) {
        let key = metadata.artworkKey(player: player.rawValue)
        if artworkRequest.key != key {
            clearArtwork()
            artworkRequest.begin(key: key)
        }
        guard artwork == nil, !artworkLoading, Date() >= nextArtworkAttempt else { return }
        artworkLoading = true
        let generation = artworkRequest.generation
        artworkTask = Task { [weak self] in
            guard let self else { return }
            let image = await self.artworkLoader.image(for: metadata, player: player)
            guard !Task.isCancelled, self.preferences.mediaEnabled,
                  self.artworkRequest.accepts(generation: generation, key: key) else { return }
            self.artwork = image
            self.artworkLoading = false
            self.artworkTask = nil
            self.nextArtworkAttempt = Date().addingTimeInterval(30)
        }
    }
    private func clearArtwork() {
        artworkTask?.cancel()
        artworkTask = nil
        artworkRequest.begin(key: nil)
        artwork = nil
        artworkLoading = false
        nextArtworkAttempt = .distantPast
    }
    func stop() {
        poller?.cancel()
        selectionObserver?.cancel()
        clearArtwork()
        artworkLoader.clearCache()
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
