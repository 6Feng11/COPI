import XCTest
@testable import CopyCore

final class ImageFileStoreTests: XCTestCase {
    func testPrepareDirectoriesCreatesOriginalsAndThumbnails() throws {
        let store = ImageFileStore(rootDirectory: temporaryDirectory())

        try store.prepareDirectories()

        XCTAssertTrue(FileManager.default.fileExists(atPath: store.originalsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.thumbnailsDirectory.path))
    }

    func testSaveOriginalWritesImageBytes() throws {
        let store = ImageFileStore(rootDirectory: temporaryDirectory())
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let data = Data([0x01, 0x02, 0x03])

        let fileURL = try store.saveOriginal(data: data, id: id, fileExtension: "png")

        XCTAssertEqual(try Data(contentsOf: fileURL), data)
        XCTAssertEqual(fileURL.lastPathComponent, "\(id.uuidString).png")
    }

    func testThumbnailURLUsesThumbnailDirectory() {
        let store = ImageFileStore(rootDirectory: temporaryDirectory())
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

        let fileURL = store.thumbnailURL(for: id, fileExtension: "jpg")

        XCTAssertEqual(fileURL.deletingLastPathComponent(), store.thumbnailsDirectory)
        XCTAssertEqual(fileURL.lastPathComponent, "\(id.uuidString).jpg")
    }

    func testClearImagesRemovesOriginalAndThumbnailFiles() throws {
        let store = ImageFileStore(rootDirectory: temporaryDirectory())
        let original = try store.saveOriginal(
            data: Data([0x01]),
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            fileExtension: "png"
        )
        try store.prepareDirectories()
        let thumbnail = store.thumbnailURL(
            for: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            fileExtension: "png"
        )
        try Data([0x02]).write(to: thumbnail)

        try store.clearImages()

        XCTAssertFalse(FileManager.default.fileExists(atPath: original.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: thumbnail.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.originalsDirectory.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.thumbnailsDirectory.path))
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
