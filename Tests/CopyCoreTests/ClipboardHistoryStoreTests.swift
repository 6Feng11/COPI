import XCTest
@testable import CopyCore

final class ClipboardHistoryStoreTests: XCTestCase {
    func testRecordInsertsNewestItemAtTop() {
        var store = ClipboardHistoryStore()
        let first = makeItem(text: "first", createdAt: 100)
        let second = makeItem(text: "second", createdAt: 200)

        _ = store.record(first, now: Date(timeIntervalSince1970: 100))
        _ = store.record(second, now: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(store.items.map(\.plainText), ["second", "first"])
    }

    func testNewestDuplicateUpdatesExistingRecordWithoutAddingRow() {
        var store = ClipboardHistoryStore()
        let original = makeItem(text: "same", createdAt: 100)
        let duplicate = makeItem(text: "same", createdAt: 200)

        let recorded = store.record(original, now: Date(timeIntervalSince1970: 100))
        let updated = store.record(duplicate, now: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(recorded.id, updated.id)
        XCTAssertEqual(store.items[0].createdAt, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(store.items[0].useCount, 1)
    }

    func testOlderDuplicateMovesExistingRecordToTop() {
        var store = ClipboardHistoryStore()
        let original = makeItem(text: "same", createdAt: 100)
        let other = makeItem(text: "other", createdAt: 150)
        let duplicate = makeItem(text: "same", createdAt: 200)

        let recorded = store.record(original, now: Date(timeIntervalSince1970: 100))
        _ = store.record(other, now: Date(timeIntervalSince1970: 150))
        let updated = store.record(duplicate, now: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(recorded.id, updated.id)
        XCTAssertEqual(store.items.map(\.plainText), ["same", "other"])
        XCTAssertEqual(store.items[0].useCount, 1)
        XCTAssertEqual(store.items[0].createdAt, Date(timeIntervalSince1970: 200))
    }

    func testSearchMatchesPreviewTextAndURL() {
        var store = ClipboardHistoryStore()
        _ = store.record(makeItem(text: "plain note", createdAt: 100), now: Date(timeIntervalSince1970: 100))
        _ = store.record(makeItem(text: "https://example.com/docs", createdAt: 200), now: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(store.search("note").map(\.plainText), ["plain note"])
        XCTAssertEqual(store.search("example").map(\.url), ["https://example.com/docs"])
        XCTAssertEqual(store.search("").count, 2)
    }

    func testRetentionLimitTrimsOldestRecords() {
        var store = ClipboardHistoryStore(retentionLimit: 2)

        _ = store.record(makeItem(text: "one", createdAt: 100), now: Date(timeIntervalSince1970: 100))
        _ = store.record(makeItem(text: "two", createdAt: 200), now: Date(timeIntervalSince1970: 200))
        _ = store.record(makeItem(text: "three", createdAt: 300), now: Date(timeIntervalSince1970: 300))

        XCTAssertEqual(store.items.map(\.plainText), ["three", "two"])
    }

    func testDeleteAndClearRemoveRecords() {
        var store = ClipboardHistoryStore()
        let first = store.record(makeItem(text: "first", createdAt: 100), now: Date(timeIntervalSince1970: 100))
        _ = store.record(makeItem(text: "second", createdAt: 200), now: Date(timeIntervalSince1970: 200))

        store.delete(id: first.id)

        XCTAssertEqual(store.items.map(\.plainText), ["second"])

        store.clear()

        XCTAssertTrue(store.items.isEmpty)
    }

    private func makeItem(text: String, createdAt: TimeInterval) -> ClipboardItem {
        ClipboardNormalizer.makeTextItem(
            text,
            sourceAppBundleId: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: createdAt)
        )!
    }
}
