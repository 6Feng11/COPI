import AppKit
import CopyCore
import Foundation

struct PasteboardClient {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func readText() -> String? {
        pasteboard.string(forType: .string)
    }

    func readImageData() -> Data? {
        if let data = pasteboard.data(forType: .tiff) {
            return data
        }
        if let data = pasteboard.data(forType: .png) {
            return data
        }
        guard let image = NSImage(pasteboard: pasteboard) else {
            return nil
        }
        return image.tiffRepresentation
    }

    func write(_ item: ClipboardItem) {
        pasteboard.clearContents()

        switch item.type {
        case .text, .link:
            if let text = item.plainText {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            guard let imagePath = item.imagePath,
                  let image = NSImage(contentsOfFile: imagePath)
            else {
                return
            }
            pasteboard.writeObjects([image])
        }
    }
}
