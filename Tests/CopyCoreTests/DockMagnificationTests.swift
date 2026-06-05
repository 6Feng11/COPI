import CopyCore
import XCTest

final class DockMagnificationTests: XCTestCase {
    func testNilPointerReturnsBaseScale() {
        let scale = DockMagnification.scale(
            pointerPosition: nil,
            itemCenter: 100,
            distance: 120,
            maxScale: 1.05
        )

        XCTAssertEqual(scale, 1)
    }

    func testPointerAtItemCenterReturnsMaximumScale() {
        let scale = DockMagnification.scale(
            pointerPosition: 100,
            itemCenter: 100,
            distance: 120,
            maxScale: 1.05
        )

        XCTAssertEqual(scale, 1.05, accuracy: 0.0001)
    }

    func testPointerHalfwayThroughDistanceReturnsPartialScale() {
        let scale = DockMagnification.scale(
            pointerPosition: 160,
            itemCenter: 100,
            distance: 120,
            maxScale: 1.05
        )

        XCTAssertEqual(scale, 1.025, accuracy: 0.0001)
    }

    func testPointerOutsideDistanceReturnsBaseScale() {
        let scale = DockMagnification.scale(
            pointerPosition: 230,
            itemCenter: 100,
            distance: 120,
            maxScale: 1.05
        )

        XCTAssertEqual(scale, 1)
    }

    func testHoveredIndexReturnsMaximumScale() {
        let scale = DockMagnification.scale(
            hoveredIndex: 2,
            itemIndex: 2,
            maxScale: 1.032,
            neighborScale: 1.014
        )

        XCTAssertEqual(scale, 1.032, accuracy: 0.0001)
    }

    func testAdjacentIndexReturnsNeighborScale() {
        let scale = DockMagnification.scale(
            hoveredIndex: 2,
            itemIndex: 3,
            maxScale: 1.032,
            neighborScale: 1.014
        )

        XCTAssertEqual(scale, 1.014, accuracy: 0.0001)
    }

    func testDistantIndexReturnsBaseScale() {
        let scale = DockMagnification.scale(
            hoveredIndex: 2,
            itemIndex: 4,
            maxScale: 1.032,
            neighborScale: 1.014
        )

        XCTAssertEqual(scale, 1)
    }

    func testNilHoveredIndexReturnsBaseScaleForIndexModel() {
        let scale = DockMagnification.scale(
            hoveredIndex: nil,
            itemIndex: 4,
            maxScale: 1.032,
            neighborScale: 1.014
        )

        XCTAssertEqual(scale, 1)
    }
}
