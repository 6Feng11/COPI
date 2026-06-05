public enum ClipboardColumnLayout {
    public enum ColumnID: Equatable, Hashable, Sendable {
        case textAndLinks
        case images
    }

    public struct Column: Equatable, Sendable {
        public var id: ColumnID
        public var types: [ClipboardItemType]
        public var title: String
        public var widthUnit: Int

        public init(
            id: ColumnID,
            types: [ClipboardItemType],
            title: String,
            widthUnit: Int
        ) {
            self.id = id
            self.types = types
            self.title = title
            self.widthUnit = widthUnit
        }
    }

    public static let columns: [Column] = [
        Column(id: .textAndLinks, types: [.text, .link], title: "文字 / 链接", widthUnit: 5),
        Column(id: .images, types: [.image], title: "图片", widthUnit: 3)
    ]

    public static var totalWidthUnits: Int {
        columns.reduce(0) { $0 + $1.widthUnit }
    }

    public static func widths(
        totalWidth: Double,
        columnSpacing: Double
    ) -> [ColumnID: Double] {
        let spacingWidth = columnSpacing * Double(max(columns.count - 1, 0))
        let availableWidth = max(totalWidth - spacingWidth, 0)
        let unitWidth = availableWidth / Double(totalWidthUnits)

        return Dictionary(uniqueKeysWithValues: columns.map { column in
            (column.id, unitWidth * Double(column.widthUnit))
        })
    }

    public static func scrollIndicatorGutterTrailingPadding(for columnID: ColumnID) -> Double {
        switch columnID {
        case .textAndLinks:
            return 14
        case .images:
            return 0
        }
    }

    public static func items(
        in columnID: ColumnID,
        from items: [ClipboardItem]
    ) -> [ClipboardItem] {
        guard let column = columns.first(where: { $0.id == columnID }) else {
            return []
        }

        return items.filter { column.types.contains($0.type) }
    }
}
