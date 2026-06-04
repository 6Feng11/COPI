public enum ClipboardSelectionAction: Equatable {
    case pasteIntoFocusedInput
    case copyOnly
}

public enum ClipboardSelectionPolicy {
    public static func action(wasTextInputFocusedWhenOpened: Bool) -> ClipboardSelectionAction {
        wasTextInputFocusedWhenOpened ? .pasteIntoFocusedInput : .copyOnly
    }
}
