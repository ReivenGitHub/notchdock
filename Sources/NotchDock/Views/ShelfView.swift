import AppKit
import SwiftUI

struct ShelfView: View {
    @EnvironmentObject private var shelf: ShelfStore
    @EnvironmentObject private var state: PanelState
    @State private var query = ""
    @AppStorage("shelfSortByName") private var sortByName = false
    private var visibleItems: [ShelfItem] {
        let matching = shelf.items.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        return sortByName ? matching.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending } : Array(matching.reversed())
    }
    var body: some View {
        Group { if shelf.items.isEmpty { emptyShelf } else { populatedShelf } }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(state.dropTargeted ? DockTheme.accent.opacity(0.07) : Color.clear, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(state.dropTargeted ? DockTheme.accent : .clear, style: StrokeStyle(lineWidth: 1, dash: [5, 5])))
    }
    private var emptyShelf: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray.and.arrow.down").font(.system(size: 26, weight: .light)).foregroundStyle(DockTheme.accent)
            Text("Drop it here. Pick it up anywhere.").font(.system(size: 15, weight: .medium))
            Text(shelf.message ?? "A temporary home for your files. Originals stay where they are.")
                .font(.system(size: 10)).foregroundStyle(DockTheme.muted).lineLimit(2)
            AccentButton(title: "Choose files", symbol: "plus", action: chooseFiles)
        }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity).dockCard()
    }
    private var populatedShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass").foregroundStyle(DockTheme.muted)
                    TextField("Search files", text: $query).textFieldStyle(.plain)
                        .accessibilityLabel("Search shelf files")
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.plain).help("Clear search")
                    }
                }.padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 7))
                    .frame(maxWidth: 220)
                Spacer()
                Text("\(shelf.items.count)/\(ShelfStore.capacity)").foregroundStyle(DockTheme.muted)
                Menu {
                    Picker("Sort", selection: $sortByName) {
                        Text("Newest first").tag(false)
                        Text("Name A–Z").tag(true)
                    }
                    Divider()
                    Button("Remove unavailable references", action: shelf.removeUnavailable)
                    Button("Clear shelf references", action: shelf.clear)
                } label: { Image(systemName: "ellipsis.circle") }
                    .menuStyle(.borderlessButton).frame(width: 24).help("Shelf options")
                Button(action: chooseFiles) { Label("Add", systemImage: "plus") }
                    .buttonStyle(.plain).foregroundStyle(DockTheme.accent)
            }.font(.system(size: 10))
            if visibleItems.isEmpty {
                Text("No files match “\(query)”.").font(.system(size: 12)).foregroundStyle(DockTheme.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) { ForEach(visibleItems) { item in fileCard(item) } }.padding(.vertical, 2)
                }
            }
            Text(shelf.message ?? "Drag to share · Eye to preview · Right-click for more")
                .font(.system(size: 9)).foregroundStyle(DockTheme.muted).lineLimit(2)
        }
    }
    private func fileCard(_ item: ShelfItem) -> some View {
        VStack(spacing: 4) {
            HStack {
                Button { shelf.preview(item) } label: { Image(systemName: "eye") }
                    .disabled(!item.available).help("Quick Look \(item.name)")
                Spacer()
                Button { shelf.remove(item.id) } label: { Image(systemName: "xmark") }
                    .help("Remove \(item.name) from shelf")
            }.font(.system(size: 9)).buttonStyle(.plain).foregroundStyle(DockTheme.muted)
                .padding(.horizontal, 9).padding(.top, 8)
            Button { shelf.open(item) } label: {
                VStack(spacing: 4) {
                    Image(nsImage: item.icon).resizable().scaledToFit().frame(width: 32, height: 32).opacity(item.available ? 1 : 0.35)
                    Text(item.name).font(.system(size: 10, weight: .medium)).lineLimit(1).truncationMode(.middle)
                    Text(item.available ? "Drag to share" : "File unavailable").font(.system(size: 8)).foregroundStyle(DockTheme.muted)
                }.frame(width: 96, height: 76)
            }.buttonStyle(.plain).disabled(!item.available).accessibilityLabel("Open \(item.name)")
        }
        .dockCard().onDrag { NSItemProvider(object: item.url as NSURL) }
        .contextMenu {
            Button("Quick Look") { shelf.preview(item) }.disabled(!item.available)
            Button("Open") { shelf.open(item) }.disabled(!item.available)
            Button("Show in Finder") { shelf.reveal(item) }.disabled(!item.available)
            Button("Copy file") { shelf.copy(item) }.disabled(!item.available)
            Button("Copy path") { shelf.copy(item, pathOnly: true) }
            Divider()
            Button("Remove from shelf") { shelf.remove(item.id) }
        }.help(item.url.path)
    }
    private func chooseFiles() { state.beginInteraction(); shelf.chooseFiles(); state.endInteraction() }
}
