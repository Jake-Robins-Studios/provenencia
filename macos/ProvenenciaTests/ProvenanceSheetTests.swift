import Foundation
import Testing
@testable import Provenencia

struct ProvenanceSheetTests {
    private typealias D = ReconciledValueDisplayTests
    private let en = Locale(identifier: "en_US")

    private func row(_ id: String, records: Int) -> ReconciledValueRowModel {
        let field = D.field(
            "single", key: "date", label: "Birth date", valueType: "date", [D.value(1, "kept")],
            counts: .init(records: records, sources: 1)
        )
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

    /// S15-21 T-4 (D-8, AC-1.1, AC-1.2).
    @Test func citationTextFallsBack() {
        var formatted = record("a", rank: 1)
        #expect(!formatted.isFormatted && formatted.citationText == formatted.citation.line)
        formatted.rendered = renderedCitation("cit-a", full: "Rendered, 1880")
        #expect(formatted.isFormatted && formatted.citationText == "Rendered, 1880")
        #expect(formatted.spoken.contains("Rendered, 1880") && !formatted.spoken.contains(formatted.citation.line))
        formatted.rendered = renderedCitation("cit-a", full: "")
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

    /// S15-27 T-8 (D-9, AC-4.2).
    @Test func withRendersSetsEachRecordsRender() {
        let a = record("a", citation: "ca"), b = record("b", citation: "cb"), c = record("c", citation: "cc")
        let both = content([[a, b, c]]).withRenders([
            "ca": renderedCitation("ca", full: "same"), "cc": renderedCitation("cc", full: "same"),
        ])
        #expect(both.records.map(\.id) == ["a", "b", "c"])
        #expect(both.records.map { $0.rendered?.full.plain } == ["same", nil, "same"])

        let one = content([[a, b, c]]).withRenders(["ca": renderedCitation("ca")])
        #expect(one.records.map(\.id) == ["a", "b", "c"])
        #expect(one.records.map { $0.rendered != nil } == [true, false, false])
    }

    /// S15-21 T-8 (D-9, AC-2.2, AC-2.3, AC-2.4).
    @Test func copyButtonsFollowTheRender() {
        var formatted = record("a", rank: 1)
        formatted.rendered = renderedCitation("cit-a", short: "Short")
        let both = PVProvenanceRecordRow.copies(for: formatted)
        #expect(both.map(\.kind) == [.full, .short])
        #expect(both.map(\.text) == ["cit-a", "Short"])
        #expect(both.allSatisfy { $0.rich != nil })
        formatted.rendered = renderedCitation("cit-a")
        #expect(PVProvenanceRecordRow.copies(for: formatted).map(\.kind) == [.full])
        formatted.rendered = renderedCitation("cit-a", full: "")
        #expect(PVProvenanceRecordRow.copies(for: formatted).map(\.kind) == [.citation])
        let today = PVProvenanceRecordRow.copies(for: record("b", rank: 1))
        #expect(today.map(\.kind) == [.citation])
        #expect(today.first?.rich == nil)
    }

    /// S15-27 T-9 (AC-4.1, D-1): the rule before each record, in a group's values.
    @Test func ruleFallsBeforeEachRecordButTheFirstAfterALine() {
        typealias Table = PVProvenanceRecordTable
        let led = Table.followsLine(hasHeading: true, valueIndex: 0, hasOwner: false)
        // A heading leads its first record: no rule before it, one before each later record.
        #expect(led)
        #expect(!Table.drawsRule(recordIndex: 0, followsLine: led))
        #expect(Table.drawsRule(recordIndex: 1, followsLine: led))
        #expect(Table.drawsRule(recordIndex: 2, followsLine: led))
        // The owner line leads only the group's first value.
        #expect(Table.followsLine(hasHeading: false, valueIndex: 0, hasOwner: true))
        #expect(!Table.followsLine(hasHeading: false, valueIndex: 1, hasOwner: true))
        // No heading and no owner line: a rule falls before the first record too.
        let bare = Table.followsLine(hasHeading: false, valueIndex: 0, hasOwner: false)
        #expect(!bare && Table.drawsRule(recordIndex: 0, followsLine: bare))
    }

    /// S15-21 T-7 (D-11, AC-1.1).
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

    @Test func aRowCountsFromTheEngine() {
        let row = row("life.birthDate", records: 3)
        #expect(row.recordCount == 3 && row.hasRecords)
        let empty = ReconciledValueRowModel.empty(id: "x", label: "X", face: .text, emptyText: "")
        #expect(empty.recordCount == 0 && !empty.hasRecords)
        // A life row sums its owners' counts.
        let owners = [3, 1].enumerated().map { index, records in
            CatalogOwnerField(
                entity: CatalogCanonicalEntity(id: "ev\(index)", ref: "EVT-\(index)", subjectTypeID: "t", label: ""),
                field: D.field("single", key: "date", valueType: "date", [], counts: .init(records: records, sources: 1))
            )
        }
        let life = ReconciledValueRowModel.derived(
            id: "life.birthDate", label: "Birth date", face: .date, lead: "1822", emptyText: "", mixed: true,
            owners: owners, shownOwnerID: "ev0", kind: .birthDate, locale: en
        )
        #expect(life.recordCount == 4 && life.hasRecords)
    }

    private func ownerOf(
        _ link: String, _ outcomes: [CatalogReconcilerOutcome], place: CatalogCanonicalEntity,
        _ name: String = "York", pooledSupport: Int = 0, counts: Bool = true
    ) -> CatalogOwnerField {
        CatalogOwnerField(
            entity: CatalogCanonicalEntity(id: link, ref: "LOC-\(link)", subjectTypeID: "t", label: ""),
            event: nil, place: CatalogChainedPlace(entity: place, names: [name]),
            field: D.field(
                "single", key: "place", label: "place", valueType: "subject",
                [D.value(1, "kept", pooledSupport: pooledSupport, .text(name))],
                outcomes: outcomes, counts: counts ? .init(records: outcomes.count, sources: 1) : .init()
            )
        )
    }

    /// AC-2.1 – AC-2.3 (D-1).
    @Test func aRowAsksForItsOwnRecords() {
        let name = D.field("single", [D.value(1, "kept")], counts: .init(records: 1, sources: 1))
        #expect(ReconciledValueRowModel(field: name, locale: en).provenanceRequest(entityID: "P")
            == .fields([CatalogProvenancePair(ownerID: "P", propertyID: "p-name")]))
        let start = D.field("single", key: "start_date", valueType: "date", [], counts: .init(records: 1, sources: 1))
        let end = D.field("single", key: "end_date", valueType: "date", [], counts: .init(records: 0, sources: 0))
        let period = ReconciledValueRowModel.spanning(
            id: "period", label: "Period", lead: "1800 – 1850", emptyText: "", fields: [start, end], locale: en
        )
        #expect(period.provenanceRequest(entityID: "L") == .fields([
            CatalogProvenancePair(ownerID: "L", propertyID: "p-start_date"),
            CatalogProvenancePair(ownerID: "L", propertyID: "p-end_date"),
        ]))
        let birthPlace = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: false,
            owners: [ownerOf("lk1", [D.outcome("a", "kept")], place: CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: ""))],
            shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        #expect(birthPlace.provenanceRequest(entityID: "P") == .derived(personID: "P", kind: .birthPlace))
        // An Event's place row has no kind to ask with; an empty row has no records.
        let placeRow = ReconciledValueRowModel.derived(
            id: "place", label: "Place", face: .place, lead: "York", emptyText: "", mixed: false,
            owners: [ownerOf("lk1", [D.outcome("a", "kept")], place: CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: ""))],
            shownOwnerID: "pl1", locale: en
        )
        #expect(placeRow.provenanceRequest(entityID: "E") == nil)
        #expect(ReconciledValueRowModel.empty(id: "x", label: "X", face: .text, emptyText: "").provenanceRequest(entityID: "E") == nil)
    }

    /// AC-2.4, AC-2.5 (D-5, D-6, D-9).
    @Test func contentTakesRecordsFromTheRead() {
        let page = D.mergedName
        let row = ReconciledValueRowModel(field: page, locale: en)
        let before = row.provenanceContent(records: [])
        #expect(before.groups.isEmpty && before.records.isEmpty)
        #expect(before.summary == "merged from 2 Sources · 4 records")
        #expect(before.title == "Name" && before.shown == row.shown)
        var renamed = row
        renamed.label = "Born"
        #expect(renamed.provenanceContent(records: []).title == "Born")

        let read = CatalogOwnerField(
            entity: CatalogCanonicalEntity(id: "P", ref: "PER-1", subjectTypeID: "t", label: ""), field: page
        )
        let after = row.provenanceContent(records: [read])
        #expect(after.records.count == 4 && after.summary == before.summary)
        // A field the read left out has no records; the owner holds no other field's.
        let other = CatalogOwnerField(
            entity: read.entity, field: D.field("single", key: "sex_at_birth", [D.value(1, "kept")], counts: .init(records: 1, sources: 1))
        )
        #expect(row.provenanceContent(records: [other]).records.isEmpty)

        // A Period whose read lacks end_date shows start_date's records only.
        let start = D.field("single", key: "start_date", valueType: "date", [D.value(1, "kept")],
                            outcomes: [D.outcome("s", "kept")], counts: .init(records: 1, sources: 1))
        let end = D.field("single", key: "end_date", valueType: "date", [], counts: .init(records: 0, sources: 0))
        let period = ReconciledValueRowModel.spanning(id: "p", label: "Period", lead: "1800", emptyText: "", fields: [start, end], locale: en)
        let periodRead = [CatalogOwnerField(entity: read.entity, field: start)]
        #expect(period.provenanceContent(records: periodRead).records.map(\.id) == ["s"])
        #expect(period.provenanceContent(records: []).records.isEmpty)
        #expect(period.provenanceContent(records: []).summary == "1 record")
    }

    @Test func aLifeRowGroupsTheReadsOwnersShownFirst() {
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let leeds = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        let pageOwners = [
            ownerOf("lk1", [D.outcome("a", "kept")], place: york),
            ownerOf("lk2", [D.outcome("c", "kept")], place: leeds, "Leeds"),
        ]
        let row = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: true,
            owners: pageOwners, shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        // The read's owners come in another order; the shown owner leads, two links to one Place pool.
        let read = [
            ownerOf("lk2", [D.outcome("c", "kept")], place: leeds, "Leeds"),
            ownerOf("lk1", [D.outcome("a", "kept")], place: york),
            ownerOf("lk3", [D.outcome("b", "kept")], place: york),
        ]
        let content = row.provenanceContent(records: read)
        #expect(content.groups.map { $0.owner?.id } == ["pl1", "pl2"])
        #expect(content.groups[0].records.map(\.id) == ["a", "b"])
        #expect(content.summary == "2 records from 2 Places")
        #expect(PVProvenanceSheetContent.ownerGroups(read, shownOwnerID: "pl1").map { $0.map(\.entity.id) } == [["lk1", "lk3"], ["lk2"]])
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
        #expect(record.mark == ReconciledValueDisplay.outcomeMark(outcome))
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
        #expect(ReconciledValueDisplay.counted(kept.outcome))
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
        let owners = [
            ownerOf("lk-t", [D.outcome("t", "kept")], place: toronto, "Toronto"),
            ownerOf("lk-y", [D.outcome("y", "kept")], place: yorkville, "Yorkville"),
        ]
        let row = ReconciledValueRowModel.derived(
            id: "life.deathPlace", label: "Death place", face: .place, lead: "Toronto", emptyText: "", mixed: true,
            owners: owners, shownOwnerID: "pl1", kind: .deathPlace, locale: en
        )
        let content = row.provenanceContent(records: owners)
        #expect(content.groups.count == 2)
        #expect(content.groups.allSatisfy { $0.values.count == 1 && $0.values[0].heading == nil })
    }

    @Test func twoLinksToOnePlaceFormOneGroup() {
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let leeds = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        // York is the only Place: no group line, and the summary counts records.
        let onlyOwners = [ownerOf("lk1", [D.outcome("a", "kept")], place: york), ownerOf("lk2", [D.outcome("b", "kept")], place: york)]
        let only = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: false,
            owners: onlyOwners, shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        let onlyContent = only.provenanceContent(records: onlyOwners)
        #expect(onlyContent.groups.count == 1 && onlyContent.groups[0].owner == nil)
        #expect(onlyContent.groups[0].records.count == 2)
        #expect(onlyContent.summary == "2 records")

        // York by two links and Leeds: one group each, York's holding both links' records in link order.
        let bothOwners = [
            ownerOf("lk1", [D.outcome("a", "kept")], place: york),
            ownerOf("lk3", [D.outcome("c", "kept")], place: leeds, "Leeds"),
            ownerOf("lk2", [D.outcome("b", "kept")], place: york),
        ]
        let both = ReconciledValueRowModel.derived(
            id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: true,
            owners: bothOwners, shownOwnerID: "pl1", kind: .birthPlace, locale: en
        )
        let content = both.provenanceContent(records: bothOwners)
        #expect(content.groups.map { $0.owner?.id } == ["pl1", "pl2"])
        #expect(content.groups.map { $0.owner?.title } == ["York", "Leeds"])
        #expect(content.groups[0].records.map(\.id) == ["a", "b"])
        #expect(content.summary == "3 records from 2 Places")
    }

    /// AC-3.5 (D-8): the pooled heading counts what Go sent for the value.
    @Test func aPooledPlaceGroupHasOneHeadingPerValue() {
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let leeds = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        func row(pooled: Int) -> PVProvenanceSheetContent {
            let owners = [
                ownerOf("lk1", [D.outcome("a", "kept", source: "s1"), D.outcome("d", "lost", rank: nil, source: "s1")], place: york, pooledSupport: pooled),
                ownerOf("lk2", [D.outcome("b", "kept", source: "s2")], place: york, pooledSupport: pooled),
                ownerOf("lk3", [D.outcome("c", "kept")], place: leeds, "Leeds", pooledSupport: 1),
            ]
            let model = ReconciledValueRowModel.derived(
                id: "life.birthPlace", label: "Birth place", face: .place, lead: "York", emptyText: "", mixed: true,
                owners: owners, shownOwnerID: "pl1", kind: .birthPlace, locale: en
            )
            return model.provenanceContent(records: owners)
        }
        let values = row(pooled: 2).groups[0].values
        #expect(values.map { $0.records.map(\.id) } == [["a", "b"], ["d"]])
        guard case .value(let heading)? = values[0].heading else {
            Issue.record("expected a value heading")
            return
        }
        #expect(heading.text == "York" && heading.support == L10n.Conclusions.sourceCount(2))
        #expect(values[1].heading == .otherRecords)

        guard case .value(let sharedHeading)? = row(pooled: 1).groups[0].values[0].heading else {
            Issue.record("expected a value heading")
            return
        }
        #expect(sharedHeading.support == L10n.Conclusions.sourceCount(1))
    }

    @Test func theSummarySaysOnlyWhatTheRowKnows() {
        let merged = D.field("merged", [
            D.value(1, "kept", support: 3, against: 1, .name(D.jamesRobins)),
        ], counts: .init(records: 4, sources: 3))
        #expect(ReconciledValueRowModel(field: merged, locale: en).provenanceContent(records: []).summary
            == "merged from 3 Sources · 1 record disagrees · 4 records")

        let single = D.field("single", [
            D.value(1, "kept", support: 1, .name(D.jamesRobins)),
        ], counts: .init(records: 1, sources: 1))
        #expect(ReconciledValueRowModel(field: single, locale: en).provenanceContent(records: []).summary?.hasPrefix("from 1 Source") == true)

        let first = CatalogCanonicalEntity(id: "ev1", ref: "EVT-1", subjectTypeID: "t", label: "")
        let second = CatalogCanonicalEntity(id: "ev2", ref: "EVT-2", subjectTypeID: "t", label: "")
        func owner(_ entity: CatalogCanonicalEntity, records: Int) -> CatalogOwnerField {
            CatalogOwnerField(entity: entity, event: nil, field: D.field(
                "single", key: "date", label: "date", valueType: "date", [], counts: .init(records: records, sources: 1)
            ))
        }
        let two = ReconciledValueRowModel.derived(
            id: "life.birthDate", label: "Birth date", face: .date, lead: "1822", emptyText: "", mixed: true,
            owners: [owner(first, records: 3), owner(second, records: 1)], shownOwnerID: "ev1",
            kind: .birthDate, locale: en
        )
        #expect(two.provenanceContent(records: []).summary == "4 records from 2 birth events")
        let one = ReconciledValueRowModel.derived(
            id: "life.birthDate", label: "Birth date", face: .date, lead: "1822", emptyText: "", mixed: false,
            owners: [owner(first, records: 2)], shownOwnerID: "ev1", kind: .birthDate, locale: en
        )
        #expect(one.provenanceContent(records: []).summary == "2 records")
        #expect(ReconciledValueRowModel.empty(id: "x", label: "X", face: .text, emptyText: "").provenanceContent(records: []).summary == nil)
    }

    @Test func theLoadAreaNamesRecords() {
        #expect(L10n.string(L10n.ProvenanceSheet.recordsLoading) == "Loading records")
        #expect(L10n.string(L10n.ProvenanceSheet.recordsFailedTitle) == "Records could not be read")
    }

    // MARK: The fold (S15-27)

    private typealias Content = PVProvenanceSheetContent
    private typealias Position = PVProvenanceSheetContent.RecordPosition

    private static let fold = PVProvenanceRecordTable.fold

    private func heading(_ rank: Int) -> Content.Group.ValueGroup.Heading {
        .value(.init(rank: rank, text: "v\(rank)", support: ""))
    }

    private func owner(_ id: String) -> Content.Group.OwnerLine {
        .init(id: id, title: id, ref: nil, spoken: id)
    }

    private func single(_ records: [Content.Record]) -> [Content.Group] {
        [Content.Group(owner: nil, values: [.init(heading: nil, records: records)])]
    }

    private func recordCount(_ groups: [Content.Group]) -> Int {
        groups.reduce(0) { $0 + $1.records.count }
    }

    private func records(_ count: Int, prefix: String = "r") -> [Content.Record] {
        PVProvenancePreviewData.records(count, prefix: prefix)
    }

    /// S15-27 T-1 (AC-1.1, AC-1.3, AC-1.4, D-4).
    @Test func foldShowsFiftyRecordsThenAPageAtATime() {
        let groups = single(records(120))
        let first = Content.folded(groups, by: Self.fold, pages: 0)
        #expect(recordCount(first.groups) == 50 && first.hidden == 70 && first.firstRevealed == Position(group: 0, value: 0, record: 50))
        let second = Content.folded(groups, by: Self.fold, pages: 1)
        #expect(recordCount(second.groups) == 100 && second.hidden == 20 && second.firstRevealed == Position(group: 0, value: 0, record: 100))
        let third = Content.folded(groups, by: Self.fold, pages: 2)
        #expect(recordCount(third.groups) == 120 && third.hidden == 0 && third.firstRevealed == nil)
        let edge = Content.folded(single(records(51)), by: Self.fold, pages: 0)
        #expect(recordCount(edge.groups) == 50 && edge.hidden == 1)

        // Records 48 - 53 repeat one citation: the cut falls between them like any others.
        var repeated = records(60)
        for index in 47..<53 { repeated[index].outcome.citationID = "same" }
        let cut = Content.folded(single(repeated), by: Self.fold, pages: 0)
        #expect(recordCount(cut.groups) == 50 && cut.hidden == 10)
        #expect(cut.groups[0].records.map(\.id).suffix(3) == ["r48", "r49", "r50"])
    }

    /// S15-27 T-3 (AC-2.1, AC-2.2).
    @Test func foldKeepsLinesOverShownRecordsOnly() {
        let owners = [
            Content.Group(owner: owner("a"), values: [.init(heading: nil, records: records(50, prefix: "a"))]),
            Content.Group(owner: owner("b"), values: [.init(heading: nil, records: records(3, prefix: "b"))]),
        ]
        let cut = Content.folded(owners, by: Self.fold, pages: 0)
        #expect(cut.groups.map(\.id) == ["a"] && cut.hidden == 3 && cut.firstRevealed == Position(group: 1, value: 0, record: 0))
        #expect(Content.folded(owners, by: Self.fold, pages: 1).groups == owners)

        let values = [Content.Group(owner: nil, values: [
            .init(heading: heading(1), records: records(60, prefix: "p")),
            .init(heading: heading(2), records: records(5, prefix: "q")),
        ])]
        let first = Content.folded(values, by: Self.fold, pages: 0)
        #expect(first.groups[0].values.count == 1 && first.groups[0].values[0].heading == heading(1))
        #expect(first.groups[0].values[0].records.count == 50)
        let second = Content.folded(values, by: Self.fold, pages: 1)
        #expect(second.groups == values)
    }

    /// S15-27 T-4 (AC-1.2, AC-2.3).
    @Test func foldLeavesASmallTableWhole() {
        let small = single(records(50))
        let whole = Content.folded(small, by: Self.fold, pages: 0)
        #expect(whole.groups == small && whole.hidden == 0 && whole.firstRevealed == nil)
        let none = Content.folded([], by: Self.fold, pages: 0)
        #expect(none.groups.isEmpty && none.hidden == 0 && none.firstRevealed == nil)

        let empty = Content.Group(owner: owner("empty"), values: [])
        let big = Content.Group(owner: owner("big"), values: [.init(heading: nil, records: records(60))])
        #expect(Content.folded([empty, big], by: Self.fold, pages: 0).groups.map(\.id) == ["empty", "big"])
        #expect(Content.folded([big, empty], by: Self.fold, pages: 0).groups.map(\.id) == ["big"])
        #expect(Content.folded([big, empty], by: Self.fold, pages: 1).groups.map(\.id) == ["big", "empty"])
    }

    /// S15-27 T-5 (D-4, D-5).
    @Test func foldKeepsEveryShownPosition() {
        let groups = [
            Content.Group(owner: owner("a"), values: [
                .init(heading: heading(1), records: records(40, prefix: "a")),
                .init(heading: heading(2), records: records(30, prefix: "b")),
            ]),
            Content.Group(owner: owner("b"), values: [.init(heading: nil, records: records(35, prefix: "c"))]),
            Content.Group(owner: owner("c"), values: [
                .init(heading: heading(1), records: records(10, prefix: "d")),
                .init(heading: heading(3), records: records(15, prefix: "e")),
            ]),
        ]
        var order: [Position] = []
        for (g, group) in groups.enumerated() {
            for (v, value) in group.values.enumerated() {
                for r in value.records.indices { order.append(Position(group: g, value: v, record: r)) }
            }
        }
        #expect(order.count == 130)
        for pages in 0...3 {
            let folded = Content.folded(groups, by: Self.fold, pages: pages)
            let shown = Self.fold.shownCount(count: 130, pages: pages)
            for (g, group) in folded.groups.enumerated() {
                #expect(group.owner == groups[g].owner)
                for (v, value) in group.values.enumerated() {
                    #expect(value.heading == groups[g].values[v].heading)
                    for (r, record) in value.records.enumerated() {
                        #expect(record == groups[g].values[v].records[r])
                    }
                }
            }
            #expect(recordCount(folded.groups) == shown)
            #expect(folded.firstRevealed == (shown < 130 ? order[shown] : nil))
        }
    }

    /// S15-27 T-6 (D-6).
    @Test func foldClampsPastTheEnd() {
        let folded = Content.folded(single(records(60)), by: Self.fold, pages: 9)
        #expect(recordCount(folded.groups) == 60 && folded.hidden == 0 && folded.firstRevealed == nil)
    }
}
