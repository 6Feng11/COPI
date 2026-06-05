import Foundation

public struct DeleteConfirmationState: Equatable, Sendable {
    public private(set) var confirmingItemID: ClipboardItem.ID?

    public init(confirmingItemID: ClipboardItem.ID? = nil) {
        self.confirmingItemID = confirmingItemID
    }

    public var isConfirming: Bool {
        confirmingItemID != nil
    }

    public func isConfirming(_ itemID: ClipboardItem.ID) -> Bool {
        confirmingItemID == itemID
    }

    public mutating func requestConfirmation(for itemID: ClipboardItem.ID) {
        confirmingItemID = itemID
    }

    public mutating func cancel() {
        confirmingItemID = nil
    }

    public mutating func consumeConfirmedDelete(for itemID: ClipboardItem.ID) -> Bool {
        guard confirmingItemID == itemID else {
            return false
        }

        confirmingItemID = nil
        return true
    }
}
