public enum DockMagnification {
    public static func scale(
        pointerPosition: Double?,
        itemCenter: Double,
        distance: Double,
        maxScale: Double
    ) -> Double {
        guard let pointerPosition,
              distance > 0,
              maxScale >= 1
        else {
            return 1
        }

        let absoluteDistance = abs(pointerPosition - itemCenter)
        guard absoluteDistance < distance else {
            return 1
        }

        let progress = 1 - absoluteDistance / distance
        return 1 + (maxScale - 1) * progress
    }

    public static func scale(
        hoveredIndex: Int?,
        itemIndex: Int,
        maxScale: Double,
        neighborScale: Double
    ) -> Double {
        guard let hoveredIndex,
              maxScale >= 1,
              neighborScale >= 1
        else {
            return 1
        }

        let indexDistance = abs(hoveredIndex - itemIndex)
        switch indexDistance {
        case 0:
            return maxScale
        case 1:
            return neighborScale
        default:
            return 1
        }
    }
}
