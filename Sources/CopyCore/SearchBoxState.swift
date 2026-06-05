public struct SearchBoxState: Equatable, Sendable {
    public enum Presentation: Equatable, Sendable {
        case compactCircle
        case fullWidthOverlay
    }

    public var query: String
    public var isExpanded: Bool

    public var presentation: Presentation {
        isExpanded ? .fullWidthOverlay : .compactCircle
    }

    public init(query: String, isExpanded: Bool) {
        self.query = query
        self.isExpanded = isExpanded
    }

    public func collapsedAfterOutsideTap() -> SearchBoxState {
        guard isExpanded else {
            return self
        }

        return SearchBoxState(query: "", isExpanded: false)
    }
}
