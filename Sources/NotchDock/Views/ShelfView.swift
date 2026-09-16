import AppKit
import SwiftUI

struct ShelfView: View {
    @EnvironmentObject private var shelf: ShelfStore
    @EnvironmentObject private var state: PanelState
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
            HStack {
                Text("\(shelf.items.count) / \(ShelfStore.capacity) files").foregroundStyle(DockTheme.muted)
                Spacer()
                Button("Clear shelf") { shelf.clear() }.buttonStyle(.plain).foregroundStyle(DockTheme.muted)
                    .help("Remove all shelf references. Your files stay in place.")
                Button(action: chooseFiles) { Label("Add", systemImage: "plus") }
                    .buttonStyle(.plain).foregroundStyle(DockTheme.accent).padding(.leading, 10)
            }.font(.system(size: 10))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) { ForEach(shelf.items) { item in fileCard(item) } }.padding(.vertical, 2)
            }
            Text(shelf.message ?? "Drag a file out to share it · Right-click for more")
                .font(.system(size: 9)).foregroundStyle(DockTheme.muted).lineLimit(2)
        }
    }
    private func fileCard(_ item: ShelfItem) -> some View {
        VStack(spacing: 5) {
            Button { shelf.open(item) } label: {
                VStack(spacing: 6) {
                    Image(nsImage: item.icon).resizable().scaledToFit().frame(width: 38, height: 38).opacity(item.available ? 1 : 0.35)
                    Text(item.name).font(.system(size: 10, weight: .medium)).lineLimit(1).truncationMode(.middle)
                    Text(item.available ? "Drag to share" : "File unavailable").font(.system(size: 8)).foregroundStyle(DockTheme.muted)
                }.frame(width: 96, height: 104)
            }.buttonStyle(.plain).disabled(!item.available).accessibilityLabel("Open \(item.name)")
        }
        .dockCard().onDrag { NSItemProvider(object: item.url as NSURL) }
        .contextMenu {
            Button("Open") { shelf.open(item) }.disabled(!item.available)
            Button("Show in Finder") { shelf.reveal(item) }.disabled(!item.available)
            Divider()
            Button("Remove from shelf") { shelf.remove(item.id) }
        }.help(item.url.path)
    }
    private func chooseFiles() { state.beginInteraction(); shelf.chooseFiles(); state.endInteraction() }
}
