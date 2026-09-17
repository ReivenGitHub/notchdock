import AppKit
import Combine
import NotchDockCore
import SwiftUI

private final class NotchPanel: NSPanel {
    var dismiss: () -> Void = {}
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func cancelOperation(_ sender: Any?) { dismiss() }
}

@MainActor
final class PanelController {
    private let panel: NotchPanel
    private let state: PanelState
    private let preferences: Preferences
    private let media: MediaService
    private let shelf: ShelfStore
    private let focus: FocusStore
    private let displays: DisplayService
    private let mirror: MirrorService
    private var subscriptions = Set<AnyCancellable>()
    private var openWork: DispatchWorkItem?
    private var closeWork: DispatchWorkItem?
    private var pointerInside = false
    private var interactionCount = 0
    private var screenObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var keyObserver: NSObjectProtocol?
    private var globalPointerMonitor: Any?
    private var localPointerMonitor: Any?

    init(state: PanelState, preferences: Preferences, media: MediaService,
         shelf: ShelfStore, focus: FocusStore, battery: BatteryService, displays: DisplayService,
         airDrop: AirDropService, mirror: MirrorService) {
        self.state = state
        self.preferences = preferences
        self.media = media
        self.shelf = shelf
        self.focus = focus
        self.displays = displays
        self.mirror = mirror
        panel = NotchPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.acceptsMouseMovedEvents = true
        panel.animationBehavior = .none
        panel.title = "NotchDock"
        let hostingView = NSHostingView(rootView: NotchView()
            .environmentObject(state).environmentObject(preferences).environmentObject(media)
            .environmentObject(shelf).environmentObject(focus).environmentObject(battery)
            .environmentObject(airDrop).environmentObject(mirror))
        hostingView.sizingOptions = []
        panel.contentView = hostingView
        panel.dismiss = { [weak self] in self?.collapse() }
        state.togglePanel = { [weak self] in self?.toggle() }
        state.closePanel = { [weak self] in self?.collapse() }
        state.pointerChanged = { [weak self] inside in self?.pointerChanged(inside) }
        state.targetChanged = { [weak self] targeted in
            guard let self else { return }
            if targeted { self.cancelPending(); self.state.tab = .shelf; self.expand() }
            else { self.scheduleClose() }
        }
        state.beginInteraction = { [weak self] in self?.interactionCount += 1; self?.cancelPending() }
        state.endInteraction = { [weak self] in
            guard let self else { return }
            self.interactionCount = max(0, self.interactionCount - 1)
            self.scheduleClose()
        }
        state.$expanded.removeDuplicates().sink { [weak self] expanded in
            self?.layout(expanded: expanded, animated: true)
            self?.media.setVisible(expanded)
            if expanded { self?.shelf.refresh() }
        }.store(in: &subscriptions)
        state.$pinned.dropFirst().sink { [weak self] pinned in
            if !pinned { DispatchQueue.main.async { self?.scheduleClose() } }
        }.store(in: &subscriptions)
        state.$expanded.combineLatest(state.$tab).map { $0 && $1 == .mirror }.removeDuplicates()
            .sink { [weak self] visible in self?.mirror.setVisible(visible) }.store(in: &subscriptions)
        state.$tab.dropFirst().sink { [weak self] tab in
            if tab != .mirror { DispatchQueue.main.async { self?.scheduleClose() } }
        }.store(in: &subscriptions)
        preferences.$displayTarget.combineLatest(preferences.$hideWhenIdle).dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { guard let self else { return }; self.layout(expanded: self.state.expanded) }
        }.store(in: &subscriptions)
        focus.$archive.map { $0.session.phase }.removeDuplicates().dropFirst().sink { [weak self] _ in
            self?.scheduleActivityLayout()
        }.store(in: &subscriptions)
        media.$track.map(\.playing).removeDuplicates().dropFirst().sink { [weak self] _ in
            self?.scheduleActivityLayout()
        }.store(in: &subscriptions)
        keyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: panel, queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.scheduleClose() } }
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in guard let self else { return }; self.layout(expanded: self.state.expanded) }
        }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in guard let self else { return }; self.layout(expanded: self.state.expanded) }
        }
        // Transparent pixels may pass events through to the application underneath.
        // Observe only pointer events, never keys, and do not consume other apps' events.
        let pointerEvents: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .leftMouseDown]
        globalPointerMonitor = NSEvent.addGlobalMonitorForEvents(matching: pointerEvents) { [weak self] event in
            self?.trackIdlePointer(event, allowClick: true)
        }
        localPointerMonitor = NSEvent.addLocalMonitorForEvents(matching: pointerEvents) { [weak self] event in
            if let self { self.trackIdlePointer(event, allowClick: event.window !== self.panel) }
            return event
        }
        layout(expanded: false)
        panel.orderFrontRegardless()
    }
    func toggle() {
        if state.expanded { collapse() }
        else { expand(); panel.makeKey() }
    }
    func expand() { cancelPending(); state.expanded = true; panel.orderFrontRegardless() }
    func collapse() { cancelPending(); state.pinned = false; state.expanded = false }
    func focusFinished() {
        state.tab = .focus
        expand()
        let work = DispatchWorkItem { [weak self] in self?.scheduleClose() }
        closeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }
    private func pointerChanged(_ inside: Bool) {
        pointerInside = inside
        cancelPending()
        if inside, preferences.expandOnHover, !state.expanded {
            let work = DispatchWorkItem { [weak self] in self?.expand() }
            openWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: work)
        } else if !inside { scheduleClose() }
    }
    private func trackIdlePointer(_ event: NSEvent, allowClick: Bool) {
        guard state.blendsIntoNotch, !state.expanded else { return }
        let inside = panel.frame.contains(NSEvent.mouseLocation)
        if inside, event.type == .leftMouseDragged {
            state.tab = .shelf
            expand()
        } else if inside, event.type == .leftMouseDown, allowClick {
            toggle()
        } else if inside != pointerInside {
            pointerChanged(inside)
        }
    }
    private func scheduleClose() {
        closeWork?.cancel()
        guard state.expanded, state.tab != .mirror, !state.pinned, !state.dropTargeted, !pointerInside,
              interactionCount == 0, !isEditingText else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.state.tab != .mirror, !self.state.pinned, !self.state.dropTargeted,
                  !self.pointerInside, self.interactionCount == 0, !self.isEditingText else { return }
            self.state.expanded = false
        }
        closeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }
    private func cancelPending() { openWork?.cancel(); closeWork?.cancel() }
    private var isEditingText: Bool { panel.isKeyWindow && panel.firstResponder is NSTextView }
    private func scheduleActivityLayout() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.state.expanded else { return }
            self.layout(expanded: false, animated: true)
        }
    }
    private func layout(expanded: Bool, animated: Bool = false) {
        guard let screen = displays.screen(for: preferences.displayTarget) else { panel.orderOut(nil); return }
        let notchWidth: CGFloat
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notchWidth = max(0, right.minX - left.maxX)
        } else { notchWidth = 0 }
        let geometry = OverlayGeometry(screen: screen.frame, safeTop: screen.safeAreaInsets.top, hardwareWidth: notchWidth)
        state.topPadding = geometry.topPadding
        let active = focus.hasActiveSession || (preferences.mediaEnabled && media.track.playing)
        let mode: OverlayGeometry.Mode = expanded ? .expanded : (active || !preferences.hideWhenIdle ? .activity : .idle)
        state.layoutMode = mode
        state.hardwareNotchWidth = geometry.hasHardwareNotch ? notchWidth : 0
        state.blendsIntoNotch = geometry.hasHardwareNotch && mode == .idle
        let frame = geometry.frame(mode: mode)
        if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.24
                panel.animator().setFrame(frame, display: true)
            }
        } else { panel.setFrame(frame, display: true) }
        panel.orderFrontRegardless()
    }
    func stop() {
        cancelPending()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
        if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
        if let globalPointerMonitor { NSEvent.removeMonitor(globalPointerMonitor); self.globalPointerMonitor = nil }
        if let localPointerMonitor { NSEvent.removeMonitor(localPointerMonitor); self.localPointerMonitor = nil }
        subscriptions.removeAll()
        panel.orderOut(nil)
    }
}
