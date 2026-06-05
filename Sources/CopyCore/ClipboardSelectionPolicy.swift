public enum ClipboardSelectionAction: Equatable {
    case pasteIntoFocusedInput
    case copyOnly
}

public enum ClipboardSelectionToastPlacement: Equatable {
    case centeredOnPanel
}

public struct ClipboardSelectionFeedback: Equatable {
    public let message: String
    public let placement: ClipboardSelectionToastPlacement
}

public enum ClipboardSelectionPolicy {
    public static func action(wasTextInputFocusedWhenOpened: Bool) -> ClipboardSelectionAction {
        wasTextInputFocusedWhenOpened ? .pasteIntoFocusedInput : .copyOnly
    }

    public static func feedback(
        for action: ClipboardSelectionAction,
        isAccessibilityTrusted: Bool
    ) -> ClipboardSelectionFeedback {
        ClipboardSelectionFeedback(
            message: isAccessibilityTrusted ? "已复制" : "已复制，需开启辅助功能",
            placement: .centeredOnPanel
        )
    }
}
