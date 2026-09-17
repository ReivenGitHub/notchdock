import SwiftUI

struct OverviewView: View {
    var body: some View {
        HStack(spacing: 12) {
            MusicCard().frame(maxWidth: .infinity, maxHeight: .infinity)
            FocusMiniCard().frame(width: 190, height: 174)
        }
    }
}
private struct MusicCard: View {
    @EnvironmentObject private var media: MediaService
    @EnvironmentObject private var preferences: Preferences
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "waveform").foregroundStyle(DockTheme.accent)
                Text("NOW PLAYING").tracking(1.7)
                Spacer()
                Text(preferences.player.title).foregroundStyle(DockTheme.muted)
            }.font(.system(size: 8, weight: .semibold))
            if !preferences.mediaEnabled {
                Text("Your soundtrack,\nwithin reach.").font(.system(size: 19, weight: .medium))
                Spacer(minLength: 0)
                AccentButton(title: "Connect music", symbol: "music.note", action: media.enable)
            } else if let error = media.error {
                Text(error).font(.system(size: 11)).foregroundStyle(.white.opacity(0.7))
                    .lineLimit(4).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Button("Retry connection", action: media.retry).font(.system(size: 11, weight: .medium))
                    .foregroundStyle(DockTheme.accent).buttonStyle(.plain)
            } else {
                HStack(spacing: 11) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11)
                            .fill(LinearGradient(colors: [DockTheme.accent.opacity(0.28), Color(red: 0.12, green: 0.22, blue: 0.19)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        Image(systemName: "music.note").font(.system(size: 21)).foregroundStyle(DockTheme.accent)
                    }.frame(width: 46, height: 46)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(media.track.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Text(media.track.artist).font(.system(size: 10)).foregroundStyle(DockTheme.muted).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                GeometryReader { geometry in
                    Capsule().fill(Color.white.opacity(0.08))
                        .overlay(alignment: .leading) {
                            Capsule().fill(DockTheme.accent).frame(width: geometry.size.width * media.track.progress)
                        }
                }.frame(height: 3).accessibilityLabel("Playback progress")
                HStack(spacing: 20) {
                    Spacer()
                    transport("backward.end.fill", label: "Previous track") { media.send(.previous) }
                    Button { media.send(.playPause) } label: {
                        Image(systemName: media.track.playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(.black)
                            .frame(width: 32, height: 32).background(DockTheme.accent, in: Circle())
                    }.buttonStyle(.plain).disabled(media.busy).accessibilityLabel(media.track.playing ? "Pause music" : "Play music")
                    transport("forward.end.fill", label: "Next track") { media.send(.next) }
                    Spacer()
                    if !media.track.hasTrack {
                        Button(action: media.openPlayer) { Image(systemName: "arrow.up.right") }
                            .buttonStyle(.plain).help("Open \(preferences.player.title)")
                    }
                }
            }
        }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).dockCard()
    }
    private func transport(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 11)).frame(width: 22, height: 28) }
            .buttonStyle(.plain).disabled(media.busy || !media.track.hasTrack).accessibilityLabel(label).help(label)
    }
}
private struct FocusMiniCard: View {
    @EnvironmentObject private var focus: FocusStore
    @EnvironmentObject private var state: PanelState
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 5) {
                Image(systemName: focus.mode.symbol).foregroundStyle(DockTheme.accent)
                Text(focus.mode.title.uppercased()).tracking(1.2)
                Spacer()
                Button { state.tab = .focus } label: { Image(systemName: "arrow.up.right") }
                    .buttonStyle(.plain).accessibilityLabel("Open focus timer")
            }.font(.system(size: 8, weight: .semibold))
            Text(focus.label).font(.system(size: 35, weight: .light, design: .rounded)).monospacedDigit()
            Text("\(focus.today.minutes) min focused today")
                .font(.system(size: 10)).foregroundStyle(DockTheme.muted)
            Spacer(minLength: 0)
            AccentButton(title: focus.isRunning ? "Pause" : (focus.session.phase == .paused ? "Resume" : "Start \(focus.mode == .focus ? "focus" : "break")"),
                         symbol: focus.isRunning ? "pause.fill" : "play.fill", action: focus.toggle)
        }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).dockCard()
    }
}
