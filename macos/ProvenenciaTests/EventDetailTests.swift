import Foundation
import Testing
@testable import Provenencia

struct EventDetailTests {
    private typealias D = ReconciledValueDisplayTests
    private let en = Locale(identifier: "en_US")

    private func detail(
        label: String = "",
        ref: String = "EVT-8PL22",
        fields: [CatalogConclusionField] = [],
        members: Int = 4,
        summary: CatalogEventSummary? = nil
    ) -> CatalogConclusionDetail {
        CatalogConclusionDetail(
            entity: CatalogCanonicalEntity(id: "e1", ref: ref, subjectTypeID: "t", label: label),
            fields: fields,
            memberCount: members,
            summary: summary.map { .event($0) }
        )
    }

    private func content(_ detail: CatalogConclusionDetail) -> EventDetailContent {
        EventDetailContent(detail: detail, locale: en)
    }

    private func dateField(
        _ key: String,
        _ date: CatalogDateValueInput,
        id: String = "rec"
    ) -> CatalogConclusionField {
        D.field(
            "single", key: key, label: key, valueType: "date",
            [D.value(1, "kept", .date(date))],
            outcomes: [D.outcome(id, "kept", title: "Census", recorded: .date(date))]
        )
    }

    /// The Properties Go names behind each kind of dating (the event period registry's four keys).
    private static func property(_ key: String, _ role: CatalogEventDatingProperty.Role) -> CatalogEventDatingProperty {
        CatalogEventDatingProperty(key: key, role: role)
    }

    private let occurrence = EventDetailTests.property("date", .occurrence)
    private let startProperty = EventDetailTests.property("start_date", .start)
    private let endProperty = EventDetailTests.property("end_date", .end)
    private let asOfProperty = EventDetailTests.property("as_of", .asOf)

    /// A summary with the dating and the Properties behind it that the test states: Go chose them.
    private func dated(
        dating: CatalogEventDating = CatalogEventDating(),
        properties: [CatalogEventDatingProperty] = []
    ) -> CatalogEventSummary {
        var summary = CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: "e1", ref: "EVT-8PL22", subjectTypeID: "t", label: ""),
            title: CatalogEventTitle(rule: .ref, ref: "EVT-8PL22")
        )
        summary.dating = dating
        summary.datingProperties = properties
        return summary
    }

    private func year(_ year: Int32) -> CatalogDateValueInput {
        CatalogDateValueInput(kind: "point", startYear: year)
    }

    private func day(_ year: Int32, _ month: Int32, _ day: Int32) -> CatalogDateValueInput {
        CatalogDateValueInput(kind: "point", startYear: year, startMonth: month, startDay: day)
    }

    /// A multi-valued field of dates: each displayed value with its Source count, one record each, plus
    /// `denied` records that read as a date but went into no value.
    private func multiDateField(
        _ key: String,
        _ values: [(date: CatalogDateValueInput, support: Int)],
        denied: [CatalogDateValueInput] = []
    ) -> CatalogConclusionField {
        D.field(
            "multiple", key: key, label: key, valueType: "date",
            values.enumerated().map { D.value($0.offset + 1, "kept", support: $0.element.support, .date($0.element.date)) },
            outcomes: values.enumerated().map {
                D.outcome("\(key)-\($0.offset + 1)", "kept", rank: $0.offset + 1, title: "Census", recorded: .date($0.element.date))
            } + denied.enumerated().map {
                D.outcome("\(key)-denied-\($0.offset)", "denied", rank: nil, title: "Directory", recorded: .date($0.element))
            }
        )
    }

    private var asOfDating: (low: CatalogDateValueInput, high: CatalogDateValueInput) { (day(1990, 1, 10), day(2015, 2, 10)) }

    @Test func anAsOfEventsHeaderLineReadsItsDating() {
        var event = dated()
        event.dating = CatalogEventDating(
            kind: .asOf,
            low: CatalogDateValueInput(kind: "point", startYear: 1990, startMonth: 1, startDay: 10),
            high: CatalogDateValueInput(kind: "point", startYear: 2015, startMonth: 2, startDay: 10),
            openLow: true, openHigh: true
        )
        #expect(EventSecondaryDisplay.content(event, locale: en).date == "as of 10 Jan 1990–10 Feb 2015")
        #expect(content(detail(summary: event)).secondaryDate == "as of 10 Jan 1990–10 Feb 2015")
    }

    private func summary(_ title: CatalogEventTitle) -> CatalogEventSummary {
        CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: "e1", ref: "EVT-8PL22", subjectTypeID: "t", label: ""),
            title: title
        )
    }

    @Test func headerCountsRecords() {
        #expect(content(detail(members: 4)).members == "4 records")
        #expect(content(detail(members: 1)).members == "1 record")
    }

    @Test func titleIsTheSummaryChosenTitle() {
        let page = EventDetailContent(
            detail: detail(summary: summary(CatalogEventTitle(rule: .recordedName, recordedName: "Fire at York", ref: "EVT-8PL22"))),
            locale: en
        )
        #expect(page.title == .name("Fire at York"))
        #expect(page.showsRef)
        #expect(page.ref == "EVT-8PL22")
    }

    @Test func withNoSummaryTheTitleIsTheLabelThenTheRef() {
        // A recorded name in the detail does not choose a title; only Go's summary does.
        let named = content(detail(label: "Grandpa's fire", fields: [
            D.field("single", key: "event_name", label: "Event name", valueType: "text", [D.value(1, "kept", .text("Fire at York"))]),
        ]))
        #expect(named.title == .label("Grandpa's fire"))
    }

    @Test func refTitleHidesTheTrailingRef() {
        let page = content(detail())
        #expect(page.title == .ref("EVT-8PL22"))
        #expect(!page.showsRef)
    }

    @Test func anOccurrenceKeepsTheDateRowWhateverElseIsRecorded() {
        let point = day(1817, 5, 14)
        let dating = CatalogEventDating(kind: .occurrence, low: point)
        let page = content(detail(fields: [
            dateField("date", point, id: "point"),
            dateField("start_date", year(1849), id: "start"),
            multiDateField("as_of", [(year(1820), 1)]),
        ], summary: dated(dating: dating, properties: [occurrence])))
        #expect(page.rows.map(\.label) == ["Date", "Place"])
        #expect(page.rows[0].shown.lead == "14 May 1817")
        #expect(page.rows[0].provenanceContent().records.map(\.id) == ["point"])
        #expect(page.secondaryDate == "14 May 1817")
    }

    @Test func spanLeadWhenThereIsNoDate() {
        let start = year(1849)
        let end = year(1851)
        let page = content(detail(fields: [
            dateField("start_date", start, id: "start"),
            dateField("end_date", end, id: "end"),
        ], summary: dated(
            dating: CatalogEventDating(kind: .span, low: start, high: end), properties: [startProperty, endProperty]
        )))
        #expect(page.rows[0].shown.lead == L10n.Dates.rowSpan(start: "1849", end: "1851", locale: en))
        #expect(page.rows[0].provenanceContent().records.map(\.id) == ["start", "end"])
        #expect(page.rows[0].shown.badge == nil)
        #expect(page.secondaryDate == page.rows[0].shown.lead)
    }

    @Test func aSpanWithOneSideIsThatFieldsRow() {
        let start = year(1849)
        let page = content(detail(fields: [
            dateField("start_date", start, id: "start"),
        ], summary: dated(
            dating: CatalogEventDating(kind: .span, low: start), properties: [startProperty, endProperty]
        )))
        #expect(page.rows[0].label == "Date")
        #expect(page.rows[0].shown.lead == "1849")
        #expect(page.rows[0].provenanceContent().records.map(\.id) == ["start"])
    }

    @Test func dateRowFallsToTheSpanWhenTheDateShowsNothing() {
        let start = year(1849)
        let end = year(1851)
        let page = content(detail(fields: [
            D.field(
                "single", key: SeededPropertyKey.date, label: "Date", valueType: "date", [],
                outcomes: [D.outcome("rec", "kept", title: "Census", recorded: .date(start))]
            ),
            dateField("start_date", start, id: "start"),
            dateField("end_date", end, id: "end"),
        ], summary: dated(
            dating: CatalogEventDating(kind: .span, low: start, high: end), properties: [startProperty, endProperty]
        )))
        #expect(page.rows[0].shown.lead == L10n.Dates.rowSpan(start: "1849", end: "1851", locale: en))
        #expect(page.rows[0].provenanceContent().records.map(\.id) == ["start", "end"])
        #expect(page.rows[0].shown.lead == page.secondaryDate)
    }

    @Test func dateRowFollowsTheDatingWhenFieldsDisagree() {
        let start = year(1849)
        let end = year(1851)
        let page = content(detail(fields: [
            dateField("date", day(1817, 5, 14), id: "point"),
            dateField("start_date", start, id: "start"),
            dateField("end_date", end, id: "end"),
        ], summary: dated(
            dating: CatalogEventDating(kind: .span, low: start, high: end), properties: [startProperty, endProperty]
        )))
        #expect(page.rows[0].shown.lead == L10n.Dates.rowSpan(start: "1849", end: "1851", locale: en))
        #expect(page.rows[0].shown.lead == page.secondaryDate)
    }

    @Test func bandLineReadsTheSummary() {
        let point = day(1817, 5, 14)
        let dating = CatalogEventDating(kind: .occurrence, low: point)
        let withDate = content(detail(summary: dated(dating: dating, properties: [occurrence])))
        #expect(withDate.secondaryDate == "14 May 1817")
        #expect(withDate.secondaryDate == EventSecondaryDisplay.content(dated(dating: dating), locale: en).date)

        // A `date` field with records but no displayed value: the band shows the kept span, as the list row does.
        let start = year(1849)
        let end = year(1851)
        let span = dated(
            dating: CatalogEventDating(kind: .span, low: start, high: end), properties: [startProperty, endProperty]
        )
        let spanned = content(detail(
            fields: [D.field(
                "single", key: SeededPropertyKey.date, label: "Date", valueType: "date", [],
                outcomes: [D.outcome("rec", "kept", title: "Census", recorded: .date(start))]
            )],
            summary: span
        ))
        #expect(spanned.secondaryDate == EventSecondaryDisplay.content(span, locale: en).date)
        #expect(spanned.secondaryDate == L10n.Dates.rowSpan(start: "1849", end: "1851", locale: en))
    }

    // MARK: As-of dating

    private func asOfPage(
        fields: [CatalogConclusionField],
        dating: CatalogEventDating,
        properties: [CatalogEventDatingProperty]? = nil
    ) -> ReconciledValueRowModel {
        content(detail(fields: fields, summary: dated(dating: dating, properties: properties ?? [startProperty, asOfProperty, endProperty]))).rows[0]
    }

    private func openBoth() -> CatalogEventDating {
        CatalogEventDating(kind: .asOf, low: asOfDating.low, high: asOfDating.high, openLow: true, openHigh: true)
    }

    @Test func asOfRowListsEachAsOfEarliestFirst() {
        let row = asOfPage(
            fields: [multiDateField("as_of", [(asOfDating.low, 1), (asOfDating.high, 2)], denied: [year(1970)])],
            dating: openBoth()
        )
        #expect(row.shown.listedValues.map(\.text) == ["as of 10 Jan 1990", "as of 10 Feb 2015"])
        #expect(row.shown.listedValues.map(\.support) == ["1 Source", "2 Sources"])
        #expect(row.shown.listedValues.map(\.rank) == [1, 2])
        for line in row.shown.listedValues {
            let styled = try! #require(line.styled)
            let dateRuns = styled.runs.filter { $0.attributes[DateRowDisplay.DateRun.self] == true }
            #expect(dateRuns.count == 1)
            #expect(String(styled[dateRuns[0].range].characters) == String(line.text.dropFirst("as of ".count)))
        }
        #expect(row.shown.lead == "as of 10 Jan 1990–10 Feb 2015")
        #expect(row.shown.badge == nil && row.count == nil)
        #expect(row.provenanceContent().records.count == 3)
        #expect(row.accessibilityLabel == "Date, as of 10 Jan 1990; as of 10 Feb 2015")
        #expect(row.label == "Date")
    }

    @Test func asOfRowListsTheStartAndEndBesideItsAsOfs() {
        let ys = (y1985: year(1985), y1990: year(1990), y2015: year(2015))
        func row(
            fields: [CatalogConclusionField], dating: CatalogEventDating
        ) -> (lines: [String], records: [String], lead: String?) {
            let r = asOfPage(fields: fields, dating: dating)
            return (r.shown.listedValues.map(\.text), r.provenanceContent().records.map(\.id), r.shown.lead)
        }
        let start = dateField("start_date", ys.y1985, id: "start")
        let end = dateField("end_date", ys.y2015, id: "end")

        let fromAndTwo = row(
            fields: [start, multiDateField("as_of", [(ys.y1990, 1), (day(2015, 2, 10), 1)])],
            dating: CatalogEventDating(kind: .asOf, low: ys.y1985, high: day(2015, 2, 10), openLow: false, openHigh: true)
        )
        #expect(fromAndTwo.lines == ["from 1985", "as of 1990", "as of 10 Feb 2015"])
        #expect(fromAndTwo.records == ["start", "as_of-1", "as_of-2"])
        #expect(fromAndTwo.lead == DateRowDisplay.line(
            dating: CatalogEventDating(kind: .asOf, low: ys.y1985, high: day(2015, 2, 10), openLow: false, openHigh: true), locale: en
        ))

        let untilOnly = row(
            fields: [multiDateField("as_of", [(ys.y1990, 1)]), end],
            dating: CatalogEventDating(kind: .asOf, low: ys.y1990, high: ys.y2015, openLow: true, openHigh: false)
        )
        #expect(untilOnly.lines == ["as of 1990", "until 2015"])
        #expect(untilOnly.records == ["as_of-1", "end"])

        // An as-of before the start: lines keep the order Go sends, whatever the dates say.
        let before = row(
            fields: [start, multiDateField("as_of", [(year(1980), 1)])],
            dating: CatalogEventDating(kind: .asOf, low: year(1980), high: ys.y1985, openLow: true, openHigh: false)
        )
        #expect(before.lines == ["from 1985", "as of 1980"])

        let closed = row(
            fields: [start, multiDateField("as_of", [(ys.y1990, 1)]), end],
            dating: CatalogEventDating(kind: .asOf, low: ys.y1985, high: ys.y2015)
        )
        #expect(closed.lines == ["from 1985", "as of 1990", "until 2015"])
        #expect(closed.lead == "1985–2015")
        #expect(closed.records == ["start", "as_of-1", "end"])
    }

    @Test func anAsOfFieldThatIsNotMultipleListsItsFirstValue() {
        let two = D.field(
            "mixed", key: "as_of", label: "as_of", valueType: "date",
            [D.value(1, "kept", .date(asOfDating.low)), D.value(2, "kept", .date(asOfDating.high))],
            outcomes: [
                D.outcome("as_of-1", "kept", rank: 1, title: "Census", recorded: .date(asOfDating.low)),
                D.outcome("as_of-2", "kept", rank: 2, title: "Census", recorded: .date(asOfDating.high)),
            ]
        )
        let row = asOfPage(fields: [two], dating: openBoth())
        #expect(row.shown.listedValues.map(\.text) == ["as of 10 Jan 1990"])
    }

    @Test func asOfRowLinesHaveDistinctIDs() {
        let row = asOfPage(
            fields: [
                dateField("start_date", year(1985), id: "start"),
                multiDateField("as_of", [(year(1990), 1), (year(2015), 1)]),
            ],
            dating: CatalogEventDating(kind: .asOf, low: year(1985), high: year(2015), openLow: false, openHigh: true)
        )
        #expect(Set(row.shown.listedValues.map(\.id)).count == 3)
        #expect(row.shown.listedValues.map(\.rank) == [1, 1, 2])
    }

    @Test func asOfLinesKeepTheirQualifiers() {
        let about = CatalogDateValueInput(kind: "point", qualifier: "ABT", startYear: 1990)
        let before = CatalogDateValueInput(kind: "point", qualifier: "BEF", startYear: 2015)
        let two = asOfPage(
            fields: [multiDateField("as_of", [(about, 1), (before, 1)])],
            dating: CatalogEventDating(kind: .asOf, low: about, high: before, openLow: true, openHigh: true)
        )
        #expect(two.shown.listedValues.map(\.text) == ["as of abt 1990", "as of bef 2015"])
        let one = asOfPage(
            fields: [multiDateField("as_of", [(asOfDating.low, 1)])],
            dating: CatalogEventDating(kind: .asOf, low: asOfDating.low, openLow: true, openHigh: true)
        )
        #expect(one.shown.listedValues.map(\.text) == ["as of 10 Jan 1990"])
        #expect(one.accessibilityLabel == "Date, as of 10 Jan 1990")
    }

    @Test func undatedRowShowsTheFieldWithRecords() {
        let all = [occurrence, startProperty, endProperty, asOfProperty]
        func page(_ fields: [CatalogConclusionField]) -> ReconciledValueRowModel {
            content(detail(fields: fields, summary: dated(properties: all))).rows[0]
        }
        func unshown(_ key: String, _ id: String) -> CatalogConclusionField {
            D.field(
                "single", key: key, label: key, valueType: "date", [],
                outcomes: [D.outcome(id, "kept", title: "Census", recorded: .date(year(1849)))]
            )
        }
        let one = page([unshown("date", "d")])
        #expect(one.label == "Date" && one.shown.emptyText == "Nothing recorded")
        #expect(one.provenanceContent().records.map(\.id) == ["d"])

        let asOf = page([D.field(
            "multiple", key: "as_of", label: "As of", valueType: "date", [],
            outcomes: [D.outcome("a", "denied", rank: nil, title: "Census", recorded: .date(year(1849)))]
        )])
        #expect(asOf.label == "Date" && asOf.shown.emptyText == "Nothing recorded")
        #expect(asOf.provenanceContent().records.map(\.id) == ["a"])

        let both = page([unshown("date", "d"), unshown("start_date", "s")])
        #expect(both.shown.lead == nil && both.shown.emptyText == "No date recorded")
        #expect(both.provenanceContent().records.map(\.id) == ["d", "s"])

        let none = page([])
        #expect(none.shown.emptyText == "No date recorded" && none.provenanceContent().records.isEmpty)
    }

    @Test func aLongListFoldsTwentyThenFifty() {
        let fold = ReconciledValueRowModel.listFold
        let lines = (0..<900).map { PVProvenanceSheetContent.Value(rank: $0 + 1, text: "as of \(1100 + $0)", support: "1 Source") }
        let first = fold.shown(lines, pages: 0)
        #expect(first.shown.count == 20 && first.hidden == 880)
        #expect(fold.nextPageCount(hidden: first.hidden) == 50)
        #expect(fold.shown(lines, pages: 1).shown.count == 70)
        #expect(fold.shown(Array(lines.prefix(21)), pages: 0).shown.count == 21)
        let shown = PVProvenanceSheetContent.Shown(
            face: .date, lead: nil, listedValues: lines, emptyText: "", badge: nil
        )
        #expect(ReconciledValueRowModel.spokenValue(shown)?.split(separator: ";").count == 20)
    }

    @Test func theSpokenLabelGrowsWithEachPage() {
        func lines(_ label: String) -> Int { label.split(separator: ";").count }
        let years = (0..<900).map { (date: year(Int32(1100 + $0)), support: 1) }
        let dates = asOfPage(
            fields: [multiDateField("as_of", years)],
            dating: CatalogEventDating(kind: .asOf, low: year(1100), high: year(1999), openLow: true, openHigh: true)
        )
        #expect(lines(dates.accessibilityLabel(pages: 0)) == 20)
        #expect(lines(dates.accessibilityLabel(pages: 1)) == 70)
        #expect(dates.accessibilityLabel(pages: 0) == dates.accessibilityLabel)

        let twentyOne = asOfPage(
            fields: [multiDateField("as_of", (0..<21).map { (date: year(Int32(1100 + $0)), support: 1) })],
            dating: CatalogEventDating(kind: .asOf, low: year(1100), high: year(1120), openLow: true, openHigh: true)
        )
        #expect(lines(twentyOne.accessibilityLabel(pages: 0)) == 21)
        #expect(twentyOne.accessibilityLabel(pages: 0) == twentyOne.accessibilityLabel)
        let spanning = ReconciledValueRowModel.spanning(
            id: "s", label: "Date", lead: "1990–2015", emptyText: "No date", fields: [], locale: en
        )
        #expect(spanning.accessibilityLabel(pages: 0) == spanning.accessibilityLabel)
        let derived = ReconciledValueRowModel.derived(
            id: "d", label: "Place", face: .place, lead: "York", emptyText: "None", mixed: true
        )
        #expect(derived.accessibilityLabel(pages: 0) == derived.accessibilityLabel)
        let empty = ReconciledValueRowModel.empty(id: "e", label: "Date", face: .date, emptyText: "No date")
        #expect(empty.accessibilityLabel(pages: 0) == empty.accessibilityLabel)

        let ranks: [Int] = Array(1...25)
        let names = D.field(
            "multiple", key: "toponym", label: "Name", valueType: "text",
            ranks.map { D.value($0, "kept", .text("Name \($0)")) },
            outcomes: ranks.map { D.outcome("n\($0)", "kept", rank: $0, recorded: .text("Name \($0)")) }
        )
        let place = PlaceDetailContent.namesRow(names, locale: en)
        #expect(lines(place.accessibilityLabel(pages: 0)) == 20)
        #expect(lines(place.accessibilityLabel(pages: 1)) == 25)
        #expect(place.accessibilityLabel(pages: 0) == place.accessibilityLabel)
    }

    @Test func aMixedDerivedRowSpeaksTheSameLabelAtNoPages() {
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let toronto = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        let summary = CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: "e1", ref: "EVT-8PL22", subjectTypeID: "t", label: ""),
            eventTypeKey: "birth", eventTypeOrigin: CatalogOrigin.provenencia, eventTypeLabel: "Birth",
            subjects: [],
            places: [CatalogChainedPlace(entity: york, names: ["York"]), CatalogChainedPlace(entity: toronto, names: ["Toronto"])],
            title: CatalogEventTitle(
                rule: .subject, ref: "EVT-8PL22", typeKey: "birth", typeOrigin: CatalogOrigin.provenencia, typeLabel: "Birth",
                subjects: [], place: "York"
            )
        )
        let row = EventDetailContent(detail: detail(summary: summary), locale: en).rows[1]
        #expect(row.shown.badge == .mixed)
        #expect(row.accessibilityLabel(pages: 0) == row.accessibilityLabel)
        #expect(row.accessibilityLabel.hasSuffix(L10n.string(L10n.ProvenanceSheet.badgeMixed)))
    }

    @Test func missingDateIsAnEmptyDateRow() {
        let page = content(detail(summary: dated()))
        let date = page.rows[0]
        #expect(date.label == "Date" && date.shown.face == .date && date.shown.lead == nil)
        #expect(date.shown.emptyText == "No date recorded")
        #expect(date.provenanceContent().records.isEmpty)
        #expect(page.secondaryDate == nil)
    }

    @Test func summarySuppliesSubjectsAndPlace() {
        let james = CatalogCanonicalEntity(id: "p1", ref: "PER-1", subjectTypeID: "t", label: "")
        let york = CatalogCanonicalEntity(id: "pl1", ref: "PLC-1", subjectTypeID: "t", label: "")
        let toronto = CatalogCanonicalEntity(id: "pl2", ref: "PLC-2", subjectTypeID: "t", label: "")
        let summary = CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: "e1", ref: "EVT-8PL22", subjectTypeID: "t", label: ""),
            eventTypeKey: "birth",
            eventTypeOrigin: CatalogOrigin.provenencia,
            eventTypeLabel: "Birth",
            subjects: [
                CatalogEventSubject(
                    entity: james,
                    name: CatalogNameValue(form: "James Robins"),
                    nameValueCount: 1
                ),
            ],
            places: [
                CatalogChainedPlace(entity: york, names: ["York"]),
                CatalogChainedPlace(entity: toronto, names: ["Toronto"]),
            ],
            title: CatalogEventTitle(
                rule: .subject, ref: "EVT-8PL22", typeKey: "birth", typeOrigin: CatalogOrigin.provenencia, typeLabel: "Birth",
                subjects: [CatalogNameValue(form: "James Robins")], place: "York"
            )
        )
        let page = EventDetailContent(detail: detail(summary: summary), locale: en)
        #expect(page.title == .name(L10n.EventTitle.ofOne(type: "Birth", subject: "James Robins", locale: en)))
        #expect(page.secondaryPlace == "York")
        #expect(page.rows[1].shown.lead == "York" && page.rows[1].shown.badge == .mixed && page.rows[1].provenanceContent().records.isEmpty)
        #expect(!page.rows[1].hasRecords && page.rows[1].recordCount == 0)
        #expect(!page.rows[1].shown.lead!.contains(","))
        #expect(page.rows[1].opens?.location == .placeDetail(entityId: "pl1", ref: "PLC-1", title: "York"))
    }

    @Test func placeRowIsEmpty() {
        let page = content(detail(fields: [
            dateField("date", CatalogDateValueInput(kind: "point", startYear: 1810), id: "d"),
        ]))
        let place = page.rows[1]
        #expect(place.label == "Place" && place.shown.face == .place && place.shown.lead == nil)
        #expect(place.shown.emptyText == "No place recorded")
        #expect(place.provenanceContent().records.isEmpty)
        #expect(!place.hasRecords && place.recordCount == 0)
    }

    @Test func noPictureLeavesTheMarkAndNoGallery() {
        let page = content(detail())
        #expect(page.gallery.tiles.isEmpty)
        #expect(!page.gallery.offersEarliest)
        #expect(page.thumbnail == .init(mark: .subjectEvent, label: L10n.Conclusions.eventNoImage))
    }

    @Test func aSinglePictureLeadsTheHeaderWithoutAMenu() {
        var source = detail()
        source.pictures = [D.picture("a", path: "objects/ab/cd.png", title: "Wedding photograph", leads: true)]
        let page = content(source)
        #expect(page.thumbnail.imageRelPath == "objects/ab/cd.png")
        #expect(page.thumbnail.mark == .subjectEvent)
        #expect(page.thumbnail.label == L10n.Conclusions.eventPictureThumb)
        #expect(page.thumbnail.imageLabel == "Picture from Wedding photograph")
        #expect(!page.gallery.offersEarliest)
    }

    @Test func aChosenLaterPictureOffersTheEarliest() {
        var source = detail()
        source.pictures = [
            D.picture("a", path: "objects/ab/cd.png", title: "Wedding photograph", leads: false),
            D.picture("b", path: "objects/ef/01.png", title: "Family album", leads: true),
        ]
        let gallery = content(source).gallery
        #expect(gallery.title == L10n.Conclusions.picturesSection)
        #expect(gallery.countLabel == "2 pictures")
        #expect(gallery.tiles.map(\.id) == ["a", "b"])
        #expect(gallery.tiles.map(\.isLead) == [false, true])
        #expect(gallery.offersEarliest)
        #expect(gallery.choose == .eventThumbnail)
        #expect(gallery.tiles[0].useAsLabel == "Use the picture from Wedding photograph as thumbnail")
        #expect(gallery.tiles[1].useAsLabel == "Use the picture from Family album as thumbnail")
        #expect(gallery.tiles[1].chosenToastBody == "Using the picture from Family album as the thumbnail.")
        #expect(gallery.tiles[0].accessibilityLabel == "Picture from Wedding photograph")
        #expect(gallery.tiles[1].accessibilityLabel == "Picture from Family album, thumbnail")
    }

    @Test func twoTilesSharingAPathNameTheLeadingSource() {
        var source = detail()
        source.pictures = [
            D.picture("a", path: "objects/ab/cd.png", title: "First copy", leads: false),
            D.picture("b", path: "objects/ab/cd.png", title: "Second copy", leads: true),
        ]
        let page = content(source)
        #expect(page.thumbnail.imageLabel == "Picture from Second copy")
        #expect(page.gallery.offersEarliest)
    }
}
