import AppKit
import ImageIO
import NotchDockCore

private final class ArtworkRedirectPolicy: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        let allowed = request.url.flatMap { ArtworkPolicy.spotifyURL($0.absoluteString) } != nil
        completionHandler(allowed ? request : nil)
    }
}

/// Artwork comes from Music's local scripting data or Spotify's supplied image URL.
/// No title/artist search, account token, persistent network cache, or album-art database.
final class ArtworkLoader {
    private let bridge: AppleScriptBridge
    private let cache = NSCache<NSString, NSImage>()
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
    func image(for metadata: PlaybackMetadata, player: PlayerApp) async -> NSImage? {
        let key = metadata.artworkKey(player: player.rawValue) as NSString
        if let image = cache.object(forKey: key) { return image }
        let data: Data?
        if player == .spotify { data = await spotifyData(metadata.artworkURL) }
        else { data = await musicData(metadata) }
        guard !Task.isCancelled, let data, !data.isEmpty, data.count <= ArtworkPolicy.maximumBytes,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 512,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        cache.setObject(image, forKey: key)
        return image
    }
    private func spotifyData(_ text: String) async -> Data? {
        guard let url = ArtworkPolicy.spotifyURL(text), !Task.isCancelled else { return nil }
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
