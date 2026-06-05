import Foundation

public struct ClipboardColorSwatch: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static func parse(_ text: String) -> ClipboardColorSwatch? {
        guard let candidate = normalizedCandidate(from: text) else {
            return nil
        }

        if let hexColor = parseHex(candidate) {
            return hexColor
        }

        return parseFunction(candidate)
    }

    private static func normalizedCandidate(from text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains(where: \.isNewline)
        else {
            return nil
        }

        if let colonIndex = trimmed.firstIndex(of: ":") {
            let prefix = trimmed[..<colonIndex].lowercased()
            guard prefix.contains("color") || prefix.hasPrefix("--") else {
                return nil
            }

            var value = trimmed[trimmed.index(after: colonIndex)...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let semicolonIndex = value.firstIndex(of: ";") {
                value = String(value[..<semicolonIndex])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return value.isEmpty ? nil : value
        }

        return trimmed
    }

    private static func parseHex(_ text: String) -> ClipboardColorSwatch? {
        let hasHashPrefix = text.hasPrefix("#")
        let hex = hasHashPrefix ? String(text.dropFirst()) : text
        guard hasHashPrefix || hex.count == 6 else {
            return nil
        }

        let expanded: String
        switch hex.count {
        case 3, 4:
            guard hasHashPrefix else {
                return nil
            }
            expanded = hex.map { "\($0)\($0)" }.joined()
        case 6, 8:
            guard hasHashPrefix || hex.count == 6 else {
                return nil
            }
            expanded = hex
        default:
            return nil
        }

        guard expanded.allSatisfy(\.isHexDigit),
              let red = byteValue(expanded, offset: 0),
              let green = byteValue(expanded, offset: 2),
              let blue = byteValue(expanded, offset: 4)
        else {
            return nil
        }

        let alpha = expanded.count == 8
            ? byteValue(expanded, offset: 6) ?? 255
            : 255

        return ClipboardColorSwatch(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            alpha: Double(alpha) / 255
        )
    }

    private static func byteValue(_ text: String, offset: Int) -> UInt8? {
        let start = text.index(text.startIndex, offsetBy: offset)
        let end = text.index(start, offsetBy: 2)
        return UInt8(text[start..<end], radix: 16)
    }

    private static func parseFunction(_ text: String) -> ClipboardColorSwatch? {
        guard let openIndex = text.firstIndex(of: "("),
              text.last == ")"
        else {
            return nil
        }

        let functionName = text[..<openIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let bodyStart = text.index(after: openIndex)
        let bodyEnd = text.index(before: text.endIndex)
        let body = String(text[bodyStart..<bodyEnd])
        let tokens = tokenizeFunctionBody(body)

        switch functionName {
        case "rgb", "rgba":
            return parseRGB(tokens)
        case "hsl", "hsla":
            return parseHSL(tokens)
        case "hsb", "hsba", "hsv", "hsva":
            return parseHSB(tokens)
        default:
            return nil
        }
    }

    private static func tokenizeFunctionBody(_ body: String) -> [String] {
        body
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "/", with: " / ")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private static func parseRGB(_ tokens: [String]) -> ClipboardColorSwatch? {
        let (components, alphaToken) = splitAlpha(from: tokens)
        guard components.count == 3,
              let red = parseRGBComponent(components[0]),
              let green = parseRGBComponent(components[1]),
              let blue = parseRGBComponent(components[2]),
              let alpha = parseAlpha(alphaToken)
        else {
            return nil
        }

        return ClipboardColorSwatch(red: red, green: green, blue: blue, alpha: alpha)
    }

    private static func parseHSL(_ tokens: [String]) -> ClipboardColorSwatch? {
        let (components, alphaToken) = splitAlpha(from: tokens)
        guard components.count == 3,
              let hue = parseHue(components[0]),
              let saturation = parsePercent(components[1]),
              let lightness = parsePercent(components[2]),
              let alpha = parseAlpha(alphaToken)
        else {
            return nil
        }

        return hslToRGB(hue: hue, saturation: saturation, lightness: lightness, alpha: alpha)
    }

    private static func parseHSB(_ tokens: [String]) -> ClipboardColorSwatch? {
        let (components, alphaToken) = splitAlpha(from: tokens)
        guard components.count == 3,
              let hue = parseHue(components[0]),
              let saturation = parsePercent(components[1]),
              let brightness = parsePercent(components[2]),
              let alpha = parseAlpha(alphaToken)
        else {
            return nil
        }

        return hsbToRGB(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }

    private static func splitAlpha(from tokens: [String]) -> ([String], String?) {
        if let slashIndex = tokens.firstIndex(of: "/") {
            let components = Array(tokens[..<slashIndex])
            let alpha = tokens.index(after: slashIndex) < tokens.endIndex
                ? tokens[tokens.index(after: slashIndex)]
                : nil
            return (components, alpha)
        }

        if tokens.count == 4 {
            return (Array(tokens.prefix(3)), tokens[3])
        }

        return (tokens, nil)
    }

    private static func parseRGBComponent(_ token: String) -> Double? {
        if token.hasSuffix("%") {
            return parsePercent(token)
        }

        guard let value = Double(token),
              value >= 0,
              value <= 255
        else {
            return nil
        }

        return value / 255
    }

    private static func parseAlpha(_ token: String?) -> Double? {
        guard let token else {
            return 1
        }

        if token.hasSuffix("%") {
            return parsePercent(token)
        }

        guard let value = Double(token),
              value >= 0,
              value <= 1
        else {
            return nil
        }

        return value
    }

    private static func parsePercent(_ token: String) -> Double? {
        guard token.hasSuffix("%"),
              let value = Double(token.dropLast()),
              value >= 0,
              value <= 100
        else {
            return nil
        }

        return value / 100
    }

    private static func parseHue(_ token: String) -> Double? {
        let normalized = token
            .replacingOccurrences(of: "deg", with: "")
            .replacingOccurrences(of: "°", with: "")
        guard let value = Double(normalized) else {
            return nil
        }

        let wrapped = value.truncatingRemainder(dividingBy: 360)
        return wrapped < 0 ? wrapped + 360 : wrapped
    }

    private static func hslToRGB(
        hue: Double,
        saturation: Double,
        lightness: Double,
        alpha: Double
    ) -> ClipboardColorSwatch {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let huePrime = hue / 60
        let x = chroma * (1 - abs(huePrime.truncatingRemainder(dividingBy: 2) - 1))
        let match = lightness - chroma / 2
        let rgb = hueSectionRGB(huePrime: huePrime, chroma: chroma, x: x)

        return ClipboardColorSwatch(
            red: rgb.red + match,
            green: rgb.green + match,
            blue: rgb.blue + match,
            alpha: alpha
        )
    }

    private static func hsbToRGB(
        hue: Double,
        saturation: Double,
        brightness: Double,
        alpha: Double
    ) -> ClipboardColorSwatch {
        let chroma = brightness * saturation
        let huePrime = hue / 60
        let x = chroma * (1 - abs(huePrime.truncatingRemainder(dividingBy: 2) - 1))
        let match = brightness - chroma
        let rgb = hueSectionRGB(huePrime: huePrime, chroma: chroma, x: x)

        return ClipboardColorSwatch(
            red: rgb.red + match,
            green: rgb.green + match,
            blue: rgb.blue + match,
            alpha: alpha
        )
    }

    private static func hueSectionRGB(
        huePrime: Double,
        chroma: Double,
        x: Double
    ) -> (red: Double, green: Double, blue: Double) {
        switch huePrime {
        case 0..<1:
            return (chroma, x, 0)
        case 1..<2:
            return (x, chroma, 0)
        case 2..<3:
            return (0, chroma, x)
        case 3..<4:
            return (0, x, chroma)
        case 4..<5:
            return (x, 0, chroma)
        default:
            return (chroma, 0, x)
        }
    }
}
