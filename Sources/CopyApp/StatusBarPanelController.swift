import AppKit
import CopyCore
import QuartzCore
import SwiftUI

@MainActor
final class StatusBarPanelController: NSObject {
    private let model: AppModel
    private let onShortcutSettingsRequested: () -> Void
    private let statusItem: NSStatusItem
    private let panel: NSPanel
    private let toastPresenter = CopyToastPresenter()
    private let panelSize = NSSize(width: 720, height: 560)
    private var focusedInputContext = FocusedInputContext(
        application: nil,
        focusedElement: nil,
        wasTextInputFocused: false,
        isAccessibilityTrusted: false
    )
    private var lastExternalTextInputContext = FocusedInputContext(
        application: nil,
        focusedElement: nil,
        wasTextInputFocused: false,
        isAccessibilityTrusted: false
    )
    private var focusCaptureTimer: Timer?
    private var localPanelDismissMonitor: Any?
    private var globalPanelDismissMonitor: Any?
    private var isAnimatingPanelOut = false

    init(
        model: AppModel,
        onShortcutSettingsRequested: @escaping () -> Void
    ) {
        self.model = model
        self.onShortcutSettingsRequested = onShortcutSettingsRequested
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.panel = FloatingClipboardPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        configureStatusItem()
        configurePanel()
        startFocusedInputTracking()
    }

    @objc func togglePanel() {
        if panel.isVisible {
            hidePanel(animated: true)
        } else {
            showPanel()
        }
    }

    func showPanel() {
        focusedInputContext = resolvedFocusedInputContextForPanelOpen()
        model.captureCurrentPasteboardNow()
        panel.setFrame(panelFrame(), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        installPanelDismissMonitors()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }
        button.image = NSImage(
            systemSymbolName: StatusMenuIcon.statusBarApp.systemName,
            accessibilityDescription: "COPI"
        )
        button.image?.isTemplate = true
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showStatusMenu()
        } else {
            togglePanel()
        }
    }

    private func showStatusMenu() {
        statusItem.menu = makeStatusMenu()
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func makeStatusMenu() -> NSMenu {
        let menu = NSMenu()
        addMenuItem(
            title: model.isRecordingPaused ? "恢复记录" : "暂停记录",
            action: #selector(toggleRecordingFromMenu),
            icon: .recording(isPaused: model.isRecordingPaused),
            to: menu
        )
        addMenuItem(
            title: "清空全部历史",
            action: #selector(clearHistoryFromMenu),
            icon: .clearHistory,
            to: menu
        )
        menu.addItem(.separator())
        addMenuItem(
            title: "修改快捷键",
            action: #selector(showShortcutSettingsFromMenu),
            icon: .shortcutSettings,
            to: menu
        )
        menu.addItem(.separator())
        addMenuItem(title: "退出", action: #selector(quitFromMenu), icon: .quit, to: menu)
        return menu
    }

    private func addMenuItem(
        title: String,
        action: Selector,
        icon: StatusMenuIcon,
        to menu: NSMenu
    ) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.image = menuIcon(named: icon.systemName)
        menu.addItem(item)
    }

    private func menuIcon(named systemName: String) -> NSImage? {
        let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil)
        image?.isTemplate = true
        image?.size = NSSize(width: 16, height: 16)
        return image
    }

    @objc private func toggleRecordingFromMenu() {
        model.toggleRecordingPaused()
        let message = model.isRecordingPaused ? "已暂停记录" : "已恢复记录"
        toastPresenter.show(message: message, centeredOn: panelFrame())
    }

    @objc private func clearHistoryFromMenu() {
        model.clearHistory()
        toastPresenter.show(message: "已清空全部历史", centeredOn: panelFrame())
    }

    @objc private func showShortcutSettingsFromMenu() {
        onShortcutSettingsRequested()
    }

    func showShortcutChangedToast(_ shortcut: CopyCore.KeyboardShortcut, centeredOn frame: NSRect?) {
        let message = "快捷键已改为 \(shortcut.displayText)"
        if let frame {
            toastPresenter.show(message: message, centeredOn: frame)
        } else {
            toastPresenter.show(message: message, centeredOn: panelFrame())
        }
    }

    @objc private func quitFromMenu() {
        NSApplication.shared.terminate(nil)
    }

    private func configurePanel() {
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(
            rootView: ClipboardOverlayView(
                model: model,
                onSelectItem: { [weak self] item in
                    self?.selectClipboardItem(item)
                },
                onOpenLink: { [weak self] item in
                    self?.openLinkItem(item)
                }
            )
        )
    }

    private func startFocusedInputTracking() {
        focusCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshLastExternalTextInputContext()
            }
        }
    }

    private func refreshLastExternalTextInputContext() {
        guard panel.isVisible == false else {
            return
        }

        let context = FocusedInputDetector.capture(promptForAccessibility: false)
        guard context.wasTextInputFocused,
              FocusedInputDetector.isCurrentApplication(context) == false
        else {
            return
        }

        lastExternalTextInputContext = context
    }

    private func resolvedFocusedInputContextForPanelOpen() -> FocusedInputContext {
        let capturedContext = FocusedInputDetector.capture()
        if capturedContext.wasTextInputFocused,
           FocusedInputDetector.isCurrentApplication(capturedContext) == false {
            lastExternalTextInputContext = capturedContext
            return capturedContext
        }

        if ClipboardFocusedInputContextPolicy.shouldReuseLastTextInputContext(
            capturedWasTextInputFocused: capturedContext.wasTextInputFocused,
            capturedApplicationIsCurrentApp: FocusedInputDetector.isCurrentApplication(capturedContext),
            lastWasTextInputFocused: lastExternalTextInputContext.wasTextInputFocused
        ) {
            return lastExternalTextInputContext
        }

        return capturedContext
    }

    private func selectClipboardItem(_ item: ClipboardItem) {
        guard !isAnimatingPanelOut else {
            return
        }

        model.restore(item)
        let selectionAction = ClipboardSelectionPolicy.action(
            wasTextInputFocusedWhenOpened: focusedInputContext.wasTextInputFocused
        )
        let feedback = ClipboardSelectionPolicy.feedback(
            for: selectionAction,
            isAccessibilityTrusted: focusedInputContext.isAccessibilityTrusted
        )
        let toastFrame = panel.frame

        hidePanel(animated: true) { [weak self] in
            switch selectionAction {
            case .pasteIntoFocusedInput:
                if let focusedInputContext = self?.focusedInputContext {
                    PasteInjector.paste(item, into: focusedInputContext)
                }
            case .copyOnly:
                break
            }

            switch feedback.placement {
            case .centeredOnPanel:
                self?.toastPresenter.show(message: feedback.message, centeredOn: toastFrame)
            }
        }
    }

    private func openLinkItem(_ item: ClipboardItem) {
        guard !isAnimatingPanelOut,
              let url = LinkDestination.url(for: item)
        else {
            return
        }

        hidePanel(animated: true) {
            NSWorkspace.shared.open(url)
        }
    }

    private func hidePanel(animated: Bool, completion: (@MainActor @Sendable () -> Void)? = nil) {
        removePanelDismissMonitors()

        guard panel.isVisible else {
            completion?()
            return
        }

        guard animated else {
            panel.orderOut(nil)
            completion?()
            return
        }

        isAnimatingPanelOut = true
        let originalFrame = panel.frame
        let targetFrame = originalFrame.offsetBy(dx: 0, dy: 34)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().alphaValue = 0
            panel.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self else {
                    completion?()
                    return
                }

                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
                self.panel.setFrame(originalFrame, display: false)
                self.isAnimatingPanelOut = false
                completion?()
            }
        }
    }

    private func panelFrame() -> NSRect {
        let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? statusItem.button?.window?.screen
            ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        return ClipboardPanelPlacement.centeredFrame(
            panelSize: panelSize,
            visibleFrame: visibleFrame
        )
    }

    private func statusButtonFrame() -> NSRect? {
        guard let button = statusItem.button,
              let window = button.window
        else {
            return nil
        }

        return window.convertToScreen(button.frame)
    }

    private func installPanelDismissMonitors() {
        removePanelDismissMonitors()

        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localPanelDismissMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            MainActor.assumeIsolated { [weak self] in
                let clickLocation = Self.screenLocation(for: event)
                self?.hidePanelIfNeededForOutsideClick(at: clickLocation)
            }
            return event
        }
        globalPanelDismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            let clickLocation = Self.globalScreenLocation(for: event)
            Task { @MainActor [weak self] in
                self?.hidePanelIfNeededForOutsideClick(at: clickLocation)
            }
        }
    }

    private func removePanelDismissMonitors() {
        if let localPanelDismissMonitor {
            NSEvent.removeMonitor(localPanelDismissMonitor)
            self.localPanelDismissMonitor = nil
        }

        if let globalPanelDismissMonitor {
            NSEvent.removeMonitor(globalPanelDismissMonitor)
            self.globalPanelDismissMonitor = nil
        }
    }

    private func hidePanelIfNeededForOutsideClick(at clickLocation: NSPoint) {
        guard panel.isVisible,
              !isAnimatingPanelOut,
              ClipboardPanelDismissalPolicy.shouldDismiss(
                  clickLocation: clickLocation,
                  panelFrame: panel.frame,
                  statusButtonFrame: statusButtonFrame()
              )
        else {
            return
        }

        hidePanel(animated: true)
    }

    private static func screenLocation(for event: NSEvent) -> NSPoint {
        guard let window = event.window else {
            return event.locationInWindow
        }

        return window.convertPoint(toScreen: event.locationInWindow)
    }

    private nonisolated static func globalScreenLocation(for event: NSEvent) -> NSPoint {
        event.locationInWindow
    }
}

private final class FloatingClipboardPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
