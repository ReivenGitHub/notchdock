import Foundation

public struct ShortcutModifiers: OptionSet, Codable, Equatable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let command = Self(rawValue: 1 << 0)
    public static let option = Self(rawValue: 1 << 1)
    public static let control = Self(rawValue: 1 << 2)
    public static let shift = Self(rawValue: 1 << 3)
}

public struct ShortcutBinding: Codable, Equatable {
    public let keyCode: UInt32
    public let modifiers: ShortcutModifiers
    public let keyName: String
    public init(keyCode: UInt32, modifiers: ShortcutModifiers, keyName: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyName = keyName
    }
    public static let standard = Self(keyCode: 49, modifiers: [.command, .option], keyName: "Space")
    public var isValid: Bool {
        keyCode <= 127 && ![53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63].contains(keyCode)
            && !modifiers.intersection([.command, .option, .control]).isEmpty
            && modifiers.rawValue & ~UInt32(15) == 0 && !keyName.isEmpty
    }
    public var label: String {
        (modifiers.contains(.control) ? "⌃" : "")
            + (modifiers.contains(.option) ? "⌥" : "")
            + (modifiers.contains(.shift) ? "⇧" : "")
            + (modifiers.contains(.command) ? "⌘" : "") + keyName
    }
}
