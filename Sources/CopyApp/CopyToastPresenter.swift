import AppKit
import SwiftUI

@MainActor
final class CopyToastPresenter {
    private var toastPanel: NSPanel?

    func show(message: String, near frame: NSRect) {
        toastPanel?.orderOut(nil)

        let size = NSSize(width: message.count > 3 ? 210 : 118, height: 42)
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height - 16
        )
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: CopyToastView(message: message))
        panel.alphaValue = 0
        toastPanel = panel

        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            panel.animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self, weak panel] in
            guard let panel else {
                return
            }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                panel.animator().alphaValue = 0
            } completionHandler: { [weak self, weak panel] in
                Task { @MainActor in
                    guard let panel else {
                        return
                    }
                    panel.orderOut(nil)
                    if self?.toastPanel === panel {
                        self?.toastPanel = nil
                    }
                }
            }
        }
    }
}

private struct CopyToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .preferredColorScheme(.dark)
    }
}
