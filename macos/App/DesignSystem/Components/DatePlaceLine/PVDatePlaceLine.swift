import SwiftUI

/// A date · place line under a title: a Person's *b.* and *d.* lines, an
/// Event's summary. A missing half says it is unknown, or with
/// `missing: .omitted` is left out with its dot, and the line stays one line,
/// its place cut at the tail. One VoiceOver element with the caller's spoken
/// label. The date and place come already worded: this view draws, it does not
/// format. An optional trailing part is drawn after the place and never cut
/// (", with Heinrich Weber"): the place gives way to it.
struct PVDatePlaceLine: View {
    /// What a line says of a half that is not recorded. `.stated` is the
    /// header: both halves always, the missing one "unknown". `.omitted` is a
    /// tile or a list row: the missing half is left out, with its dot.
    enum Missing: Equatable { case stated, omitted }

    /// A leading abbreviation (*b.*, *d.*); nil for none.
    var leading: String?
    let date: String?
    let place: String?
    let accessibilityLabel: String
    var missing: Missing = .stated
    var dateSize: CGFloat = PVTypeScale.caption
    /// The date's ink; a list row mutes it.
    var dateTone: Color = PVColor.textPrimary
    /// Places beyond the one shown; a "+N" badge when above zero.
    var extraCount: Int = 0
    /// Drawn right after the last part (the place, else the date, else the
    /// leading abbreviation), the comma attached, and never cut.
    var trailing: String?

    init(
        leading: String? = nil,
        date: String?,
        place: String?,
        accessibilityLabel: String,
        missing: Missing = .stated,
        dateSize: CGFloat = PVTypeScale.caption,
        dateTone: Color = PVColor.textPrimary,
        extraCount: Int = 0,
        trailing: String? = nil
    ) {
        self.leading = leading
        self.date = date
        self.place = place
        self.accessibilityLabel = accessibilityLabel
        self.missing = missing
        self.dateSize = dateSize
        self.dateTone = dateTone
        self.extraCount = extraCount
        self.trailing = trailing
    }

    /// The date half as spoken: the date, or the "date unknown" copy.
    nonisolated static func spokenDate(_ date: String?) -> String {
        date ?? L10n.string(L10n.DesignSystem.datePlaceLineDateUnknown)
    }

    /// The place half as spoken: the place, or the "place unknown" copy.
    nonisolated static func spokenPlace(_ place: String?) -> String {
        place ?? L10n.string(L10n.DesignSystem.datePlaceLinePlaceUnknown)
    }

    /// The date and place as one plain-text line, "3 May 1790 · Bremen". A nil
    /// or empty half is left out, with its dot; empty when neither is recorded.
    nonisolated static func text(date: String?, place: String?) -> String {
        let date = date ?? ""
        let place = place ?? ""
        if date.isEmpty { return place }
        if place.isEmpty { return date }
        return L10n.Conclusions.lineJoin(first: date, rest: place)
    }

    private var drawsDate: Bool { date != nil || missing == .stated }
    private var drawsPlace: Bool { place != nil || missing == .stated }

    /// `part` with the trailing part beside it, when `part` is the last one drawn.
    @ViewBuilder
    private func ending<Part: View>(_ part: Part, when last: Bool) -> some View {
        if last, let trailing {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                part
                Text(verbatim: trailing)
                    .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                    .foregroundStyle(PVColor.onSelection(PVColor.textSecondary))
                    .lineLimit(1)
                    .fixedSize()
                    .layoutPriority(1)
            }
        } else {
            part
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space4) {
            if let leading {
                ending(
                    Text(verbatim: leading)
                        .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                        .foregroundStyle(PVColor.onSelection(PVColor.textMuted)),
                    when: !drawsDate && !drawsPlace
                )
            }
            if let date {
                ending(
                    Text(verbatim: date)
                        .font(PVFont.mono(size: dateSize))
                        .foregroundStyle(PVColor.onSelection(dateTone))
                        .lineLimit(missing == .omitted ? 1 : nil)
                        .layoutPriority(1),
                    when: !drawsPlace
                )
            } else if missing == .stated {
                Text(L10n.DesignSystem.datePlaceLineDateUnknown)
                    .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                    .foregroundStyle(PVColor.onSelection(PVColor.textMuted))
            }
            if missing == .stated || (date != nil && place != nil) {
                Text(verbatim: "·")
                    .foregroundStyle(PVColor.onSelection(PVColor.textFaint))
            }
            if let place {
                ending(
                    Text(verbatim: place)
                        .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                        .foregroundStyle(PVColor.onSelection(PVColor.textSecondary))
                        .lineLimit(missing == .omitted ? 1 : nil)
                        .truncationMode(.tail),
                    when: true
                )
            } else if missing == .stated {
                ending(
                    Text(L10n.DesignSystem.datePlaceLinePlaceUnknown)
                        .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                        .foregroundStyle(PVColor.onSelection(PVColor.textMuted)),
                    when: true
                )
            }
            if extraCount > 0 {
                PVBadge.moreCount(extraCount)
                    .layoutPriority(1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Trailing part") {
    VStack(alignment: .leading, spacing: PVSpacing.space4) {
        PVDatePlaceLine(
            leading: "m.", date: "3 May 1812", place: "Altona", accessibilityLabel: "Date and place",
            missing: .omitted, trailing: ", with Heinrich Weber"
        )
        PVDatePlaceLine(
            leading: "m.", date: "abt 1816", place: nil, accessibilityLabel: "Date only",
            missing: .omitted, trailing: ", with Heinrich Weber"
        )
        PVDatePlaceLine(
            leading: "m.", date: nil, place: nil, accessibilityLabel: "Abbreviation only",
            missing: .omitted, trailing: ", with Heinrich Weber"
        )
        PVDatePlaceLine(
            leading: "m.", date: "3 May 1812", place: "A very long place name that gives way to the trailing part",
            accessibilityLabel: "Cut place", missing: .omitted, trailing: ", with Heinrich Weber"
        )
        .frame(width: 280, alignment: .leading)
    }
    .padding(PVSpacing.space9)
    .background(PVColor.surfacePage)
}
