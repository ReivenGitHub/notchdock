import AppKit
import UniformTypeIdentifiers

enum FileDropLoader {
    static func supports(_ providers: [NSItemProvider]) -> Bool {
        providers.contains { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
    }
    static func load(_ providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            let url: URL? = await withCheckedContinuation { continuation in
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { value, _ in
                    if let data = value as? Data {
                        continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                    } else if let url = value as? URL {
                        continuation.resume(returning: url)
                    } else if let string = value as? String {
                        continuation.resume(returning: URL(string: string))
                    } else { continuation.resume(returning: nil) }
                }
            }
            if let url, url.isFileURL { urls.append(url.standardizedFileURL) }
        }
        return urls
    }
}
