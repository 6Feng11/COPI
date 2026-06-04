import XCTest
@testable import CopyCore

final class LocalHistoryRepositoryTests: XCTestCase {
    func testLoadReturnsEmptyArrayWhenFileDoesNotExist() throws {
        let repository = LocalHistoryRepository(fileURL: temporaryFileURL())

        let items = try repository.load()

        XCTAssertTrue(items.isEmpty)
    }

    func testSaveAndLoadRoundTripsItems() throws {
        let fileURL = temporaryFileURL()
        let repository = LocalHistoryRepository(fileURL: fileURL)
        let item = ClipboardNormalizer.makeTextItem(
            "https://example.com",
            sourceAppBundleId: "com.apple.Safari",
            sourceAppName: "Safari",
            now: Date(timeIntervalSince1970: 100)
        )!

        try repository.save([item])
        let loaded = try repository.load()

        XCTAssertEqual(loaded, [item])
    }

    func testSaveCreatesParentDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = root.appendingPathComponent("nested/history.json")
        let repository = LocalHistoryRepository(fileURL: fileURL)

        try repository.save([])

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.json")
    }
}
