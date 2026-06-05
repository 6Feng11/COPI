import CopyCore
import XCTest

final class SearchBoxStateTests: XCTestCase {
    func testOutsideTapCollapsesExpandedSearchAndClearsQuery() {
        let state = SearchBoxState(query: "链接", isExpanded: true)

        let nextState = state.collapsedAfterOutsideTap()

        XCTAssertEqual(nextState, SearchBoxState(query: "", isExpanded: false))
    }

    func testOutsideTapKeepsCollapsedSearchUnchanged() {
        let state = SearchBoxState(query: "", isExpanded: false)

        let nextState = state.collapsedAfterOutsideTap()

        XCTAssertEqual(nextState, state)
    }

    func testCollapsedSearchUsesCompactCirclePresentation() {
        let state = SearchBoxState(query: "", isExpanded: false)

        XCTAssertEqual(state.presentation, .compactCircle)
    }

    func testExpandedSearchUsesFullWidthOverlayPresentation() {
        let state = SearchBoxState(query: "剪贴板", isExpanded: true)

        XCTAssertEqual(state.presentation, .fullWidthOverlay)
    }
}
