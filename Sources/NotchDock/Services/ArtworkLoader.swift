import Foundation
import ImageIO
import NotchDockCore
import UniformTypeIdentifiers

private final class ArtworkRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let allowed = request.url.map {
            ArtworkPolicy.remoteURL($0.absoluteString, provider: "spotify") != nil
                || ArtworkPolicy.remoteURL($0.absoluteString, provider: "youtubeChrome") != nil
        } ?? false
        completionHandler(allowed ? request : nil)
    }
}

/// Artwork comes from Music's local scripting data or a supported player's supplied image URL.
/// No title/artist search, account token, persistent network cache, or album-art database.
final class ArtworkLoader {
    private let bridge: AppleScriptBridge
    private let cache = NSCache<NSString, NSData>()
    private let network: URLSession
    init(bridge: AppleScriptBridge) {
        self.bridge = bridge
        cache.countLimit = 16
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        network = URLSession(configuration: config, delegate: ArtworkRedirectPolicy(), delegateQueue: nil)
    }
    func clearCache() { cache.removeAllObjects() }
    func thumbnail(for metadata: PlaybackMetadata, player: PlayerApp) async -> Data? {
        let key = metadata.artworkKey(player: player.rawValue) as NSString
        if let data = cache.object(forKey: key) { return data as Data }
        let data: Data?
        if player == .music { data = await musicData(metadata) }
        else { data = await remoteData(metadata.artworkURL, provider: player.rawValue) }
        guard !Task.isCancelled, let data, !data.isEmpty, data.count <= ArtworkPolicy.maximumBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 512,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }
        // Only immutable data crosses back to the UI actor; AppKit images stay on the UI thread.
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output as CFMutableData, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination), !Task.isCancelled else { return nil }
        let thumbnail = output as Data
        cache.setObject(thumbnail as NSData, forKey: key)
        return thumbnail
    }
    private func remoteData(_ text: String, provider: String) async -> Data? {
        guard let url = ArtworkPolicy.remoteURL(text, provider: provider), !Task.isCancelled else { return nil }
        do {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
            request.setValue("image/*", forHTTPHeaderField: "Accept")
            let (bytes, response) = try await network.bytes(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  response.mimeType?.hasPrefix("image/") == true,
                  response.expectedContentLength <= Int64(ArtworkPolicy.maximumBytes) else { return nil }
            var data = Data()
            for try await byte in bytes {
                guard data.count < ArtworkPolicy.maximumBytes, !Task.isCancelled else { return nil }
                data.append(byte)
            }
            return data
        } catch { return nil }
    }
    private func musicData(_ metadata: PlaybackMetadata) async -> Data? {
        guard !Task.isCancelled else { return nil }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("NotchDock-Art-" + UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
                                                   attributes: [.posixPermissions: 0o700])
        } catch { return nil }
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("cover")
        let result = await bridge.run(MediaScripts.musicArtwork, arguments: [file.path, metadata.trackID,
                                                                         metadata.title, metadata.artist, metadata.album])
        guard !Task.isCancelled, case .success("ok") = result,
              let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= ArtworkPolicy.maximumBytes else { return nil }
        return try? Data(contentsOf: file, options: .mappedIfSafe)
    }
}
