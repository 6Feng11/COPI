import CoreGraphics

public enum ClipboardPanelPlacement {
    public static func centeredFrame(panelSize: CGSize, visibleFrame: CGRect) -> CGRect {
        CGRect(
            x: visibleFrame.midX - panelSize.width / 2,
            y: visibleFrame.midY - panelSize.height / 2,
            width: panelSize.width,
            height: panelSize.height
        )
    }
}

public enum ClipboardPanelDismissalPolicy {
    public static func shouldDismiss(
        clickLocation: CGPoint,
        panelFrame: CGRect,
        statusButtonFrame: CGRect?
    ) -> Bool {
        if panelFrame.contains(clickLocation) {
            return false
        }

        if let statusButtonFrame,
           statusButtonFrame.contains(clickLocation) {
            return false
        }

        return true
    }
}
