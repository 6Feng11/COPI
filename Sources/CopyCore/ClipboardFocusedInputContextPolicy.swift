public enum ClipboardFocusedInputContextPolicy {
    public static func shouldReuseLastTextInputContext(
        capturedWasTextInputFocused: Bool,
        capturedApplicationIsCurrentApp: Bool,
        lastWasTextInputFocused: Bool
    ) -> Bool {
        !capturedWasTextInputFocused
            && capturedApplicationIsCurrentApp
            && lastWasTextInputFocused
    }
}
