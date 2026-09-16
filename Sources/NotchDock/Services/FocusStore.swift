import AppKit
import Combine
import NotchDockCore

@MainActor
final class FocusStore: ObservableObject {
    @Published private(set) var session = FocusSession()
    @Published private(set) var now = Date()
    @Published private(set) var storageError: String?
    var onCompletion: () -> Void = {}
    private var clock: AnyCancellable?
    var label: String { FocusSession.clock(session.remaining(at: now)) }
    var progress: Double { session.progress(at: now) }
    var isRunning: Bool { session.phase == .running }
    var status: String {
        switch session.phase {
        case .idle: return "Make room for deep work."
        case .running: return "One thing at a time."
        case .paused: return "Take a breath. Resume when ready."
        case .finished: return "Session complete. Nice work."
        }
    }
    init() {
        do {
            if let saved = try LocalStore.load(FocusSession.self, from: "focus.json"),
               saved.duration.isFinite, (60...10_800).contains(saved.duration),
               saved.pausedRemaining.isFinite, (0...saved.duration).contains(saved.pausedRemaining),
               saved.phase != .running || saved.deadline != nil {
                session = saved
                if session.tick(at: now) { persist() }
            }
        } catch { storageError = "The previous timer could not be restored." }
        clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in
            guard let self else { return }
            self.now = date
            if self.session.tick(at: date) { self.persist(); self.onCompletion() }
        }
    }
    func toggle() {
        now = Date()
        if session.tick(at: now) { onCompletion(); persist(); return }
        if isRunning { session.pause(at: now) } else { session.start(at: now) }
        persist()
    }
    func choose(minutes: Int) { session.reset(duration: TimeInterval(minutes * 60)); now = Date(); persist() }
    func reset() { session.reset(); now = Date(); persist() }
    private func persist() {
        do { try LocalStore.save(session, to: "focus.json"); storageError = nil }
        catch { storageError = "Timer is working, but could not be saved for the next launch." }
    }
}
