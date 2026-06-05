import CopyCore
import Foundation

@MainActor
final class ShortcutStore {
    private let defaults: UserDefaults
    private let key = "copy.globalShortcut"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> KeyboardShortcut {
        guard let data = defaults.data(forKey: key),
              let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data),
              shortcut.isValidGlobalShortcut
        else {
            return .defaultShortcut
        }

        return shortcut
    }

    func save(_ shortcut: KeyboardShortcut) {
        guard shortcut.isValidGlobalShortcut,
              let data = try? JSONEncoder().encode(shortcut)
        else {
            return
        }

        defaults.set(data, forKey: key)
    }
}
