import AppKit
import Combine

@MainActor
final class AirDropService: NSObject, ObservableObject, NSSharingServiceDelegate {
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    var beginInteraction: () -> Void = {}
    var endInteraction: () -> Void = {}
    private var service: NSSharingService?

    func share(_ urls: [URL]) {
        guard !busy else { return }
        var seen = Set<String>()
        let files = urls.filter { $0.isFileURL && FileManager.default.fileExists(atPath: $0.path) }
            .map(\.standardizedFileURL).filter { seen.insert($0.path).inserted }
        guard !files.isEmpty else { message = "Choose files available on this Mac, then try again."; return }
        guard let service = NSSharingService(named: .sendViaAirDrop), service.canPerform(withItems: files) else {
            message = "AirDrop is unavailable for these files. Check AirDrop in Finder and try again."
            return
        }
        self.service = service
        service.delegate = self
        busy = true
        message = "Choose a recipient in AirDrop."
        beginInteraction()
        NSApp.activate(ignoringOtherApps: true)
        service.perform(withItems: files)
    }
    func chooseFiles() {
        guard !busy else { return }
        let picker = NSOpenPanel()
        picker.canChooseFiles = true
        picker.canChooseDirectories = true
        picker.allowsMultipleSelection = true
        picker.prompt = "AirDrop"
        beginInteraction()
        NSApp.activate(ignoringOtherApps: true)
        let accepted = picker.runModal() == .OK
        endInteraction()
        if accepted { share(picker.urls) }
    }
    func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !busy, FileDropLoader.supports(providers) else { return false }
        beginInteraction()
        Task {
            let urls = await FileDropLoader.load(providers)
            endInteraction()
            share(urls)
        }
        return true
    }
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        finish(sharingService, message: "Shared with AirDrop.")
    }
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        let canceled = (error as NSError).domain == NSCocoaErrorDomain
            && (error as NSError).code == CocoaError.Code.userCancelled.rawValue
        finish(sharingService, message: canceled ? "AirDrop canceled." : "AirDrop did not finish. Check Wi-Fi, Bluetooth, and the receiving device.")
    }
    private func finish(_ sharingService: NSSharingService, message: String) {
        guard service === sharingService else { return }
        service?.delegate = nil
        service = nil
        busy = false
        self.message = message
        endInteraction()
    }
}
