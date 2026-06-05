import CopyCore
import XCTest

final class KeyboardShortcutTests: XCTestCase {
    func testDefaultShortcutIsCommandD() {
        let shortcut = KeyboardShortcut.defaultShortcut

        XCTAssertEqual(shortcut.keyCode, 2)
        XCTAssertEqual(shortcut.keyEquivalent, "D")
        XCTAssertEqual(shortcut.modifiers, [.command])
        XCTAssertEqual(shortcut.displayText, "⌘D")
    }

    func testShortcutDisplayOrdersModifiersLikeMacOS() {
        let shortcut = KeyboardShortcut(
            keyCode: 9,
            keyEquivalent: "v",
            modifiers: [.control, .option, .shift, .command]
        )

        XCTAssertEqual(shortcut.displayText, "^⌥⇧⌘V")
    }

    func testGlobalShortcutRequiresPrimaryModifier() {
        XCTAssertTrue(KeyboardShortcut.defaultShortcut.isValidGlobalShortcut)

        let plainD = KeyboardShortcut(keyCode: 2, keyEquivalent: "D", modifiers: [])
        let shiftD = KeyboardShortcut(keyCode: 2, keyEquivalent: "D", modifiers: [.shift])

        XCTAssertFalse(plainD.isValidGlobalShortcut)
        XCTAssertFalse(shiftD.isValidGlobalShortcut)
    }

    func testShortcutEditorSuppressesGlobalHotKeyWhileOpen() {
        XCTAssertTrue(KeyboardShortcutEditorPolicy.shouldHandleGlobalHotKey(isEditorOpen: false))
        XCTAssertFalse(KeyboardShortcutEditorPolicy.shouldHandleGlobalHotKey(isEditorOpen: true))
    }

    func testShortcutRecorderChromeHidesNativeTitleAndShowsShortDescription() {
        XCTAssertEqual(ShortcutRecorderChrome.nativeWindowTitle, "")
        XCTAssertFalse(ShortcutRecorderChrome.showsNativeTitle)
        XCTAssertTrue(ShortcutRecorderChrome.showsDescription)
        XCTAssertEqual(ShortcutRecorderChrome.descriptionText, "按下要修改的快捷键组合")
        XCTAssertGreaterThan(
            ShortcutRecorderChrome.borderTrailOpacity,
            ShortcutRecorderChrome.inactiveBorderOpacity
        )
    }

    func testShortcutRecorderActiveStateUsesBorderWithoutGreyFill() {
        XCTAssertEqual(ShortcutRecorderChrome.activeFillOpacity, 0)
        XCTAssertEqual(ShortcutRecorderChrome.activeBorderOpacity, ShortcutRecorderChrome.inactiveBorderOpacity)
    }

    func testShortcutRecorderActiveBorderUsesMotionPrimitiveBorderTrailDefaults() {
        XCTAssertTrue(ShortcutRecorderChrome.usesBorderTrailWhenActive)
        XCTAssertEqual(ShortcutRecorderChrome.borderTrailSize, 60)
        XCTAssertEqual(ShortcutRecorderChrome.borderTrailDuration, 5)
        XCTAssertEqual(ShortcutRecorderChrome.borderTrailLineWidth, 2)
        XCTAssertEqual(ShortcutRecorderChrome.borderTrailAnimationTiming, "linear")
    }

    func testShortcutRecorderFooterButtonsUseMagneticButtonVisualsWithoutEffect() {
        XCTAssertTrue(ShortcutRecorderChrome.footerButtonsUseMagneticVisualStyle)
        XCTAssertFalse(ShortcutRecorderChrome.footerButtonsUseMagneticEffect)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonHeight, 42)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonHorizontalPadding, 18)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonCornerRadius, 8)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonBorderOpacity, 0.14)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonHoverFillOpacity, 0.14)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonBaseWidth, 104)
        XCTAssertEqual(ShortcutRecorderChrome.footerButtonGroupSpacing, 10)
        XCTAssertEqual(ShortcutRecorderChrome.windowHeight, 236)
        XCTAssertEqual(ShortcutRecorderChrome.windowContentPadding, 22)
        XCTAssertEqual(
            ShortcutRecorderChrome.footerButtonBottomInset,
            ShortcutRecorderChrome.windowContentPadding
        )
    }
}
