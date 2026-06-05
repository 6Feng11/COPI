import CopyCore
import XCTest

final class ClipboardColumnLayoutTests: XCTestCase {
    func testColumnOrderAndWeightsFollowClipboardLayout() {
        let columns = ClipboardColumnLayout.columns

        XCTAssertEqual(columns.map(\.id), [.textAndLinks, .images])
        XCTAssertEqual(columns.map(\.types), [[.text, .link], [.image]])
        XCTAssertEqual(columns.map(\.title), ["文字 / 链接", "图片"])
        XCTAssertEqual(columns.map(\.widthUnit), [5, 3])
    }

    func testTotalWidthUnitsTreatImageWidthAsBaseUnitX() {
        XCTAssertEqual(ClipboardColumnLayout.totalWidthUnits, 8)
    }

    func testColumnWidthsGiveImageColumnEnoughRoomForAspectRatioPreviews() {
        let widths = ClipboardColumnLayout.widths(totalWidth: 804, columnSpacing: 4)

        XCTAssertEqual(widths[.textAndLinks], 500)
        XCTAssertEqual(widths[.images], 300)
    }

    func testTextColumnReservesTrailingGutterForScrollIndicator() {
        XCTAssertEqual(
            ClipboardColumnLayout.scrollIndicatorGutterTrailingPadding(for: .textAndLinks),
            14
        )
        XCTAssertEqual(
            ClipboardColumnLayout.scrollIndicatorGutterTrailingPadding(for: .images),
            0
        )
    }

    func testItemsAreFilteredByColumnType() {
        let textItem = ClipboardItem(type: .text, preview: "A", contentHash: "t", createdAt: Date())
        let linkItem = ClipboardItem(type: .link, preview: "https://a.com", contentHash: "l", createdAt: Date())
        let imageItem = ClipboardItem(type: .image, preview: "图片", contentHash: "i", createdAt: Date())
        let items = [textItem, linkItem, imageItem]

        XCTAssertEqual(ClipboardColumnLayout.items(in: .textAndLinks, from: items), [textItem, linkItem])
        XCTAssertEqual(ClipboardColumnLayout.items(in: .images, from: items), [imageItem])
    }
}
