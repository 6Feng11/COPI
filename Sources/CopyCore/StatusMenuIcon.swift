import Foundation

public struct StatusMenuIcon: Equatable, Sendable {
    public let systemName: String

    public static let statusBarApp = StatusMenuIcon(systemName: "clipboard")

    public static func recording(isPaused: Bool) -> StatusMenuIcon {
        StatusMenuIcon(systemName: isPaused ? "play.circle" : "pause.circle")
    }

    public static let clearHistory = StatusMenuIcon(systemName: "trash")
    public static let shortcutSettings = StatusMenuIcon(systemName: "keyboard")
    public static let quit = StatusMenuIcon(systemName: "power")
}
