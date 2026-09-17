import AppKit
import NotchDockCore
import SwiftUI

struct ShortcutRecorder: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var state: PanelState
    @State private var error: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Toggle panel")
                Spacer()
                Button(state.recordingShortcut ? "Press shortcut…" : preferences.shortcut?.label ?? "Disabled") {
                    error = nil
                    state.recordingShortcut.toggle()
                }.help("Record a shortcut with Command, Option, or Control. Escape cancels.")
                Button("Reset") { state.recordingShortcut = false; preferences.shortcut = .standard; error = nil }
                Button("Disable") { state.recordingShortcut = false; preferences.shortcut = nil; error = nil }
            }
            if state.recordingShortcut {
                Text(error ?? "Press a key with ⌘, ⌥, or ⌃. Escape cancels.").font(.caption).foregroundStyle(.secondary)
                KeyCapture { event in
                    if event.keyCode == 53 { state.recordingShortcut = false; return }
                    guard !event.isARepeat else { return }
                    let binding = Self.binding(for: event)
                    guard binding.isValid else { error = "Include Command, Option, or Control."; return }
                    preferences.shortcut = binding
                    state.recordingShortcut = false
                }.frame(width: 1, height: 1).accessibilityHidden(true)
            } else if preferences.shortcut != nil && !state.shortcutAvailable {
                Text("That shortcut is unavailable. Choose another combination or use the menu bar.")
                    .font(.caption).foregroundStyle(.orange)
            }
        }.onDisappear { state.recordingShortcut = false }
    }
    private static func binding(for event: NSEvent) -> ShortcutBinding {
        var modifiers: ShortcutModifiers = []
        if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
        if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
        if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
        if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        let names: [UInt16: String] = [49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 117: "Forward Delete",
                                     123: "←", 124: "→", 125: "↓", 126: "↑", 115: "Home", 119: "End",
                                     116: "Page Up", 121: "Page Down", 122: "F1", 120: "F2", 99: "F3",
                                     118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9",
                                     109: "F10", 103: "F11", 111: "F12"]
        let name = names[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
        return ShortcutBinding(keyCode: UInt32(event.keyCode), modifiers: modifiers, keyName: name)
    }
}

private struct KeyCapture: NSViewRepresentable {
    let onKey: (NSEvent) -> Void
    func makeNSView(context: Context) -> CaptureView { CaptureView(onKey: onKey) }
    func updateNSView(_ view: CaptureView, context: Context) { view.onKey = onKey }

    final class CaptureView: NSView {
        var onKey: (NSEvent) -> Void
        init(onKey: @escaping (NSEvent) -> Void) { self.onKey = onKey; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }
        override var acceptsFirstResponder: Bool { true }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in guard let self else { return }; self.window?.makeFirstResponder(self) }
        }
        override func keyDown(with event: NSEvent) { onKey(event) }
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard window?.firstResponder === self else { return false }
            onKey(event)
            return true
        }
    }
}
