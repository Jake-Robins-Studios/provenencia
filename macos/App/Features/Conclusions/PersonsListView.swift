import SwiftUI

/// The Persons list (S9-09, board S9-D2). The place, query key, and history
/// entry stay Persons. The secondary line is the birth and death.
typealias PersonsListView = ConclusionListPage<PersonsList>

enum PersonsList: ConclusionListKind {
    static func key(project: ProjectKey) -> CatalogQueryKey { .personsList(project: project) }
    static var title: LocalizedStringResource { L10n.Workspace.personsTitle }
    static var identifierRoot: String { "persons" }
    static var emptyTitle: LocalizedStringResource { L10n.Workspace.personsEmptyTitle }
    static var emptyMessage: LocalizedStringResource { L10n.Workspace.personsEmptyMessage }
    static func countMeta(_ count: Int) -> String { L10n.Workspace.personCount(count) }
    static func refreshingMeta(_ count: Int) -> String { L10n.Workspace.personCountRefreshing(count) }
    static var mark: PVMarkKey { .subjectPerson }

    static func ref(_ summary: CatalogPersonSummary) -> String { summary.entity.ref }
    static func updatedAt(_ summary: CatalogPersonSummary) -> String { summary.updated.at }
    static func thumbnailRelPath(_ summary: CatalogPersonSummary) -> String { summary.pictureImageRelPath }

    static func titleSource(_ summary: CatalogPersonSummary) -> PVTitleSource {
        titleSource(summary, orders: NameFormatOrders())
    }

    static func titleSource(_ summary: CatalogPersonSummary, orders: NameFormatOrders) -> PVTitleSource {
        PersonTitleDisplay.titleSource(summary, style: .sorted, orders: orders)
    }

    static func accessibilityLabel(_ summary: CatalogPersonSummary) -> String {
        accessibilityLabel(summary, orders: NameFormatOrders())
    }

    static func accessibilityLabel(_ summary: CatalogPersonSummary, orders: NameFormatOrders) -> String {
        let title = ConclusionListRow.accessibilityLabel(titleSource(summary, orders: orders), ref: summary.entity.ref)
        let lines = lifeLines(summary)
        guard let life = L10n.DesignSystem.spokenJoin(lines.map(\.accessibilityLabel)) else { return title }
        let label = L10n.DesignSystem.spokenJoin(title, life)
        let extra = lines.reduce(0) { $0 + $1.extraPlaces }
        guard extra > 0 else { return label }
        return L10n.DesignSystem.spokenJoin(label, L10n.Conclusions.morePlaces(count: extra))
    }

    private static func lifeLines(_ summary: CatalogPersonSummary) -> [PersonLifeDisplay.LifeLine] {
        PersonLifeDisplay.lifeLines(summary, missing: .omitted)
    }

    static func location(_ summary: CatalogPersonSummary) -> WorkspaceLocation {
        location(summary, orders: NameFormatOrders())
    }

    static func location(_ summary: CatalogPersonSummary, orders: NameFormatOrders) -> WorkspaceLocation {
        .personDetail(
            entityId: summary.entity.id,
            ref: summary.entity.ref,
            title: PersonTitleDisplay.title(summary, style: .sorted, orders: orders)
        )
    }

    @MainActor
    static func secondary(_ summary: CatalogPersonSummary) -> PersonLifeLine {
        PersonLifeLine(lines: lifeLines(summary))
    }
}

/// Birth, then death, under a Person's name: each its date and place, with a +N for other
/// kept places. The row's own label speaks them, so they are hidden from VoiceOver.
struct PersonLifeLine: View {
    let lines: [PersonLifeDisplay.LifeLine]

    /// Nothing when nothing is recorded, so `PVList` lays out no second line.
    var body: some View {
        if !lines.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space6) {
                ForEach(lines, id: \.abbreviation) { line in
                    PVDatePlaceLine(line, dateTone: PVColor.textMuted, showsExtraPlaces: true)
                }
            }
            .accessibilityHidden(true)
        }
    }
}
