import AppKit
import ApplicationServices

struct FocusedInputContext {
    let application: NSRunningApplication?
    let wasTextInputFocused: Bool
}

enum FocusedInputDetector {
    static func capture() -> FocusedInputContext {
        FocusedInputContext(
            application: NSWorkspace.shared.frontmostApplication,
            wasTextInputFocused: isFocusedElementTextInput()
        )
    }

    private static func isFocusedElementTextInput() -> Bool {
        guard AXIsProcessTrusted() else {
            return false
        }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )
        guard result == .success, let focusedValue else {
            return false
        }

        let focusedElement = focusedValue as! AXUIElement
        return roleIndicatesTextInput(focusedElement) || subroleIndicatesTextInput(focusedElement)
    }

    private static func roleIndicatesTextInput(_ element: AXUIElement) -> Bool {
        guard let role = stringAttribute(kAXRoleAttribute, from: element) else {
            return false
        }

        return [
            kAXTextFieldRole as String,
            kAXTextAreaRole as String,
            kAXComboBoxRole as String
        ].contains(role)
    }

    private static func subroleIndicatesTextInput(_ element: AXUIElement) -> Bool {
        guard let subrole = stringAttribute(kAXSubroleAttribute, from: element) else {
            return false
        }

        return subrole.localizedCaseInsensitiveContains("Text")
    }

    private static func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success else {
            return nil
        }

        return value as? String
    }
}
