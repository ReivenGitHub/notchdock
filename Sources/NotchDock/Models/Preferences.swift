import Combine
import Foundation
import NotchDockCore

enum PlayerApp: String, CaseIterable, Identifiable, Hashable {
    case automatic, music, spotify, youtubeChrome, youtubeSafari
    var id: String { rawValue }
    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .music: return "Apple Music"
        case .spotify: return "Spotify"
        case .youtubeChrome: return "YouTube · Chrome"
        case .youtubeSafari: return "YouTube · Safari"
        }
    }
    var bundleID: String? {
        switch self {
        case .automatic: return nil
        case .music: return "com.apple.Music"
        case .spotify: return "com.spotify.client"
        case .youtubeChrome: return "com.google.Chrome"
        case .youtubeSafari: return "com.apple.Safari"
        }
    }
    var isBrowser: Bool { self == .youtubeChrome || self == .youtubeSafari }
    static let detectable: [PlayerApp] = [.music, .spotify, .youtubeChrome, .youtubeSafari]
}

@MainActor
final class Preferences: ObservableObject {
    private let defaults: UserDefaults
    @Published var expandOnHover: Bool { didSet { defaults.set(expandOnHover, forKey: "expandOnHover") } }
    @Published var displayTarget: String { didSet { defaults.set(displayTarget, forKey: "displayTarget") } }
    @Published var hideWhenIdle: Bool { didSet { defaults.set(hideWhenIdle, forKey: "hideWhenIdle") } }
    @Published var shortcut: ShortcutBinding? { didSet {
        if let data = try? JSONEncoder().encode(shortcut) { defaults.set(data, forKey: "shortcut") }
    } }
    @Published var mediaEnabled: Bool { didSet { defaults.set(mediaEnabled, forKey: "mediaEnabled") } }
    @Published var player: PlayerApp { didSet { defaults.set(player.rawValue, forKey: "player") } }
    @Published var playCompletionSound: Bool { didSet { defaults.set(playCompletionSound, forKey: "playCompletionSound") } }
    @Published var showOnCompletion: Bool { didSet { defaults.set(showOnCompletion, forKey: "showOnCompletion") } }
    @Published var focusMinutes: Int { didSet { defaults.set(focusMinutes, forKey: "focusMinutes") } }
    @Published var shortBreakMinutes: Int { didSet { defaults.set(shortBreakMinutes, forKey: "shortBreakMinutes") } }
    @Published var longBreakMinutes: Int { didSet { defaults.set(longBreakMinutes, forKey: "longBreakMinutes") } }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["expandOnHover": true, "preferBuiltInDisplay": true,
                                     "hideWhenIdle": true, "mediaEnabled": false, "playCompletionSound": true,
                                     "showOnCompletion": true, "focusMinutes": 25,
                                     "shortBreakMinutes": 5, "longBreakMinutes": 15])
        expandOnHover = defaults.bool(forKey: "expandOnHover")
        displayTarget = defaults.string(forKey: "displayTarget")
            ?? (defaults.bool(forKey: "preferBuiltInDisplay") ? "automatic" : "primary")
        hideWhenIdle = defaults.bool(forKey: "hideWhenIdle")
        shortcut = .standard
        if let data = defaults.data(forKey: "shortcut") {
            do {
                let saved = try JSONDecoder().decode(ShortcutBinding?.self, from: data)
                shortcut = saved == nil || saved?.isValid == true ? saved : .standard
            } catch { shortcut = .standard }
        }
        mediaEnabled = defaults.bool(forKey: "mediaEnabled")
        player = PlayerApp(rawValue: defaults.string(forKey: "player") ?? "") ?? .automatic
        playCompletionSound = defaults.bool(forKey: "playCompletionSound")
        showOnCompletion = defaults.bool(forKey: "showOnCompletion")
        focusMinutes = min(180, max(1, defaults.integer(forKey: "focusMinutes")))
        shortBreakMinutes = min(60, max(1, defaults.integer(forKey: "shortBreakMinutes")))
        longBreakMinutes = min(60, max(1, defaults.integer(forKey: "longBreakMinutes")))
    }
    func minutes(for mode: FocusMode) -> Int {
        switch mode {
        case .focus: return focusMinutes
        case .shortBreak: return shortBreakMinutes
        case .longBreak: return longBreakMinutes
        }
    }
}
