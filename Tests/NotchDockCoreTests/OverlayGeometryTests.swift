import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import XCTest
@testable import NotchDockCore

final class OverlayGeometryTests: XCTestCase {
    func testNotchedScreenKeepsContentBelowCameraAndWingsBesideIt() {
        let geometry = OverlayGeometry(screen: CGRect(x: 0, y: 0, width: 1_512, height: 982), safeTop: 32, hardwareWidth: 184)
        XCTAssertEqual(geometry.topPadding, 40)
        XCTAssertGreaterThan(geometry.compactSize.width, geometry.hardwareWidth)
        XCTAssertGreaterThan(geometry.compactSize.height, geometry.safeTop)
    }
    func testExpandedAndCollapsedFramesStayAnchoredAtTopCenter() {
        let geometry = OverlayGeometry(screen: CGRect(x: 0, y: 0, width: 1_440, height: 900), safeTop: 0, hardwareWidth: 0)
        for expanded in [false, true] {
            let frame = geometry.frame(expanded: expanded)
            XCTAssertEqual(frame.maxY, 900)
            XCTAssertEqual(frame.midX, 720)
        }
    }
    func testSecondaryDisplayCanHaveNegativeCoordinates() {
        let screen = CGRect(x: -1_920, y: -180, width: 1_920, height: 1_080)
        let frame = OverlayGeometry(screen: screen, safeTop: 0, hardwareWidth: 0).frame(expanded: true)
        XCTAssertEqual(frame.midX, -960)
        XCTAssertEqual(frame.maxY, 900)
        XCTAssertTrue(screen.contains(frame))
    }
    func testNarrowScreenDoesNotOverflowHorizontally() {
        let screen = CGRect(x: 300, y: 0, width: 500, height: 800)
        let geometry = OverlayGeometry(screen: screen, safeTop: 0, hardwareWidth: 0)
        XCTAssertEqual(geometry.expandedSize.width, 476)
        XCTAssertTrue(screen.contains(geometry.frame(expanded: true)))
    }
}
