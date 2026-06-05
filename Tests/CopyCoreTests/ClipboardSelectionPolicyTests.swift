import CopyCore
import XCTest

final class ClipboardSelectionPolicyTests: XCTestCase {
    func testInputFocusChoosesDirectPaste() {
        let action = ClipboardSelectionPolicy.action(wasTextInputFocusedWhenOpened: true)

        XCTAssertEqual(action, .pasteIntoFocusedInput)
    }

    func testNonInputFocusChoosesCopyOnly() {
        let action = ClipboardSelectionPolicy.action(wasTextInputFocusedWhenOpened: false)

        XCTAssertEqual(action, .copyOnly)
    }

    func testClipboardSelectionFeedbackUsesCenteredCopiedToastForEverySelectionAction() {
        let directPasteFeedback = ClipboardSelectionPolicy.feedback(
            for: .pasteIntoFocusedInput,
            isAccessibilityTrusted: true
        )
        let copyOnlyFeedback = ClipboardSelectionPolicy.feedback(
            for: .copyOnly,
            isAccessibilityTrusted: true
        )

        XCTAssertEqual(directPasteFeedback.message, "已复制")
        XCTAssertEqual(copyOnlyFeedback.message, "已复制")
        XCTAssertEqual(directPasteFeedback.placement, .centeredOnPanel)
        XCTAssertEqual(copyOnlyFeedback.placement, .centeredOnPanel)
    }

    func testClipboardSelectionFeedbackExplainsAccessibilityFallback() {
        let feedback = ClipboardSelectionPolicy.feedback(
            for: .pasteIntoFocusedInput,
            isAccessibilityTrusted: false
        )

        XCTAssertEqual(feedback.message, "已复制，需开启辅助功能")
        XCTAssertEqual(feedback.placement, .centeredOnPanel)
    }
}
