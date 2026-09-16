import Foundation

public struct ShelfSelection: Equatable {
    public let accepted: [URL]
    public let duplicateCount: Int
    public let rejectedCount: Int
    public let overflowCount: Int

    /// Accepts local references only. Never copies, moves, or deletes user files.
    public init(candidates: [URL], existing: [URL], capacity: Int = 24) {
        var keys = Set(existing.map { $0.standardizedFileURL.path })
        var accepted: [URL] = []
        var duplicates = 0
        var rejected = 0
        var overflow = 0
        let available = max(0, capacity - existing.count)
        for url in candidates {
            guard url.isFileURL else { rejected += 1; continue }
            let normalized = url.standardizedFileURL
            guard !keys.contains(normalized.path) else { duplicates += 1; continue }
            guard accepted.count < available else { overflow += 1; continue }
            keys.insert(normalized.path)
            accepted.append(normalized)
        }
        self.accepted = accepted
        duplicateCount = duplicates
        rejectedCount = rejected
        overflowCount = overflow
    }
}
