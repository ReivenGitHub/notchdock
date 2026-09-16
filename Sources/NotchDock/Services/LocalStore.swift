import Foundation

enum LocalStore {
    static func location(_ filename: String) throws -> URL {
        let base = try FileManager.default.url(for: .applicationSupportDirectory,
                                              in: .userDomainMask, appropriateFor: nil, create: true)
        let directory = base.appendingPathComponent("NotchDock", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent(filename)
    }
    static func save<T: Encodable>(_ value: T, to filename: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: location(filename), options: .atomic)
    }
    static func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T? {
        let url = try location(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
}
