import AppKit
import AVFoundation
import SwiftUI

struct MirrorView: View {
    @EnvironmentObject private var mirror: MirrorService
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Color.black
                CameraPreview(session: mirror.session, mirrored: mirror.mirrored)
                    .opacity(mirror.state == .running ? 1 : 0)
                if mirror.state != .running {
                    VStack(spacing: 10) {
                        Image(systemName: "web.camera").font(.system(size: 28, weight: .light)).foregroundStyle(DockTheme.accent)
                        if mirror.state == .starting || mirror.state == .requesting {
                            ProgressView().controlSize(.small)
                        } else { Text("Camera off").font(.system(size: 11)).foregroundStyle(DockTheme.muted) }
                    }
                }
            }.frame(width: 272, height: 180).clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel(mirror.state == .running ? "Live camera mirror" : "Camera off")
            VStack(alignment: .leading, spacing: 10) {
                Label("Mirror", systemImage: "web.camera").font(.system(size: 16, weight: .medium))
                Text(message).font(.system(size: 10)).foregroundStyle(DockTheme.muted).fixedSize(horizontal: false, vertical: true)
                if mirror.state == .running {
                    Toggle("Flip horizontally", isOn: $mirror.mirrored).toggleStyle(.checkbox).font(.system(size: 10))
                    AccentButton(title: "Turn camera off", symbol: "power", action: mirror.stop)
                } else if mirror.state == .denied {
                    Button("Camera settings", action: mirror.openCameraSettings).buttonStyle(.plain).foregroundStyle(DockTheme.accent)
                    Button("Retry", action: mirror.start).buttonStyle(.plain).foregroundStyle(.white)
                } else if mirror.state != .starting && mirror.state != .requesting {
                    AccentButton(title: "Start mirror", symbol: "video", action: mirror.start)
                }
                Spacer(minLength: 0)
                Text("Live preview only. No photos, recordings, or microphone.")
                    .font(.system(size: 9)).foregroundStyle(DockTheme.muted)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity).dockCard()
    }
    private var message: String {
        switch mirror.state {
        case .off: return "A quick check, right at your notch."
        case .requesting: return "Allow camera access in the macOS prompt."
        case .starting: return "Starting camera…"
        case .running: return mirror.cameraName + " · turns off when you leave Mirror."
        case .denied: return "Allow NotchDock in System Settings → Privacy & Security → Camera, then retry."
        case .unavailable(let message): return message
        }
    }
}

private struct CameraPreview: NSViewRepresentable {
    let session: AVCaptureSession
    let mirrored: Bool
    func makeNSView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.preview.session = session
        view.setMirrored(mirrored)
        return view
    }
    func updateNSView(_ view: PreviewView, context: Context) { view.setMirrored(mirrored) }
    static func dismantleNSView(_ view: PreviewView, coordinator: ()) { view.preview.session = nil }

    final class PreviewView: NSView {
        let preview = AVCaptureVideoPreviewLayer()
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            preview.videoGravity = .resizeAspectFill
            layer?.addSublayer(preview)
        }
        required init?(coder: NSCoder) { nil }
        override func layout() {
            super.layout()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            preview.frame = bounds
            CATransaction.commit()
        }
        func setMirrored(_ value: Bool) {
            guard let connection = preview.connection, connection.isVideoMirroringSupported else { return }
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = value
        }
    }
}
