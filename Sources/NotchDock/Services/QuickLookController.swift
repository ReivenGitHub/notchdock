import AppKit
import Quartz

@MainActor
final class QuickLookController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var preview: QLPreviewView?
    func show(_ url: URL) {
        if window == nil {
            let frame = NSRect(x: 0, y: 0, width: 680, height: 480)
            guard let view = QLPreviewView(frame: frame, style: .normal) else { return }
            let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .resizable, .miniaturizable],
                                  backing: .buffered, defer: false)
            view.autostarts = false
            window.contentView = view
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            self.window = window
            preview = view
        }
        preview?.previewItem = url as NSURL
        window?.title = url.lastPathComponent
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    func windowWillClose(_ notification: Notification) { preview?.previewItem = nil }
}
