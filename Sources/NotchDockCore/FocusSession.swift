import Foundation

/// A deadline-based timer. Sleep and delayed UI ticks do not lose elapsed time.
public struct FocusSession: Codable, Equatable {
    public enum Phase: String, Codable { case idle, running, paused, finished }
    public private(set) var phase: Phase = .idle
    public private(set) var duration: TimeInterval
    public private(set) var deadline: Date?
    public private(set) var pausedRemaining: TimeInterval

    public init(duration: TimeInterval = 25 * 60) {
        let safeDuration = Self.clamp(duration)
        self.duration = safeDuration
        self.pausedRemaining = safeDuration
    }
    public func remaining(at now: Date) -> TimeInterval {
        switch phase {
        case .running: return min(duration, max(0, deadline?.timeIntervalSince(now) ?? 0))
        case .finished: return 0
        case .idle, .paused: return pausedRemaining
        }
    }
    public func progress(at now: Date) -> Double { min(1, max(0, 1 - remaining(at: now) / duration)) }
    public mutating func start(at now: Date) {
        guard phase != .running else { return }
        if phase == .finished { pausedRemaining = duration }
        deadline = now.addingTimeInterval(pausedRemaining)
        phase = .running
    }
    public mutating func pause(at now: Date) {
        guard phase == .running else { return }
        pausedRemaining = remaining(at: now)
        deadline = nil
        phase = pausedRemaining > 0 ? .paused : .finished
    }
    /// Returns true once per completion, even when a Mac wakes after the deadline.
    @discardableResult
    public mutating func tick(at now: Date) -> Bool {
        guard phase == .running, remaining(at: now) <= 0 else { return false }
        phase = .finished
        pausedRemaining = 0
        deadline = nil
        return true
    }
    public mutating func reset(duration newDuration: TimeInterval? = nil) {
        if let newDuration { duration = Self.clamp(newDuration) }
        pausedRemaining = duration
        deadline = nil
        phase = .idle
    }
    public static func clock(_ seconds: TimeInterval) -> String {
        let safe = seconds.isFinite ? seconds : 0
        let total = Int(ceil(min(86_400, max(0, safe))))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
    private static func clamp(_ value: TimeInterval) -> TimeInterval {
        value.isFinite ? min(3 * 60 * 60, max(60, value)) : 25 * 60
    }
}
