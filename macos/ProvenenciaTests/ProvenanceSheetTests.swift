import Foundation
import Testing
@testable import Provenencia

struct ProvenanceSheetTests {
    private typealias D = ReconciledValueDisplayTests
    private let en = Locale(identifier: "en_US")

    private func row(_ id: String, records: Int) -> ReconciledValueRowModel {
        let outcomes = (0..<records).map { D.outcome("\(id)-\($0)", "kept") }
        let field = D.field("single", key: "date", label: "Birth date", valueType: "date", [D.value(1, "kept")], outcomes: outcomes)
        var model = ReconciledValueRowModel(field: field, locale: en)
        model.id = id
        return model
    }

    @Test func theSheetFollowsItsRowAcrossARefresh() {
        let item = ProvenanceSheetItem(id: "life.birthDate")
        #expect(item.row(in: [row("name", records: 1), row("life.birthDate", records: 3)])?.recordCount == 3)
        #expect(item.row(in: [row("name", records: 1), row("life.birthDate", records: 4)])?.recordCount == 4)
        #expect(item.row(in: [row("name", records: 1)]) == nil)
        #expect(item.row(in: [row("life.birthDate", records: 0)]) == nil)
    }

    private func record(_ id: String, rank: Int, reason: String = "kept") -> PVProvenanceSheetContent.Record {
        PVProvenanceSheetContent.Record(
            outcome: D.outcome(id, reason, rank: rank == 0 ? nil : rank, groupRank: rank),
            in: D.field("mixed"), locale: en
        )
    }

    private func record(_ id: String, citation: String, rank: Int = 1) -> PVProvenanceSheetContent.Record {
        var record = self.record(id, rank: rank)
        record.outcome.citationID = citation
        return record
    }

    /// T-4 (D-8, AC-1.1, AC-1.2).
    @Test func citationTextFallsBack() {
        var formatted = record("a", rank: 1)
        #expect(!formatted.isFormatted && formatted.citationText == formatted.citation.line)
        formatted.rendered = renderedCitation("cit-a", key: "full:x", full: "Rendered, 1880")
        #expect(formatted.isFormatted && formatted.citationText == "Rendered, 1880")
        #expect(formatted.spoken.contains("Rendered, 1880") && !formatted.spoken.contains(formatted.citation.line))
        formatted.rendered = renderedCitation("cit-a", key: "citation:cit-a", full: "")
        #expect(!formatted.isFormatted && formatted.citationText == formatted.citation.line)
        #expect(formatted.spoken.contains(formatted.citation.line))
    }

    private func content(_ runs: [[PVProvenanceSheetContent.Record]]) -> PVProvenanceSheetContent {
        let groups = runs.enumerated().map { index, records in
            PVProvenanceSheetContent.Group.ValueGroup(
                heading: .value(.init(rank: index + 1, text: "v\(index)", support: "")), records: records)
        }
        return PVProvenanceSheetContent(
            title: "T", shown: .init(face: .text, lead: "x", emptyText: "", badge: nil), summary: nil,
            groups: [PVProvenanceSheetContent.Group(owner: nil, values: groups)])
    }

    private func runKeys(_ content: PVProvenanceSheetContent) -> [[[String]]] {
        content.groups[0].values.map { $0.citations.map { $0.records.map(\.id) } }
    }

    /// T-5 (D-7, AC-3.1, AC-3.2, AC-3.4).
    @Test func groupedGathersByEngineKeyWithinARun() {
        let a = record("a", citation: "ca"), b = record("b", citation: "cb"), c = record("c", citation: "cc")
        let grouped = content([[a, b, c]]).grouped(by: [
            "ca": renderedCitation("ca", key: "K"), "cb": renderedCitation("cb", key: "L"), "cc": renderedCitation("cc", key: "K"),
        ])
        #expect(runKeys(grouped) == [[["a", "c"], ["b"]]])
        #expect(grouped.records.map(\.id) == ["a", "c", "b"])
        #expect(grouped.records.allSatisfy { $0.rendered != nil })

        // The same key in two value runs stays in two runs.
        let apart = content([[a], [c]]).grouped(by: ["ca": renderedCitation("ca", key: "K"), "cc": renderedCitation("cc", key: "K")])
        #expect(runKeys(apart) == [[["a"]], [["c"]]])

        // The engine's key keeps a Citation with no format alone; two records of one share its run.
        let none1 = record("n1", citation: "c1"), none2 = record("n2", citation: "c2"), none3 = record("n3", citation: "c1")
        let alone = content([[none1, none2, none3]]).grouped(by: [
            "c1": renderedCitation("c1", key: "citation:c1", full: ""), "c2": renderedCitation("c2", key: "citation:c2", full: ""),
        ])
        #expect(runKeys(alone) == [[["n1", "n3"], ["n2"]]])

        // A record missing from the renders is its own run.
        let missing = content([[a, c]]).grouped(by: ["ca": renderedCitation("ca", key: "K")])
        #expect(runKeys(missing) == [[["a"], ["c"]]])
        #expect(missing.records.map(\.rendered) == [renderedCitation("ca", key: "K"), nil])
    }

    /// T-8 (D-9, AC-2.2, AC-2.3, AC-2.4).
    @Test func copyButtonsFollowTheRender() {
        var formatted = record("a", rank: 1)
        formatted.rendered = renderedCitation("cit-a", key: "full:x", short: "Short")
        let both = PVProvenanceRecordRow.copies(for: formatted)
        #expect(both.map(\.kind) == [.full, .short])
        #expect(both.map(\.text) == ["cit-a", "Short"])
        #expect(both.allSatisfy { $0.rich != nil })
        formatted.rendered = renderedCitation("cit-a", key: "full:x")
        #expect(PVProvenanceRecordRow.copies(for: formatted).map(\.kind) == [.full])
        formatted.rendered = renderedCitation("cit-a", key: "citation:cit-a", full: "")
        #expect(PVProvenanceRecordRow.copies(for: formatted).map(\.kind) == [.citation])
        let today = PVProvenanceRecordRow.copies(for: record("b", rank: 1))
        #expect(today.map(\.kind) == [.citation])
        #expect(today.first?.rich == nil)
    }

    /// AC-3.3: the rule before each citation run, in a group's values.
    @Test func ruleFallsBeforeEachRunButTheFirstAfterALine() {
        typealias Table = PVProvenanceRecordTable
        let a = record("a", citation: "ca"), b = record("b", citation: "cb")
        let led = Table.followsLine(hasHeading: true, valueIndex: 0, hasOwner: false)
        // A heading leads its first run: no rule before it, one before `b`; the records of a run draw none.
        #expect(led)
        #expect(!Table.drawsRule(runIndex: 0, followsLine: led))
        #expect(Table.drawsRule(runIndex: 1, followsLine: led))
        let grouped = content([[a, a, b]]).grouped(by: [
            "ca": renderedCitation("ca", key: "K"), "cb": renderedCitation("cb", key: "L"),
        ])
        #expect(runKeys(grouped) == [[["a", "a"], ["b"]]])
        // The owner line leads only the group's first value.
        #expect(Table.followsLine(hasHeading: false, valueIndex: 0, hasOwner: true))
        #expect(!Table.followsLine(hasHeading: false, valueIndex: 1, hasOwner: true))
        // No heading and no owner line: a rule falls before the first run too.
        let bare = Table.followsLine(hasHeading: false, valueIndex: 0, hasOwner: false)
        #expect(!bare && Table.drawsRule(runIndex: 0, followsLine: bare))
    }

    /// T-7 (D-11, AC-1.1).
    @Test func styledMarksItalicRuns() {
        let render = CatalogCitationRender(
            runs: [CatalogCitationRun(text: "a", italic: false), CatalogCitationRun(text: "b", italic: true)],
            plain: "ab")
        let styled = render.styled
        #expect(String(styled.characters) == "ab")
        let intent = AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.self
        let runs = Array(styled.runs)
        #expect(runs.count == 2)
        #expect(runs[0][intent] == nil)
        #expect(runs[1][intent] == .emphasized)
    }

    @Test func aFaceComesFromTheField() {
        let date = D.field("single", key: "date", label: "Birth date", valueType: "date", [D.value(1, "kept")], outcomes: [])
        let text = D.field("single", key: "name", label: "Name", valueType: "text", [D.value(1, "kept")], outcomes: [])
        #expect(PVProvenanceFace(field: date) == .date)
        #expect(PVProvenanceFace(field: text) == .text)
    }

    @Test func aRowBuildsItsContentOnCall() {
        let row = row("life.birthDate", records: 3)
        #expect(row.recordCount == 3)
        let content = row.provenanceContent()
        #expect(content.records.map(\.id) == ["life.birthDate-0", "life.birthDate-1", "life.birthDate-2"])
        #expect(content.title == "Birth date" && content.shown == row.shown)
        #expect(content.summary?.hasSuffix("3 records") == true)

        let empty = ReconciledValueRowModel.empty(id: "x", label: "X", face: .text, emptyText: "")
        #expect(empty.recordCount == 0)
        #expect(empty.provenanceContent().records.isEmpty)

        // A relabelled row and its sheet cannot disagree.
        var renamed = row
        renamed.label = "Born"
        #expect(renamed.provenanceContent().title == "Born")
    }

    @Test func aRecordComesFromOneOutcome() {
        let outcome = D.outcome("bible", "outvoted", rank: 2, source: "S1", title: "Family Bible", groupRank: 1)
        let field = D.field("merged", [
            D.value(1, "kept", support: 2, .name(D.jamesRobins)),
            D.value(2, "kept", .name(CatalogNameValue(form: "James Robbins"))),
        ], outcomes: [outcome])
        let record = PVProvenanceSheetContent.Record(outcome: outcome, in: field, locale: en)
        #expect(record.id == "bible" && record.outcome == outcome)
        #expect(record.readAs == ReconciledValueDisplay.readAs(outcome, propertyKey: field.propertyKey, locale: en, orders: NameFormatOrders()))
        #expect(record.readAsIsPhrase == ReconciledValueDisplay.readAsIsPhrase(outcome, propertyKey: field.propertyKey))
        #expect(!record.counted)
        #expect(record.phrase == ReconciledValueDisplay.outcomePhrase(outcome, in: field, locale: en))
        #expect(record.mark == ReconciledValueDisplay.outcomeMark(outcome, in: field))
        #expect(record.citation == CitationLineDisplay.parts(outcome))
        #expect(record.observationRef == "OBS-bible" && record.subjectRef == "CPR-bible")
    }

    @Test func linksReachTheirPlaces() {
        let outcome = D.outcome("bible", "kept", source: "S1", title: "Family Bible")
        let record = PVProvenanceSheetContent.Record(outcome: outcome, in: D.field("single"), locale: en)
        #expect(WorkspaceLocation.provenance(record, .source) == .sourcePage(sourceId: "S1", ref: nil, title: "Family Bible"))
        let citation = WorkspaceLocation.provenance(record, .citation)
        #expect(citation.sourceSurface == .citationComposer)
        #expect(citation.citationId == "cit-bible" && citation.observationId == nil)
        let observation = WorkspaceLocation.provenance(record, .observation)
        #expect(observation.citationId == "cit-bible" && observation.observationId == "bible")
    }

    @Test func aRecordSpeaksAsOneLine() {
        let r = record("r0", rank: 1)
        let parts = [r.readAs, r.citation.line, r.phrase, r.observationRef, r.subjectRef]
        #expect(r.spoken == parts.joined(separator: ", "))
    }

    @Test func aGalleryRecordNeedsNoField() {
        let kept = PVProvenanceSheetContent.Record(outcome: D.outcome("k", "kept", title: "Register"), in: nil, locale: en)
        #expect(ReconciledValueDisplay.counted(kept.outcome, in: nil))
        #expect(kept.counted && kept.phrase == "kept" && kept.mark == .check)
        #expect(kept.readAs.isEmpty && !kept.readAsIsPhrase)
        let expected = [kept.citation.line, kept.phrase, kept.observationRef, kept.subjectRef]
        #expect(kept.spoken == L10n.DesignSystem.spokenJoin(expected))
        #expect(kept.spoken.hasPrefix(kept.citation.line))

        let weak = PVProvenanceSheetContent.Record(
            outcome: D.outcome("w", "weak", credibilityOffset: -2), in: nil, locale: en)
        #expect(!weak.counted)
        #expect(weak.phrase == "weak · low-trust Source" && weak.mark == .signalLow)

        let against = PVProvenanceSheetContent.Record(outcome: D.outcome("a", "against"), in: nil, locale: en)
        #expect(!against.counted && against.phrase == L10n.string(L10n.Conclusions.outcomeAgainst))
    }

    @Test func valuesGroupTheirRecordsAndTheRestComeLast() {
        let field = D.field("mixed", [
            D.value(1, "kept", support: 2, .name(D.jamesRobins)),
            D.value(2, "kept", .name(CatalogNameValue(form: "James Robbins"))),
        ])
        func groups(_ ranks: [Int], in field: CatalogConclusionField) -> [PVProvenanceSheetContent.Group.ValueGroup] {
            let records = ranks.enumerated().map { record("r\($0.offset)", rank: $0.element) }
            return PVProvenanceSheetContent.valueGroups(records, field: field, locale: en, orders: NameFormatOrders())
        }

        let mixed = groups([1, 1, 2, 0], in: field)
        #expect(mixed.map(\.records.count) == [2, 1, 1])
        guard case .value(let first) = mixed[0].heading, case .value(let second) = mixed[1].heading else {
            Issue.record("expected value headings, got \(mixed.map(\.heading))")
            return
        }
        #expect(first.rank == 1 && first.support == "2 Sources")
        #expect(second.rank == 2 && second.text == "James Robbins")
        #expect(mixed[2].heading == .otherRecords)

        // A merged name: every record went into the one displayed value.
        let merged = groups([1, 1, 1], in: field)
        #expect(merged.count == 1 && merged[0].heading == nil)

        // A birth date with every record lost still says so.
        let lost = groups([0, 0], in: D.field("", key: "date", valueType: "date"))
        #expect(lost.count == 1 && lost[0].heading == .otherRecords)

        // A rank with no displayed value reads as other records.
        let orphan = groups([3, 0], in: field)
        #expect(orphan.map(\.heading) == [.otherRecords, .otherRecords])
    }

    @Test func placeOwnersEachHoldOneValueWithoutHeadings() {
        let toronto = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let yorkville = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        func owner(_ place: CatalogCanonicalEntity, _ name: String, _ id: String, link: String? = nil) -> CatalogOwnerField {
            CatalogOwnerField(
                entity: CatalogCanonicalEntity(id: link ?? "lk-\(id)", ref: "LOC-\(id)", subjectTypeID: "t", label: ""),
                event: nil, place: CatalogChainedPlace(entity: place, names: [name]),
                field: D.field(
                    "single", key: "place", label: "place", valueType: "subject", [D.value(1, "kept", .text(name))],
                    outcomes: [D.outcome(id, "kept")]
                )
            )
        }
        let row = ReconciledValueRowModel.derived(
            id: "life.deathPlace", label: "Death place", face: .place, lead: "Toronto", emptyText: "", mixed: true,
            owners: [owner(toronto, "Toronto", "t"), owner(yorkville, "Yorkville", "y")], shownOwnerID: "pl1",
            kind: .deathPlace, locale: en
        )
        #expect(row.provenanceContent().groups.count == 2)
        #expect(row.provenanceContent().groups.allSatisfy { $0.values.count == 1 && $0.values[0].heading == nil })
    }

    @Test func twoLinksToOnePlaceFormOneGroup() {
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let leeds = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        func owner(_ link: String, _ id: String, place: CatalogCanonicalEntity = york, _ name: String = "York") -> CatalogOwnerField {
            CatalogOwnerField(
                entity: CatalogCanonicalEntity(id: link, ref: "LOC-\(link)", subjectTypeID: "t", label: ""),
                event: nil, place: CatalogChainedPlace(entity: place, names: [name]),
                field: D.field(
                    "single", key: "place", label: "place", valueType: "subject", [D.value(1, "kept", .text(name))],
                    outcomes: [D.outcome(id, "kept")]
                )
            )
        }
        // York is the only Place: no group line, and the summary counts records.
        let only = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: false,
            owners: [owner("lk1", "a"), owner("lk2", "b")], shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        #expect(only.provenanceContent().groups.count == 1 && only.provenanceContent().groups[0].owner == nil)
        #expect(only.provenanceContent().groups[0].records.count == 2)
        #expect(only.provenanceContent().summary == "2 records")

        // York by two links and Leeds: one group each, York's holding both links' records in link order.
        let both = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: true,
            owners: [owner("lk1", "a"), owner("lk3", "c", place: leeds, "Leeds"), owner("lk2", "b")],
            shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        #expect(both.provenanceContent().groups.map { $0.owner?.id } == ["pl1", "pl2"])
        #expect(both.provenanceContent().groups.map { $0.owner?.title } == ["York", "Leeds"])
        #expect(both.provenanceContent().groups[0].records.map(\.id) == ["a", "b"])
        #expect(both.provenanceContent().summary == "3 records from 2 Places")
    }

    @Test func aPooledPlaceGroupHasOneHeadingPerValue() {
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let leeds = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        func owner(
            _ link: String, _ outcomes: [CatalogReconcilerOutcome],
            place: CatalogCanonicalEntity = york, _ name: String = "York"
        ) -> CatalogOwnerField {
            CatalogOwnerField(
                entity: CatalogCanonicalEntity(id: link, ref: "LOC-\(link)", subjectTypeID: "t", label: ""),
                event: nil, place: CatalogChainedPlace(entity: place, names: [name]),
                field: D.field(
                    "single", key: "place", label: "place", valueType: "subject", [D.value(1, "kept", .text(name))],
                    outcomes: outcomes
                )
            )
        }
        let row = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: true,
            owners: [
                owner("lk1", [D.outcome("a", "kept", source: "s1"), D.outcome("d", "lost", rank: nil, source: "s1")]),
                owner("lk2", [D.outcome("b", "kept", source: "s2")]),
                owner("lk3", [D.outcome("c", "kept")], place: leeds, "Leeds"),
            ],
            shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        let values = row.provenanceContent().groups[0].values
        #expect(values.map { $0.records.map(\.id) } == [["a", "b"], ["d"]])
        guard case .value(let heading)? = values[0].heading else {
            Issue.record("expected a value heading")
            return
        }
        #expect(heading.text == "York" && heading.support == L10n.Conclusions.sourceCount(2))
        #expect(values[1].heading == .otherRecords)

        // Two links whose kept records cite the same Source: one Source, not two.
        let shared = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: true,
            owners: [
                owner("lk1", [D.outcome("a", "kept", source: "s1"), D.outcome("d", "lost", rank: nil, source: "s1")]),
                owner("lk2", [D.outcome("b", "kept", source: "s1")]),
                owner("lk3", [D.outcome("c", "kept")], place: leeds, "Leeds"),
            ],
            shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        guard case .value(let sharedHeading)? = shared.provenanceContent().groups[0].values[0].heading else {
            Issue.record("expected a value heading")
            return
        }
        #expect(sharedHeading.support == L10n.Conclusions.sourceCount(1))
    }

    @Test func theSummarySaysOnlyWhatTheRowKnows() {
        let merged = D.field("merged", [
            D.value(1, "kept", support: 3, against: 1, .name(D.jamesRobins)),
        ], outcomes: (0..<4).map { D.outcome("r\($0)", "kept", source: "s\($0 % 3)") })
        #expect(ReconciledValueRowModel(field: merged, locale: en).provenanceContent().summary
            == "merged from 3 Sources · 1 record disagrees · 4 records")

        let single = D.field("single", [
            D.value(1, "kept", support: 1, .name(D.jamesRobins)),
        ], outcomes: [D.outcome("r0", "kept", source: "s0")])
        #expect(ReconciledValueRowModel(field: single, locale: en).provenanceContent().summary?.hasPrefix("from 1 Source") == true)

        let first = CatalogCanonicalEntity(id: "ev1", ref: "EVT-1", subjectTypeID: "t", label: "")
        let second = CatalogCanonicalEntity(id: "ev2", ref: "EVT-2", subjectTypeID: "t", label: "")
        func owner(_ entity: CatalogCanonicalEntity, _ ids: [String]) -> CatalogOwnerField {
            CatalogOwnerField(entity: entity, event: nil, field: D.field(
                "single", key: "date", label: "date", valueType: "date", [], outcomes: ids.map { D.outcome($0, "kept") }
            ))
        }
        let two = ReconciledValueRowModel.derived(
            id: "life.birthDate", label: "Birth date", face: .date, lead: "1822", emptyText: "", mixed: true,
            owners: [owner(first, ["a", "b", "c"]), owner(second, ["d"])], shownOwnerID: "ev1",
            kind: .birthDate, locale: en
        )
        #expect(two.provenanceContent().summary == "4 records from 2 birth events")
        let one = ReconciledValueRowModel.derived(
            id: "life.birthDate", label: "Birth date", face: .date, lead: "1822", emptyText: "", mixed: false,
            owners: [owner(first, ["a", "b"])], shownOwnerID: "ev1", kind: .birthDate, locale: en
        )
        #expect(one.provenanceContent().summary == "2 records")
        #expect(ReconciledValueRowModel.empty(id: "x", label: "X", face: .text, emptyText: "").provenanceContent().summary == nil)
    }

    // MARK: The fold (S15-27)

    private typealias Content = PVProvenanceSheetContent
    private typealias Position = PVProvenanceSheetContent.RunPosition

    private static let fold = PVProvenanceRecordTable.fold

    /// A run of `size` records.
    private func run(_ id: String, size: Int = 1) -> Content.Group.ValueGroup.CitationRun {
        .init(key: "full:\(id)", records: (0..<size).map {
            PVProvenancePreviewData.record("\(id)-\($0)", readAs: "1817", title: "T", detail: "d")
        })
    }

    private func runs(_ count: Int, prefix: String = "r", sizes: [Int: Int] = [:]) -> [Content.Group.ValueGroup.CitationRun] {
        (0..<count).map { run("\(prefix)\($0)", size: sizes[$0] ?? 1) }
    }

    private func heading(_ rank: Int) -> Content.Group.ValueGroup.Heading {
        .value(.init(rank: rank, text: "v\(rank)", support: ""))
    }

    private func owner(_ id: String) -> Content.Group.OwnerLine {
        .init(id: id, title: id, ref: nil, spoken: id)
    }

    private func single(_ citations: [Content.Group.ValueGroup.CitationRun]) -> [Content.Group] {
        [Content.Group(owner: nil, values: [.init(heading: nil, citations: citations)])]
    }

    private func runCount(_ groups: [Content.Group]) -> Int {
        groups.reduce(0) { $0 + $1.values.reduce(0) { $0 + $1.citations.count } }
    }

    /// T-1 (AC-1.1, AC-1.4, D-1, D-2).
    @Test func foldShowsFiftyRunsThenAPageAtATime() {
        let groups = single(runs(120))
        let first = Content.folded(groups, by: Self.fold, pages: 0)
        #expect(runCount(first.groups) == 50 && first.hidden == 70 && first.firstRevealed == Position(group: 0, value: 0, run: 50))
        let second = Content.folded(groups, by: Self.fold, pages: 1)
        #expect(runCount(second.groups) == 100 && second.hidden == 20 && second.firstRevealed == Position(group: 0, value: 0, run: 100))
        let third = Content.folded(groups, by: Self.fold, pages: 2)
        #expect(runCount(third.groups) == 120 && third.hidden == 0 && third.firstRevealed == nil)
        let edge = Content.folded(single(runs(51)), by: Self.fold, pages: 0)
        #expect(runCount(edge.groups) == 50 && edge.hidden == 1)
    }

    /// T-2 (AC-1.3).
    @Test func foldNeverSplitsARun() {
        let folded = Content.folded(single(runs(60, sizes: [49: 6])), by: Self.fold, pages: 0)
        #expect(runCount(folded.groups) == 50 && folded.groups[0].records.count == 55)
        #expect(folded.hidden == 10 && folded.firstRevealed == Position(group: 0, value: 0, run: 50))
    }

    /// T-3 (AC-2.1, AC-2.2).
    @Test func foldKeepsLinesOverShownRunsOnly() {
        let owners = [
            Content.Group(owner: owner("a"), values: [.init(heading: nil, citations: runs(50, prefix: "a"))]),
            Content.Group(owner: owner("b"), values: [.init(heading: nil, citations: runs(3, prefix: "b"))]),
        ]
        let cut = Content.folded(owners, by: Self.fold, pages: 0)
        #expect(cut.groups.map(\.id) == ["a"] && cut.hidden == 3 && cut.firstRevealed == Position(group: 1, value: 0, run: 0))
        #expect(Content.folded(owners, by: Self.fold, pages: 1).groups == owners)

        let values = [Content.Group(owner: nil, values: [
            .init(heading: heading(1), citations: runs(60, prefix: "p")),
            .init(heading: heading(2), citations: runs(5, prefix: "q")),
        ])]
        let first = Content.folded(values, by: Self.fold, pages: 0)
        #expect(first.groups[0].values.count == 1 && first.groups[0].values[0].heading == heading(1))
        #expect(first.groups[0].values[0].citations.count == 50)
        let second = Content.folded(values, by: Self.fold, pages: 1)
        #expect(second.groups == values)
    }

    /// T-4 (AC-1.2, AC-2.3).
    @Test func foldLeavesASmallTableWhole() {
        let small = single(runs(50))
        let whole = Content.folded(small, by: Self.fold, pages: 0)
        #expect(whole.groups == small && whole.hidden == 0 && whole.firstRevealed == nil)
        let none = Content.folded([], by: Self.fold, pages: 0)
        #expect(none.groups.isEmpty && none.hidden == 0 && none.firstRevealed == nil)

        let empty = Content.Group(owner: owner("empty"), values: [])
        let big = Content.Group(owner: owner("big"), values: [.init(heading: nil, citations: runs(60))])
        #expect(Content.folded([empty, big], by: Self.fold, pages: 0).groups.map(\.id) == ["empty", "big"])
        #expect(Content.folded([big, empty], by: Self.fold, pages: 0).groups.map(\.id) == ["big"])
        #expect(Content.folded([big, empty], by: Self.fold, pages: 1).groups.map(\.id) == ["big", "empty"])
    }

    /// T-5 (D-2, D-3).
    @Test func foldKeepsEveryShownPosition() {
        let groups = [
            Content.Group(owner: owner("a"), values: [
                .init(heading: heading(1), citations: runs(40, prefix: "a")),
                .init(heading: heading(2), citations: runs(30, prefix: "b")),
            ]),
            Content.Group(owner: owner("b"), values: [.init(heading: nil, citations: runs(35, prefix: "c"))]),
            Content.Group(owner: owner("c"), values: [
                .init(heading: heading(1), citations: runs(10, prefix: "d")),
                .init(heading: heading(3), citations: runs(15, prefix: "e")),
            ]),
        ]
        var order: [(Position, Content.Group.ValueGroup.CitationRun)] = []
        for (g, group) in groups.enumerated() {
            for (v, value) in group.values.enumerated() {
                for (r, run) in value.citations.enumerated() { order.append((Position(group: g, value: v, run: r), run)) }
            }
        }
        #expect(order.count == 130)
        for pages in 0...3 {
            let folded = Content.folded(groups, by: Self.fold, pages: pages)
            let shown = Self.fold.shownCount(count: 130, pages: pages)
            for (g, group) in folded.groups.enumerated() {
                for (v, value) in group.values.enumerated() {
                    #expect(value.heading == groups[g].values[v].heading)
                    for (r, run) in value.citations.enumerated() {
                        #expect(run == groups[g].values[v].citations[r])
                    }
                }
            }
            #expect(runCount(folded.groups) == shown)
            #expect(folded.firstRevealed == (shown < 130 ? order[shown].0 : nil))
        }
    }

    /// T-6 (D-4).
    @Test func foldClampsPastTheEnd() {
        let folded = Content.folded(single(runs(60)), by: Self.fold, pages: 9)
        #expect(runCount(folded.groups) == 60 && folded.hidden == 0 && folded.firstRevealed == nil)
    }
}
