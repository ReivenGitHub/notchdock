import AppKit
import Combine
import NotchDockCore

@MainActor
final class FocusStore: ObservableObject {
    @Published private(set) var archive = FocusArchive()
    @Published private(set) var now = Date()
    @Published private(set) var storageError: String?
    var onCompletion: () -> Void = {}
    private var clock: AnyCancellable?
    private let preferences: Preferences
    var session: FocusSession { archive.session }
    var mode: FocusMode { archive.mode }
    var hasActiveSession: Bool { session.phase == .running || session.phase == .paused }
    var today: (sessions: Int, minutes: Int) { archive.today(at: now) }
    var label: String { FocusSession.clock(session.remaining(at: now)) }
    var progress: Double { session.progress(at: now) }
    var isRunning: Bool { session.phase == .running }
    var status: String {
        switch session.phase {
        case .idle: return mode == .focus ? "Make room for deep work." : "Step away. Come back refreshed."
        case .running: return mode == .focus ? "One thing at a time." : "A little time to recharge."
        case .paused: return "Take a breath. Resume when ready."
        case .finished: return mode == .focus ? "Session complete. Nice work." : "Break complete. Ready when you are."
        }
    }
    init(preferences: Preferences) {
        self.preferences = preferences
        do {
            if let saved = try LocalStore.load(FocusArchive.self, from: "focus-state.json"), saved.isValid {
                archive = saved
            } else if let legacy = try LocalStore.load(FocusSession.self, from: "focus.json"),
                      FocusArchive(session: legacy).isValid {
                archive = FocusArchive(session: legacy)
            } else {
                archive = FocusArchive(session: FocusSession(duration: Double(preferences.focusMinutes * 60)))
            }
            // Restore and count expired deadlines without replaying an old sound.
            archive.tick(at: now)
            persist()
        } catch { storageError = "The previous timer could not be restored." }
        clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in
            guard let self else { return }
            self.now = date
            if self.archive.tick(at: date) { self.persist(); self.onCompletion() }
        }
    }
    func toggle() {
        now = Date()
        if !hasActiveSession { archive.reset(duration: Double(preferences.minutes(for: mode) * 60)) }
        let completed = archive.toggle(at: now)
        persist()
        if completed { onCompletion() }
    }
    func choose(mode: FocusMode) {
        guard !hasActiveSession else { return }
        archive.reset(mode: mode, duration: Double(preferences.minutes(for: mode) * 60))
        now = Date()
        persist()
    }
    func updateIdleDuration() {
        guard session.phase == .idle else { return }
        archive.reset(duration: Double(preferences.minutes(for: mode) * 60))
        persist()
    }
    func reset() {
        archive.reset(duration: Double(preferences.minutes(for: mode) * 60))
        now = Date()
        persist()
    }
    private func persist() {
        do { try LocalStore.save(archive, to: "focus-state.json"); storageError = nil }
        catch { storageError = "Timer is working, but could not be saved for the next launch." }
    }
}
