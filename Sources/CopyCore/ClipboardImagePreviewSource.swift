import Foundation

public enum ClipboardImagePreviewSource {
    public static func displayPath(
        for item: ClipboardItem,
        fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) -> String? {
        guard item.type == .image else {
            return nil
        }

        if let thumbnailPath = item.thumbnailPath,
           fileExists(thumbnailPath) {
            return thumbnailPath
        }

        if let imagePath = item.imagePath,
           fileExists(imagePath) {
            return imagePath
        }

        return nil
    }

    public static func needsThumbnailBackfill(
        for item: ClipboardItem,
        fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) -> Bool {
        guard item.type == .image,
              let imagePath = item.imagePath,
              fileExists(imagePath)
        else {
            return false
        }

        guard let thumbnailPath = item.thumbnailPath else {
            return true
        }

        return !fileExists(thumbnailPath)
    }
}
