import Foundation

public struct TextInsertionResult: Equatable, Sendable {
    public let text: String
    public let selectedRange: NSRange
}

public enum TextInsertion {
    public static func replacingSelection(
        in text: String,
        selectedRange: NSRange,
        with insertedText: String
    ) -> TextInsertionResult? {
        guard let range = Range(selectedRange, in: text) else {
            return nil
        }

        var updatedText = text
        updatedText.replaceSubrange(range, with: insertedText)

        return TextInsertionResult(
            text: updatedText,
            selectedRange: NSRange(location: selectedRange.location + insertedText.utf16.count, length: 0)
        )
    }
}
