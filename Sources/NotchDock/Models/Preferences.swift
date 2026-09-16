import Combine
import Foundation

enum PlayerApp: String, CaseIterable, Identifiable, Hashable {
    case music, spotify
    var id: String { rawValue }
    var title: String { self == .music ? "Apple Music" : "Spotify" }
    var bundleID: String { self == .music ? "com.apple.Music" : "com.spotify.client" }
}

@MainActor
final class Preferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var expandOnHover: Bool { didSet { defaults.set(expandOnHover, forKey: "expandOnHover") } }
    @Published var preferBuiltInDisplay: Bool { didSet { defaults.set(preferBuiltInDisplay, forKey: "preferBuiltInDisplay") } }
    @Published var mediaEnabled: Bool { didSet { defaults.set(mediaEnabled, forKey: "mediaEnabled") } }
    @Published var player: PlayerApp { didSet { defaults.set(player.rawValue, forKey: "player") } }
    @Published var playCompletionSound: Bool { didSet { defaults.set(playCompletionSound, forKey: "playCompletionSound") } }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["expandOnHover": true, "preferBuiltInDisplay": true,
                                     "mediaEnabled": false, "playCompletionSound": true])
        expandOnHover = defaults.bool(forKey: "expandOnHover")
        preferBuiltInDisplay = defaults.bool(forKey: "preferBuiltInDisplay")
        mediaEnabled = defaults.bool(forKey: "mediaEnabled")
        player = PlayerApp(rawValue: defaults.string(forKey: "player") ?? "") ?? .music
        playCompletionSound = defaults.bool(forKey: "playCompletionSound")
    }
}
