import Foundation

public enum ClipboardItemType: String, Codable, Equatable, Sendable {
    case text
    case link
    case image
}

public struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var type: ClipboardItemType
    public var preview: String
    public var plainText: String?
    public var url: String?
    public var imagePath: String?
    public var thumbnailPath: String?
    public var sourceAppBundleId: String?
    public var sourceAppName: String?
    public var contentHash: String
    public var createdAt: Date
    public var lastUsedAt: Date?
    public var useCount: Int
    public var isFavorite: Bool

    public init(
        id: UUID = UUID(),
        type: ClipboardItemType,
        preview: String,
        plainText: String? = nil,
        url: String? = nil,
        imagePath: String? = nil,
        thumbnailPath: String? = nil,
        sourceAppBundleId: String? = nil,
        sourceAppName: String? = nil,
        contentHash: String,
        createdAt: Date,
        lastUsedAt: Date? = nil,
        useCount: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.type = type
        self.preview = preview
        self.plainText = plainText
        self.url = url
        self.imagePath = imagePath
        self.thumbnailPath = thumbnailPath
        self.sourceAppBundleId = sourceAppBundleId
        self.sourceAppName = sourceAppName
        self.contentHash = contentHash
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
        self.isFavorite = isFavorite
    }
}
