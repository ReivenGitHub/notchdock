import Foundation
import XCTest
@testable import NotchDockCore

final class ShortcutBindingTests: XCTestCase {
    func testDefaultKeepsExistingShortcut() {
        XCTAssertTrue(ShortcutBinding.standard.isValid)
        XCTAssertEqual(ShortcutBinding.standard.keyCode, 49)
        XCTAssertEqual(ShortcutBinding.standard.label, "⌥⌘Space")
    }
    func testPlainAndShiftOnlyKeysCannotHijackTyping() {
        XCTAssertFalse(ShortcutBinding(keyCode: 0, modifiers: [], keyName: "A").isValid)
        XCTAssertFalse(ShortcutBinding(keyCode: 0, modifiers: [.shift], keyName: "A").isValid)
        XCTAssertTrue(ShortcutBinding(keyCode: 0, modifiers: [.control, .shift], keyName: "A").isValid)
    }
    func testEscapeModifiersAndInvalidSavedValuesAreRejected() {
        for code: UInt32 in [53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 128] {
            XCTAssertFalse(ShortcutBinding(keyCode: code, modifiers: [.command], keyName: "Key").isValid)
        }
        XCTAssertFalse(ShortcutBinding(keyCode: 0, modifiers: .init(rawValue: 17), keyName: "A").isValid)
        XCTAssertFalse(ShortcutBinding(keyCode: 0, modifiers: [.command], keyName: "").isValid)
    }
    func testCustomAndDisabledBindingsRoundTrip() throws {
        let binding = ShortcutBinding(keyCode: 8, modifiers: [.control, .option, .shift], keyName: "C")
        let data = try JSONEncoder().encode(binding)
        XCTAssertEqual(try JSONDecoder().decode(ShortcutBinding.self, from: data), binding)
        XCTAssertEqual(binding.label, "⌃⌥⇧C")
        let disabled: ShortcutBinding? = nil
        XCTAssertNil(try JSONDecoder().decode(ShortcutBinding?.self, from: JSONEncoder().encode(disabled)))
    }
}
