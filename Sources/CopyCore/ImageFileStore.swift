import Foundation

public struct ImageFileStore: Sendable {
    public let rootDirectory: URL

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    public var originalsDirectory: URL {
        rootDirectory.appendingPathComponent("Images/original", isDirectory: true)
    }

    public var thumbnailsDirectory: URL {
        rootDirectory.appendingPathComponent("Images/thumbnails", isDirectory: true)
    }

    public func prepareDirectories() throws {
        try FileManager.default.createDirectory(
            at: originalsDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: thumbnailsDirectory,
            withIntermediateDirectories: true
        )
    }

    public func saveOriginal(data: Data, id: UUID, fileExtension: String) throws -> URL {
        try prepareDirectories()
        let fileURL = originalsDirectory.appendingPathComponent(
            "\(id.uuidString).\(normalizedExtension(fileExtension))"
        )
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    public func thumbnailURL(for id: UUID, fileExtension: String) -> URL {
        thumbnailsDirectory.appendingPathComponent(
            "\(id.uuidString).\(normalizedExtension(fileExtension))"
        )
    }

    public func clearImages() throws {
        let imagesDirectory = rootDirectory.appendingPathComponent("Images", isDirectory: true)
        if FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try FileManager.default.removeItem(at: imagesDirectory)
        }
        try prepareDirectories()
    }

    private func normalizedExtension(_ fileExtension: String) -> String {
        let normalized = fileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        return normalized.isEmpty ? "dat" : normalized
    }
}
