import SwiftUI

/// One field on a Conclusion detail page (board S9-D5): label · lead value ·
/// state badge, Source count and disagreement · disclosures for a mixed
/// field's other values and for the Why. State is always text, never colour
/// alone. Snowflake: Person, Event and Place pages share it from this folder.
struct ReconciledValueRow: View {
    /// How the row offers where its value came from. `.why` is the Why disclosure
    /// (the Event and Place pages). `.sheet` is the Person page's mode: the row
    /// ends with a 28pt slot holding the provenance control (empty when the row
    /// has no records) and draws no Why.
    enum Provenance {
        case why
        case sheet
    }

    let model: ReconciledValueRowModel
    var provenance: Provenance = .why
    /// Opens the provenance sheet on this row (`.sheet` mode only).
    var openProvenance: () -> Void = {}
    /// The section's focus for the open arrow: the row's id when the arrow has the keyboard, so
    /// Back can give it back (`ConclusionDetailRowsSection`).
    let openFocus: FocusState<String?>.Binding
    @Environment(WorkspaceNavigation.self) private var navigation
    @State private var showsOtherValues = false
    @State private var showsWhy = false
    /// How many pages of a long list of lines the row has revealed (`ReconciledValueRowModel.listFold`).
    @State private var folds = ConclusionFoldState<String>()
    /// Where the keyboard goes when the last page of lines is revealed and Show more leaves.
    @FocusState private var focusedStop: Stop?

    /// A disclosure stop of the row.
    private enum Stop: Hashable {
        case why, provenance, others, more
    }

    /// The value column starts after the label column and its gap.
    static let labelWidth: CGFloat = 132
    static let disclosureInset: CGFloat = labelWidth + PVSpacing.space6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PVDivider()
            HStack(alignment: .center, spacing: PVSpacing.space6) {
                summary
                disclosures
                if provenance == .sheet {
                    provenanceSlot
                }
            }
            .frame(minHeight: 52)
            .padding(.vertical, PVSpacing.space3)
            if folded.hidden > 0 {
                ConclusionShowMoreRow(
                    hidden: folded.hidden,
                    fold: ReconciledValueRowModel.listFold,
                    focus: $focusedStop,
                    stop: .more,
                    revealed: revealsLastPage ? firstStop : nil,
                    expand: { folds.revealPage(model.id) }
                )
                .padding(.leading, Self.disclosureInset)
                .padding(.bottom, PVSpacing.space3)
                .accessibilityIdentifier("conclusion.detail.row.\(model.id).more")
            }
            if showsOtherValues {
                otherValues
                    .padding(.leading, Self.disclosureInset)
                    .padding(.bottom, PVSpacing.space5)
            }
            if provenance == .why, showsWhy {
                ReconciliationReasoningView(model: model)
                .padding(.leading, Self.disclosureInset)
                .padding(.bottom, PVSpacing.space5)
            }
        }
        .accessibilityIdentifier("conclusion.detail.row.\(model.id)")
        .onChange(of: model.shown.listedValues.map(\.id)) { folds = ConclusionFoldState<String>() }
    }

    /// The row's first disclosure stop: the Why (`.why`) or the provenance control (`.sheet`), else the
    /// other values. Nil when the row has none.
    private var firstStop: Stop? {
        if model.recordCount > 0 { return provenance == .why ? .why : .provenance }
        return model.otherValuesLabel == nil ? nil : .others
    }

    /// Whether the next Show more press reveals every line left.
    private var revealsLastPage: Bool {
        ReconciledValueRowModel.listFold.shown(model.shown.listedValues, pages: folds.pages(model.id) + 1).hidden == 0
    }

    /// The row's lines at the pages revealed, and how many the fold leaves out.
    private var folded: (shown: PVProvenanceSheetContent.Shown, hidden: Int) {
        var shown = model.shown
        let fold = ReconciledValueRowModel.listFold.shown(shown.listedValues, pages: folds.pages(model.id))
        shown.listedValues = fold.shown
        return (shown, fold.hidden)
    }

    /// Label, value and state: one VoiceOver element with the row's spoken
    /// label; the disclosures stay separate controls.
    private var summary: some View {
        HStack(alignment: model.shown.listedValues.isEmpty ? .center : .firstTextBaseline, spacing: PVSpacing.space6) {
            Text(model.label)
                .pvMicroCaps()
                .foregroundStyle(PVColor.textMuted)
                .frame(width: Self.labelWidth, alignment: .leading)
            value
                .frame(maxWidth: .infinity, alignment: .leading)
            state
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel(pages: folds.pages(model.id)))
    }

    private var value: some View {
        PVProvenanceValueList(folded.shown)
    }

    private var state: some View {
        HStack(spacing: PVSpacing.space4) {
            if let badge = model.shown.badge {
                PVProvenanceStateBadge(badge)
            }
            if let count = model.count {
                Text(count)
                    .font(PVFont.mono(size: PVTypeScale.caption))
                    .foregroundStyle(PVColor.textMuted)
            }
            if let against = model.against {
                HStack(spacing: PVSpacing.space2) {
                    PVIcon(.circleMinus, size: 12)
                    Text(against)
                        .font(PVFont.body(size: PVTypeScale.caption))
                }
                .foregroundStyle(PVColor.textSecondary)
            }
        }
    }

    private var disclosures: some View {
        HStack(spacing: PVSpacing.space2) {
            if let label = model.otherValuesLabel {
                PVDisclosureButton(label, isExpanded: $showsOtherValues)
                    .focused($focusedStop, equals: .others)
                    .accessibilityIdentifier("conclusion.detail.row.\(model.id).others")
            }
            if provenance == .why, model.recordCount > 0 {
                PVDisclosureButton(L10n.Conclusions.whyButton, isExpanded: $showsWhy)
                    .focused($focusedStop, equals: .why)
                    .accessibilityIdentifier("conclusion.detail.row.\(model.id).why")
            }
            if let opens = model.opens {
                PVIconButton(.arrowUpRight, label: opens.label, size: .sm, action: open(opens))
                    .focused(openFocus, equals: model.id)
                    .pvActivatesOnReturn(when: openFocus.wrappedValue == model.id, open(opens))
                .accessibilityIdentifier("conclusion.detail.row.\(model.id).open")
            }
        }
        .frame(minWidth: 72, alignment: .trailing)
    }

    /// Opens the place the row leads to, writing the row onto the page's history entry.
    private func open(_ opens: ReconciledValueRowModel.Opens) -> () -> Void {
        {
            navigation.go(to: opens.location, from: ConclusionSectionAnchor(part: .detailRow, id: model.id))
        }
    }

    /// The 28pt slot at the row's end: the provenance control when the row has
    /// records, else empty so the values line up (VoiceOver skips the empty slot).
    @ViewBuilder
    private var provenanceSlot: some View {
        if model.recordCount == 0 {
            Color.clear
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        } else {
            PVIconButton(.info, label: L10n.Conclusions.provenanceOpen(model.label), size: .sm, action: openProvenance)
                .focused($focusedStop, equals: .provenance)
                .frame(width: 28, height: 28)
                .accessibilityIdentifier("conclusion.detail.row.\(model.id).provenance")
        }
    }

    private var otherValues: some View {
        PVCard(tone: .sunken, cornerRadius: PVRadius.sm) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(model.otherValues) { other in
                    HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space5) {
                        Text(verbatim: "\(other.rank)")
                            .font(PVFont.mono(size: PVTypeScale.caption))
                            .foregroundStyle(PVColor.textFaint)
                            .frame(width: 24, alignment: .leading)
                        Text(other.text)
                            .font(model.shown.face.valueFont)
                            .foregroundStyle(PVColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(other.support)
                            .font(PVFont.mono(size: PVTypeScale.caption))
                            .foregroundStyle(PVColor.textSecondary)
                    }
                    .padding(.horizontal, PVSpacing.space5)
                    .padding(.vertical, PVSpacing.space4)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, PVSpacing.space2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.Conclusions.otherValuesList(model.label))
    }
}

/// A page's field rows, under a heading with the refreshing spinner when `title` is given.
/// A page that draws neither (the Person page's Vitals, which shows refreshing in its
/// section switcher) passes nil.
struct ConclusionDetailRowsSection: View {
    let rows: [ReconciledValueRowModel]
    let refreshing: Bool
    var title: LocalizedStringResource? = nil
    var provenance: ReconciledValueRow.Provenance = .why

    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(\.pvWidthClass) private var widthClass
    /// The row whose provenance sheet is open (`.sheet` mode); one presenter for all rows.
    @State private var provenanceItem: ProvenanceSheetItem?
    /// The row whose open arrow has the keyboard (`ReconciledValueRow.openFocus`).
    @FocusState private var openFocus: String?

    /// Where Back puts the keyboard for `anchor`: the open arrow of the row it opened from. Nil
    /// for a row that is gone or no longer leads anywhere.
    static func anchorTarget(
        rows: [ReconciledValueRowModel], anchor: ConclusionSectionAnchor
    ) -> String? {
        guard anchor.part == .detailRow, let row = rows.first(where: { $0.id == anchor.id }), row.opens != nil
        else { return nil }
        return row.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                PVSectionHeader(title: title, aside: {
                    if refreshing {
                        ProgressView().controlSize(.small)
                    }
                })
            }
            ForEach(rows) { row in
                ReconciledValueRow(
                    model: row, provenance: provenance,
                    openProvenance: { provenanceItem = ProvenanceSheetItem(id: row.id) },
                    openFocus: $openFocus
                )
                .id(row.id)
            }
        }
        .conclusionAnchorRestore([.detailRow], isReady: true, focus: $openFocus) {
            Self.anchorTarget(rows: rows, anchor: $0)
        }
        .pvSheet(item: $provenanceItem) { item in
            if let row = item.row(in: rows) {
                ProvenanceSheetHost(
                    content: row.provenanceContent(),
                    columns: PVProvenanceColumns(widthClass: widthClass),
                    idPrefix: "conclusion.detail.provenance",
                    open: { navigation.go(to: .provenance($0, $1)) }
                )
                .accessibilityIdentifier("conclusion.detail.provenance.\(row.id)")
            }
        }
        // A row that leaves the page closes its sheet.
        .onChange(of: rows) {
            if let item = provenanceItem, item.row(in: rows) == nil {
                provenanceItem = nil
            }
        }
    }
}
