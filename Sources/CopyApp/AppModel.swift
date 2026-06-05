import AppKit
import CopyCore
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var isRecordingPaused = false

    private var historyStore: ClipboardHistoryStore
    private let repository: LocalHistoryRepository
    private let imageStore: ImageFileStore
    private let pasteboardClient: PasteboardClient
    private var timer: Timer?
    private var lastPasteboardChangeCount: Int
    private var suppressNextChange = false

    init(
        applicationSupportDirectory: URL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("Copy", isDirectory: true),
        pasteboardClient: PasteboardClient = PasteboardClient()
    ) {
        self.repository = LocalHistoryRepository(
            fileURL: applicationSupportDirectory.appendingPathComponent("history.json")
        )
        self.imageStore = ImageFileStore(rootDirectory: applicationSupportDirectory)
        self.pasteboardClient = pasteboardClient
        self.historyStore = ClipboardHistoryStore()
        self.lastPasteboardChangeCount = pasteboardClient.changeCount

        loadHistory()
        startMonitoring()
    }

    func search(_ query: String) -> [ClipboardItem] {
        historyStore.search(query)
    }

    func toggleRecordingPaused() {
        isRecordingPaused.toggle()
    }

    func clearHistory() {
        historyStore.clear()
        items = historyStore.items
        try? repository.save(items)
        try? imageStore.clearImages()
    }

    func delete(_ item: ClipboardItem) {
        historyStore.delete(id: item.id)
        items = historyStore.items
        try? repository.save(items)
    }

    func restore(_ item: ClipboardItem) {
        pasteboardClient.write(item)
        suppressNextChange = true
        lastPasteboardChangeCount = pasteboardClient.changeCount
    }

    func captureCurrentPasteboardNow() {
        pollPasteboard(force: true)
    }

    private func loadHistory() {
        var loadedItems = (try? repository.load()) ?? []
        if backfillMissingImageThumbnails(in: &loadedItems) {
            try? repository.save(loadedItems)
        }
        historyStore = ClipboardHistoryStore(items: loadedItems, retentionLimit: 1000)
        items = historyStore.items
    }

    private func backfillMissingImageThumbnails(in items: inout [ClipboardItem]) -> Bool {
        var didChange = false

        for index in items.indices {
            guard ClipboardImagePreviewSource.needsThumbnailBackfill(for: items[index]),
                  let imagePath = items[index].imagePath,
                  let imageData = try? Data(contentsOf: URL(fileURLWithPath: imagePath))
            else {
                continue
            }

            let thumbnailURL = imageStore.thumbnailURL(for: items[index].id, fileExtension: "jpg")
            guard let writtenThumbnailURL = try? ImageThumbnailWriter.writeThumbnail(
                from: imageData,
                to: thumbnailURL
            ) else {
                continue
            }

            items[index].thumbnailPath = writtenThumbnailURL.path
            didChange = true
        }

        return didChange
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    private func pollPasteboard(force: Bool = false) {
        let currentChangeCount = pasteboardClient.changeCount
        guard force || currentChangeCount != lastPasteboardChangeCount else {
            return
        }
        lastPasteboardChangeCount = currentChangeCount

        if suppressNextChange {
            suppressNextChange = false
            return
        }

        guard !isRecordingPaused else {
            return
        }

        if let text = pasteboardClient.readText(),
           let item = ClipboardNormalizer.makeTextItem(
            text,
            sourceAppBundleId: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            sourceAppName: NSWorkspace.shared.frontmostApplication?.localizedName,
            now: Date()
           ) {
            record(item)
            return
        }

        if let imageData = pasteboardClient.readImageData() {
            recordImage(data: imageData)
        }
    }

    private func record(_ item: ClipboardItem) {
        let recorded = historyStore.record(item, now: Date())
        items = historyStore.items
        try? repository.save(items)

        if recorded.type == .image {
            try? repository.save(items)
        }
    }

    private func recordImage(data: Data) {
        let id = UUID()
        let hash = ClipboardNormalizer.contentHash(
            for: .image,
            content: data.base64EncodedString()
        )
        let originalURL = try? imageStore.saveOriginal(
            data: data,
            id: id,
            fileExtension: "tiff"
        )
        let thumbnailURL = try? ImageThumbnailWriter.writeThumbnail(
            from: data,
            to: imageStore.thumbnailURL(for: id, fileExtension: "jpg")
        )

        let item = ClipboardItem(
            id: id,
            type: .image,
            preview: "图片",
            imagePath: originalURL?.path,
            thumbnailPath: thumbnailURL?.path,
            sourceAppBundleId: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            sourceAppName: NSWorkspace.shared.frontmostApplication?.localizedName,
            contentHash: hash,
            createdAt: Date()
        )
        record(item)
    }
}

private enum ImageThumbnailWriter {
    static func writeThumbnail(
        from data: Data,
        to outputURL: URL,
        maxPixelWidth: CGFloat = 640,
        maxPixelHeight: CGFloat = 3_200,
        compressionFactor: CGFloat = 0.74
    ) throws -> URL? {
        guard let image = NSImage(data: data),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return nil
        }

        let sourceWidth = CGFloat(cgImage.width)
        let sourceHeight = CGFloat(cgImage.height)
        guard sourceWidth > 0, sourceHeight > 0 else {
            return nil
        }

        let scale = min(
            1,
            maxPixelWidth / sourceWidth,
            maxPixelHeight / sourceHeight
        )
        let targetSize = NSSize(
            width: max(1, floor(sourceWidth * scale)),
            height: max(1, floor(sourceHeight * scale))
        )

        let thumbnail = NSImage(size: targetSize)
        thumbnail.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1
        )
        thumbnail.unlockFocus()

        guard let tiffData = thumbnail.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let thumbnailData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: compressionFactor]
              )
        else {
            return nil
        }

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try thumbnailData.write(to: outputURL, options: .atomic)
        return outputURL
    }
}
