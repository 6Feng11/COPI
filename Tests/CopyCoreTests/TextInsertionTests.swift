import CopyCore
import XCTest

final class TextInsertionTests: XCTestCase {
    func testInsertionAtCollapsedSelectionMovesCursorAfterInsertedText() {
        let result = TextInsertion.replacingSelection(
            in: "hello world",
            selectedRange: NSRange(location: 6, length: 0),
            with: "copy "
        )

        XCTAssertEqual(result?.text, "hello copy world")
        XCTAssertEqual(result?.selectedRange.location, 11)
        XCTAssertEqual(result?.selectedRange.length, 0)
    }

    func testInsertionReplacesSelectedText() {
        let result = TextInsertion.replacingSelection(
            in: "hello world",
            selectedRange: NSRange(location: 6, length: 5),
            with: "copy"
        )

        XCTAssertEqual(result?.text, "hello copy")
        XCTAssertEqual(result?.selectedRange.location, 10)
        XCTAssertEqual(result?.selectedRange.length, 0)
    }

    func testInvalidSelectionReturnsNil() {
        let result = TextInsertion.replacingSelection(
            in: "hello",
            selectedRange: NSRange(location: 20, length: 0),
            with: "copy"
        )

        XCTAssertNil(result)
    }
}
