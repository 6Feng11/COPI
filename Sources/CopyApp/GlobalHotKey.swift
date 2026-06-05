import Carbon
import CopyCore
import Foundation

@MainActor
final class GlobalHotKey {
    private static var activeHotKey: GlobalHotKey?
    private static var eventHandler: EventHandlerRef?

    private var shortcut: KeyboardShortcut
    private let handler: @MainActor () -> Void
    private var hotKeyRef: EventHotKeyRef?

    init(shortcut: KeyboardShortcut, handler: @escaping @MainActor () -> Void) {
        self.shortcut = shortcut
        self.handler = handler
    }

    func register() {
        Self.installEventHandlerIfNeeded()
        unregister()

        let hotKeyID = EventHotKeyID(signature: fourCharCode("COPY"), id: 1)
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            carbonModifiers(for: shortcut.modifiers),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &newHotKeyRef
        )

        guard status == noErr else {
            return
        }

        hotKeyRef = newHotKeyRef
        Self.activeHotKey = self
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        if Self.activeHotKey === self {
            Self.activeHotKey = nil
        }
    }

    func update(shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
        register()
    }

    private static func installEventHandlerIfNeeded() {
        guard eventHandler == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, _, _ in
                Task { @MainActor in
                    GlobalHotKey.activeHotKey?.handler()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    private func fourCharCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { partialResult, character in
            (partialResult << 8) + OSType(character)
        }
    }

    private func carbonModifiers(for modifiers: KeyboardShortcut.Modifiers) -> UInt32 {
        var carbonModifiers: UInt32 = 0
        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        return carbonModifiers
    }
}
