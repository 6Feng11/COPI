import CoreGraphics

public enum CopyToastPlacement {
    public static let verticalOffset = 16.0
    public static let feedbackWidth = 118.0
    public static let feedbackHeight = 42.0

    public static func feedbackSize(for message: String) -> CGSize {
        CGSize(width: feedbackWidth, height: feedbackHeight)
    }

    public static func feedbackOrigin(anchor: CGRect, size: CGSize) -> CGPoint {
        centeredOrigin(anchor: anchor, size: size)
    }

    public static func centeredOrigin(anchor: CGRect, size: CGSize) -> CGPoint {
        CGPoint(
            x: anchor.midX - size.width / 2,
            y: anchor.midY - size.height / 2
        )
    }

    public static func nearAnchorOrigin(anchor: CGRect, size: CGSize) -> CGPoint {
        CGPoint(
            x: anchor.midX - size.width / 2,
            y: anchor.maxY - size.height - verticalOffset
        )
    }
}
