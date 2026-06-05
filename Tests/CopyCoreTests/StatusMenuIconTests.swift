import CopyCore
import XCTest

final class StatusMenuIconTests: XCTestCase {
    func testStatusBarAppIconUsesSimpleClipboardSymbol() {
        XCTAssertEqual(StatusMenuIcon.statusBarApp.systemName, "clipboard")
    }

    func testRecordingMenuIconChangesWithPausedState() {
        XCTAssertEqual(StatusMenuIcon.recording(isPaused: false).systemName, "pause.circle")
        XCTAssertEqual(StatusMenuIcon.recording(isPaused: true).systemName, "play.circle")
    }

    func testStaticStatusMenuIconsMatchMenuActions() {
        XCTAssertEqual(StatusMenuIcon.clearHistory.systemName, "trash")
        XCTAssertEqual(StatusMenuIcon.shortcutSettings.systemName, "keyboard")
        XCTAssertEqual(StatusMenuIcon.quit.systemName, "power")
    }
}
