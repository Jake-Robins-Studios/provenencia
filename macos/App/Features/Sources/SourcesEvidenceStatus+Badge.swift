import SwiftUI

/// How an Evidence graph's status is drawn: the badge a Sources list graph row carries.
extension SourcesModel.EvidenceStatus {
    var badgeTone: PVBadgeTone {
        switch self {
        case .empty: .neutral
        case .inProgress: .warning
        case .promoted: .success
        }
    }

    var badgeIcon: PVSymbol {
        switch self {
        case .empty: .circleDashed
        case .inProgress: .circleDot
        case .promoted: .circleCheck
        }
    }

    /// Every badge of the Sources table is this wide, so they share a right edge down the column: the
    /// width of Not started, the widest label.
    static var badgeWidth: CGFloat { 128 }

    /// Only a graph with nothing on it draws an outline instead of a fill.
    var badgeSubtle: Bool { self == .empty }

    /// The status as a Sources list badge. Hidden from VoiceOver: the graph
    /// row's label carries the status.
    @MainActor var badge: some View {
        PVBadge(label, tone: badgeTone, icon: badgeIcon, subtle: badgeSubtle, minWidth: Self.badgeWidth)
            .accessibilityHidden(true)
    }
}
