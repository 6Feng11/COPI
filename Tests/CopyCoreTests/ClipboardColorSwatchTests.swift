import CopyCore
import XCTest

final class ClipboardColorSwatchTests: XCTestCase {
    func testParsesHexColor() throws {
        let swatch = try XCTUnwrap(ClipboardColorSwatch.parse("#1E90FF"))

        XCTAssertEqual(swatch.red, 30.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.green, 144.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.blue, 1.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.alpha, 1.0, accuracy: 0.0001)
    }

    func testParsesShortHexColor() throws {
        let swatch = try XCTUnwrap(ClipboardColorSwatch.parse("#0AF"))

        XCTAssertEqual(swatch.red, 0.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.green, 170.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.blue, 1.0, accuracy: 0.0001)
    }

    func testParsesBareSixDigitHexColorCopiedFromDesignTools() throws {
        let black = try XCTUnwrap(ClipboardColorSwatch.parse("000000"))
        let blue = try XCTUnwrap(ClipboardColorSwatch.parse("1E90FF"))

        XCTAssertEqual(black.red, 0.0, accuracy: 0.0001)
        XCTAssertEqual(black.green, 0.0, accuracy: 0.0001)
        XCTAssertEqual(black.blue, 0.0, accuracy: 0.0001)
        XCTAssertEqual(blue.red, 30.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(blue.green, 144.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(blue.blue, 1.0, accuracy: 0.0001)
    }

    func testParsesRGBColor() throws {
        let swatch = try XCTUnwrap(ClipboardColorSwatch.parse("rgb(30, 144, 255)"))

        XCTAssertEqual(swatch.red, 30.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.green, 144.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.blue, 1.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.alpha, 1.0, accuracy: 0.0001)
    }

    func testParsesModernCSSRGBColor() throws {
        let swatch = try XCTUnwrap(ClipboardColorSwatch.parse("rgb(30 144 255 / 50%)"))

        XCTAssertEqual(swatch.red, 30.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.green, 144.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.blue, 1.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.alpha, 0.5, accuracy: 0.0001)
    }

    func testParsesHSLColor() throws {
        let swatch = try XCTUnwrap(ClipboardColorSwatch.parse("hsl(210, 100%, 56%)"))

        XCTAssertEqual(swatch.red, 0.12, accuracy: 0.01)
        XCTAssertEqual(swatch.green, 0.56, accuracy: 0.01)
        XCTAssertEqual(swatch.blue, 1.0, accuracy: 0.01)
    }

    func testParsesHSBAndHSVColors() throws {
        let hsb = try XCTUnwrap(ClipboardColorSwatch.parse("hsb(210, 88%, 100%)"))
        let hsv = try XCTUnwrap(ClipboardColorSwatch.parse("hsv(210, 88%, 100%)"))

        XCTAssertEqual(hsb.red, 0.12, accuracy: 0.01)
        XCTAssertEqual(hsb.green, 0.56, accuracy: 0.01)
        XCTAssertEqual(hsb.blue, 1.0, accuracy: 0.01)
        XCTAssertEqual(hsb, hsv)
    }

    func testParsesCSSColorDeclaration() throws {
        let swatch = try XCTUnwrap(ClipboardColorSwatch.parse("color: #1E90FF;"))

        XCTAssertEqual(swatch.red, 30.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.green, 144.0 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(swatch.blue, 1.0, accuracy: 0.0001)
    }

    func testRejectsNonColorText() {
        XCTAssertNil(ClipboardColorSwatch.parse("今天复制了一段普通文本"))
        XCTAssertNil(ClipboardColorSwatch.parse("#XYZ"))
        XCTAssertNil(ClipboardColorSwatch.parse("rgb(999, 0, 0)"))
        XCTAssertNil(ClipboardColorSwatch.parse("这段文本里有 000000 但不是单独色值"))
    }
}
