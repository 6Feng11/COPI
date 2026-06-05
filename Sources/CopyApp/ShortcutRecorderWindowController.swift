import AppKit
import CopyCore
import QuartzCore
import SwiftUI

@MainActor
final class ShortcutRecorderWindowController: NSWindowController {
    private let onSave: (CopyCore.KeyboardShortcut) -> Void
    private let onClose: () -> Void

    init(
        currentShortcut: CopyCore.KeyboardShortcut,
        onSave: @escaping (CopyCore.KeyboardShortcut) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onClose = onClose

        let panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: ShortcutRecorderChrome.windowWidth,
                height: ShortcutRecorderChrome.windowHeight
            ),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = ShortcutRecorderChrome.nativeWindowTitle
        panel.titleVisibility = ShortcutRecorderChrome.showsNativeTitle ? .visible : .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.level = .floating

        super.init(window: panel)
        panel.delegate = self

        panel.contentView = NSHostingView(
            rootView: ShortcutRecorderView(
                initialShortcut: currentShortcut,
                onCancel: { [weak self] in
                    self?.close()
                },
                onSave: { [weak self] (shortcut: CopyCore.KeyboardShortcut) in
                    self?.onSave(shortcut)
                    self?.close()
                }
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ShortcutRecorderWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

private struct ShortcutRecorderView: View {
    @State private var shortcut: CopyCore.KeyboardShortcut
    @State private var errorText: String?
    let onCancel: () -> Void
    private let onSave: (CopyCore.KeyboardShortcut) -> Void

    init(
        initialShortcut: CopyCore.KeyboardShortcut,
        onCancel: @escaping () -> Void,
        onSave: @escaping (CopyCore.KeyboardShortcut) -> Void
    ) {
        _shortcut = State(initialValue: initialShortcut)
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(ShortcutRecorderChrome.contentTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    if ShortcutRecorderChrome.showsDescription {
                        Text(ShortcutRecorderChrome.descriptionText)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }

                ShortcutCaptureView(shortcut: $shortcut)
                    .frame(height: CGFloat(ShortcutRecorderChrome.captureHeight))

                if let errorText {
                    Text(errorText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.9))
                }

                Spacer(minLength: 0)
            }
            .padding(.top, CGFloat(ShortcutRecorderChrome.windowContentPadding))
            .padding(.horizontal, CGFloat(ShortcutRecorderChrome.windowContentPadding))
            .padding(.bottom, footerReservedHeight)

            VStack {
                Spacer()
                footerControls
            }
            .padding(.horizontal, CGFloat(ShortcutRecorderChrome.windowContentPadding))
            .padding(.bottom, CGFloat(ShortcutRecorderChrome.footerButtonBottomInset))
        }
        .frame(
            width: CGFloat(ShortcutRecorderChrome.windowWidth),
            height: CGFloat(ShortcutRecorderChrome.windowHeight)
        )
        .background(Color.black.opacity(0.92))
    }

    private var footerReservedHeight: CGFloat {
        CGFloat(
            ShortcutRecorderChrome.footerButtonHeight
                + ShortcutRecorderChrome.footerButtonBottomInset
                + 18
        )
    }

    private var footerControls: some View {
        HStack {
            Button("取消") {
                onCancel()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            HStack(spacing: CGFloat(ShortcutRecorderChrome.footerButtonGroupSpacing)) {
                Button("恢复默认") {
                    shortcut = .defaultShortcut
                    errorText = nil
                }
                .buttonStyle(ShortcutFooterButtonStyle(isPrimary: false))

                Button("保存") {
                    guard shortcut.isValidGlobalShortcut else {
                        errorText = "快捷键需要包含 Command、Option 或 Control。"
                        return
                    }
                    onSave(shortcut)
                }
                .buttonStyle(ShortcutFooterButtonStyle(isPrimary: true))
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

private struct ShortcutFooterButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        ShortcutFooterButtonBody(configuration: configuration, isPrimary: isPrimary)
    }
}

private struct ShortcutFooterButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let isPrimary: Bool
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: CGFloat(ShortcutRecorderChrome.footerButtonFontSize), weight: .medium))
            .foregroundStyle(isPrimary ? Color.white : Color.white.opacity(0.88))
            .padding(.horizontal, CGFloat(ShortcutRecorderChrome.footerButtonHorizontalPadding))
            .frame(
                width: CGFloat(ShortcutRecorderChrome.footerButtonBaseWidth),
                height: CGFloat(ShortcutRecorderChrome.footerButtonHeight)
            )
            .background(backgroundShape)
            .overlay(borderShape)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .onHover { isHovered = $0 }
    }

    private var backgroundShape: some View {
        RoundedRectangle(
            cornerRadius: CGFloat(ShortcutRecorderChrome.footerButtonCornerRadius),
            style: .continuous
        )
        .fill(backgroundColor)
    }

    private var borderShape: some View {
        RoundedRectangle(
            cornerRadius: CGFloat(ShortcutRecorderChrome.footerButtonCornerRadius),
            style: .continuous
        )
        .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
    }

    private var backgroundColor: Color {
        if isPrimary {
            return Color.accentColor.opacity(ShortcutRecorderChrome.footerButtonPrimaryFillOpacity)
        }

        if isHovered {
            return Color.white.opacity(ShortcutRecorderChrome.footerButtonHoverFillOpacity)
        }

        return Color.clear
    }

    private var borderOpacity: Double {
        isPrimary ? 0 : ShortcutRecorderChrome.footerButtonBorderOpacity
    }
}

private struct ShortcutCaptureView: NSViewRepresentable {
    @Binding var shortcut: CopyCore.KeyboardShortcut

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView()
        view.onShortcutChange = { (shortcut: CopyCore.KeyboardShortcut) in
            self.shortcut = shortcut
        }
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {
        nsView.shortcut = shortcut
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}

private final class ShortcutCaptureNSView: NSView {
    private let borderTrailLayer = CAShapeLayer()

    private var isEditing = false {
        didSet {
            syncBorderTrail()
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBorderTrailLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBorderTrailLayer()
    }

    var shortcut: CopyCore.KeyboardShortcut = .defaultShortcut {
        didSet {
            needsDisplay = true
        }
    }
    var onShortcutChange: ((CopyCore.KeyboardShortcut) -> Void)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        syncBorderTrail()
    }

    override func becomeFirstResponder() -> Bool {
        isEditing = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isEditing = false
        return true
    }

    override func layout() {
        super.layout()
        updateBorderTrailPath()
        syncBorderTrail()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard let keyEquivalent = event.charactersIgnoringModifiers?.uppercased(),
              keyEquivalent.isEmpty == false
        else {
            return
        }

        let nextShortcut = CopyCore.KeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            keyEquivalent: keyEquivalent,
            modifiers: CopyCore.KeyboardShortcut.Modifiers(event.modifierFlags)
        )
        shortcut = nextShortcut
        onShortcutChange?(nextShortcut)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let rect = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(
            roundedRect: rect,
            xRadius: CGFloat(ShortcutRecorderChrome.captureCornerRadius),
            yRadius: CGFloat(ShortcutRecorderChrome.captureCornerRadius)
        )
        let isActive = isEditing || window?.firstResponder === self
        NSColor.white
            .withAlphaComponent(
                isActive
                    ? ShortcutRecorderChrome.activeFillOpacity
                    : ShortcutRecorderChrome.inactiveFillOpacity
            )
            .setFill()
        path.fill()

        let strokeColor = isActive
            ? NSColor.white.withAlphaComponent(ShortcutRecorderChrome.activeBorderOpacity)
            : NSColor.white.withAlphaComponent(ShortcutRecorderChrome.inactiveBorderOpacity)
        strokeColor.setStroke()
        path.lineWidth = CGFloat(
            isActive
                ? ShortcutRecorderChrome.activeBorderWidth
                : ShortcutRecorderChrome.inactiveBorderWidth
        )
        path.stroke()

        let text = shortcut.displayText
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let origin = CGPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        text.draw(at: origin, withAttributes: attributes)
    }

    private func setupBorderTrailLayer() {
        guard ShortcutRecorderChrome.usesBorderTrailWhenActive else {
            return
        }

        borderTrailLayer.fillColor = NSColor.clear.cgColor
        borderTrailLayer.strokeColor = NSColor.controlAccentColor
            .withAlphaComponent(ShortcutRecorderChrome.borderTrailOpacity)
            .cgColor
        borderTrailLayer.lineWidth = CGFloat(ShortcutRecorderChrome.borderTrailLineWidth)
        borderTrailLayer.lineCap = .round
        borderTrailLayer.lineJoin = .round
        borderTrailLayer.shadowColor = NSColor.controlAccentColor.cgColor
        borderTrailLayer.shadowOpacity = Float(ShortcutRecorderChrome.borderTrailGlowOpacity)
        borderTrailLayer.shadowRadius = CGFloat(ShortcutRecorderChrome.borderTrailGlowRadius)
        borderTrailLayer.shadowOffset = .zero
        borderTrailLayer.isHidden = true
        layer?.addSublayer(borderTrailLayer)
    }

    private func syncBorderTrail() {
        let isActive = isEditing || window?.firstResponder === self
        updateBorderTrailPath()
        borderTrailLayer.isHidden = !isActive

        if isActive {
            startBorderTrailAnimationIfNeeded()
        } else {
            borderTrailLayer.removeAnimation(forKey: "copy.borderTrail")
        }
    }

    private func updateBorderTrailPath() {
        let rect = bounds.insetBy(dx: 1, dy: 1)
        guard rect.width > 0, rect.height > 0 else {
            return
        }

        let radius = CGFloat(ShortcutRecorderChrome.captureCornerRadius)
        borderTrailLayer.frame = bounds
        borderTrailLayer.path = CGPath(
            roundedRect: rect,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )
        let perimeter = roundedRectPerimeter(rect: rect, radius: radius)
        borderTrailLayer.lineDashPattern = [
            NSNumber(value: ShortcutRecorderChrome.borderTrailSize),
            NSNumber(value: Double(perimeter))
        ]
    }

    private func startBorderTrailAnimationIfNeeded() {
        guard borderTrailLayer.animation(forKey: "copy.borderTrail") == nil else {
            return
        }

        let rect = bounds.insetBy(dx: 1, dy: 1)
        let radius = CGFloat(ShortcutRecorderChrome.captureCornerRadius)
        let perimeter = roundedRectPerimeter(rect: rect, radius: radius)
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.fromValue = 0
        animation.toValue = -(perimeter + CGFloat(ShortcutRecorderChrome.borderTrailSize))
        animation.duration = ShortcutRecorderChrome.borderTrailDuration
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = .infinity
        borderTrailLayer.add(animation, forKey: "copy.borderTrail")
    }

    private func roundedRectPerimeter(rect: CGRect, radius: CGFloat) -> CGFloat {
        let clampedRadius = min(radius, min(rect.width, rect.height) / 2)
        return 2 * (rect.width - 2 * clampedRadius)
            + 2 * (rect.height - 2 * clampedRadius)
            + 2 * .pi * clampedRadius
    }
}

private extension CopyCore.KeyboardShortcut.Modifiers {
    init(_ flags: NSEvent.ModifierFlags) {
        var modifiers: CopyCore.KeyboardShortcut.Modifiers = []
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        self = modifiers
    }
}
