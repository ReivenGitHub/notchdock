import AppKit
import Combine
import NotchDockCore
import UniformTypeIdentifiers

struct ShelfItem: Identifiable {
    let id: UUID
    var url: URL
    var available: Bool
    var name: String { url.lastPathComponent }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
}
private struct SavedShelfItem: Codable {
    let id: UUID
    let bookmark: Data?
    let path: String
}

@MainActor
final class ShelfStore: ObservableObject {
    static let capacity = 24
    @Published private(set) var items: [ShelfItem] = []
    @Published var message: String?
    private let quickLook = QuickLookController()

    init() {
        do {
            let saved = try LocalStore.load([SavedShelfItem].self, from: "shelf.json") ?? []
            var seen = Set<String>()
            for entry in saved.prefix(Self.capacity) {
                var stale = false
                let restored = entry.bookmark.flatMap {
                    try? URL(resolvingBookmarkData: $0, options: [.withoutUI, .withoutMounting],
                             relativeTo: nil, bookmarkDataIsStale: &stale)
                }
                let url = (restored ?? URL(fileURLWithPath: entry.path)).standardizedFileURL
                guard seen.insert(url.path).inserted else { continue }
                items.append(ShelfItem(id: entry.id, url: url, available: FileManager.default.fileExists(atPath: url.path)))
            }
        } catch { message = "Your saved shelf could not be loaded. You can add files again." }
    }
    func add(_ urls: [URL]) {
        let candidates = urls.filter { $0.isFileURL && FileManager.default.fileExists(atPath: $0.path) }
        let selection = ShelfSelection(candidates: candidates, existing: items.map(\.url), capacity: Self.capacity)
        items.append(contentsOf: selection.accepted.map { ShelfItem(id: UUID(), url: $0, available: true) })
        if selection.overflowCount > 0 {
            message = "Shelf full: keep up to \(Self.capacity) files. Remove an item to make space."
        } else if candidates.count < urls.count {
            message = "Some files are unavailable. Download cloud files locally and try again."
        } else if selection.accepted.isEmpty && selection.duplicateCount > 0 {
            message = "Those files are already on your shelf."
        } else { message = nil }
        persist()
    }
    func remove(_ id: UUID) { items.removeAll { $0.id == id }; message = nil; persist() }
    func clear() { items.removeAll(); message = nil; persist() }
    func removeUnavailable() {
        refresh()
        let count = items.count
        items.removeAll { !$0.available }
        message = "Removed \(count - items.count) unavailable references."
        persist()
    }
    func preview(_ item: ShelfItem) {
        guard FileManager.default.fileExists(atPath: item.url.path) else {
            message = "This file is unavailable. It may have moved or be offline."
            refresh()
            return
        }
        quickLook.show(item.url)
    }
    func copy(_ item: ShelfItem, pathOnly: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pathOnly { pasteboard.setString(item.url.path, forType: .string) }
        else { pasteboard.writeObjects([item.url as NSURL]) }
        message = pathOnly ? "Path copied." : "File reference copied. Paste it into another app."
    }
    func refresh() {
        for index in items.indices { items[index].available = FileManager.default.fileExists(atPath: items[index].url.path) }
    }
    func open(_ item: ShelfItem) {
        guard NSWorkspace.shared.open(item.url) else {
            message = "This file could not be opened. It may have moved or be offline."
            refresh(); return
        }
    }
    func reveal(_ item: ShelfItem) { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
    func chooseFiles() {
        let picker = NSOpenPanel()
        picker.canChooseDirectories = true
        picker.canChooseFiles = true
        picker.allowsMultipleSelection = true
        picker.prompt = "Add to shelf"
        NSApp.activate(ignoringOtherApps: true)
        if picker.runModal() == .OK { add(picker.urls) }
    }
    func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        guard FileDropLoader.supports(providers) else { return false }
        Task {
            let urls = await FileDropLoader.load(providers)
            if urls.isEmpty { message = "No local files were found in that drop." }
            else { add(urls) }
        }
        return true
    }
    private func persist() {
        let saved = items.map { item in
            SavedShelfItem(id: item.id,
                           bookmark: try? item.url.bookmarkData(options: .minimalBookmark,
                                                               includingResourceValuesForKeys: nil, relativeTo: nil),
                           path: item.url.path)
        }
        do { try LocalStore.save(saved, to: "shelf.json") }
        catch { message = "Shelf is available for this session, but could not be saved." }
    }
}
