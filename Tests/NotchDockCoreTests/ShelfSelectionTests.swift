import Foundation
import XCTest
@testable import NotchDockCore

final class ShelfSelectionTests: XCTestCase {
    func testDeduplicatesAgainstShelfAndWithinDrop() {
        let a = URL(fileURLWithPath: "/tmp/a.txt")
        let b = URL(fileURLWithPath: "/tmp/b.txt")
        let selection = ShelfSelection(candidates: [a, b, b], existing: [a])
        XCTAssertEqual(selection.accepted, [b])
        XCTAssertEqual(selection.duplicateCount, 2)
    }
    func testRejectsWebLinks() {
        let selection = ShelfSelection(candidates: [URL(string: "https://example.com/file.pdf")!], existing: [])
        XCTAssertTrue(selection.accepted.isEmpty)
        XCTAssertEqual(selection.rejectedCount, 1)
    }
    func testCapacityAppliesAcrossExistingAndNewFiles() {
        let urls = (0..<5).map { URL(fileURLWithPath: "/tmp/\($0).txt") }
        let selection = ShelfSelection(candidates: Array(urls.dropFirst()), existing: [urls[0]], capacity: 3)
        XCTAssertEqual(selection.accepted, [urls[1], urls[2]])
        XCTAssertEqual(selection.overflowCount, 2)
    }
    func testStandardizesPathsBeforeDeduplication() {
        let a = URL(fileURLWithPath: "/tmp/folder/../a.txt")
        let b = URL(fileURLWithPath: "/tmp/a.txt")
        XCTAssertEqual(ShelfSelection(candidates: [a], existing: [b]).duplicateCount, 1)
    }
    func testNoCapacityStillHandlesDuplicates() {
        let a = URL(fileURLWithPath: "/tmp/a.txt")
        let b = URL(fileURLWithPath: "/tmp/b.txt")
        let selection = ShelfSelection(candidates: [a, b], existing: [a], capacity: 0)
        XCTAssertEqual(selection.duplicateCount, 1)
        XCTAssertEqual(selection.overflowCount, 1)
        XCTAssertTrue(selection.accepted.isEmpty)
    }
}
