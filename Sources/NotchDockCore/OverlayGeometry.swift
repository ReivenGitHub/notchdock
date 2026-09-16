import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public struct OverlayGeometry: Equatable {
    public let screen: CGRect
    public let safeTop: CGFloat
    public let hardwareWidth: CGFloat
    public init(screen: CGRect, safeTop: CGFloat, hardwareWidth: CGFloat) {
        self.screen = screen
        self.safeTop = max(0, safeTop)
        self.hardwareWidth = max(0, hardwareWidth)
    }
    public var topPadding: CGFloat { safeTop > 0 ? safeTop + 8 : 16 }
    public var compactSize: CGSize {
        CGSize(width: min(screen.width - 24, max(204, hardwareWidth + 124)), height: max(34, safeTop + 7))
    }
    public var expandedSize: CGSize { CGSize(width: min(580, screen.width - 24), height: topPadding + 272) }
    public func frame(expanded: Bool) -> CGRect {
        let size = expanded ? expandedSize : compactSize
        return CGRect(x: screen.midX - size.width / 2, y: screen.maxY - size.height, width: size.width, height: size.height)
    }
}
