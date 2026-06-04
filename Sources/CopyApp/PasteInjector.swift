import AppKit
import CopyCore

enum PasteInjector {
    static func paste(_ item: ClipboardItem, into context: FocusedInputContext) {
        if let text = item.plainText,
           FocusedInputDetector.insertText(text, into: context) {
            return
        }

        pasteIntoFocusedContext(context)
    }

    static func pasteIntoFocusedContext(_ context: FocusedInputContext) {
        if shouldReactivate(context.application) {
            if #available(macOS 14.0, *) {
                context.application?.activate()
            } else {
                context.application?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
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

    private static func shouldReactivate(_ application: NSRunningApplication?) -> Bool {
        guard let application else {
            return false
        }

        return NSWorkspace.shared.frontmostApplication?.processIdentifier != application.processIdentifier
    }
}
