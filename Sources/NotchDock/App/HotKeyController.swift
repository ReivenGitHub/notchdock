import Carbon
import Foundation
import NotchDockCore

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
        if result != noErr { handler = nil }
    }
    func configure(_ binding: ShortcutBinding?) {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        registered = false
        guard handler != nil, let binding, binding.isValid else { return }
        var modifiers: UInt32 = 0
        if binding.modifiers.contains(.command) { modifiers |= UInt32(cmdKey) }
        if binding.modifiers.contains(.option) { modifiers |= UInt32(optionKey) }
        if binding.modifiers.contains(.control) { modifiers |= UInt32(controlKey) }
        if binding.modifiers.contains(.shift) { modifiers |= UInt32(shiftKey) }
        let identifier = EventHotKeyID(signature: OSType(0x4E44434B), id: 1)
        registered = RegisterEventHotKey(binding.keyCode, modifiers, identifier,
                                        GetApplicationEventTarget(), 0, &hotKey) == noErr
    }
    func stop() {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        if let handler { RemoveEventHandler(handler); self.handler = nil }
        registered = false
    }
}
