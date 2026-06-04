import XCTest
@testable import CopyCore

final class ClipboardNormalizerTests: XCTestCase {
    func testMakeTextItemTrimsTextAndBuildsPreview() throws {
        let now = Date(timeIntervalSince1970: 100)

        let item = try XCTUnwrap(
            ClipboardNormalizer.makeTextItem(
                "  First line\nSecond line with more detail  ",
                sourceAppBundleId: "com.apple.Notes",
                sourceAppName: "Notes",
                now: now
            )
        )

        XCTAssertEqual(item.type, .text)
        XCTAssertEqual(item.preview, "First line")
        XCTAssertEqual(item.plainText, "First line\nSecond line with more detail")
        XCTAssertNil(item.url)
        XCTAssertEqual(item.sourceAppBundleId, "com.apple.Notes")
        XCTAssertEqual(item.sourceAppName, "Notes")
        XCTAssertEqual(item.createdAt, now)
        XCTAssertEqual(item.useCount, 0)
        XCTAssertFalse(item.isFavorite)
    }

    func testMakeTextItemRejectsWhitespaceOnlyText() {
        let item = ClipboardNormalizer.makeTextItem(
            " \n\t ",
            sourceAppBundleId: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 100)
        )

        XCTAssertNil(item)
    }

    func testMakeTextItemDetectsURLs() throws {
        let item = try XCTUnwrap(
            ClipboardNormalizer.makeTextItem(
                "https://example.com/docs?tab=copy",
                sourceAppBundleId: nil,
                sourceAppName: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        XCTAssertEqual(item.type, .link)
        XCTAssertEqual(item.url, "https://example.com/docs?tab=copy")
        XCTAssertEqual(item.preview, "https://example.com/docs?tab=copy")
    }

    func testPreviewUsesFirstNonEmptyLineAndCapsLength() throws {
        let item = try XCTUnwrap(
            ClipboardNormalizer.makeTextItem(
                "\n\nabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789",
                sourceAppBundleId: nil,
                sourceAppName: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        XCTAssertEqual(item.preview, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567...")
    }

    func testContentHashIsStableForEquivalentText() throws {
        let first = try XCTUnwrap(
            ClipboardNormalizer.makeTextItem(
                "  same text  ",
                sourceAppBundleId: nil,
                sourceAppName: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )
        let second = try XCTUnwrap(
            ClipboardNormalizer.makeTextItem(
                "same text",
                sourceAppBundleId: "different",
                sourceAppName: "Different",
                now: Date(timeIntervalSince1970: 200)
            )
        )

        XCTAssertEqual(first.contentHash, second.contentHash)
    }
}
