import Foundation
import XCTest
@testable import NotchDockCore

final class FocusArchiveTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testCompletionIsRecordedOnceAcrossRelaunch() throws {
        var archive = FocusArchive(session: FocusSession(duration: 60))
        archive.toggle(at: start)
        XCTAssertTrue(archive.tick(at: start.addingTimeInterval(90)))
        let saved = try JSONEncoder().encode(archive)
        var restored = try JSONDecoder().decode(FocusArchive.self, from: saved)
        XCTAssertFalse(restored.tick(at: start.addingTimeInterval(120)))
        XCTAssertEqual(restored.completions.count, 1)
        XCTAssertEqual(restored.completions.first?.finishedAt, start.addingTimeInterval(60))
    }
    func testPauseAndResumeKeepSessionIdentity() {
        var archive = FocusArchive(session: FocusSession(duration: 60))
        archive.toggle(at: start)
        let id = archive.sessionID
        archive.toggle(at: start.addingTimeInterval(20))
        XCTAssertEqual(archive.session.phase, .paused)
        XCTAssertEqual(archive.completions.count, 0)
        archive.toggle(at: start.addingTimeInterval(200))
        XCTAssertEqual(archive.sessionID, id)
        XCTAssertTrue(archive.tick(at: start.addingTimeInterval(240)))
        XCTAssertEqual(archive.completions.first?.id, id)
    }
    func testResetDoesNotCountAbandonedSession() {
        var archive = FocusArchive(session: FocusSession(duration: 60))
        archive.toggle(at: start)
        archive.reset()
        XCTAssertFalse(archive.tick(at: start.addingTimeInterval(600)))
        XCTAssertEqual(archive.today(at: start).sessions, 0)
    }
    func testBreaksDoNotInflateFocusTotals() {
        var archive = FocusArchive(session: FocusSession(duration: 60), mode: .shortBreak)
        archive.toggle(at: start)
        archive.tick(at: start.addingTimeInterval(60))
        XCTAssertEqual(archive.completions.count, 1)
        XCTAssertEqual(archive.today(at: start).minutes, 0)
        archive.reset(mode: .focus, duration: 120)
        archive.toggle(at: start.addingTimeInterval(60))
        archive.tick(at: start.addingTimeInterval(180))
        XCTAssertEqual(archive.today(at: start).sessions, 1)
        XCTAssertEqual(archive.today(at: start).minutes, 2)
    }
    func testLateWakeUsesDeadlineDayRatherThanWakeDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnight = calendar.startOfDay(for: start)
        var archive = FocusArchive(session: FocusSession(duration: 60))
        archive.toggle(at: midnight.addingTimeInterval(-120))
        archive.tick(at: midnight.addingTimeInterval(3_600))
        XCTAssertEqual(archive.today(at: midnight, calendar: calendar).sessions, 0)
        XCTAssertEqual(archive.today(at: midnight.addingTimeInterval(-1), calendar: calendar).sessions, 1)
    }
    func testClickAfterDeadlineCompletesInsteadOfStartingAnotherSession() {
        var archive = FocusArchive(session: FocusSession(duration: 60))
        archive.toggle(at: start)
        XCTAssertTrue(archive.toggle(at: start.addingTimeInterval(61)))
        XCTAssertEqual(archive.session.phase, .finished)
        let completedID = archive.sessionID
        archive.toggle(at: start.addingTimeInterval(62))
        XCTAssertNotEqual(archive.sessionID, completedID)
        XCTAssertEqual(archive.session.phase, .running)
    }
    func testLegacyRunningTimerPreservesDeadlineAndCompletesOnce() throws {
        var legacy = FocusSession(duration: 300)
        legacy.start(at: start)
        let data = try JSONEncoder().encode(legacy)
        let restored = try JSONDecoder().decode(FocusSession.self, from: data)
        var archive = FocusArchive(session: restored)
        XCTAssertTrue(archive.isValid)
        XCTAssertEqual(archive.session.deadline, legacy.deadline)
        XCTAssertTrue(archive.tick(at: start.addingTimeInterval(400)))
        XCTAssertFalse(archive.tick(at: start.addingTimeInterval(500)))
        XCTAssertEqual(archive.today(at: start).minutes, 5)
    }
    func testHistoryIsBoundedAndKeepsMostRecentCompletions() {
        var archive = FocusArchive(session: FocusSession(duration: 60))
        for index in 0..<205 {
            let date = start.addingTimeInterval(Double(index * 120))
            archive.toggle(at: date)
            archive.tick(at: date.addingTimeInterval(60))
        }
        XCTAssertTrue(archive.isValid)
        XCTAssertEqual(archive.completions.count, 200)
        XCTAssertEqual(Set(archive.completions.map(\.id)).count, 200)
        XCTAssertEqual(archive.completions.first?.finishedAt, start.addingTimeInterval(660))
    }
}
