import CopyCore
import XCTest

final class ClipboardImagePreviewSourceTests: XCTestCase {
    func testDisplayPathPrefersExistingThumbnail() {
        let item = ClipboardItem(
            type: .image,
            preview: "图片",
            imagePath: "/images/original/full.tiff",
            thumbnailPath: "/images/thumbnails/full.jpg",
            contentHash: "image-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let path = ClipboardImagePreviewSource.displayPath(
            for: item,
            fileExists: { $0 == "/images/thumbnails/full.jpg" }
        )

        XCTAssertEqual(path, "/images/thumbnails/full.jpg")
    }

    func testDisplayPathFallsBackToOriginalWhenThumbnailIsMissing() {
        let item = ClipboardItem(
            type: .image,
            preview: "图片",
            imagePath: "/images/original/full.tiff",
            thumbnailPath: "/images/thumbnails/full.jpg",
            contentHash: "image-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let path = ClipboardImagePreviewSource.displayPath(
            for: item,
            fileExists: { $0 == "/images/original/full.tiff" }
        )

        XCTAssertEqual(path, "/images/original/full.tiff")
    }

    func testDisplayPathIgnoresNonImageItems() {
        let item = ClipboardItem(
            type: .text,
            preview: "文字",
            plainText: "文字",
            imagePath: "/images/original/full.tiff",
            thumbnailPath: "/images/thumbnails/full.jpg",
            contentHash: "text-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let path = ClipboardImagePreviewSource.displayPath(
            for: item,
            fileExists: { _ in true }
        )

        XCTAssertNil(path)
    }

    func testNeedsThumbnailBackfillOnlyWhenImageOriginalExistsAndThumbnailIsMissing() {
        let item = ClipboardItem(
            type: .image,
            preview: "图片",
            imagePath: "/images/original/full.tiff",
            thumbnailPath: "/images/thumbnails/full.jpg",
            contentHash: "image-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertTrue(
            ClipboardImagePreviewSource.needsThumbnailBackfill(
                for: item,
                fileExists: { $0 == "/images/original/full.tiff" }
            )
        )
        XCTAssertFalse(
            ClipboardImagePreviewSource.needsThumbnailBackfill(
                for: item,
                fileExists: { _ in true }
            )
        )
    }

    func testNeedsThumbnailBackfillIgnoresNonImageItems() {
        let item = ClipboardItem(
            type: .text,
            preview: "文字",
            plainText: "文字",
            imagePath: "/images/original/full.tiff",
            thumbnailPath: "/images/thumbnails/full.jpg",
            contentHash: "text-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertFalse(
            ClipboardImagePreviewSource.needsThumbnailBackfill(
                for: item,
                fileExists: { _ in true }
            )
        )
    }
}
