import Foundation

public struct KeyboardShortcut: Codable, Equatable, Sendable {
    public struct Modifiers: OptionSet, Codable, Equatable, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        public static let command = Modifiers(rawValue: 1 << 0)
        public static let shift = Modifiers(rawValue: 1 << 1)
        public static let option = Modifiers(rawValue: 1 << 2)
        public static let control = Modifiers(rawValue: 1 << 3)
    }

    public var keyCode: UInt32
    public var keyEquivalent: String
    public var modifiers: Modifiers

    public init(
        keyCode: UInt32,
        keyEquivalent: String,
        modifiers: Modifiers
    ) {
        self.keyCode = keyCode
        self.keyEquivalent = keyEquivalent.uppercased()
        self.modifiers = modifiers
    }

    public static let defaultShortcut = KeyboardShortcut(
        keyCode: 2,
        keyEquivalent: "D",
        modifiers: [.command]
    )

    public var isValidGlobalShortcut: Bool {
        modifiers.intersection([.command, .option, .control]).isEmpty == false
            && keyEquivalent.isEmpty == false
    }

    public var displayText: String {
        modifierDisplayText + keyEquivalent
    }

    private var modifierDisplayText: String {
        var text = ""
        if modifiers.contains(.control) {
            text += "^"
        }
        if modifiers.contains(.option) {
            text += "⌥"
        }
        if modifiers.contains(.shift) {
            text += "⇧"
        }
        if modifiers.contains(.command) {
            text += "⌘"
        }
        return text
    }
}
