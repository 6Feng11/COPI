import CopyCore
import XCTest

final class ClipboardCardChromeTests: XCTestCase {
    func testCardTypeLabelIsHiddenBecauseColumnTitleOwnsType() {
        XCTAssertFalse(ClipboardCardChrome.showsTypeLabel)
    }

    func testAllClipboardCardTypesUseWholeCardSelectionHitTarget() {
        XCTAssertTrue(ClipboardCardChrome.usesWholeCardSelectionHitTarget(for: .text))
        XCTAssertTrue(ClipboardCardChrome.usesWholeCardSelectionHitTarget(for: .link))
        XCTAssertTrue(ClipboardCardChrome.usesWholeCardSelectionHitTarget(for: .image))
    }

    func testHoverChromeTapFallsThroughToCardSelectionUnlessDeleteIsConfirming() {
        XCTAssertEqual(
            ClipboardCardChrome.hoverChromeTapAction(isDeleteConfirming: false),
            .selectCard
        )
        XCTAssertEqual(
            ClipboardCardChrome.hoverChromeTapAction(isDeleteConfirming: true),
            .ignore
        )
    }

    func testTimestampOnlyShowsWhenCardIsHovered() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        let today = now.addingTimeInterval(-12)

        XCTAssertNil(
            ClipboardCardChrome.timestampText(
                isHovered: false,
                date: today,
                now: now,
                calendar: calendar
            )
        )
        XCTAssertEqual(
            ClipboardCardChrome.timestampText(
                isHovered: true,
                date: today,
                now: now,
                calendar: calendar
            ),
            ClipboardTimeFormatter.timeString(for: today, calendar: calendar)
        )
    }

    func testHoverTimestampUsesPingFangAndShowsDeleteOutlineIcon() {
        XCTAssertEqual(ClipboardCardChrome.timestampFontName, "PingFang SC")
        XCTAssertEqual(ClipboardCardChrome.timestampFontWeightName, "regular")
        XCTAssertEqual(ClipboardCardChrome.hoverDeleteIconSystemName, "trash")
        XCTAssertEqual(ClipboardCardChrome.hoverDeleteIconSize, 12)
        XCTAssertEqual(ClipboardCardChrome.deleteConfirmationTextSize, 12)
        XCTAssertEqual(ClipboardCardChrome.hoverChromeTextSize, 14)
        XCTAssertEqual(ClipboardCardChrome.hoverChromeIconSize, 14)
        XCTAssertEqual(ClipboardCardChrome.hoverChromeControlHeight, 48)
        XCTAssertEqual(ClipboardCardChrome.textCardContentInset, 12)
        XCTAssertEqual(ClipboardCardChrome.textLineBaselineToCenterOffset, 5)
        XCTAssertEqual(ClipboardCardChrome.deleteConfirmationWidth, 96)
        XCTAssertEqual(ClipboardCardChrome.deleteConfirmationSpringResponse, 0.24)
        XCTAssertEqual(ClipboardCardChrome.linkHoverContentGap, 10)
        XCTAssertEqual(ClipboardCardChrome.linkActionIconSystemName, "arrow.up.right")
    }

    func testDeleteConfirmationButtonsShowCancelBeforeDelete() {
        XCTAssertEqual(ClipboardCardChrome.deleteConfirmationButtonOrder, [.cancel, .delete])
    }

    func testLinkActionOnlyShowsForHoveredLinkWithDestination() {
        XCTAssertNil(ClipboardCardChrome.linkActionTitle(isHovered: false, hasDestination: true))
        XCTAssertNil(ClipboardCardChrome.linkActionTitle(isHovered: true, hasDestination: false))
        XCTAssertEqual(ClipboardCardChrome.linkActionTitle(isHovered: true, hasDestination: true), "前往")
    }

    func testLinkActionIsPlacedBeforeURLText() {
        XCTAssertEqual(ClipboardCardChrome.linkActionPlacement, .leading)
    }

    func testLinkTextReservesTenPointGapBeforeHoverChromeContent() {
        XCTAssertGreaterThan(
            ClipboardCardChrome.linkTrailingHoverContentReservedWidth,
            ClipboardCardChrome.linkHoverContentGap
        )
        XCTAssertEqual(
            ClipboardCardChrome.linkTrailingHoverContentReservedWidth
                - ClipboardCardChrome.linkHoverMetadataReservedWidth,
            ClipboardCardChrome.linkHoverContentGap
        )
    }

    func testHoverChromeOpacityMatchesProgressiveBlurHoverState() {
        XCTAssertEqual(ClipboardCardChrome.hoverChromeOpacity(isHovered: false), 0)
        XCTAssertEqual(ClipboardCardChrome.hoverChromeOpacity(isHovered: true), 1)
    }

    func testHoverChromeOnlyRendersForActiveHoverOrConfirmationState() {
        XCTAssertFalse(
            ClipboardCardChrome.shouldRenderHoverChrome(
                isHovered: false,
                isDeleteConfirming: false
            )
        )
        XCTAssertTrue(
            ClipboardCardChrome.shouldRenderHoverChrome(
                isHovered: true,
                isDeleteConfirming: false
            )
        )
        XCTAssertTrue(
            ClipboardCardChrome.shouldRenderHoverChrome(
                isHovered: false,
                isDeleteConfirming: true
            )
        )
    }

    func testImagePreviewUsesOuterCardAsItsOnlyContainer() {
        XCTAssertFalse(ClipboardCardChrome.usesNestedImagePreviewContainer)
    }

    func testImagePreviewUsesImageAspectRatioInsteadOfSquareCrop() {
        XCTAssertEqual(
            ClipboardCardChrome.imagePreviewAspectRatio(width: 1200, height: 3600),
            1.0 / 3.0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            ClipboardCardChrome.imagePreviewAspectRatio(width: 2400, height: 1200),
            2.0,
            accuracy: 0.0001
        )
    }

    func testImagePreviewFallsBackToSquareRatioForInvalidImageDimensions() {
        XCTAssertEqual(ClipboardCardChrome.imagePreviewAspectRatio(width: 0, height: 800), 1)
        XCTAssertEqual(ClipboardCardChrome.imagePreviewAspectRatio(width: 800, height: 0), 1)
    }

    func testImageHoverChromeUsesBottomPlacementLikeProgressiveBlurHoverExample() {
        XCTAssertEqual(ClipboardCardChrome.hoverChromePlacement(for: .image), .bottom)
    }

    func testImageHoverChromeContentAlignsToTrailingEdge() {
        XCTAssertTrue(ClipboardCardChrome.hoverChromeUsesTrailingContent(for: .image))
    }

    func testTextColumnHoverChromeUsesOpaqueTrailingShieldToHideCoveredContent() {
        XCTAssertEqual(ClipboardCardChrome.hoverChromePlacement(for: .text), .trailing)
        XCTAssertEqual(ClipboardCardChrome.hoverChromePlacement(for: .link), .trailing)

        let spec = ClipboardCardChrome.progressiveBlurSpec(for: .text)

        XCTAssertEqual(spec.blurLayers, 7)
        XCTAssertEqual(spec.blurIntensity, 0.68)
        XCTAssertEqual(spec.fixedHeight, ClipboardCardChrome.hoverChromeControlHeight)
        XCTAssertEqual(spec.transitionDuration, 0.14)
        XCTAssertEqual(spec.widthFraction, 0.56)
        XCTAssertEqual(spec.edgeFadeFraction, 0.88)
        XCTAssertEqual(spec.materialOpacity, 0.94)
        XCTAssertEqual(spec.tintOpacity, 0.78)
        XCTAssertEqual(spec.legibilityScrimOpacity, 0.88)
    }

    func testTextAndLinkHoverChromeVisibleHeightStaysSingleLineHeight() {
        XCTAssertEqual(
            ClipboardCardChrome.hoverChromeVisibleHeight(containerHeight: 280, for: .text),
            ClipboardCardChrome.hoverChromeControlHeight
        )
        XCTAssertEqual(
            ClipboardCardChrome.hoverChromeVisibleHeight(containerHeight: 280, for: .link),
            ClipboardCardChrome.hoverChromeControlHeight
        )
    }

    func testFixedHoverChromeVisibleHeightNeverExceedsContainerHeight() {
        XCTAssertEqual(
            ClipboardCardChrome.hoverChromeVisibleHeight(containerHeight: 32, for: .text),
            32
        )
    }

    func testImageProgressiveBlurMatchesOfficialHoverExampleParameters() {
        let spec = ClipboardCardChrome.progressiveBlurSpec(for: .image)

        XCTAssertEqual(spec.blurLayers, 8)
        XCTAssertEqual(spec.blurIntensity, 0.5)
        XCTAssertEqual(spec.heightFraction, 0.75)
        XCTAssertEqual(spec.transitionDuration, 0.2)
        XCTAssertEqual(
            ClipboardCardChrome.hoverChromeVisibleHeight(containerHeight: 280, for: .image),
            210
        )
    }

    func testImageProgressiveBlurUsesSourceImageInsteadOfMaterialPanel() {
        let spec = ClipboardCardChrome.progressiveBlurSpec(for: .image)

        XCTAssertTrue(spec.usesSourceImageBackdrop)
        XCTAssertFalse(spec.usesMaterialBackdrop)
    }

    func testImageProgressiveBlurAddsEdgeFadeAndLegibilityScrim() {
        let spec = ClipboardCardChrome.progressiveBlurSpec(for: .image)

        XCTAssertEqual(spec.edgeFadeFraction, 0.28)
        XCTAssertEqual(spec.legibilityScrimOpacity, 0.42)
    }

    func testSearchEntryIsHiddenForTheCurrentPanelLayout() {
        XCTAssertFalse(ClipboardCardChrome.showsSearchEntry)
    }

    func testEmptyStateShowsOnlyWhenThereAreNoVisibleItems() {
        XCTAssertTrue(ClipboardCardChrome.showsEmptyState(visibleItemCount: 0))
        XCTAssertFalse(ClipboardCardChrome.showsEmptyState(visibleItemCount: 1))
    }

    func testEmptyStateUsesBundledImageCenteredInPanel() {
        XCTAssertEqual(ClipboardCardChrome.emptyStateImageName, "EmptyState")
        XCTAssertEqual(ClipboardCardChrome.emptyStateImageExtension, "png")
        XCTAssertEqual(ClipboardCardChrome.emptyStateImageDisplaySize, 200)
    }

    func testPanelBackgroundUsesMacOSMaterialWithDarkTint() {
        XCTAssertTrue(ClipboardCardChrome.usesPanelMaterialBackground)
        XCTAssertEqual(ClipboardCardChrome.panelCornerRadius, 28)
        XCTAssertEqual(ClipboardCardChrome.panelMaterialTintOpacity, 0.72)
        XCTAssertEqual(ClipboardCardChrome.panelBorderOpacity, 0.10)
    }

    func testColumnTitleOnlyShowsWhenColumnIsHovered() {
        XCTAssertEqual(ClipboardCardChrome.columnTitleOpacity(isHovered: false), 0)
        XCTAssertEqual(ClipboardCardChrome.columnTitleOpacity(isHovered: true), 1)
    }

    func testColumnTitleReservesTopSpaceBeforeFirstCard() {
        XCTAssertEqual(ClipboardCardChrome.columnTitleHeight, 24)
        XCTAssertEqual(ClipboardCardChrome.columnTitleTopInset, 2)
        XCTAssertGreaterThanOrEqual(
            ClipboardCardChrome.columnContentTopInset,
            ClipboardCardChrome.columnTitleTopInset + ClipboardCardChrome.columnTitleHeight + 6
        )
    }

    func testTextCardDisplaysFullCopiedPlainTextInsteadOfPreview() {
        let item = ClipboardItem(
            type: .text,
            preview: "第一行...",
            plainText: "第一行完整内容\n第二行完整内容\n第三行完整内容",
            contentHash: "text-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(
            ClipboardCardChrome.displayText(for: item),
            "第一行完整内容\n第二行完整内容\n第三行完整内容"
        )
        XCTAssertNil(ClipboardCardChrome.textLineLimit(for: item))
    }

    func testTextCardFallsBackToPreviewWhenPlainTextIsMissing() {
        let item = ClipboardItem(
            type: .text,
            preview: "旧数据文字",
            contentHash: "text-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(ClipboardCardChrome.displayText(for: item), "旧数据文字")
        XCTAssertNil(ClipboardCardChrome.textLineLimit(for: item))
    }

    func testSingleLineTextCardUsesFortyEightPointMinimumHeight() {
        let item = ClipboardItem(
            type: .text,
            preview: "单行文字",
            plainText: "单行文字",
            contentHash: "text-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertEqual(ClipboardCardChrome.minimumCardHeight(for: item), 48)
    }

    func testMultiLineTextAndImageCardsDoNotUseTextMinimumHeight() {
        let textItem = ClipboardItem(
            type: .text,
            preview: "多行",
            plainText: "第一行\n第二行",
            contentHash: "text-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )
        let imageItem = ClipboardItem(
            type: .image,
            preview: "图片",
            contentHash: "image-hash",
            createdAt: Date(timeIntervalSince1970: 0)
        )

        XCTAssertNil(ClipboardCardChrome.minimumCardHeight(for: textItem))
        XCTAssertNil(ClipboardCardChrome.minimumCardHeight(for: imageItem))
    }
}
