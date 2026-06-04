import AppKit
import ApplicationServices

struct FocusedInputContext: @unchecked Sendable {
    let application: NSRunningApplication?
    let focusedElement: AXUIElement?
    let wasTextInputFocused: Bool
    let isAccessibilityTrusted: Bool
}

enum FocusedInputDetector {
    static func capture() -> FocusedInputContext {
        let application = NSWorkspace.shared.frontmostApplication
        let isTrusted = accessibilityIsTrusted()
        guard isTrusted, let focusedElement = focusedElement() else {
            return FocusedInputContext(
                application: application,
                focusedElement: nil,
                wasTextInputFocused: false,
                isAccessibilityTrusted: isTrusted
            )
        }

        return FocusedInputContext(
            application: application,
            focusedElement: focusedElement,
            wasTextInputFocused: isTextInput(focusedElement),
            isAccessibilityTrusted: isTrusted
        )
    }

    static func restoreFocus(_ context: FocusedInputContext) {
        guard context.isAccessibilityTrusted,
              context.wasTextInputFocused,
              let focusedElement = context.focusedElement
        else {
            return
        }

        AXUIElementSetAttributeValue(
            AXUIElementCreateSystemWide(),
            kAXFocusedUIElementAttribute as CFString,
            focusedElement
        )
        AXUIElementSetAttributeValue(
            focusedElement,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        )
    }

    private static func accessibilityIsTrusted() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private static func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )
        guard result == .success, let focusedValue else {
            return nil
        }

        return (focusedValue as! AXUIElement)
    }

    private static func isTextInput(_ element: AXUIElement) -> Bool {
        roleIndicatesTextInput(element) || subroleIndicatesTextInput(element)
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
