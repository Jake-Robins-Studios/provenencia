import SwiftUI

/// The Person page's Family section (S13-12, board S13-D3): the person's
/// parents, siblings, partners and children as person tiles joined by lines.
/// It declares its reads in `ConclusionPageSection.reads`, keeps the diagram
/// drawn while it reloads, and opens a relative on their Family.
struct PersonFamilySection: View {
    let entityId: String
    let pageIdentifier: String

    @Environment(WorkspaceSession.self) private var session
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(\.pvWidthClass) private var widthClass

    /// The pages of each list the researcher has unfolded. Reset when the page is another person.
    @State private var folds = PagedFoldState<PersonFamilyContent.Fold>()

    private var root: String { ConclusionPageSection.family.accessibilityIdentifierRoot(pageIdentifier: pageIdentifier) }

    var body: some View {
        let inputs = PersonFamilyContent.Inputs(folds: folds, orders: session.nameFormat, locale: .autoupdatingCurrent)
        ConclusionPageSectionHost<CatalogPersonFamily, PersonFamilyContent.Inputs, PersonFamilyContent, PersonFamilyDiagram>(
            section: .family,
            entityId: entityId,
            accessibilityIdentifierRoot: root,
            errorTitle: L10n.Conclusions.familyErrorTitle,
            emptyTitle: L10n.Conclusions.familyEmptyTitle,
            emptyMessage: L10n.string(L10n.Conclusions.familyEmptyMessage),
            extra: inputs,
            make: { PersonFamilyContent(family: $0, folds: $1.folds, locale: $1.locale, orders: $1.orders) },
            isEmpty: \.isEmpty
        ) { content in
            PersonFamilyDiagram(
                content: content,
                projectDir: session.projectKey.projectDir,
                widthClass: widthClass,
                accessibilityIdentifierRoot: root,
                open: { navigation.go(to: $0, from: $1) },
                expand: { self.folds.revealPage($0) }
            )
        }
    }
}

/// The two columns laid out by `PersonFamilyLayout`: lines, captions, then one
/// container per group in reading order, so Tab runs the left column group by
/// group, then the right column group by group. A marriage line takes no Tab stop.
struct PersonFamilyDiagram: View {
    let content: PersonFamilyContent
    let projectDir: String
    let widthClass: PVWidthClass
    let accessibilityIdentifierRoot: String
    let open: (WorkspaceLocation, ConclusionSectionAnchor?) -> Void
    var expand: (PersonFamilyContent.Fold) -> Void = { _ in }

    @State private var width: CGFloat = 0
    /// The tile with the keyboard: a tile's id.
    @FocusState private var focused: String?

    var body: some View {
        Group {
            if width > 0 {
                diagram(PersonFamilyLayout(content: content, width: width, widthClass: widthClass))
            } else {
                Color.clear.frame(height: 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .pvScrollsShowMoreReveals()
        .conclusionAnchorRestore([.family], isReady: width > 0, focus: $focused) { content.anchorStop(for: $0) }
    }

    private func diagram(_ layout: PersonFamilyLayout) -> some View {
        let tiles = Dictionary(content.allTiles.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let lines = Dictionary(content.allMarriageLines.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return ZStack(alignment: .topLeading) {
            Path { path in
                for segment in layout.segments { path.addRect(segment) }
            }
            .fill(PVColor.borderStrong)
            .accessibilityHidden(true)
            ForEach(Array(layout.captions.enumerated()), id: \.offset) { _, caption in
                Text(verbatim: caption.text)
                    .pvMicroCaps()
                    .foregroundStyle(PVColor.textMuted)
                    .fixedSize()
                    .offset(x: caption.origin.x, y: caption.origin.y)
                    .accessibilityHidden(true)
            }
            ForEach(Array(layout.groups.enumerated()), id: \.offset) { _, group in
                ZStack(alignment: .topLeading) {
                    // VoiceOver reads the items in the order the layout lists them, which a
                    // marriage line between two tiles needs: it is read after the second.
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        placed(item, tiles: tiles, lines: lines)
                            .accessibilitySortPriority(Double(group.items.count - index))
                    }
                }
                .frame(width: group.frame.width, height: group.frame.height, alignment: .topLeading)
                .offset(x: group.frame.minX, y: group.frame.minY)
                .accessibilityElement(children: .contain)
                .accessibilityLabel(group.label)
            }
        }
        .frame(width: width, height: layout.height, alignment: .topLeading)
    }
}

extension PersonFamilyDiagram {
    /// One item of a group at its frame: a tile, a marriage line, or a Show more row.
    @ViewBuilder
    fileprivate func placed(
        _ item: PersonFamilyLayout.Placed,
        tiles: [String: PersonCardLink],
        lines: [String: PersonFamilyContent.MarriageLine]
    ) -> some View {
        switch item {
        case .tile(let placed):
            if let tile = tiles[placed.id] {
                PVPersonCard(content: tile.content, projectDir: projectDir) {
                    if let location = tile.location {
                        open(location, ConclusionSectionAnchor(part: .family, id: placed.id))
                    }
                }
                .frame(width: placed.frame.width, height: placed.frame.height)
                .focused($focused, equals: placed.id)
                .id(placed.id)
                .offset(x: placed.frame.minX, y: placed.frame.minY)
                .accessibilityIdentifier("\(accessibilityIdentifierRoot).tile.\(placed.id)")
            }
        case .line(let placed):
            if let marriage = lines[placed.id] {
                // Spoken as the content words it (the couple's names, then the line), never a Tab stop.
                PVDatePlaceLine(marriage.line)
                    .frame(width: placed.frame.width, height: placed.frame.height, alignment: .leading)
                    .help(marriage.line.text)
                    .id(placed.id)
                    .offset(x: placed.frame.minX, y: placed.frame.minY)
                    .accessibilityIdentifier("\(accessibilityIdentifierRoot).marriage.\(placed.id)")
            }
        case .more(let more):
            let revealed = content.firstRevealed(by: more.fold)
            PVShowMoreRow(
                hidden: more.count,
                fold: PersonFamilyContent.fold,
                focus: $focused,
                stop: PersonFamilyContent.moreID(more.fold),
                revealed: revealed,
                revealedRow: revealed.map(AnyHashable.init)
            ) { expand(more.fold) }
                .id(PersonFamilyContent.moreID(more.fold))
                .frame(width: more.frame.width, height: more.frame.height, alignment: .leading)
                .offset(x: more.frame.minX, y: more.frame.minY)
                .accessibilityIdentifier("\(accessibilityIdentifierRoot).more")
        }
    }
}


#if DEBUG
#Preview("F1 Shared parent") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.full) }
#Preview("F2 Records that disagree") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.conflicting) }
#Preview("F3 One-parent groups") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.oneParentGroups) }
#Preview("F4 Unrelated sets") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.unrelatedSets) }
#Preview("F6 No parents recorded") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.siblingsOnly) }
#Preview("M1 Marriages") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.married) }
#Preview("M2 Missing halves") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.marriageHalves) }
#Preview("M3 Two marriages") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.twoMarriages) }
#Preview("M4 Three parents") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.threeParentMarriages) }
#Preview("11h After clicking Anna") { PersonFamilyPreviewData.diagram(PersonFamilyPreviewData.annaOnly) }
#endif
