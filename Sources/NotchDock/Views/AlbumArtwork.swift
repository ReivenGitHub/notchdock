import SwiftUI

struct AlbumArtwork: View {
    @EnvironmentObject private var media: MediaService
    let size: CGFloat
    var body: some View {
        ZStack {
            LinearGradient(colors: [DockTheme.accent.opacity(0.25), Color(red: 0.09, green: 0.17, blue: 0.14)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            if let artwork = media.artwork {
                Image(nsImage: artwork).resizable().scaledToFill()
            } else if media.artworkLoading {
                ProgressView().controlSize(.mini).scaleEffect(size < 30 ? 0.7 : 1)
            } else {
                Image(systemName: "music.note").font(.system(size: size * 0.38)).foregroundStyle(DockTheme.accent)
            }
        }.frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size < 30 ? 5 : 10))
            .overlay(RoundedRectangle(cornerRadius: size < 30 ? 5 : 10).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            .accessibilityLabel(media.artwork == nil ? "Album artwork unavailable" : "Album artwork for \(media.track.album)")
            .help(media.track.album.isEmpty ? media.track.title : media.track.album)
            .contextMenu { Button("Reload album artwork", action: media.reloadArtwork) }
    }
}
