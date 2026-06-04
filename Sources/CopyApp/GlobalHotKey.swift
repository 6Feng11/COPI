import Carbon
import Foundation

@MainActor
final class GlobalHotKey {
    enum Command {
        case commandShiftV

        var keyCode: UInt32 {
            switch self {
            case .commandShiftV:
                return 9
            }
        }

        var modifiers: UInt32 {
            switch self {
            case .commandShiftV:
                return UInt32(cmdKey | shiftKey)
            }
        }
    }

    private static var activeHotKey: GlobalHotKey?
    private static var eventHandler: EventHandlerRef?

    private let command: Command
    private let handler: @MainActor () -> Void
    private var hotKeyRef: EventHotKeyRef?

    init(command: Command, handler: @escaping @MainActor () -> Void) {
        self.command = command
        self.handler = handler
    }

    func register() {
        Self.installEventHandlerIfNeeded()
        unregister()

        let hotKeyID = EventHotKeyID(signature: fourCharCode("COPY"), id: 1)
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            command.keyCode,
            command.modifiers,
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
}
