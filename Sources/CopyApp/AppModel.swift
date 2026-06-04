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

    private func loadHistory() {
        let loadedItems = (try? repository.load()) ?? []
        historyStore = ClipboardHistoryStore(items: loadedItems, retentionLimit: 1000)
        items = historyStore.items
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    private func pollPasteboard() {
        let currentChangeCount = pasteboardClient.changeCount
        guard currentChangeCount != lastPasteboardChangeCount else {
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

        let item = ClipboardItem(
            id: id,
            type: .image,
            preview: "图片",
            imagePath: originalURL?.path,
            thumbnailPath: imageStore.thumbnailURL(for: id, fileExtension: "tiff").path,
            sourceAppBundleId: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            sourceAppName: NSWorkspace.shared.frontmostApplication?.localizedName,
            contentHash: hash,
            createdAt: Date()
        )
        record(item)
    }
}
