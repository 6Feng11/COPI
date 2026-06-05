import CopyCore
import AppKit
import SwiftUI

struct ClipboardOverlayView: View {
    @ObservedObject var model: AppModel
    let onSelectItem: (ClipboardItem) -> Void
    let onOpenLink: (ClipboardItem) -> Void

    @State private var query = ""
    @State private var isSearchExpanded = false
    @State private var hoveredDockItemID: ClipboardItem.ID?
    @State private var hoveredColumnID: ClipboardColumnLayout.ColumnID?
    @State private var deleteConfirmation = DeleteConfirmationState()
    @StateObject private var imageCache = ClipboardImageCache()
    @FocusState private var isSearchFocused: Bool

    private let dockMaximumScale = 1.032
    private let dockNeighborScale = 1.014
    private let clipboardCardSpacing = 8.0
    private let clipboardCardHoverInset = 5.0
    private let columnSpacing = 8.0

    private var results: [ClipboardItem] {
        model.search(query)
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    collapseSearchAfterOutsideTap()
                    cancelDeleteConfirmation()
                }

            if ClipboardCardChrome.showsEmptyState(visibleItemCount: results.count) {
                emptyStateView
            } else {
                historyList
            }
        }
        .padding(18)
        .frame(width: 800, height: 560)
        .background(panelBackground)
        .overlay(
            panelShape
                .stroke(Color.white.opacity(ClipboardCardChrome.panelBorderOpacity), lineWidth: 1)
        )
        .preferredColorScheme(.dark)
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: CGFloat(ClipboardCardChrome.panelCornerRadius),
            style: .continuous
        )
    }

    @ViewBuilder
    private var panelBackground: some View {
        if ClipboardCardChrome.usesPanelMaterialBackground {
            panelShape
                .fill(.regularMaterial)
                .overlay(
                    panelShape
                        .fill(Color.black.opacity(ClipboardCardChrome.panelMaterialTintOpacity))
                )
        } else {
            panelShape
                .fill(Color.black.opacity(0.94))
        }
    }

    private var headerBar: some View {
        ZStack(alignment: .trailing) {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
                .contentShape(Rectangle())
                .onTapGesture {
                    collapseSearchAfterOutsideTap()
                }

            dynamicSearch
                .zIndex(isSearchExpanded ? 2 : 1)
        }
        .frame(height: 44)
    }

    private var dynamicSearch: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isSearchExpanded = true
                    isSearchFocused = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            if isSearchExpanded {
                TextField("搜索", text: $query)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                if !query.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            query = ""
                            isSearchFocused = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
        }
        .padding(.leading, isSearchExpanded ? 8 : 3)
        .padding(.trailing, isSearchExpanded ? 12 : 0)
        .frame(maxWidth: isSearchExpanded ? .infinity : nil)
        .frame(width: isSearchExpanded ? nil : 40)
        .frame(height: 40)
        .background(searchBackground)
        .overlay(searchBorder)
        .shadow(
            color: isSearchExpanded ? Color.white.opacity(0.12) : Color.clear,
            radius: 18,
            x: 0,
            y: 8
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSearchExpanded)
        .onChange(of: isSearchFocused) { _, focused in
            guard !focused else {
                return
            }
            collapseSearchAfterOutsideTap()
        }
    }

    @ViewBuilder
    private var searchBackground: some View {
        if isSearchExpanded {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.30),
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Capsule(style: .continuous))
                )
        } else {
            Circle()
                .fill(Color.white.opacity(0.09))
        }
    }

    @ViewBuilder
    private var searchBorder: some View {
        if isSearchExpanded {
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.42),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        } else {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func collapseSearchAfterOutsideTap() {
        guard isSearchExpanded else {
            return
        }

        let nextState = SearchBoxState(
            query: query,
            isExpanded: isSearchExpanded
        ).collapsedAfterOutsideTap()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            query = nextState.query
            isSearchExpanded = nextState.isExpanded
            isSearchFocused = false
        }
    }

    private var historyList: some View {
        GeometryReader { proxy in
            let columnWidths = ClipboardColumnLayout.widths(
                totalWidth: proxy.size.width,
                columnSpacing: columnSpacing
            )

            HStack(alignment: .top, spacing: columnSpacing) {
                ForEach(ClipboardColumnLayout.columns, id: \.id) { column in
                    let columnWidth = CGFloat(columnWidths[column.id] ?? 0)

                    clipboardColumn(for: column)
                        .frame(
                            width: columnWidth,
                            height: proxy.size.height
                        )
                }
            }
        }
        .frame(maxHeight: .infinity)
        .simultaneousGesture(
            TapGesture().onEnded {
                collapseSearchAfterOutsideTap()
            }
        )
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if let image = emptyStateImage() {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(
                    width: CGFloat(ClipboardCardChrome.emptyStateImageDisplaySize),
                    height: CGFloat(ClipboardCardChrome.emptyStateImageDisplaySize)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .allowsHitTesting(false)
        } else {
            Color.clear
        }
    }

    private func emptyStateImage() -> NSImage? {
        let name = ClipboardCardChrome.emptyStateImageName
        let fileExtension = ClipboardCardChrome.emptyStateImageExtension

        if let bundleURL = Bundle.main.url(forResource: name, withExtension: fileExtension),
           let image = NSImage(contentsOf: bundleURL) {
            return image
        }

        let projectResourceURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources")
            .appendingPathComponent("\(name).\(fileExtension)")
        return NSImage(contentsOf: projectResourceURL)
    }

    private func clipboardColumn(for column: ClipboardColumnLayout.Column) -> some View {
        let columnItems = ClipboardColumnLayout.items(in: column.id, from: results)
        let isColumnHovered = hoveredColumnID == column.id
        let trailingGutter = CGFloat(
            ClipboardColumnLayout.scrollIndicatorGutterTrailingPadding(for: column.id)
        )

        return ZStack(alignment: .topLeading) {
            ScrollView {
                LazyVStack(spacing: clipboardCardSpacing) {
                    ForEach(columnItems) { item in
                        overlayRow(for: item, in: columnItems)
                    }
                }
                .padding(.top, CGFloat(ClipboardCardChrome.columnContentTopInset))
                .padding(.bottom, 2)
                .padding(.leading, clipboardCardHoverInset)
                .padding(.trailing, clipboardCardHoverInset + trailingGutter)
            }
            .scrollClipDisabled()
            .frame(maxHeight: .infinity)

            columnTitleOverlay(for: column, isHovered: isColumnHovered)
        }
        .onHover { isHovered in
            hoveredColumnID = isHovered ? column.id : nil
            if !isHovered {
                hoveredDockItemID = nil
            }
        }
    }

    private func columnTitleOverlay(
        for column: ClipboardColumnLayout.Column,
        isHovered: Bool
    ) -> some View {
        Text(column.title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(height: CGFloat(ClipboardCardChrome.columnTitleHeight))
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.42))
            )
            .padding(.leading, clipboardCardHoverInset)
            .padding(.top, CGFloat(ClipboardCardChrome.columnTitleTopInset))
            .opacity(ClipboardCardChrome.columnTitleOpacity(isHovered: isHovered))
            .animation(.easeOut(duration: 0.18), value: isHovered)
            .allowsHitTesting(false)
    }

    private func overlayRow(for item: ClipboardItem, in columnItems: [ClipboardItem]) -> some View {
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let scale = dockScale(for: item, in: columnItems)
        let isHovered = hoveredDockItemID == item.id
        let isDeleteConfirming = deleteConfirmation.isConfirming(item.id)
        let shouldRenderHoverChrome = ClipboardCardChrome.shouldRenderHoverChrome(
            isHovered: isHovered,
            isDeleteConfirming: isDeleteConfirming
        )

        let rowAlignment = item.type == .image
            ? Alignment.center
            : Alignment(horizontal: .trailing, vertical: .clipboardTextLineCenter)

        return ZStack(alignment: rowAlignment) {
            clipboardContentBlock(for: item, isHovered: isHovered)
                .padding(item.type == .image ? 0 : CGFloat(ClipboardCardChrome.textCardContentInset))
                .alignmentGuide(.clipboardTextLineCenter) { dimensions in
                    dimensions[.lastTextBaseline] - CGFloat(ClipboardCardChrome.textLineBaselineToCenterOffset)
                }

            if shouldRenderHoverChrome {
                hoverChromeBackdrop(
                    for: item,
                    isHovered: shouldRenderHoverChrome
                )
                .allowsHitTesting(false)
                .transition(.opacity)

                hoverChromeContent(
                    for: item,
                    isHovered: shouldRenderHoverChrome,
                    isBottom: item.type == .image,
                    isTrailing: item.type != .image,
                    isDeleteConfirming: isDeleteConfirming
                )
                .alignmentGuide(.clipboardTextLineCenter) { dimensions in
                    dimensions[VerticalAlignment.center]
                }
                .transition(.opacity)
            }
        }
            .animation(
                .easeOut(duration: ClipboardCardChrome.progressiveBlurSpec(for: item.type).transitionDuration),
                value: shouldRenderHoverChrome
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: minimumCardHeight(for: item))
            .contentShape(cardShape)
            .background(
                cardShape.fill(Color.white.opacity(0.07))
            )
            .clipShape(cardShape)
            .scaleEffect(scale, anchor: .center)
            .shadow(
                color: Color.black.opacity(scale > 1 ? 0.22 : 0),
                radius: scale > 1 ? 12 : 0,
                x: 0,
                y: scale > 1 ? 7 : 0
            )
            .zIndex(scale)
            .animation(.spring(response: 0.26, dampingFraction: 0.76), value: scale)
            .onHover { isHovered in
                hoveredDockItemID = isHovered ? item.id : nil
                if !isHovered, deleteConfirmation.isConfirming(item.id) {
                    cancelDeleteConfirmation()
                }
            }
            .contentShape(cardShape)
            .onTapGesture {
                selectWholeCardIfNeeded(item)
            }
        .contextMenu {
            Button("复制回剪贴板") {
                onSelectItem(item)
            }
            if LinkDestination.url(for: item) != nil {
                Button("前往") {
                    onOpenLink(item)
                }
            }
            Button("删除", role: .destructive) {
                model.delete(item)
            }
        }
    }

    private func minimumCardHeight(for item: ClipboardItem) -> CGFloat? {
        guard let height = ClipboardCardChrome.minimumCardHeight(for: item) else {
            return nil
        }

        return CGFloat(height)
    }

    private func dockScale(for item: ClipboardItem, in columnItems: [ClipboardItem]) -> CGFloat {
        guard let itemIndex = columnItems.firstIndex(where: { $0.id == item.id }) else {
            return 1
        }

        let hoveredIndex = hoveredDockItemID.flatMap { hoveredID in
            columnItems.firstIndex(where: { $0.id == hoveredID })
        }
        let scale = DockMagnification.scale(
            hoveredIndex: hoveredIndex,
            itemIndex: itemIndex,
            maxScale: dockMaximumScale,
            neighborScale: dockNeighborScale
        )
        return CGFloat(scale)
    }

    private func clipboardContentBlock(for item: ClipboardItem, isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item.type {
            case .text:
                textContent(for: item)
            case .link:
                HStack(spacing: 10) {
                    if ClipboardCardChrome.linkActionPlacement == .leading {
                        openLinkButton(for: item, isHovered: isHovered)
                            .layoutPriority(1)
                        linkPreviewText(for: item)
                    } else {
                        linkPreviewText(for: item)
                        openLinkButton(for: item, isHovered: isHovered)
                            .layoutPriority(1)
                    }
                }
                .padding(
                    .trailing,
                    isHovered ? CGFloat(ClipboardCardChrome.linkTrailingHoverContentReservedWidth) : 0
                )
                .animation(.easeOut(duration: 0.16), value: isHovered)
            case .image:
                imagePreview(for: item)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
        }
    }

    private func linkPreviewText(for item: ClipboardItem) -> some View {
        Text(item.preview)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func textContent(for item: ClipboardItem) -> some View {
        let displayText = ClipboardCardChrome.displayText(for: item)

        if let swatch = ClipboardCardChrome.colorSwatch(for: item) {
            HStack(alignment: .center, spacing: 8) {
                colorSwatchCircle(for: swatch)
                Text(displayText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(ClipboardCardChrome.textLineLimit(for: item))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        } else {
            Text(displayText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(ClipboardCardChrome.textLineLimit(for: item))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
    }

    private func colorSwatchCircle(for swatch: ClipboardColorSwatch) -> some View {
        Circle()
            .fill(
                Color(
                    red: swatch.red,
                    green: swatch.green,
                    blue: swatch.blue,
                    opacity: swatch.alpha
                )
            )
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.24), lineWidth: 0.75)
            )
    }

    private func selectWholeCardIfNeeded(_ item: ClipboardItem) {
        guard ClipboardCardChrome.usesWholeCardSelectionHitTarget(for: item.type),
              deleteConfirmation.isConfirming(item.id) == false
        else {
            return
        }

        onSelectItem(item)
    }

    private func hoverChromeBackdrop(
        for item: ClipboardItem,
        isHovered: Bool
    ) -> some View {
        let placement = ClipboardCardChrome.hoverChromePlacement(for: item.type)
        let blurSpec = ClipboardCardChrome.progressiveBlurSpec(for: item.type)
        let backdropImage = blurSpec.usesSourceImageBackdrop ? image(for: item) : nil

        return GeometryReader { proxy in
            ZStack(alignment: hoverChromeAlignment(for: placement)) {
                ProgressiveBlurHoverStrip(
                    placement: placement,
                    spec: blurSpec,
                    backdropImage: backdropImage
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hoverChromeFrameAlignment(for: placement))

                if blurSpec.legibilityScrimOpacity > 0 {
                    hoverLegibilityScrim(spec: blurSpec, placement: placement)
                        .frame(
                            width: hoverLegibilityScrimWidth(
                                containerWidth: proxy.size.width,
                                placement: placement,
                                spec: blurSpec
                            ),
                            height: hoverLegibilityScrimHeight(
                                containerHeight: proxy.size.height,
                                placement: placement,
                                spec: blurSpec
                            )
                        )
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: hoverChromeFrameAlignment(for: placement)
                        )
                }

            }
        }
        .opacity(ClipboardCardChrome.hoverChromeOpacity(isHovered: isHovered))
        .animation(.easeOut(duration: blurSpec.transitionDuration), value: isHovered)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func hoverChromeContent(
        for item: ClipboardItem,
        isHovered: Bool,
        isBottom: Bool,
        isTrailing: Bool,
        isDeleteConfirming: Bool
    ) -> some View {
        let alignsTrailing = ClipboardCardChrome.hoverChromeUsesTrailingContent(for: item.type)
        let content = HStack(alignment: .center, spacing: isBottom || isTrailing ? 8 : 0) {
            if alignsTrailing {
                Spacer()
            }
            sourceAppIcon(for: item)
                .frame(
                    width: CGFloat(ClipboardCardChrome.hoverChromeIconSize),
                    height: CGFloat(ClipboardCardChrome.hoverChromeIconSize)
                )
            if let timestamp = ClipboardCardChrome.timestampText(
                isHovered: isHovered,
                date: item.createdAt
            ) {
                Text(timestamp)
                    .font(
                        .custom(
                            ClipboardCardChrome.timestampFontName,
                            size: CGFloat(ClipboardCardChrome.hoverChromeTextSize)
                        )
                        .weight(.regular)
                    )
                    .foregroundStyle(.white.opacity(isBottom ? 0.86 : 0.64))
                    .lineLimit(1)
                    .transition(.opacity)
                    .shadow(
                        color: Color.black.opacity(isBottom ? 0.52 : 0),
                        radius: isBottom ? 5 : 0,
                        x: 0,
                        y: 1
                    )
                deleteConfirmationControl(
                    for: item,
                    isBottom: isBottom,
                    isConfirming: isDeleteConfirming
                )
            }
        }

        if isBottom {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(maxHeight: .infinity, alignment: .bottomTrailing)
        } else if isTrailing {
            content
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
        } else {
            content
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func deleteConfirmationControl(
        for item: ClipboardItem,
        isBottom: Bool,
        isConfirming: Bool
    ) -> some View {
        let dividerWidth: CGFloat = 1
        let buttonWidth = (CGFloat(ClipboardCardChrome.deleteConfirmationWidth) - dividerWidth) / 2

        if isConfirming {
            let orderedButtons = Array(ClipboardCardChrome.deleteConfirmationButtonOrder.enumerated())

            HStack(alignment: .center, spacing: 0) {
                ForEach(orderedButtons, id: \.offset) { index, role in
                    deleteConfirmationButton(role: role, for: item, width: buttonWidth)

                    if index < orderedButtons.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: dividerWidth, height: 12)
                    }
                }
            }
            .frame(width: ClipboardCardChrome.deleteConfirmationWidth, height: 26)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.34))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
            )
            .transition(.scale(scale: 0.82, anchor: .trailing).combined(with: .opacity))
        } else {
            Button {
                requestDeleteConfirmation(for: item)
            } label: {
                Image(systemName: ClipboardCardChrome.hoverDeleteIconSystemName)
                    .font(.system(size: CGFloat(ClipboardCardChrome.hoverDeleteIconSize), weight: .medium))
                    .foregroundStyle(.white.opacity(isBottom ? 0.72 : 0.52))
                    .frame(
                        width: CGFloat(ClipboardCardChrome.hoverDeleteIconSize),
                        height: CGFloat(ClipboardCardChrome.hoverDeleteIconSize)
                    )
            }
            .buttonStyle(.plain)
            .frame(
                width: CGFloat(ClipboardCardChrome.hoverDeleteIconSize),
                height: CGFloat(ClipboardCardChrome.hoverDeleteIconSize),
                alignment: .center
            )
            .transition(.scale(scale: 0.82, anchor: .trailing).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func deleteConfirmationButton(
        role: ClipboardCardChrome.DeleteConfirmationButtonRole,
        for item: ClipboardItem,
        width: CGFloat
    ) -> some View {
        switch role {
        case .cancel:
            Button {
                cancelDeleteConfirmation()
            } label: {
                deleteConfirmationButtonLabel(
                    title: "取消",
                    foregroundColor: Color.white.opacity(0.72),
                    width: width
                )
            }
            .buttonStyle(.plain)
        case .delete:
            Button {
                confirmDelete(item)
            } label: {
                deleteConfirmationButtonLabel(
                    title: "删除",
                    foregroundColor: Color.red.opacity(0.92),
                    width: width
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func deleteConfirmationButtonLabel(
        title: String,
        foregroundColor: Color,
        width: CGFloat
    ) -> some View {
        Text(title)
            .font(
                .custom(
                    ClipboardCardChrome.timestampFontName,
                    size: CGFloat(ClipboardCardChrome.deleteConfirmationTextSize)
                )
            )
            .foregroundStyle(foregroundColor)
            .frame(width: width, height: 26, alignment: .center)
    }

    private func requestDeleteConfirmation(for item: ClipboardItem) {
        withAnimation(deleteConfirmationAnimation) {
            deleteConfirmation.requestConfirmation(for: item.id)
        }
    }

    private func confirmDelete(_ item: ClipboardItem) {
        withAnimation(deleteConfirmationAnimation) {
            guard deleteConfirmation.consumeConfirmedDelete(for: item.id) else {
                return
            }
            model.delete(item)
        }
    }

    private func cancelDeleteConfirmation() {
        guard deleteConfirmation.isConfirming else {
            return
        }

        withAnimation(deleteConfirmationAnimation) {
            deleteConfirmation.cancel()
        }
    }

    private var deleteConfirmationAnimation: Animation {
        .spring(
            response: ClipboardCardChrome.deleteConfirmationSpringResponse,
            dampingFraction: 0.86
        )
    }

    private func hoverChromeAlignment(
        for placement: ClipboardCardChrome.HoverChromePlacement
    ) -> Alignment {
        switch placement {
        case .top:
            return .topLeading
        case .trailing:
            return .bottomTrailing
        case .bottom:
            return .bottomLeading
        }
    }

    private func hoverChromeFrameAlignment(
        for placement: ClipboardCardChrome.HoverChromePlacement
    ) -> Alignment {
        switch placement {
        case .top:
            return .top
        case .trailing:
            return .bottomTrailing
        case .bottom:
            return .bottom
        }
    }

    private func hoverLegibilityScrim(
        spec: ClipboardCardChrome.ProgressiveBlurSpec,
        placement: ClipboardCardChrome.HoverChromePlacement
    ) -> some View {
        let startPoint: UnitPoint
        let endPoint: UnitPoint
        let stops: [Gradient.Stop]
        switch placement {
        case .trailing:
            startPoint = .trailing
            endPoint = .leading
            stops = [
                .init(color: Color.black.opacity(spec.legibilityScrimOpacity), location: 0),
                .init(color: Color.black.opacity(spec.legibilityScrimOpacity * 0.96), location: 0.32),
                .init(color: Color.black.opacity(spec.legibilityScrimOpacity * 0.62), location: 0.64),
                .init(color: Color.black.opacity(0), location: 1)
            ]
        case .top:
            startPoint = .top
            endPoint = .bottom
            stops = hoverLegibilityScrimStops(for: spec)
        case .bottom:
            startPoint = .bottom
            endPoint = .top
            stops = hoverLegibilityScrimStops(for: spec)
        }

        return LinearGradient(
            stops: stops,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }

    private func hoverLegibilityScrimStops(
        for spec: ClipboardCardChrome.ProgressiveBlurSpec
    ) -> [Gradient.Stop] {
        [
            .init(color: Color.black.opacity(spec.legibilityScrimOpacity), location: 0),
            .init(color: Color.black.opacity(spec.legibilityScrimOpacity * 0.72), location: 0.36),
            .init(color: Color.black.opacity(spec.legibilityScrimOpacity * 0.28), location: 0.74),
            .init(color: Color.black.opacity(0), location: 1)
        ]
    }

    private func hoverLegibilityScrimWidth(
        containerWidth: CGFloat,
        placement: ClipboardCardChrome.HoverChromePlacement,
        spec: ClipboardCardChrome.ProgressiveBlurSpec
    ) -> CGFloat {
        switch placement {
        case .trailing:
            return containerWidth * spec.widthFraction
        case .top, .bottom:
            return containerWidth
        }
    }

    private func hoverLegibilityScrimHeight(
        containerHeight: CGFloat,
        placement: ClipboardCardChrome.HoverChromePlacement,
        spec: ClipboardCardChrome.ProgressiveBlurSpec
    ) -> CGFloat {
        switch placement {
        case .trailing, .top:
            if let fixedHeight = spec.fixedHeight {
                return min(containerHeight, CGFloat(fixedHeight))
            }
            return containerHeight * spec.heightFraction
        case .bottom:
            return containerHeight * 0.48
        }
    }

    private func hoverBlurHeight(
        containerHeight: CGFloat,
        placement: ClipboardCardChrome.HoverChromePlacement,
        spec: ClipboardCardChrome.ProgressiveBlurSpec
    ) -> CGFloat {
        switch placement {
        case .bottom:
            return containerHeight * spec.heightFraction
        case .top, .trailing:
            if let fixedHeight = spec.fixedHeight {
                return min(containerHeight, CGFloat(fixedHeight))
            }
            return containerHeight * spec.heightFraction
        }
    }

    @ViewBuilder
    private func openLinkButton(for item: ClipboardItem, isHovered: Bool) -> some View {
        if let title = ClipboardCardChrome.linkActionTitle(
            isHovered: isHovered,
            hasDestination: LinkDestination.url(for: item) != nil
        ) {
            Button {
                onOpenLink(item)
            } label: {
                HStack(spacing: 4) {
                    Text(title)
                    Image(systemName: ClipboardCardChrome.linkActionIconSystemName)
                        .font(.system(size: 10, weight: .bold))
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.86))
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .contentShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }
    }

    @ViewBuilder
    private func sourceAppIcon(for item: ClipboardItem) -> some View {
        if let image = sourceAppImage(for: item) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(
                    width: CGFloat(ClipboardCardChrome.hoverChromeIconSize),
                    height: CGFloat(ClipboardCardChrome.hoverChromeIconSize)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            Image(systemName: "app")
                .font(.system(size: CGFloat(ClipboardCardChrome.hoverChromeIconSize), weight: .medium))
                .foregroundStyle(.white.opacity(0.42))
                .frame(
                    width: CGFloat(ClipboardCardChrome.hoverChromeIconSize),
                    height: CGFloat(ClipboardCardChrome.hoverChromeIconSize)
                )
        }
    }

    private func sourceAppImage(for item: ClipboardItem) -> NSImage? {
        guard let bundleId = item.sourceAppBundleId,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
        else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    @ViewBuilder
    private func imagePreview(for item: ClipboardItem) -> some View {
        if let image = image(for: item) {
            let aspectRatio = CGFloat(
                ClipboardCardChrome.imagePreviewAspectRatio(
                    width: Double(image.size.width),
                    height: Double(image.size.height)
                )
            )

            Color.clear
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
        } else {
            Text("图片缩略图")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.52))
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
        }
    }

    private func image(for item: ClipboardItem) -> NSImage? {
        guard let imagePath = ClipboardImagePreviewSource.displayPath(for: item) else {
            return nil
        }

        return imageCache.image(at: imagePath)
    }

}

@MainActor
private final class ClipboardImageCache: ObservableObject {
    private let maxEntries: Int
    private var images: [String: NSImage] = [:]
    private var accessOrder: [String] = []

    init(maxEntries: Int = 160) {
        self.maxEntries = max(1, maxEntries)
    }

    func image(at path: String) -> NSImage? {
        if let image = images[path] {
            markRecentlyUsed(path)
            return image
        }

        guard let image = NSImage(contentsOfFile: path) else {
            return nil
        }

        images[path] = image
        markRecentlyUsed(path)
        pruneIfNeeded()
        return image
    }

    private func markRecentlyUsed(_ path: String) {
        accessOrder.removeAll { $0 == path }
        accessOrder.append(path)
    }

    private func pruneIfNeeded() {
        while images.count > maxEntries,
              let oldestPath = accessOrder.first {
            accessOrder.removeFirst()
            images.removeValue(forKey: oldestPath)
        }
    }
}

private struct ProgressiveBlurHoverStrip: View {
    let placement: ClipboardCardChrome.HoverChromePlacement
    let spec: ClipboardCardChrome.ProgressiveBlurSpec
    let backdropImage: NSImage?

    var body: some View {
        GeometryReader { proxy in
            let overlayHeight = hoverBlurHeight(containerHeight: proxy.size.height)
            let overlayWidth = hoverBlurWidth(containerWidth: proxy.size.width)

            ZStack {
                ForEach(0..<max(spec.blurLayers, 2), id: \.self) { index in
                    progressiveLayer(
                        at: index,
                        containerSize: proxy.size,
                        overlayHeight: overlayHeight,
                        overlayWidth: overlayWidth
                    )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .mask(edgeFadeMask(overlayHeight: overlayHeight, overlayWidth: overlayWidth))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func progressiveLayer(
        at index: Int,
        containerSize: CGSize,
        overlayHeight: CGFloat,
        overlayWidth: CGFloat
    ) -> some View {
        if let backdropImage {
            Image(nsImage: backdropImage)
                .resizable()
                .scaledToFill()
                .frame(width: containerSize.width, height: containerSize.height)
                .clipped()
                .blur(radius: CGFloat(Double(index) * spec.blurIntensity))
                .mask(fullSizeMask(for: index, overlayHeight: overlayHeight, overlayWidth: overlayWidth))
        } else if spec.usesMaterialBackdrop {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(spec.materialOpacity)
                Rectangle()
                    .fill(Color.black.opacity(spec.tintOpacity))
            }
                .mask(fullSizeMask(for: index, overlayHeight: overlayHeight, overlayWidth: overlayWidth))
                .blur(radius: CGFloat(Double(index) * spec.blurIntensity))
        }
    }

    private func hoverBlurHeight(containerHeight: CGFloat) -> CGFloat {
        if let fixedHeight = spec.fixedHeight {
            return min(containerHeight, CGFloat(fixedHeight))
        }

        return containerHeight * spec.heightFraction
    }

    private func hoverBlurWidth(containerWidth: CGFloat) -> CGFloat {
        containerWidth * spec.widthFraction
    }

    @ViewBuilder
    private func fullSizeMask(for index: Int, overlayHeight: CGFloat, overlayWidth: CGFloat) -> some View {
        switch placement {
        case .top:
            VStack(spacing: 0) {
                gradientMask(for: index)
                    .frame(height: overlayHeight)
                Spacer(minLength: 0)
            }
        case .trailing:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    gradientMask(for: index)
                        .frame(width: overlayWidth, height: overlayHeight)
                }
            }
        case .bottom:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                gradientMask(for: index)
                    .frame(height: overlayHeight)
            }
        }
    }

    @ViewBuilder
    private func edgeFadeMask(overlayHeight: CGFloat, overlayWidth: CGFloat) -> some View {
        if spec.edgeFadeFraction <= 0 {
            Rectangle()
                .fill(.white)
        } else {
            switch placement {
            case .top:
                VStack(spacing: 0) {
                    edgeFadeGradient()
                        .frame(height: overlayHeight)
                    Spacer(minLength: 0)
                }
            case .trailing:
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        edgeFadeGradient()
                            .frame(width: overlayWidth, height: overlayHeight)
                    }
                }
            case .bottom:
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    edgeFadeGradient()
                        .frame(height: overlayHeight)
                }
            }
        }
    }

    private func edgeFadeGradient() -> some View {
        let fadeStart = max(0, min(1, 1 - spec.edgeFadeFraction))
        let softMid = min(1, fadeStart + spec.edgeFadeFraction * 0.38)
        let softEnd = min(1, fadeStart + spec.edgeFadeFraction * 0.76)

        return LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: fadeStart),
                .init(color: .white.opacity(0.72), location: softMid),
                .init(color: .white.opacity(0.22), location: softEnd),
                .init(color: .clear, location: 1)
            ],
            startPoint: placement.gradientStartPoint,
            endPoint: placement.gradientEndPoint
        )
    }

    private func gradientMask(for index: Int) -> some View {
        let segmentSize = 1.0 / Double(spec.blurLayers + 1)
        let start = Double(index) * segmentSize
        let firstPeak = Double(index + 1) * segmentSize
        let secondPeak = Double(index + 2) * segmentSize
        let end = Double(index + 3) * segmentSize

        return LinearGradient(
            stops: [
                .init(color: .clear, location: max(0, min(1, start))),
                .init(color: .white, location: max(0, min(1, firstPeak))),
                .init(color: .white, location: max(0, min(1, secondPeak))),
                .init(color: .clear, location: max(0, min(1, end)))
            ],
            startPoint: placement.gradientStartPoint,
            endPoint: placement.gradientEndPoint
        )
    }
}

private extension ClipboardCardChrome.HoverChromePlacement {
    var gradientStartPoint: UnitPoint {
        switch self {
        case .top:
            return .top
        case .trailing:
            return .trailing
        case .bottom:
            return .bottom
        }
    }

    var gradientEndPoint: UnitPoint {
        switch self {
        case .top:
            return .bottom
        case .trailing:
            return .leading
        case .bottom:
            return .top
        }
    }
}

private extension VerticalAlignment {
    enum ClipboardTextLineCenterAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let clipboardTextLineCenter = VerticalAlignment(ClipboardTextLineCenterAlignment.self)
}
