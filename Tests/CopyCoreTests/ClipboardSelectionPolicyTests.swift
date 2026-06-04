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
}
