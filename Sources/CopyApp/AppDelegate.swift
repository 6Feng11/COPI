import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel?
    private var statusBarController: StatusBarPanelController?
    private var globalHotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let model = AppModel()
        let statusBarController = StatusBarPanelController(model: model)
        let globalHotKey = GlobalHotKey(command: .commandShiftV) { [weak statusBarController] in
            statusBarController?.togglePanel()
        }

        self.model = model
        self.statusBarController = statusBarController
        self.globalHotKey = globalHotKey

        globalHotKey.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        globalHotKey?.unregister()
    }
}
