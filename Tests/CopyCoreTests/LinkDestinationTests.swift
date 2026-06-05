import CopyCore
import XCTest

final class LinkDestinationTests: XCTestCase {
    func testReturnsURLForLinkItemURL() {
        let item = ClipboardItem(
            type: .link,
            preview: "https://example.com",
            url: "https://example.com",
            contentHash: "link-hash",
            createdAt: Date()
        )

        XCTAssertEqual(LinkDestination.url(for: item)?.absoluteString, "https://example.com")
    }

    func testReturnsPlainTextFallbackForLinkItem() {
        let item = ClipboardItem(
            type: .link,
            preview: "https://example.com/docs",
            plainText: " https://example.com/docs ",
            contentHash: "fallback-hash",
            createdAt: Date()
        )

        XCTAssertEqual(LinkDestination.url(for: item)?.absoluteString, "https://example.com/docs")
    }

    func testIgnoresNonLinkItems() {
        let item = ClipboardItem(
            type: .text,
            preview: "https://example.com",
            plainText: "https://example.com",
            contentHash: "text-hash",
            createdAt: Date()
        )

        XCTAssertNil(LinkDestination.url(for: item))
    }
}
