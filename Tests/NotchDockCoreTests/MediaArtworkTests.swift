import Foundation
import XCTest
@testable import NotchDockCore

final class MediaArtworkTests: XCTestCase {
    private func metadata(state: String = "playing", position: String = "12", duration: String = "240",
                          album: String = "Album", id: String = "track:1", cover: String = "https://i.scdn.co/image/cover") -> PlaybackMetadata {
        PlaybackMetadata(scriptOutput: [state, "Track", "Artist", album, position, duration, id, cover].joined(separator: "\u{1F}"))!
    }
    func testPlayerMetadataCarriesAlbumAndCoverURL() {
        let track = metadata()
        XCTAssertTrue(track.playing)
        XCTAssertEqual(track.album, "Album")
        XCTAssertEqual(track.artworkURL, "https://i.scdn.co/image/cover")
        XCTAssertEqual(track.progress, 0.05, accuracy: 0.001)
    }
    func testPausedTrackKeepsAlbumAndArtworkKey() {
        let playing = metadata()
        let paused = metadata(state: "paused", position: "30")
        XCTAssertFalse(paused.playing)
        XCTAssertEqual(playing.artworkKey(player: "spotify"), paused.artworkKey(player: "spotify"))
    }
    func testTrackAlbumAndProviderChangesInvalidateArtworkKey() {
        let initial = metadata().artworkKey(player: "spotify")
        XCTAssertNotEqual(initial, metadata(id: "track:2").artworkKey(player: "spotify"))
        XCTAssertNotEqual(initial, metadata(album: "Other album").artworkKey(player: "spotify"))
        XCTAssertNotEqual(initial, metadata().artworkKey(player: "music"))
    }
    func testStoppedOrMalformedMetadataDoesNotBecomeATrack() {
        XCTAssertNil(PlaybackMetadata(scriptOutput: "stopped"))
        XCTAssertNil(PlaybackMetadata(scriptOutput: "playing\u{1F}Track"))
        XCTAssertNil(PlaybackMetadata(scriptOutput: ["unknown", "T", "A", "B", "0", "0", "id", ""].joined(separator: "\u{1F}")))
    }
    func testLocaleAndInvalidNumbersStayFinite() {
        XCTAssertEqual(metadata(position: "12,5").position, 12.5)
        XCTAssertEqual(metadata(position: "NaN", duration: "Infinity").progress, 0)
        XCTAssertEqual(metadata(position: "-10").position, 0)
        XCTAssertEqual(metadata(position: "500").progress, 1)
    }
    func testApprovedSpotifyArtworkURLs() {
        for url in ["https://i.scdn.co/image/123", "https://mosaic.scdn.co/abc", "https://image-cdn.spotifycdn.com/art",
                    "https://image.spotifycdn.net/art", "https://i.scdn.co:443/image/art"] {
            XCTAssertNotNil(ArtworkPolicy.spotifyURL(url))
        }
    }
    func testUnsafeOrUnrelatedArtworkURLsAreRejected() {
        for url in ["file:///etc/passwd", "http://i.scdn.co/image/a", "https://scdn.co.evil.example/art",
                    "https://evilscdn.co/art", "https://localhost/art", "https://user:pass@i.scdn.co/art",
                    "https://i.scdn.co:8443/art", "data:image/png;base64,abc"] {
            XCTAssertNil(ArtworkPolicy.spotifyURL(url))
        }
    }
    func testOldImageCannotReplaceNewTrack() {
        var request = ArtworkRequest()
        let old = request.begin(key: "old")
        let current = request.begin(key: "current")
        XCTAssertFalse(request.accepts(generation: old, key: "old"))
        XCTAssertTrue(request.accepts(generation: current, key: "current"))
    }
    func testCanceledAndRevisitedTrackCannotAcceptItsPreviousResult() {
        var request = ArtworkRequest()
        let old = request.begin(key: "same")
        request.begin(key: nil)
        XCTAssertFalse(request.accepts(generation: old, key: "same"))
        let current = request.begin(key: "same")
        XCTAssertFalse(request.accepts(generation: old, key: "same"))
        XCTAssertTrue(request.accepts(generation: current, key: "same"))
    }
    func testMissingCoverDoesNotHideTheAlbum() {
        let track = metadata(cover: "")
        XCTAssertEqual(track.album, "Album")
        XCTAssertEqual(track.title, "Track")
        XCTAssertNil(ArtworkPolicy.spotifyURL(track.artworkURL))
    }
}
