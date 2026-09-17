import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public enum FileDropDestination: Equatable { case tray, airDrop }

/// One drop handler routes each drop exactly once; the visible targets use these same dimensions.
public enum FileDropLayout {
    public static let sideInset: CGFloat = 24
    public static let columnSpacing: CGFloat = 10
    public static let zoneHeight: CGFloat = 56
    public static let contentOffset: CGFloat = 44 // Header (28) + vertical spacing (16).

    public static func destination(at point: CGPoint, panelWidth: CGFloat,
                                   topPadding: CGFloat, shelfVisible: Bool) -> FileDropDestination {
        guard shelfVisible else { return .tray }
        let column = max(0, (panelWidth - sideInset * 2 - columnSpacing) / 2)
        let airDrop = CGRect(x: sideInset + column + columnSpacing, y: topPadding + contentOffset,
                             width: column, height: zoneHeight)
        return airDrop.contains(point) ? .airDrop : .tray
    }
}
