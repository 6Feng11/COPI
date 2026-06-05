import Foundation

public enum ShortcutRecorderChrome {
    public static let nativeWindowTitle = ""
    public static let showsNativeTitle = false
    public static let showsDescription = true
    public static let contentTitle = "修改快捷键"
    public static let descriptionText = "按下要修改的快捷键组合"

    public static let windowWidth = 360.0
    public static let windowHeight = 236.0
    public static let windowContentPadding = 22.0
    public static let captureHeight = 58.0
    public static let captureCornerRadius = 14.0

    public static let inactiveFillOpacity = 0.10
    public static let activeFillOpacity = 0.0
    public static let inactiveBorderOpacity = 0.16
    public static let activeBorderOpacity = inactiveBorderOpacity
    public static let inactiveBorderWidth = 1.0
    public static let activeBorderWidth = 1.5

    public static let usesBorderTrailWhenActive = true
    public static let borderTrailSize = 60.0
    public static let borderTrailDuration = 5.0
    public static let borderTrailLineWidth = 2.0
    public static let borderTrailOpacity = 0.92
    public static let borderTrailGlowOpacity = 0.45
    public static let borderTrailGlowRadius = 8.0
    public static let borderTrailAnimationTiming = "linear"

    public static let footerButtonsUseMagneticVisualStyle = true
    public static let footerButtonsUseMagneticEffect = false
    public static let footerButtonHeight = 42.0
    public static let footerButtonHorizontalPadding = 18.0
    public static let footerButtonCornerRadius = 8.0
    public static let footerButtonBorderOpacity = 0.14
    public static let footerButtonHoverFillOpacity = 0.14
    public static let footerButtonPrimaryFillOpacity = 0.98
    public static let footerButtonFontSize = 14.0
    public static let footerButtonBaseWidth = 104.0
    public static let footerButtonGroupSpacing = 10.0
    public static let footerButtonBottomInset = windowContentPadding
}

public enum KeyboardShortcutEditorPolicy {
    public static func shouldHandleGlobalHotKey(isEditorOpen: Bool) -> Bool {
        isEditorOpen == false
    }
}
