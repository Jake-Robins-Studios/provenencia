import SwiftUI

/// One related Place on a Place detail: title, optional role, span, opens
/// the related page (S9-D7 / S9-40).
struct PlaceRelationshipRow: View {
    let relationship: CatalogPlaceRelationship
    /// Optional role line under the title (Succeeded / Succeeded by).
    var role: String? = nil
    /// The section's `ConclusionDetailRelationship.id` for this row: the stop and scroll id Back
    /// restores, and what an open writes onto the page's history entry.
    let anchorID: String
    /// The section's focus: `anchorID` when this row has the keyboard.
    let focus: FocusState<String?>.Binding
    @Environment(WorkspaceNavigation.self) private var navigation

    var body: some View {
        Button(action: open) {
            HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space4) {
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    Text(verbatim: displayTitle)
                        .font(PVFont.body(size: PVTypeScale.bodySmall, weight: PVFontWeight.medium))
                        .foregroundStyle(PVColor.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let role, !role.isEmpty {
                        Text(verbatim: role)
                            .font(PVFont.body(size: PVTypeScale.caption))
                            .foregroundStyle(PVColor.textSecondary)
                    }
                    if !spanText.isEmpty {
                        Text(verbatim: spanText)
                            .font(PVFont.mono(size: PVTypeScale.caption))
                            .foregroundStyle(PVColor.textMuted)
                    }
                }
                Spacer(minLength: 0)
                PVIcon(.chevronForward, size: 12)
                    .foregroundStyle(PVColor.textMuted)
            }
            .padding(.vertical, PVSpacing.space4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PVFocusRingButtonStyle())
        .id(anchorID)
        .focused(focus, equals: anchorID)
        .pvActivatesOnReturn(when: focus.wrappedValue == anchorID, open)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
        .accessibilityIdentifier("places.detail.relationship.\(relationship.id)")
    }

    private func open() {
        let location = WorkspaceLocation.placeDetail(
            entityId: relationship.entity.id,
            ref: relationship.entity.ref,
            title: relationship.title.isEmpty ? nil : relationship.title
        )
        navigation.go(to: location, from: ConclusionSectionAnchor(part: .related, id: anchorID))
    }

    private var displayTitle: String {
        let t = relationship.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? relationship.entity.ref : t
    }

    private var spanText: String {
        PlacePeriodDisplay.span(start: relationship.startDate, end: relationship.endDate)
    }

    private var accessibilityLabel: String {
        var parts = [displayTitle]
        if let role, !role.isEmpty { parts.append(role) }
        if !spanText.isEmpty { parts.append(spanText) }
        return parts.joined(separator: ", ")
    }
}

/// Formats a Place period or membership span for detail rows.
enum PlacePeriodDisplay {
    static func span(
        start: CatalogDateValueInput?,
        end: CatalogDateValueInput?,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let a = start.map { DateValueDisplay.string(for: $0, locale: locale) } ?? ""
        let b = end.map { DateValueDisplay.string(for: $0, locale: locale) } ?? ""
        switch (a.isEmpty, b.isEmpty) {
        case (true, true):
            return ""
        case (false, true):
            return L10n.Conclusions.placePeriodOpen(start: a)
        case (true, false):
            return L10n.Conclusions.placePeriodUntil(end: b)
        case (false, false):
            return L10n.Conclusions.lifeSpan(born: a, died: b)
        }
    }
}

/// One related-place row inside a Place detail section (S9-40).
struct ConclusionDetailRelationship: Equatable, Identifiable {
    var relationship: CatalogPlaceRelationship
    var role: String? = nil

    var id: String {
        if let role, !role.isEmpty {
            return "\(relationship.id)-\(role)"
        }
        return relationship.id
    }
}

/// One Place hierarchy section (Part of / Contains / Succession). Carries relationship
/// rows when Go filled them; otherwise the empty sentence.
struct ConclusionDetailSection: Equatable, Identifiable {
    var id: String
    var title: LocalizedStringResource
    var aside: String
    var emptyText: String
    var relationships: [ConclusionDetailRelationship] = []
    /// Contains remainder when the list is truncated (PLD-5).
    var omittedCount: Int = 0
}

/// A relationship section: header, rows when present, otherwise the empty sentence.
struct ConclusionDetailRelationshipSection: View {
    let section: ConclusionDetailSection

    @FocusState private var focused: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PVSectionHeader(title: section.title, aside: {
                Text(verbatim: section.aside)
                    .font(PVFont.body(size: PVTypeScale.caption, italic: true))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(2)
            })
            if section.relationships.isEmpty {
                Text(verbatim: section.emptyText)
                    .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
                    .foregroundStyle(PVColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, PVSpacing.space5)
            } else {
                ForEach(section.relationships) { row in
                    PlaceRelationshipRow(relationship: row.relationship, role: row.role, anchorID: row.id, focus: $focused)
                }
                if section.omittedCount > 0 {
                    Text(verbatim: L10n.Conclusions.placeContainsMore(section.omittedCount))
                        .font(PVFont.body(size: PVTypeScale.caption, italic: true))
                        .foregroundStyle(PVColor.textMuted)
                        .padding(.vertical, PVSpacing.space3)
                }
            }
        }
        .conclusionAnchorRestore([.related], isReady: true, focus: $focused) { anchor in
            section.relationships.contains { $0.id == anchor.id }
                ? ConclusionAnchorTarget(stop: anchor.id, scrollID: anchor.id) : nil
        }
        .accessibilityElement(children: section.relationships.isEmpty ? .combine : .contain)
        .accessibilityLabel(
            section.relationships.isEmpty
                ? L10n.DesignSystem.spokenJoin(L10n.string(section.title), section.emptyText)
                : L10n.string(section.title)
        )
    }
}
