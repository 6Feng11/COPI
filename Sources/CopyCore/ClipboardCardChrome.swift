import Foundation

public enum ClipboardCardChrome {
    public enum HoverChromeTapAction: Equatable, Sendable {
        case selectCard
        case ignore
    }

    public enum HoverChromePlacement: Equatable, Sendable {
        case top
        case trailing
        case bottom
    }

    public enum LinkActionPlacement: Equatable, Sendable {
        case leading
        case trailing
    }

    public enum DeleteConfirmationButtonRole: Equatable, Sendable {
        case cancel
        case delete
    }

    public struct ProgressiveBlurSpec: Equatable, Sendable {
        public var blurLayers: Int
        public var blurIntensity: Double
        public var heightFraction: Double
        public var fixedHeight: Double?
        public var transitionDuration: Double
        public var widthFraction: Double
        public var usesSourceImageBackdrop: Bool
        public var usesMaterialBackdrop: Bool
        public var materialOpacity: Double
        public var tintOpacity: Double
        public var edgeFadeFraction: Double
        public var legibilityScrimOpacity: Double

        public init(
            blurLayers: Int,
            blurIntensity: Double,
            heightFraction: Double,
            fixedHeight: Double? = nil,
            transitionDuration: Double,
            widthFraction: Double = 1,
            usesSourceImageBackdrop: Bool = false,
            usesMaterialBackdrop: Bool = true,
            materialOpacity: Double = 1,
            tintOpacity: Double = 0,
            edgeFadeFraction: Double = 0,
            legibilityScrimOpacity: Double = 0
        ) {
            self.blurLayers = blurLayers
            self.blurIntensity = blurIntensity
            self.heightFraction = heightFraction
            self.fixedHeight = fixedHeight
            self.transitionDuration = transitionDuration
            self.widthFraction = widthFraction
            self.usesSourceImageBackdrop = usesSourceImageBackdrop
            self.usesMaterialBackdrop = usesMaterialBackdrop
            self.materialOpacity = materialOpacity
            self.tintOpacity = tintOpacity
            self.edgeFadeFraction = edgeFadeFraction
            self.legibilityScrimOpacity = legibilityScrimOpacity
        }
    }

    public static let showsTypeLabel = false
    public static let usesNestedImagePreviewContainer = false
    public static let showsSearchEntry = false
    public static let usesPanelMaterialBackground = true
    public static let panelCornerRadius = 28.0
    public static let panelMaterialTintOpacity = 0.72
    public static let panelBorderOpacity = 0.10
    public static let emptyStateImageName = "EmptyState"
    public static let emptyStateImageExtension = "png"
    public static let emptyStateImageDisplaySize = 200.0
    public static let timestampFontName = "PingFang SC"
    public static let timestampFontWeightName = "regular"
    public static let hoverDeleteIconSystemName = "trash"
    public static let hoverDeleteIconSize = 12.0
    public static let deleteConfirmationTextSize = 12.0
    public static let hoverChromeTextSize = 14.0
    public static let hoverChromeIconSize = 14.0
    public static let hoverChromeControlHeight = 48.0
    public static let columnTitleHeight = 24.0
    public static let columnTitleTopInset = 2.0
    public static let columnContentTopInset = 34.0
    public static let textCardContentInset = 12.0
    public static let textLineBaselineToCenterOffset = 5.0
    public static let deleteConfirmationWidth = 96.0
    public static let deleteConfirmationSpringResponse = 0.24
    public static let linkHoverContentGap = 10.0
    public static let linkHoverMetadataReservedWidth = 150.0
    public static let linkTrailingHoverContentReservedWidth = linkHoverMetadataReservedWidth + linkHoverContentGap
    public static let linkActionIconSystemName = "arrow.up.right"
    public static let linkActionPlacement: LinkActionPlacement = .leading
    public static let deleteConfirmationButtonOrder: [DeleteConfirmationButtonRole] = [.cancel, .delete]

    public static func timestampText(
        isHovered: Bool,
        date: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        guard isHovered else {
            return nil
        }

        return ClipboardTimeFormatter.timestampDisplayString(
            for: date,
            now: now,
            calendar: calendar
        )
    }

    public static func linkActionTitle(isHovered: Bool, hasDestination: Bool) -> String? {
        guard isHovered, hasDestination else {
            return nil
        }

        return "前往"
    }

    public static func hoverChromeOpacity(isHovered: Bool) -> Double {
        isHovered ? 1 : 0
    }

    public static func shouldRenderHoverChrome(
        isHovered: Bool,
        isDeleteConfirming: Bool
    ) -> Bool {
        isHovered || isDeleteConfirming
    }

    public static func showsEmptyState(visibleItemCount: Int) -> Bool {
        visibleItemCount == 0
    }

    public static func columnTitleOpacity(isHovered: Bool) -> Double {
        isHovered ? 1 : 0
    }

    public static func usesWholeCardSelectionHitTarget(for type: ClipboardItemType) -> Bool {
        switch type {
        case .text, .link, .image:
            return true
        }
    }

    public static func hoverChromeUsesTrailingContent(for type: ClipboardItemType) -> Bool {
        switch type {
        case .text, .link, .image:
            return true
        }
    }

    public static func hoverChromeTapAction(isDeleteConfirming: Bool) -> HoverChromeTapAction {
        isDeleteConfirming ? .ignore : .selectCard
    }

    public static func displayText(for item: ClipboardItem) -> String {
        guard item.type == .text else {
            return item.preview
        }

        return item.plainText ?? item.preview
    }

    public static func textLineLimit(for item: ClipboardItem) -> Int? {
        guard item.type == .text else {
            return 1
        }

        return nil
    }

    public static func colorSwatch(for item: ClipboardItem) -> ClipboardColorSwatch? {
        guard item.type == .text else {
            return nil
        }

        return ClipboardColorSwatch.parse(displayText(for: item))
    }

    public static func minimumCardHeight(for item: ClipboardItem) -> Double? {
        guard item.type == .text else {
            return nil
        }

        let text = displayText(for: item)
        guard !text.contains(where: \.isNewline) else {
            return nil
        }

        return 48
    }

    public static func imagePreviewAspectRatio(width: Double, height: Double) -> Double {
        guard width.isFinite,
              height.isFinite,
              width > 0,
              height > 0
        else {
            return 1
        }

        return width / height
    }

    public static func hoverChromePlacement(for type: ClipboardItemType) -> HoverChromePlacement {
        switch type {
        case .image:
            return .bottom
        case .text, .link:
            return .trailing
        }
    }

    public static func progressiveBlurSpec(for type: ClipboardItemType) -> ProgressiveBlurSpec {
        switch type {
        case .image:
            return ProgressiveBlurSpec(
                blurLayers: 8,
                blurIntensity: 0.5,
                heightFraction: 0.75,
                transitionDuration: 0.2,
                usesSourceImageBackdrop: true,
                usesMaterialBackdrop: false,
                edgeFadeFraction: 0.28,
                legibilityScrimOpacity: 0.42
            )
        case .text, .link:
            return ProgressiveBlurSpec(
                blurLayers: 7,
                blurIntensity: 0.68,
                heightFraction: 1,
                fixedHeight: hoverChromeControlHeight,
                transitionDuration: 0.14,
                widthFraction: 0.56,
                materialOpacity: 0.94,
                tintOpacity: 0.78,
                edgeFadeFraction: 0.88,
                legibilityScrimOpacity: 0.88
            )
        }
    }

    public static func hoverChromeVisibleHeight(
        containerHeight: Double,
        for type: ClipboardItemType
    ) -> Double {
        let spec = progressiveBlurSpec(for: type)
        if let fixedHeight = spec.fixedHeight {
            return min(containerHeight, fixedHeight)
        }

        return containerHeight * spec.heightFraction
    }
}
