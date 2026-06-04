import AppKit
import ApplicationServices
import CopyCore

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
        guard isTrusted, let focusedElement = focusedElement(for: application) else {
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

    static func insertText(_ text: String, into context: FocusedInputContext) -> Bool {
        guard context.isAccessibilityTrusted,
              context.wasTextInputFocused,
              let focusedElement = context.focusedElement
        else {
            return false
        }

        restoreFocus(context)

        if AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            text as CFString
        ) == .success {
            return true
        }

        guard let value = stringAttribute(kAXValueAttribute, from: focusedElement),
              let selectedRange = selectedTextRange(from: focusedElement),
              let insertion = TextInsertion.replacingSelection(
                in: value,
                selectedRange: selectedRange,
                with: text
              )
        else {
            return false
        }

        let valueResult = AXUIElementSetAttributeValue(
            focusedElement,
            kAXValueAttribute as CFString,
            insertion.text as CFString
        )
        guard valueResult == .success else {
            return false
        }

        setSelectedTextRange(insertion.selectedRange, on: focusedElement)
        return true
    }

    private static func accessibilityIsTrusted() -> Bool {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private static func focusedElement(for application: NSRunningApplication?) -> AXUIElement? {
        if let application,
           let focusedElement = focusedElement(in: AXUIElementCreateApplication(application.processIdentifier)) {
            return focusedElement
        }

        return focusedElement(in: AXUIElementCreateSystemWide())
    }

    private static func focusedElement(in element: AXUIElement) -> AXUIElement? {
        var focusedValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
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

    private static func selectedTextRange(from element: AXUIElement) -> NSRange? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &value
        )
        guard result == .success, let value else {
            return nil
        }

        var range = CFRange(location: 0, length: 0)
        guard AXValueGetValue(value as! AXValue, .cfRange, &range) else {
            return nil
        }

        return NSRange(location: range.location, length: range.length)
    }

    private static func setSelectedTextRange(_ range: NSRange, on element: AXUIElement) {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let value = AXValueCreate(.cfRange, &cfRange) else {
            return
        }

        AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            value
        )
    }
}
