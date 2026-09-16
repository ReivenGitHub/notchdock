import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var focus: FocusStore
    var body: some View {
        HStack(spacing: 26) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 5)
                Circle().trim(from: 0, to: focus.progress)
                    .stroke(DockTheme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                VStack(spacing: 5) {
                    Text(focus.label).font(.system(size: 31, weight: .light, design: .rounded)).monospacedDigit()
                    Text(focus.isRunning ? "IN THE FLOW" : "YOUR TIME")
                        .font(.system(size: 7, weight: .semibold)).tracking(1.5).foregroundStyle(DockTheme.muted)
                }
            }.frame(width: 128, height: 128)
                .accessibilityElement(children: .ignore).accessibilityLabel("Focus timer, \(focus.label) remaining")
            VStack(alignment: .leading, spacing: 12) {
                Text(focus.session.phase == .finished ? "A little pause, well earned." : "Space to do your best work.")
                    .font(.system(size: 15, weight: .medium))
                Text(focus.storageError ?? focus.status).font(.system(size: 10)).foregroundStyle(DockTheme.muted).lineLimit(2)
                HStack(spacing: 6) {
                    ForEach([15, 25, 50], id: \.self) { minutes in
                        Button { focus.choose(minutes: minutes) } label: {
                            Text("\(minutes) min").font(.system(size: 10, weight: .medium)).padding(.horizontal, 11).padding(.vertical, 7)
                                .foregroundStyle(focus.session.duration == Double(minutes * 60) ? DockTheme.accent : DockTheme.muted)
                                .background(Color.white.opacity(0.05), in: Capsule())
                        }.buttonStyle(.plain).disabled(focus.isRunning || focus.session.phase == .paused)
                    }
                }
                HStack(spacing: 12) {
                    AccentButton(title: focus.isRunning ? "Pause" : (focus.session.phase == .paused ? "Resume" : "Start session"),
                                 symbol: focus.isRunning ? "pause.fill" : "play.fill", action: focus.toggle)
                    Button("Reset", action: focus.reset).font(.system(size: 10)).foregroundStyle(DockTheme.muted).buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }.padding(18).frame(maxWidth: .infinity, maxHeight: .infinity).dockCard()
    }
}
