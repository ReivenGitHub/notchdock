import SwiftUI
import NotchDockCore

struct FocusView: View {
    @EnvironmentObject private var focus: FocusStore
    var body: some View {
        HStack(spacing: 22) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 5)
                Circle().trim(from: 0, to: focus.progress)
                    .stroke(DockTheme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                VStack(spacing: 5) {
                    Text(focus.label).font(.system(size: 28, weight: .light, design: .rounded)).monospacedDigit()
                    Text(focus.mode == .focus ? "FOCUS" : "RECHARGE")
                        .font(.system(size: 7, weight: .semibold)).tracking(1.5).foregroundStyle(DockTheme.muted)
                }
            }.frame(width: 116, height: 116)
                .accessibilityElement(children: .ignore).accessibilityLabel("\(focus.mode.title) timer, \(focus.label) remaining")
            VStack(alignment: .leading, spacing: 11) {
                HStack(spacing: 6) {
                    ForEach(FocusMode.allCases) { mode in
                        Button { focus.choose(mode: mode) } label: {
                            Text(mode.title).font(.system(size: 10, weight: .medium)).padding(.horizontal, 9).padding(.vertical, 7)
                                .foregroundStyle(focus.mode == mode ? DockTheme.accent : DockTheme.muted)
                                .background(Color.white.opacity(0.05), in: Capsule())
                        }.buttonStyle(.plain).disabled(focus.hasActiveSession)
                            .accessibilityAddTraits(focus.mode == mode ? .isSelected : [])
                    }
                }
                Text(focus.storageError ?? focus.status).font(.system(size: 10)).foregroundStyle(DockTheme.muted).lineLimit(2)
                HStack(spacing: 12) {
                    AccentButton(title: focus.isRunning ? "Pause" : (focus.session.phase == .paused ? "Resume" : "Start session"),
                                 symbol: focus.isRunning ? "pause.fill" : "play.fill", action: focus.toggle)
                    Button("Reset", action: focus.reset).font(.system(size: 10)).foregroundStyle(DockTheme.muted).buttonStyle(.plain)
                }
                Text("Today · \(focus.today.sessions) sessions · \(focus.today.minutes) min focused")
                    .font(.system(size: 9)).foregroundStyle(DockTheme.muted)
            }
            Spacer(minLength: 0)
        }.padding(18).frame(maxWidth: .infinity, maxHeight: .infinity).dockCard()
    }
}
