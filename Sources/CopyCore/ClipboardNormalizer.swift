import CryptoKit
import Foundation

public enum ClipboardNormalizer {
    private static let previewLimit = 60

    public static func makeTextItem(
        _ text: String,
        sourceAppBundleId: String?,
        sourceAppName: String?,
        now: Date
    ) -> ClipboardItem? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return nil
        }

        let detectedURL = detectURL(in: normalized)
        let type: ClipboardItemType = detectedURL == nil ? .text : .link

        return ClipboardItem(
            type: type,
            preview: makePreview(from: normalized),
            plainText: normalized,
            url: detectedURL,
            sourceAppBundleId: sourceAppBundleId,
            sourceAppName: sourceAppName,
            contentHash: contentHash(for: type, content: normalized),
            createdAt: now
        )
    }

    public static func contentHash(for type: ClipboardItemType, content: String) -> String {
        let digest = SHA256.hash(data: Data("\(type.rawValue):\(content)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func detectURL(in text: String) -> String? {
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else {
            return nil
        }
        return text
    }

    private static func makePreview(from text: String) -> String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? text

        if firstLine.count <= previewLimit {
            return firstLine
        }

        let end = firstLine.index(firstLine.startIndex, offsetBy: previewLimit)
        return String(firstLine[..<end]) + "..."
    }
}
