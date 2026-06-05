import CopyCore
import XCTest

final class ClipboardPanelBehaviorTests: XCTestCase {
    func testPanelFrameIsCenteredInVisibleScreenFrame() {
        let visibleFrame = CGRect(x: 120, y: 80, width: 1440, height: 900)
        let panelSize = CGSize(width: 720, height: 560)

        let frame = ClipboardPanelPlacement.centeredFrame(
            panelSize: panelSize,
            visibleFrame: visibleFrame
        )

        XCTAssertEqual(frame.origin.x, 480)
        XCTAssertEqual(frame.origin.y, 250)
        XCTAssertEqual(frame.size.width, 720)
        XCTAssertEqual(frame.size.height, 560)
    }

    func testOutsideClickDismissesPanelButPanelAndStatusButtonClicksStayOpen() {
        let panelFrame = CGRect(x: 480, y: 250, width: 720, height: 560)
        let statusButtonFrame = CGRect(x: 980, y: 982, width: 28, height: 22)

        XCTAssertFalse(
            ClipboardPanelDismissalPolicy.shouldDismiss(
                clickLocation: CGPoint(x: 600, y: 420),
                panelFrame: panelFrame,
                statusButtonFrame: statusButtonFrame
            )
        )
        XCTAssertFalse(
            ClipboardPanelDismissalPolicy.shouldDismiss(
                clickLocation: CGPoint(x: 990, y: 990),
                panelFrame: panelFrame,
                statusButtonFrame: statusButtonFrame
            )
        )
        XCTAssertTrue(
            ClipboardPanelDismissalPolicy.shouldDismiss(
                clickLocation: CGPoint(x: 200, y: 200),
                panelFrame: panelFrame,
                statusButtonFrame: statusButtonFrame
            )
        )
    }
}
