import Foundation

public enum LinkDestination {
    public static func url(for item: ClipboardItem) -> URL? {
        guard item.type == .link else {
            return nil
        }

        if let url = normalizedURL(from: item.url) {
            return url
        }

        return normalizedURL(from: item.plainText)
    }

    private static func normalizedURL(from value: String?) -> URL? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedValue), url.scheme != nil else {
            return nil
        }

        return url
    }
}
