import AppKit
import AVFoundation
import Combine

/// All configuration and blocking capture operations run on one private queue.
private final class MirrorCapture {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "app.notchdock.mirror", qos: .userInitiated)
    func start(completion: @escaping (Bool, String) -> Void) {
        queue.async { [self] in
            guard let device = AVCaptureDevice.default(for: .video) else {
                completion(false, "No camera found. Connect a camera and try again.")
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                session.beginConfiguration()
                session.inputs.forEach { session.removeInput($0) }
                if session.canSetSessionPreset(.medium) { session.sessionPreset = .medium }
                guard session.canAddInput(input) else {
                    session.commitConfiguration()
                    completion(false, "This camera is unavailable. Close other camera apps and retry.")
                    return
                }
                session.addInput(input)
                session.commitConfiguration()
                session.startRunning()
                completion(session.isRunning, session.isRunning ? device.localizedName : "The camera could not start. Try again.")
            } catch {
                completion(false, "The camera is unavailable. Check camera access and try again.")
            }
        }
    }
    func stop() {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
            session.beginConfiguration()
            session.inputs.forEach { session.removeInput($0) }
            session.commitConfiguration()
        }
    }
}

@MainActor
final class MirrorService: ObservableObject {
    enum State: Equatable { case off, requesting, starting, running, denied, unavailable(String) }
    @Published private(set) var state: State = .off
    @Published private(set) var cameraName = "Camera"
    @Published var mirrored = true
    private let capture = MirrorCapture()
    private var generation = 0
    private var requested = false
    private var workspaceObservers: [NSObjectProtocol] = []
    private var captureObservers: [NSObjectProtocol] = []
    var session: AVCaptureSession { capture.session }

    init() {
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {
            workspaceObservers.append(workspace.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.stop() }
            })
        }
        for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification] {
            captureObservers.append(NotificationCenter.default.addObserver(forName: name, object: capture.session, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.requested else { return }
                    self.stop()
                    self.state = .unavailable("Camera interrupted. Close other camera apps and retry.")
                }
            })
        }
    }
    func setVisible(_ visible: Bool) { if visible { start() } else { stop() } }
    func start() {
        guard !requested else { return }
        requested = true
        generation += 1
        let ticket = generation
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: beginCapture(ticket: ticket)
        case .notDetermined:
            state = .requesting
            AVCaptureDevice.requestAccess(for: .video) { [weak self] allowed in
                Task { @MainActor in
                    guard let self, self.requested, self.generation == ticket else { return }
                    if allowed { self.beginCapture(ticket: ticket) }
                    else { self.requested = false; self.state = .denied }
                }
            }
        case .denied, .restricted: requested = false; state = .denied
        @unknown default: requested = false; state = .denied
        }
    }
    private func beginCapture(ticket: Int) {
        guard requested, ticket == generation else { return }
        state = .starting
        capture.start { [weak self] running, message in
            Task { @MainActor in
                guard let self, self.requested, self.generation == ticket else { return }
                if running { self.cameraName = message; self.state = .running }
                else { self.requested = false; self.capture.stop(); self.state = .unavailable(message) }
            }
        }
    }
    func stop() {
        requested = false
        generation += 1
        state = .off
        capture.stop()
    }
    func openCameraSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
            NSWorkspace.shared.open(url)
        }
    }
    func shutdown() {
        stop()
        workspaceObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        captureObservers.forEach { NotificationCenter.default.removeObserver($0) }
        workspaceObservers.removeAll()
        captureObservers.removeAll()
    }
}
