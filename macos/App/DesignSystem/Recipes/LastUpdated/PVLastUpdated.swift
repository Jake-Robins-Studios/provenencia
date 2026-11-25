import SwiftUI

extension PVListDetail {
    /// A time as a cell with no icon: the relative words, the full stamp as help through `help`, or a
    /// faint dash when the time is empty or unparseable. The Sources list's Added and Updated cells.
    static func relative(
        _ at: String, in context: TimestampFormat.Context, help: (String) -> String
    ) -> PVListDetail {
        let text = TimestampFormat.string(at, .relative, in: context)
        return PVListDetail(
            text: text ?? "—",
            help: TimestampFormat.string(at, .stamp, in: context).map(help),
            icon: nil,
            faint: text == nil
        )
    }
}

/// The last-updated cell of a Conclusion list row (S10-22): the history icon and
/// the relative time with the full stamp as help, a faint dash when no time is
/// recorded, and the spoken suffix of the row label. `PVListDetailCell` draws
/// it. `now` is read as each row builds (no timer). The Sources table's
/// Updated cell draws `PVListDetail.relative` with no icon and reads `spoken`.
enum PVLastUpdated {
    /// Width of the column, icon included. Layout, not formatting.
    static let columnWidth: CGFloat = 136

    /// The cell: relative text with the full stamp as help, or a faint dash
    /// when the time is empty or unparseable.
    static func detail(_ updatedAt: String, in context: TimestampFormat.Context) -> PVListDetail {
        var detail = PVListDetail.relative(updatedAt, in: context, help: L10n.LastUpdated.help(stamp:))
        detail.icon = .history
        return detail
    }

    /// The column of a list: `detail` of each row's time at `columnWidth`.
    static func column<Item>(_ updatedAt: @escaping (Item) -> String) -> PVListDetailColumn<Item> {
        PVListDetailColumn(width: columnWidth) { detail(updatedAt($0), in: .current) }
    }

    /// How VoiceOver reads a last-updated time: `updated Yesterday`, or that it is unknown.
    static func spoken(_ updatedAt: String, in context: TimestampFormat.Context) -> String {
        TimestampFormat.string(updatedAt, .spoken, in: context).map(L10n.LastUpdated.a11yUpdated)
            ?? L10n.LastUpdated.a11yUnknown
    }

    /// A row's spoken label with its last-updated suffix.
    static func label(_ base: String, updatedAt: String, in context: TimestampFormat.Context) -> String {
        L10n.DesignSystem.spokenJoin(base, spoken(updatedAt, in: context))
    }
}

#if DEBUG
#Preview("Known and unknown") {
    VStack(alignment: .leading, spacing: PVSpacing.space4) {
        PVListDetailCell(
            detail: PVLastUpdated.detail("2026-10-14T21:15:00Z", in: .current),
            width: PVLastUpdated.columnWidth
        )
        PVListDetailCell(
            detail: PVLastUpdated.detail("", in: .current),
            width: PVLastUpdated.columnWidth
        )
    }
    .padding(PVSpacing.space6)
    .background(PVColor.surfaceCard)
}
#endif
