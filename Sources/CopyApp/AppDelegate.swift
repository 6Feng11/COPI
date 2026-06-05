import AppKit
import CopyCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusBarController: StatusBarPanelController?
    private var globalHotKey: GlobalHotKey?
    private let shortcutStore = ShortcutStore()
    private var shortcutRecorderWindowController: ShortcutRecorderWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = AppModel()
        let currentShortcut = shortcutStore.load()
        let globalHotKey = GlobalHotKey(shortcut: currentShortcut) { [weak self] in
            guard let self else {
                return
            }
            guard KeyboardShortcutEditorPolicy.shouldHandleGlobalHotKey(
                isEditorOpen: self.isShortcutRecorderOpen
            ) else {
                return
            }
            self.statusBarController?.togglePanel()
        }
        let statusBarController = StatusBarPanelController(
            model: model,
            onShortcutSettingsRequested: { [weak self] in
                self?.showShortcutRecorder()
            }
        )

        self.model = model
        self.statusBarController = statusBarController
        self.globalHotKey = globalHotKey

        globalHotKey.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalHotKey?.unregister()
    }

    private func showShortcutRecorder() {
        if let shortcutRecorderWindowController,
           shortcutRecorderWindowController.window?.isVisible == true {
            NSApp.activate(ignoringOtherApps: true)
            shortcutRecorderWindowController.showWindow(nil)
            return
        }

        globalHotKey?.unregister()
        let currentShortcut = shortcutStore.load()
        let windowController = ShortcutRecorderWindowController(
            currentShortcut: currentShortcut,
            onSave: { [weak self] shortcut in
                self?.saveShortcut(shortcut)
            },
            onClose: { [weak self] in
                self?.globalHotKey?.register()
                self?.shortcutRecorderWindowController = nil
            }
        )
        shortcutRecorderWindowController = windowController
        NSApp.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
    }

    private var isShortcutRecorderOpen: Bool {
        shortcutRecorderWindowController?.window?.isVisible == true
    }

    private func saveShortcut(_ shortcut: KeyboardShortcut) {
        let shortcutRecorderFrame = shortcutRecorderWindowController?.window?.frame
        shortcutStore.save(shortcut)
        globalHotKey?.update(shortcut: shortcut)
        statusBarController?.showShortcutChangedToast(shortcut, centeredOn: shortcutRecorderFrame)
    }
}
