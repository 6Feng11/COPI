import AppKit

enum PasteInjector {
    static func pasteIntoFocusedContext(_ context: FocusedInputContext) {
        if #available(macOS 14.0, *) {
            context.application?.activate()
        } else {
            context.application?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            FocusedInputDetector.restoreFocus(context)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                sendCommandV()
            }
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
