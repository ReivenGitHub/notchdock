import Foundation

public enum FocusMode: String, CaseIterable, Codable, Identifiable {
    case focus, shortBreak, longBreak
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short break"
        case .longBreak: return "Long break"
        }
    }
    public var symbol: String { self == .focus ? "timer" : "cup.and.saucer.fill" }
}

public struct FocusCompletion: Codable, Equatable, Identifiable {
    public let id: UUID
    public let mode: FocusMode
    public let duration: TimeInterval
    public let finishedAt: Date
}

/// Keeps completed sessions separate from the live timer; a deadline is counted once.
public struct FocusArchive: Codable, Equatable {
    public private(set) var session: FocusSession
    public private(set) var mode: FocusMode
    public private(set) var sessionID: UUID
    public private(set) var completions: [FocusCompletion] = []

    public init(session: FocusSession = FocusSession(), mode: FocusMode = .focus) {
        self.session = session
        self.mode = mode
        sessionID = UUID()
    }
    public var isValid: Bool {
        session.duration.isFinite && (60...10_800).contains(session.duration)
            && session.pausedRemaining.isFinite && (0...session.duration).contains(session.pausedRemaining)
            && (session.phase != .running || session.deadline != nil)
            && completions.count <= 200
            && completions.allSatisfy { $0.duration.isFinite && (60...10_800).contains($0.duration) }
    }
    @discardableResult
    public mutating func tick(at now: Date) -> Bool {
        let finishedAt = session.deadline ?? now
        guard session.tick(at: now) else { return false }
        if !completions.contains(where: { $0.id == sessionID }) {
            completions.append(FocusCompletion(id: sessionID, mode: mode, duration: session.duration, finishedAt: finishedAt))
            if completions.count > 200 { completions.removeFirst(completions.count - 200) }
        }
        return true
    }
    /// Returns true if a delayed click finds the timer already complete.
    @discardableResult
    public mutating func toggle(at now: Date) -> Bool {
        if tick(at: now) { return true }
        if session.phase == .running { session.pause(at: now) }
        else {
            if session.phase != .paused { sessionID = UUID() }
            session.start(at: now)
        }
        return false
    }
    public mutating func reset(mode: FocusMode? = nil, duration: TimeInterval? = nil) {
        if let mode { self.mode = mode }
        session.reset(duration: duration)
    }
    public func today(at now: Date, calendar: Calendar = .current) -> (sessions: Int, minutes: Int) {
        let matches = completions.filter { $0.mode == .focus && calendar.isDate($0.finishedAt, inSameDayAs: now) }
        return (matches.count, Int(matches.reduce(0) { $0 + $1.duration } / 60))
    }
}
