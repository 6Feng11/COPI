import Foundation

public struct ClipboardHistoryStore: Sendable {
    public private(set) var items: [ClipboardItem]
    public var retentionLimit: Int?

    public init(items: [ClipboardItem] = [], retentionLimit: Int? = 1000) {
        self.items = items.sorted { $0.createdAt > $1.createdAt }
        self.retentionLimit = retentionLimit
        enforceRetentionLimit()
    }

    @discardableResult
    public mutating func record(_ item: ClipboardItem, now: Date) -> ClipboardItem {
        if let existingIndex = items.firstIndex(where: { $0.contentHash == item.contentHash }) {
            var updated = items.remove(at: existingIndex)
            updated.createdAt = now
            updated.lastUsedAt = now
            updated.useCount += 1
            items.insert(updated, at: 0)
            enforceRetentionLimit()
            return updated
        }

        var newItem = item
        newItem.createdAt = now
        items.insert(newItem, at: 0)
        enforceRetentionLimit()
        return newItem
    }

    public func search(_ query: String) -> [ClipboardItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return items
        }

        let lowercasedQuery = trimmedQuery.lowercased()
        return items.filter { item in
            item.preview.lowercased().contains(lowercasedQuery)
                || item.plainText?.lowercased().contains(lowercasedQuery) == true
                || item.url?.lowercased().contains(lowercasedQuery) == true
        }
    }

    public mutating func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }

    public mutating func clear() {
        items.removeAll()
    }

    private mutating func enforceRetentionLimit() {
        guard let retentionLimit, retentionLimit >= 0, items.count > retentionLimit else {
            return
        }
        items = Array(items.prefix(retentionLimit))
    }
}
