import AppKit

enum PasteInjector {
    static func pasteIntoFocusedApp(_ application: NSRunningApplication?) {
        if #available(macOS 14.0, *) {
            application?.activate()
        } else {
            application?.activate(options: [.activateIgnoringOtherApps])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            sendCommandV()
        }
    }

    private static func sendCommandV() {
        let keyCodeForV: CGKeyCode = 9
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForV, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForV, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
