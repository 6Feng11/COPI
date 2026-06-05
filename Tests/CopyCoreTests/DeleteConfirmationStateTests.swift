import CopyCore
import XCTest

final class DeleteConfirmationStateTests: XCTestCase {
    func testRequestConfirmationTracksSelectedItem() {
        let itemID = UUID()
        var state = DeleteConfirmationState()

        state.requestConfirmation(for: itemID)

        XCTAssertTrue(state.isConfirming)
        XCTAssertTrue(state.isConfirming(itemID))
    }

    func testCancelClearsConfirmation() {
        let itemID = UUID()
        var state = DeleteConfirmationState(confirmingItemID: itemID)

        state.cancel()

        XCTAssertFalse(state.isConfirming)
        XCTAssertFalse(state.isConfirming(itemID))
    }

    func testConsumeConfirmedDeleteOnlySucceedsForMatchingItemAndClearsState() {
        let itemID = UUID()
        var state = DeleteConfirmationState(confirmingItemID: itemID)

        XCTAssertTrue(state.consumeConfirmedDelete(for: itemID))
        XCTAssertFalse(state.isConfirming)
    }

    func testConsumeConfirmedDeleteRejectsDifferentItem() {
        let itemID = UUID()
        let otherItemID = UUID()
        var state = DeleteConfirmationState(confirmingItemID: itemID)

        XCTAssertFalse(state.consumeConfirmedDelete(for: otherItemID))
        XCTAssertTrue(state.isConfirming(itemID))
    }
}
