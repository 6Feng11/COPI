import CopyCore
import XCTest

final class CopyToastPlacementTests: XCTestCase {
    func testFeedbackToastUsesCopiedToastWidthForEveryMessage() {
        XCTAssertEqual(CopyToastPlacement.feedbackSize(for: "已复制").width, 118)
        XCTAssertEqual(CopyToastPlacement.feedbackSize(for: "已暂停记录").width, 118)
        XCTAssertEqual(CopyToastPlacement.feedbackSize(for: "已恢复记录").width, 118)
        XCTAssertEqual(CopyToastPlacement.feedbackSize(for: "快捷键已改为 ⌘D").width, 118)
        XCTAssertEqual(CopyToastPlacement.feedbackSize(for: "已复制").height, 42)
    }

    func testFeedbackToastUsesCenteredOriginForMenuAndClipboardFeedback() {
        let anchor = CGRect(x: 100, y: 200, width: 360, height: 214)
        let size = CopyToastPlacement.feedbackSize(for: "已暂停记录")

        let origin = CopyToastPlacement.feedbackOrigin(anchor: anchor, size: size)

        XCTAssertEqual(origin, CopyToastPlacement.centeredOrigin(anchor: anchor, size: size))
    }

    func testToastWindowChromeStaysVisibleAfterAppDeactivation() {
        XCTAssertFalse(CopyToastWindowChrome.hidesOnDeactivate)
        XCTAssertTrue(CopyToastWindowChrome.ignoresMouseEvents)
        XCTAssertFalse(CopyToastWindowChrome.isReleasedWhenClosed)
        XCTAssertTrue(CopyToastWindowChrome.usesNonActivatingPanel)
    }

    func testToastCanBeCenteredOnShortcutRecorderFrame() {
        let anchor = CGRect(x: 100, y: 200, width: 360, height: 214)
        let size = CGSize(width: 210, height: 42)

        let origin = CopyToastPlacement.centeredOrigin(anchor: anchor, size: size)

        XCTAssertEqual(origin.x, 175)
        XCTAssertEqual(origin.y, 286)
    }

    func testNearAnchorPlacementKeepsExistingTopAlignedToastBehavior() {
        let anchor = CGRect(x: 100, y: 200, width: 360, height: 214)
        let size = CGSize(width: 210, height: 42)

        let origin = CopyToastPlacement.nearAnchorOrigin(anchor: anchor, size: size)

        XCTAssertEqual(origin.x, 175)
        XCTAssertEqual(origin.y, 356)
    }
}
