import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public struct OverlayGeometry: Equatable {
    public enum Mode: CaseIterable { case idle, activity, expanded }
    public let screen: CGRect
    public let safeTop: CGFloat
    public let hardwareWidth: CGFloat
    public init(screen: CGRect, safeTop: CGFloat, hardwareWidth: CGFloat) {
        self.screen = screen
        self.safeTop = max(0, safeTop)
        self.hardwareWidth = max(0, hardwareWidth)
    }
    public var topPadding: CGFloat { safeTop > 0 ? safeTop + 8 : 16 }
    public var hasHardwareNotch: Bool { safeTop > 0 && hardwareWidth > 0 }
    /// The idle window is transparent: its two-point lip catches hover/drop below the camera.
    /// No pixels, border, or controls are drawn outside the physical notch while idle.
    public var idleSize: CGSize {
        hasHardwareNotch ? CGSize(width: hardwareWidth, height: safeTop + 2) : CGSize(width: 120, height: 28)
    }
    public var compactSize: CGSize {
        CGSize(width: min(screen.width - 24, max(204, hardwareWidth + 124)), height: max(34, safeTop + 7))
    }
    public var expandedSize: CGSize { CGSize(width: min(580, screen.width - 24), height: topPadding + 312) }
    public func frame(expanded: Bool) -> CGRect {
        frame(mode: expanded ? .expanded : .activity)
    }
    public func frame(mode: Mode) -> CGRect {
        let size: CGSize
        switch mode {
        case .idle: size = idleSize
        case .activity: size = compactSize
        case .expanded: size = expandedSize
        }
        return CGRect(x: screen.midX - size.width / 2, y: screen.maxY - size.height, width: size.width, height: size.height)
    }
}
