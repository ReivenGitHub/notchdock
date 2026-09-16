import Foundation
import XCTest
@testable import NotchDockCore

final class FocusSessionTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000_000)
    func testPauseAndResumePreservesRemainingTime() {
        var timer = FocusSession(duration: 1_500)
        timer.start(at: start)
        timer.pause(at: start.addingTimeInterval(123))
        XCTAssertEqual(timer.phase, .paused)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(10_000)), 1_377)
        timer.start(at: start.addingTimeInterval(20_000))
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(20_100)), 1_277)
    }
    func testWakeAfterDeadlineFinishesExactlyOnce() {
        var timer = FocusSession(duration: 300)
        timer.start(at: start)
        XCTAssertTrue(timer.tick(at: start.addingTimeInterval(3_600)))
        XCTAssertFalse(timer.tick(at: start.addingTimeInterval(3_601)))
        XCTAssertEqual(timer.phase, .finished)
        XCTAssertEqual(timer.progress(at: start), 1)
        XCTAssertEqual(timer.remaining(at: start), 0)
    }
    func testCompletedSessionCanRestart() {
        var timer = FocusSession(duration: 60)
        timer.start(at: start)
        timer.tick(at: start.addingTimeInterval(61))
        timer.start(at: start.addingTimeInterval(120))
        XCTAssertEqual(timer.phase, .running)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(120)), 60)
    }
    func testRepeatedStartDoesNotExtendDeadline() {
        var timer = FocusSession(duration: 300)
        timer.start(at: start)
        timer.start(at: start.addingTimeInterval(50))
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(100)), 200)
    }
    func testResetCancelsDeadlineAndSelectsNewDuration() {
        var timer = FocusSession()
        timer.start(at: start)
        timer.reset(duration: 900)
        XCTAssertEqual(timer.phase, .idle)
        XCTAssertNil(timer.deadline)
        XCTAssertFalse(timer.tick(at: start.addingTimeInterval(100_000)))
        XCTAssertEqual(timer.remaining(at: start), 900)
    }
    func testRunningTimerSurvivesJSONRoundTripAndRestart() throws {
        var original = FocusSession(duration: 1_500)
        original.start(at: start)
        let data = try JSONEncoder().encode(original)
        var restored = try JSONDecoder().decode(FocusSession.self, from: data)
        XCTAssertEqual(restored.remaining(at: start.addingTimeInterval(500)), 1_000)
        XCTAssertTrue(restored.tick(at: start.addingTimeInterval(2_000)))
    }
    func testClockFormatsBoundariesWithoutNegativeValues() {
        XCTAssertEqual(FocusSession.clock(1_500), "25:00")
        XCTAssertEqual(FocusSession.clock(0.01), "00:01")
        XCTAssertEqual(FocusSession.clock(59.01), "01:00")
        XCTAssertEqual(FocusSession.clock(-3), "00:00")
        XCTAssertEqual(FocusSession.clock(.infinity), "00:00")
    }
    func testInvalidDurationsAreBounded() {
        XCTAssertEqual(FocusSession(duration: -10).duration, 60)
        XCTAssertEqual(FocusSession(duration: 100_000).duration, 10_800)
        XCTAssertEqual(FocusSession(duration: .nan).duration, 1_500)
    }
    func testClockMovingBackwardCannotExceedSessionDuration() {
        var timer = FocusSession(duration: 900)
        timer.start(at: start)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(-600)), 900)
        XCTAssertEqual(timer.progress(at: start.addingTimeInterval(-600)), 0)
    }
}
