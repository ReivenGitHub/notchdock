import Carbon
import Foundation

@MainActor
final class HotKeyController {
    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private let action: () -> Void
    private(set) var registered = false
    init(action: @escaping () -> Void) {
        self.action = action
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let result = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let controller = Unmanaged<HotKeyController>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { controller.action() }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &handler)
        guard result == noErr else { return }
        let identifier = EventHotKeyID(signature: OSType(0x4E44434B), id: 1)
        registered = RegisterEventHotKey(UInt32(kVK_Space), UInt32(cmdKey | optionKey), identifier,
                                        GetApplicationEventTarget(), 0, &hotKey) == noErr
    }
    func stop() {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        if let handler { RemoveEventHandler(handler); self.handler = nil }
        registered = false
    }
}
