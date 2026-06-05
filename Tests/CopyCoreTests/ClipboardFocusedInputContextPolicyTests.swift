import CopyCore
import XCTest

final class ClipboardFocusedInputContextPolicyTests: XCTestCase {
    func testUsesFreshCapturedTextInputContext() {
        XCTAssertFalse(
            ClipboardFocusedInputContextPolicy.shouldReuseLastTextInputContext(
                capturedWasTextInputFocused: true,
                capturedApplicationIsCurrentApp: false,
                lastWasTextInputFocused: true
            )
        )
    }

    func testReusesLastTextInputWhenOpeningAppStealsFocus() {
        XCTAssertTrue(
            ClipboardFocusedInputContextPolicy.shouldReuseLastTextInputContext(
                capturedWasTextInputFocused: false,
                capturedApplicationIsCurrentApp: true,
                lastWasTextInputFocused: true
            )
        )
    }

    func testDoesNotReuseLastTextInputForOtherNonInputApps() {
        XCTAssertFalse(
            ClipboardFocusedInputContextPolicy.shouldReuseLastTextInputContext(
                capturedWasTextInputFocused: false,
                capturedApplicationIsCurrentApp: false,
                lastWasTextInputFocused: true
            )
        )
    }
}
