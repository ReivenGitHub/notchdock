import Combine
import Foundation
import NotchDockCore

enum PanelTab: String, CaseIterable, Identifiable, Hashable {
    case overview = "Overview", shelf = "Files", focus = "Focus", mirror = "Mirror"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .shelf: return "tray"
        case .focus: return "timer"
        case .mirror: return "web.camera"
        }
    }
}

@MainActor
final class PanelState: ObservableObject {
    @Published var expanded = false
    @Published var presentingExpandedContent = false
    @Published var contentVisible = false
    @Published var expandedContentWidth: CGFloat = 580
    @Published var pinned = false
    @Published var tab: PanelTab = .overview
    @Published var topPadding: CGFloat = 16
    @Published var dropTargeted = false
    @Published var dropDestination: FileDropDestination?
    @Published var shortcutAvailable = true
    @Published var recordingShortcut = false
    @Published var layoutMode: OverlayGeometry.Mode = .idle
    @Published var hardwareNotchWidth: CGFloat = 0
    @Published var blendsIntoNotch = false
    var showSettings: () -> Void = {}
    var togglePanel: () -> Void = {}
    var closePanel: () -> Void = {}
    var pointerChanged: (Bool) -> Void = { _ in }
    var targetChanged: (Bool) -> Void = { _ in }
    var beginInteraction: () -> Void = {}
    var endInteraction: () -> Void = {}
}
