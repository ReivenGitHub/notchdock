import Foundation

/// The selected player's metadata. Artwork identity deliberately excludes playback position.
public struct PlaybackMetadata: Equatable {
    public let title: String
    public let artist: String
    public let album: String
    public let playing: Bool
    public let position: Double
    public let duration: Double
    public let trackID: String
    public let artworkURL: String
    public var progress: Double { duration > 0 ? min(1, max(0, position / duration)) : 0 }

    public init?(scriptOutput: String) {
        let fields = scriptOutput.components(separatedBy: "\u{1F}")
        guard fields.count == 8, ["playing", "paused"].contains(fields[0]), !fields[1].isEmpty else { return nil }
        title = fields[1]
        artist = fields[2]
        album = fields[3]
        playing = fields[0] == "playing"
        position = Self.number(fields[4])
        duration = Self.number(fields[5])
        trackID = fields[6]
        artworkURL = fields[7]
    }
    public func artworkKey(player: String) -> String {
        [player, trackID, title, artist, album, artworkURL].joined(separator: "\u{1F}")
    }
    private static func number(_ text: String) -> Double {
        let value = Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
        return value.isFinite ? max(0, value) : 0
    }
}

public enum ArtworkPolicy {
    public static let maximumBytes = 8 * 1_024 * 1_024
    /// Download only artwork URLs supplied by Spotify, including redirects within its image CDNs.
    public static func spotifyURL(_ text: String) -> URL? {
        guard let url = URL(string: text), url.scheme?.lowercased() == "https",
              url.user == nil, url.password == nil, url.port == nil || url.port == 443,
              let host = url.host?.lowercased() else { return nil }
        let domains = ["scdn.co", "spotifycdn.com", "spotifycdn.net"]
        guard domains.contains(where: { host == $0 || host.hasSuffix("." + $0) }) else { return nil }
        return url
    }
}

/// Invalidates old asynchronous image results even when a track is left and then revisited.
public struct ArtworkRequest: Equatable {
    public private(set) var generation: UInt64 = 0
    public private(set) var key: String?
    public init() {}
    @discardableResult
    public mutating func begin(key: String?) -> UInt64 {
        generation &+= 1
        self.key = key
        return generation
    }
    public func accepts(generation: UInt64, key: String) -> Bool {
        self.generation == generation && self.key == key
    }
}
