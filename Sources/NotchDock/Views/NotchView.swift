import SwiftUI
import UniformTypeIdentifiers
import NotchDockCore

struct NotchView: View {
    @EnvironmentObject private var state: PanelState
    @EnvironmentObject private var shelf: ShelfStore
    @EnvironmentObject private var focus: FocusStore
    @EnvironmentObject private var battery: BatteryService
    @EnvironmentObject private var media: MediaService
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var airDrop: AirDropService
    var body: some View {
        GeometryReader { geometry in
            content
                .onDrop(of: [UTType.fileURL], delegate: NotchFileDrop(
                    update: { location in
                        if !state.dropTargeted { state.dropTargeted = true; state.targetChanged(true) }
                        let target = destination(at: location, width: geometry.size.width)
                        if state.dropDestination != target { state.dropDestination = target }
                    },
                    exit: finishDrop,
                    perform: { info in
                        let target = destination(at: info.location, width: geometry.size.width)
                        let providers = info.itemProviders(for: [UTType.fileURL])
                        let accepted = target == .airDrop ? airDrop.acceptDrop(providers) : shelf.acceptDrop(providers)
                        finishDrop()
                        return accepted
                    }))
        }
    }
    private var content: some View {
        Group {
            if state.blendsIntoNotch {
                // The physical camera housing is already black. Do not draw an extra bar.
                Color.clear.contentShape(Rectangle()).onTapGesture(perform: state.togglePanel)
                    .accessibilityLabel("Open NotchDock").accessibilityAddTraits(.isButton)
                    .accessibilityAction { state.togglePanel() }
            } else {
                Group { if state.expanded { expanded } else { compact } }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(DockShape().fill(Color.black))
                    .overlay(DockShape().stroke(DockTheme.border, lineWidth: 0.75))
                    .clipShape(DockShape()).contentShape(DockShape())
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .foregroundStyle(.white)
            .preferredColorScheme(.dark)
            .onHover { state.pointerChanged($0) }
    }
    private func destination(at point: CGPoint, width: CGFloat) -> FileDropDestination {
        FileDropLayout.destination(at: point, panelWidth: width, topPadding: state.topPadding,
                                   shelfVisible: state.expanded && state.tab == .shelf)
    }
    private func finishDrop() {
        state.dropTargeted = false
        state.dropDestination = nil
        state.targetChanged(false)
    }
    private var compact: some View {
        Button {
            if media.track.playing { state.tab = .overview }
            state.togglePanel()
        } label: {
            GeometryReader { geometry in
                let wing = max(0, (geometry.size.width - state.hardwareNotchWidth) / 2)
                HStack(spacing: 0) {
                    Group {
                        if media.track.playing {
                            AlbumArtwork(size: min(26, geometry.size.height - 8))
                        } else {
                            Image(systemName: focus.hasActiveSession ? focus.mode.symbol : "sparkle")
                                .font(.system(size: 12, weight: .semibold)).foregroundStyle(DockTheme.accent)
                        }
                    }.frame(width: wing, height: geometry.size.height)
                    Color.clear.frame(width: state.hardwareNotchWidth)
                    Group {
                        if focus.hasActiveSession {
                            Text(focus.label).font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(focus.isRunning ? .white : DockTheme.muted)
                        } else {
                            Image(systemName: media.track.playing ? "waveform" : "chevron.down")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }.frame(width: wing, height: geometry.size.height)
                }
            }
        }.buttonStyle(.plain).accessibilityLabel("Open NotchDock")
            .help("Open NotchDock" + (preferences.shortcut.map { " · " + $0.label } ?? ""))
    }
    private var expanded: some View {
        VStack(spacing: 16) {
            header.frame(height: 28)
            Group {
                switch state.tab {
                case .overview: OverviewView()
                case .shelf: ShelfView()
                case .focus: FocusView()
                case .mirror: MirrorView()
                }
            }.frame(height: 214)
            footer.frame(height: 20)
        }.padding(.horizontal, FileDropLayout.sideInset).padding(.top, state.topPadding).padding(.bottom, 16)
    }
    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkle").foregroundStyle(DockTheme.accent).font(.system(size: 15, weight: .medium))
            Text("NotchDock").font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 6)
            HStack(spacing: 2) {
                ForEach(PanelTab.allCases) { tab in
                    Button { state.tab = tab } label: {
                        Text(tab.rawValue).font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .foregroundStyle(state.tab == tab ? .white : DockTheme.muted)
                            .background(state.tab == tab ? Color.white.opacity(0.1) : .clear, in: Capsule())
                    }.buttonStyle(.plain).accessibilityAddTraits(state.tab == tab ? .isSelected : [])
                }
            }
            IconButton(symbol: state.pinned ? "pin.fill" : "pin", label: state.pinned ? "Unpin panel" : "Keep panel open",
                       active: state.pinned) { state.pinned.toggle() }
            IconButton(symbol: "gearshape", label: "Open settings", action: state.showSettings)
        }
    }
    private var footer: some View {
        HStack(spacing: 7) {
            Circle().fill(DockTheme.accent).frame(width: 4, height: 4)
            Text(state.dropTargeted ? (state.dropDestination == .airDrop ? "Drop to choose an AirDrop recipient" : "Drop to add to Files Tray") : "A little space. A clearer day.").font(.system(size: 10))
            Spacer()
            Image(systemName: battery.symbol)
            Text(battery.label).monospacedDigit()
            Divider().frame(height: 10).padding(.horizontal, 3)
            Button(action: state.closePanel) {
                HStack(spacing: 4) { Text("Close"); Image(systemName: "chevron.up") }
            }.buttonStyle(.plain).help("Close panel (Escape)")
        }.font(.system(size: 10)).foregroundStyle(DockTheme.muted)
    }
}

private struct NotchFileDrop: DropDelegate {
    let update: (CGPoint) -> Void
    let exit: () -> Void
    let perform: (DropInfo) -> Bool
    func validateDrop(info: DropInfo) -> Bool { info.hasItemsConforming(to: [UTType.fileURL]) }
    func dropEntered(info: DropInfo) { update(info.location) }
    func dropUpdated(info: DropInfo) -> DropProposal? { update(info.location); return DropProposal(operation: .copy) }
    func dropExited(info: DropInfo) { exit() }
    func performDrop(info: DropInfo) -> Bool { perform(info) }
}
