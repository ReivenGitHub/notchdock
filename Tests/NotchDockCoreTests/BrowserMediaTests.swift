import Foundation
import XCTest
@testable import NotchDockCore

final class BrowserMediaTests: XCTestCase {
    func testYouTubeThumbnailDomainsAreAllowedForBothBrowsers() {
        for provider in ["youtubeChrome", "youtubeSafari"] {
            XCTAssertNotNil(ArtworkPolicy.remoteURL("https://i.ytimg.com/vi/abc/hqdefault.jpg", provider: provider))
            XCTAssertNotNil(ArtworkPolicy.remoteURL("https://lh3.googleusercontent.com/image", provider: provider))
        }
    }
    func testYouTubePolicyRejectsUnrelatedAndLookalikeHosts() {
        for url in ["https://youtube.example/cover", "https://ytimg.com.evil.example/cover",
                    "http://i.ytimg.com/cover", "file:///tmp/cover", "https://user@i.ytimg.com/cover"] {
            XCTAssertNil(ArtworkPolicy.remoteURL(url, provider: "youtubeChrome"))
        }
    }
    func testProvidersCannotUseEachOthersImageDomains() {
        XCTAssertNil(ArtworkPolicy.remoteURL("https://i.scdn.co/image/a", provider: "youtubeSafari"))
        XCTAssertNil(ArtworkPolicy.remoteURL("https://i.ytimg.com/vi/a/hqdefault.jpg", provider: "spotify"))
        XCTAssertNil(ArtworkPolicy.remoteURL("https://i.ytimg.com/vi/a/hqdefault.jpg", provider: "automatic"))
    }
    func testYouTubeMetadataScriptUsesPagePlaybackAndMediaMetadata() {
        let script = MediaScripts.youtubeMetadataJavaScript
        XCTAssertTrue(script.contains("querySelector('video')"))
        XCTAssertTrue(script.contains("mediaSession"))
        XCTAssertTrue(script.contains("currentTime"))
        XCTAssertTrue(script.contains("hqdefault.jpg"))
        XCTAssertTrue(script.contains("replace(/[\\u001f\\r\\n]/g"))
    }
    func testBrowserScriptsInspectOnlyYouTubeTabs() {
        for browser in [MediaScripts.Browser.chrome, .safari] {
            let script = MediaScripts.youtube(browser: browser)
            XCTAssertTrue(script.contains("youtube.com/"))
            XCTAssertTrue(script.contains("browser-js-disabled"))
            XCTAssertTrue(script.contains("pausedAnswer"))
        }
    }
    func testBrowserCommandsAreFixedAndRejectUnknownCommands() {
        XCTAssertTrue(MediaScripts.youtubeCommandJavaScript("playpause").contains("v.pause()"))
        XCTAssertTrue(MediaScripts.youtubeCommandJavaScript("next track").contains("next-button"))
        XCTAssertTrue(MediaScripts.youtubeCommandJavaScript("previous track").contains("prev-button"))
        XCTAssertEqual(MediaScripts.youtubeCommandJavaScript("arbitrary user text"), "'none'")
    }
}
