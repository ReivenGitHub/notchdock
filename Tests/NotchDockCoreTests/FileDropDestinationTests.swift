import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import XCTest
@testable import NotchDockCore

final class FileDropDestinationTests: XCTestCase {
    func testRightTargetRoutesToAirDrop() {
        XCTAssertEqual(FileDropLayout.destination(at: CGPoint(x: 430, y: 110), panelWidth: 580,
                                                  topPadding: 40, shelfVisible: true), .airDrop)
    }
    func testTrayGapHeaderAndCardsNeverRouteToAirDrop() {
        for point in [CGPoint(x: 100, y: 110), CGPoint(x: 290, y: 110), CGPoint(x: 430, y: 50), CGPoint(x: 430, y: 180)] {
            XCTAssertEqual(FileDropLayout.destination(at: point, panelWidth: 580, topPadding: 40, shelfVisible: true), .tray)
        }
    }
    func testOtherTabsAndCollapsedNotchAlwaysRouteToTray() {
        XCTAssertEqual(FileDropLayout.destination(at: CGPoint(x: 430, y: 110), panelWidth: 580,
                                                  topPadding: 40, shelfVisible: false), .tray)
    }
    func testTargetFollowsPanelWidthAndCameraPadding() {
        XCTAssertEqual(FileDropLayout.destination(at: CGPoint(x: 350, y: 140), panelWidth: 500,
                                                  topPadding: 80, shelfVisible: true), .airDrop)
        XCTAssertEqual(FileDropLayout.destination(at: CGPoint(x: 350, y: 100), panelWidth: 500,
                                                  topPadding: 80, shelfVisible: true), .tray)
    }
}
