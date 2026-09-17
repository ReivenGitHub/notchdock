import AppKit
import Combine
import CoreGraphics

struct DisplayChoice: Identifiable {
    let id: String
    let name: String
}

@MainActor
final class DisplayService: ObservableObject {
    @Published private(set) var choices: [DisplayChoice] = []
    private var observer: NSObjectProtocol?
    init() {
        refresh()
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
    }
    private func refresh() {
        choices = NSScreen.screens.compactMap { screen in
            guard let id = Self.identifier(for: screen) else { return nil }
            return DisplayChoice(id: id, name: screen.localizedName)
        }
    }
    func screen(for target: String) -> NSScreen? {
        let screens = NSScreen.screens
        if target == "primary" { return screens.first }
        if let chosen = screens.first(where: { Self.identifier(for: $0) == target }) { return chosen }
        // Keep the saved UUID so reconnecting a preferred monitor restores its placement.
        return screens.first { $0.safeAreaInsets.top > 0 } ?? screens.first
    }
    private static func identifier(for screen: NSScreen) -> String? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let uuid = CGDisplayCreateUUIDFromDisplayID(number.uint32Value)?.takeRetainedValue() else { return nil }
        return "display:" + (CFUUIDCreateString(nil, uuid) as String)
    }
    func stop() {
        if let observer { NotificationCenter.default.removeObserver(observer); self.observer = nil }
    }
}
