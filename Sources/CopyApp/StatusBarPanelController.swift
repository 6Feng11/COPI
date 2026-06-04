import AppKit
import SwiftUI

@MainActor
final class StatusBarPanelController: NSObject {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let panel: NSPanel
    private let panelSize = NSSize(width: 460, height: 560)

    init(model: AppModel) {
        self.model = model
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.panel = FloatingClipboardPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        super.init()

        configureStatusItem()
        configurePanel()
    }

    @objc func togglePanel() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            showPanel()
        }
    }

    func showPanel() {
        model.captureCurrentPasteboardNow()
        panel.setFrame(panelFrame(), display: true)
        panel.orderFrontRegardless()
        NSApplication.shared.activate()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }
        button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Copy")
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePanel)
    }

    private func configurePanel() {
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: ClipboardOverlayView(model: model))
    }

    private func panelFrame() -> NSRect {
        let screen = statusItem.button?.window?.screen
            ?? NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let origin = NSPoint(
            x: visibleFrame.midX - panelSize.width / 2,
            y: visibleFrame.maxY - panelSize.height - 10
        )
        return NSRect(origin: origin, size: panelSize)
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
