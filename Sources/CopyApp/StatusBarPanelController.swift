import AppKit
import CopyCore
import QuartzCore
import SwiftUI

@MainActor
final class StatusBarPanelController: NSObject {
    private let model: AppModel
    private let statusItem: NSStatusItem
    private let panel: NSPanel
    private let toastPresenter = CopyToastPresenter()
    private let panelSize = NSSize(width: 460, height: 560)
    private var focusedInputContext = FocusedInputContext(
        application: nil,
        focusedElement: nil,
        wasTextInputFocused: false,
        isAccessibilityTrusted: false
    )
    private var isAnimatingPanelOut = false

    init(model: AppModel) {
        self.model = model
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
    }

    @objc func togglePanel() {
        if panel.isVisible {
            hidePanel(animated: true)
        } else {
            showPanel()
        }
    }

    func showPanel() {
        focusedInputContext = FocusedInputDetector.capture()
        model.captureCurrentPasteboardNow()
        panel.setFrame(panelFrame(), display: true)
        panel.alphaValue = 1
        panel.orderFrontRegardless()
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
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(
            rootView: ClipboardOverlayView(model: model) { [weak self] item in
                self?.selectClipboardItem(item)
            }
        )
    }

    private func selectClipboardItem(_ item: ClipboardItem) {
        guard !isAnimatingPanelOut else {
            return
        }

        model.restore(item)
        let selectionAction = ClipboardSelectionPolicy.action(
            wasTextInputFocusedWhenOpened: focusedInputContext.wasTextInputFocused
        )
        let toastFrame = panel.frame

        hidePanel(animated: true) { [weak self] in
            switch selectionAction {
            case .pasteIntoFocusedInput:
                if let focusedInputContext = self?.focusedInputContext {
                    PasteInjector.paste(item, into: focusedInputContext)
                }
            case .copyOnly:
                let message = self?.focusedInputContext.isAccessibilityTrusted == false
                    ? "已复制，需开启辅助功能"
                    : "已复制"
                self?.toastPresenter.show(message: message, near: toastFrame)
            }
        }
    }

    private func hidePanel(animated: Bool, completion: (@MainActor @Sendable () -> Void)? = nil) {
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
