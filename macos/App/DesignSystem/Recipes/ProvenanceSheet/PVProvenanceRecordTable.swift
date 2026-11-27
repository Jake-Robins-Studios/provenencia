import SwiftUI

/// The records of one value, in groups, as a table of `PVProvenanceRecordRow`s:
/// a group line over each owning entity (when the content names an owner), a
/// value heading over each run of records that count under a different value,
/// and a rule between citations (records whose full citations read the same sit
/// together with none). The first record under a line follows the line, not
/// a rule. Put `PVProvenanceColumnHeadings` above it, sharing its columns.
struct PVProvenanceRecordTable: View {
    let groups: [PVProvenanceSheetContent.Group]
    let face: PVProvenanceFace
    var columns = PVProvenanceColumns()
    /// The prefix of every row's accessibility ids (`PVProvenanceRecordRow`).
    let idPrefix: String
    let open: (PVProvenanceSheetContent.Record, PVProvenanceLink) -> Void

    /// Whether a value's first citation run follows a line (its own heading, or the group's owner line for
    /// the group's first value) rather than a rule.
    nonisolated static func followsLine(hasHeading: Bool, valueIndex: Int, hasOwner: Bool) -> Bool {
        hasHeading || (valueIndex == 0 && hasOwner)
    }

    /// Whether a rule falls before a citation run: before every run but the first, and before the first
    /// unless a line leads it. A run's later records follow its first, with none between.
    nonisolated static func drawsRule(runIndex: Int, followsLine: Bool) -> Bool {
        runIndex > 0 || !followsLine
    }

    /// The fold of the table: the first 50 citation runs, then a page of `PagedFold.pageSize` at a time (S15-27 D-1).
    nonisolated static let fold = PagedFold(limit: 50, minimumHidden: 1)

    /// The table's one fold, the key of its `PagedFoldState`.
    enum Fold: Hashable { case runs }

    @State private var folds = PagedFoldState<Fold>()
    @FocusState private var focus: PVProvenanceFocus?

    var body: some View {
        let folded = PVProvenanceSheetContent.folded(groups, by: Self.fold, pages: folds.pages(.runs))
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(folded.groups.enumerated()), id: \.offset) { groupIndex, group in
                if let owner = group.owner {
                    PVDivider(color: PVColor.borderStrong)
                    PVProvenanceOwnerLine(owner)
                }
                ForEach(Array(group.values.enumerated()), id: \.offset) { valueIndex, run in
                    if let heading = run.heading {
                        PVDivider()
                        PVProvenanceValueHeading(heading: heading, face: face)
                    }
                    let followsLine = Self.followsLine(
                        hasHeading: run.heading != nil, valueIndex: valueIndex, hasOwner: group.owner != nil)
                    ForEach(Array(run.citations.enumerated()), id: \.element.key) { runIndex, citation in
                        let position = PVProvenanceSheetContent.RunPosition(group: groupIndex, value: valueIndex, run: runIndex)
                        if Self.drawsRule(runIndex: runIndex, followsLine: followsLine) {
                            PVDivider()
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(citation.records.enumerated()), id: \.element.id) { recordIndex, record in
                                PVProvenanceRecordRow(
                                    record: record, face: face, columns: columns, idPrefix: idPrefix, open: open,
                                    citationFocus: recordIndex == 0 ? PVFieldFocus($focus, equals: .citation(position)) : nil
                                )
                            }
                        }
                        .id(position)
                    }
                }
            }
            if folded.hidden > 0 {
                PVDivider()
                PVShowMoreRow(
                    hidden: folded.hidden,
                    fold: Self.fold,
                    focus: $focus,
                    stop: .showMore,
                    revealed: folded.firstRevealed.map(PVProvenanceFocus.citation),
                    revealedRow: folded.firstRevealed.map(AnyHashable.init),
                    expand: { folds.revealPage(.runs) }
                )
                .padding(.vertical, PVSpacing.space3)
            }
        }
        .preference(key: PVProvenanceShowMoreFocusKey.self, value: focus == .showMore)
    }
}

/// Whether the table's Show more row has keyboard focus, so the sheet's Done gives up Return.
/// Reduced with `||`.
struct PVProvenanceShowMoreFocusKey: PreferenceKey {
    static var defaultValue: Bool { false }
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

/// What the provenance table's keyboard focus rests on: a run's first citation link, by the run's
/// place in the whole table, or the Show more row.
enum PVProvenanceFocus: Hashable {
    case citation(PVProvenanceSheetContent.RunPosition)
    case showMore
}

// MARK: - Previews

enum PVProvenancePreviewData {
    static func record(
        _ id: String, readAs: String, title: String, detail: String, counted: Bool = true,
        phrase: String = "Kept", mark: PVSymbol = .check
    ) -> PVProvenanceSheetContent.Record {
        let outcome = CatalogReconcilerOutcome(
            observationID: id, observationRef: "OBS-\(id.uppercased())", reason: .kept, valueRank: 1,
            deniedByObservationID: "", recorded: .text(readAs), subjectID: "sub-\(id)", subjectRef: "CPR-\(id.uppercased())",
            citationID: "cit-\(id)", sourceID: "src-\(id)", sourceTitle: title, credibilityKey: "",
            transcriptionUncertain: false
        )
        return PVProvenanceSheetContent.Record(
            id: id, readAs: readAs, readAsIsPhrase: false, counted: counted, phrase: phrase, mark: mark,
            observationRef: outcome.observationRef, subjectRef: outcome.subjectRef, outcome: outcome,
            citation: .init(title: title, detail: detail, line: "\(title), \(detail)")
        )
    }

    static let census = record("census", readAs: "14 May 1817", title: "Census of Canada West, 1851", detail: "Vol. 3, p. 23")
    static let baptism = record(
        "baptism", readAs: "1817", title: "Baptism register, St James, York", detail: "image 37",
        counted: false, phrase: "Outvoted by 2 Sources", mark: .scale
    )
    static let groups = [PVProvenanceSheetContent.Group(owner: nil, records: [census, baptism])]

    private static func rendered(_ id: String, key: String) -> CatalogRenderedCitation {
        let full = [
            CatalogCitationRun(text: "1880 U.S. census, Ontario, Canada; digital image, ", italic: false),
            CatalogCitationRun(text: "Ancestry", italic: true),
            CatalogCitationRun(text: " (accessed 12 March 2025)", italic: false),
        ]
        let short = "1880 U.S. census, Ontario"
        return CatalogRenderedCitation(
            citationID: "cit-\(id)",
            full: .init(runs: full, plain: full.map(\.text).joined()),
            short: .init(runs: [CatalogCitationRun(text: short, italic: false)], plain: short),
            groupKey: key)
    }

    /// Two records of one formatted citation, then a record with no format.
    static let formattedGroups: [PVProvenanceSheetContent.Group] = {
        var first = census
        first.rendered = rendered("census", key: "full:1")
        var second = baptism
        second.rendered = rendered("baptism", key: "full:1")
        let fallback = record(
            "diary", readAs: "1817", title: "Family diary", detail: "p. 2", counted: false,
            phrase: "Another record", mark: .scale)
        return [PVProvenanceSheetContent.Group(
            owner: nil,
            values: [.init(heading: nil, citations: [
                .init(key: "full:1", records: [first, second]),
                .init(key: "record:diary", records: [fallback]),
            ])]
        )]
    }()

    /// A Birth date with two owners, the shown one first (PSK-2).
    static let ownerGroups = [
        PVProvenanceSheetContent.Group(
            owner: .init(id: "ev1", title: "Birth of Ada Lovelace", ref: "EVT-4KX2M", spoken: "Birth of Ada Lovelace", isShownOwner: true),
            records: [census, baptism]
        ),
        PVProvenanceSheetContent.Group(
            owner: .init(id: "ev2", title: "Birth of Ada Lovelace", ref: "EVT-9PQ2R", spoken: "Birth of Ada Lovelace"),
            records: [record("diary", readAs: "14 May 1817", title: "Family diary", detail: "p. 2", counted: false, phrase: "Another event", mark: .scale)]
        ),
    ]

    /// A sheet's content for the previews.
    static func content(groups: [PVProvenanceSheetContent.Group], summary: String?) -> PVProvenanceSheetContent {
        PVProvenanceSheetContent(
            title: "Birth date",
            shown: .init(face: .date, lead: "14 May 1817", emptyText: "No date recorded", badge: .merged),
            summary: summary,
            groups: groups
        )
    }
}

#Preview("One record, with and without Read as") {
    VStack(alignment: .leading, spacing: 24) {
        PVProvenanceRecordRow(
            record: PVProvenancePreviewData.census, face: .date, idPrefix: "preview", open: { _, _ in }
        )
        PVProvenanceRecordRow(
            record: PVProvenancePreviewData.census,
            columns: PVProvenanceColumns(showsReadAs: false), idPrefix: "preview", open: { _, _ in }
        )
    }
    .padding(24)
    .frame(width: 880)
    .background(PVColor.surfaceCard)
}

#Preview("A lone row above a table") {
    let columns = PVProvenanceColumns()
    VStack(alignment: .leading, spacing: 0) {
        PVProvenanceColumnHeadings(columns: columns)
        PVProvenanceRecordRow(
            record: PVProvenancePreviewData.census, face: .date, columns: columns, idPrefix: "preview", open: { _, _ in }
        )
        PVDivider()
        PVProvenanceRecordTable(
            groups: PVProvenancePreviewData.groups, face: .date, columns: columns, idPrefix: "preview", open: { _, _ in }
        )
    }
    .padding(24)
    .frame(width: 880)
    .background(PVColor.surfaceCard)
}

#Preview("Formatted, fallback and a same-citation run") {
    let columns = PVProvenanceColumns()
    VStack(alignment: .leading, spacing: 0) {
        PVProvenanceColumnHeadings(columns: columns)
        PVDivider()
        PVProvenanceRecordTable(
            groups: PVProvenancePreviewData.formattedGroups,
            face: .date, columns: columns, idPrefix: "preview", open: { _, _ in }
        )
    }
    .padding(24)
    .frame(width: 880)
    .background(PVColor.surfaceCard)
}

#Preview("Wide, with groups") {
    let columns = PVProvenanceColumns(widthClass: .wide)
    let groups = [
        PVProvenanceSheetContent.Group(
            owner: .init(id: "ev1", title: "Birth of Ada Lovelace", ref: "EVT-4KX2M", spoken: "Birth of Ada Lovelace", isShownOwner: true),
            records: [PVProvenancePreviewData.census]
        ),
        PVProvenanceSheetContent.Group(
            owner: .init(id: "ev2", title: "Birth of Ada Lovelace", ref: "EVT-9PQ2R", spoken: "Birth of Ada Lovelace"),
            values: [
                .init(heading: .value(.init(rank: 1, text: "1817", support: "2 Sources")), records: [PVProvenancePreviewData.baptism]),
                .init(heading: .otherRecords, records: [PVProvenancePreviewData.census]),
            ]
        ),
    ]
    VStack(alignment: .leading, spacing: 0) {
        PVProvenanceColumnHeadings(columns: columns)
        PVDivider()
        PVProvenanceRecordTable(groups: groups, face: .date, columns: columns, idPrefix: "preview", open: { _, _ in })
    }
    .padding(24)
    .frame(width: 1280)
    .background(PVColor.surfaceCard)
}
