import SwiftUI

/// How a value reads: names, text and terms in the body face, dates in mono,
/// places in italic. One type for the Vitals row, the provenance sheet and the
/// Why (S13-36 D-6).
enum PVProvenanceFace: Equatable {
    /// Names, text, terms, integers.
    case text
    /// Mono, like every date in the app.
    case date
    /// Italic, like every place.
    case place

    /// The face of a reconciled field's values: dates in mono, everything else text.
    init(field: CatalogConclusionField) {
        self = field.valueType == .date ? .date : .text
    }

    /// The face of a displayed value.
    var valueFont: Font {
        switch self {
        case .text: PVFont.body(size: PVTypeScale.body)
        case .date: PVFont.mono(size: 15)
        case .place: PVFont.body(size: PVTypeScale.body, italic: true)
        }
    }

    /// The face of a record's "Read as" cell: a phrase ("not …", "—") is italic.
    func readAsFont(isPhrase: Bool) -> Font {
        if isPhrase {
            return PVFont.body(size: PVTypeScale.bodySmall, italic: true)
        }
        switch self {
        case .text: return PVFont.body(size: PVTypeScale.bodySmall)
        case .date: return PVFont.mono(size: PVTypeScale.caption)
        case .place: return PVFont.body(size: PVTypeScale.bodySmall, italic: true)
        }
    }
}

/// What a record's link opens: its Source, its Citation, or its Observation.
/// The recipe names no place; the caller maps a link to one.
enum PVProvenanceLink: Equatable {
    case source
    case citation
    case observation
}

/// What a provenance sheet says: a value, the records behind it, and how they
/// group. Pure; built from the wire records by the assembler below, so a caller
/// holds the wire records and asks for a sheet when one opens (S13-36).
///
/// No view code goes in an extension of this type: its nested `Group` shadows
/// SwiftUI's.
struct PVProvenanceSheetContent: Equatable {
    /// A displayed value as a line: its text and its Source count. `styled` is the text with its
    /// date's own run marked (`DateRowDisplay.DateRun`), set for a date line worded by its role.
    /// `rank` is the wire's; lines from several fields share ranks, so `id` adds the Property.
    struct Value: Equatable, Identifiable {
        var rank: Int
        var text: String
        var support: String
        var styled: AttributedString? = nil
        var propertyKey: String = ""
        var id: String { "\(propertyKey)#\(rank)" }
    }

    /// One record in a field's provenance: what it was read as, its Source, and
    /// what the auto-reconciler did with it.
    struct Record: Equatable, Identifiable {
        var id: String
        var readAs: String
        /// "not …" or "—": set as a phrase, not in the value's face.
        var readAsIsPhrase: Bool
        /// Went into the shown value (primary ink); the rest are secondary.
        var counted: Bool
        var phrase: String
        var mark: PVSymbol
        var observationRef: String
        var subjectRef: String
        /// The wire record the rest is read from.
        var outcome: CatalogReconcilerOutcome
        /// "Source, Artifact, Citation, page" (`CitationLineDisplay`).
        var citation: CitationLineDisplay.Parts
        /// The engine's render of the record's Citation; nil until the sheet's renders arrive, and
        /// for a Citation missing from them.
        var rendered: CatalogRenderedCitation? = nil

        /// The record's citation has a full format, so the row shows its render.
        var isFormatted: Bool { rendered?.full.runs.isEmpty == false }

        /// The citation as plain text: the full render when formatted, else today's line.
        var citationText: String {
            isFormatted ? rendered?.full.plain ?? citation.line : citation.line
        }

        /// The record as one VoiceOver line: what it was read as, its citation
        /// text, the outcome, then its Observation and Subject refs. The links
        /// follow as separate controls.
        var spoken: String {
            // A record with no field (a likeness) has no Read as to speak.
            L10n.DesignSystem.spokenJoin([readAs, citationText, phrase, observationRef, subjectRef]) ?? ""
        }
    }

    /// The records of one owning entity in a derived row. `owner` is nil for a
    /// row with one owner, which needs no group line.
    struct Group: Equatable, Identifiable {
        /// A group line: the owning entity as its list titles it.
        struct OwnerLine: Equatable {
            /// The owner's entity id.
            var id: String
            var title: String
            /// The owner's ref; nil when the title is the ref.
            var ref: String?
            var spoken: String
            /// The owner behind the row's shown value, when the row has several groups.
            var isShownOwner = false
        }

        /// The records of one run of the group that count under the same
        /// displayed value, in the order Go sent them.
        struct ValueGroup: Equatable {
            enum Heading: Equatable {
                /// The displayed value the records went into.
                case value(Value)
                /// Records that count under no displayed value.
                case otherRecords
            }

            /// Records whose full citations read the same, adjacent in a value run. `key` is the
            /// engine's group key, else `record:<id>` for a record with no render.
            struct CitationRun: Equatable {
                var key: String
                var records: [Record]
            }

            var heading: Heading?
            var citations: [CitationRun]
            /// Every record of the run, in order.
            var records: [Record] { citations.flatMap(\.records) }

            init(heading: Heading?, citations: [CitationRun]) {
                self.heading = heading
                self.citations = citations
            }

            /// A run whose records each stand alone, until `grouped(by:)` gathers them.
            init(heading: Heading?, records: [Record]) {
                self.init(heading: heading, citations: records.map { .init(key: "record:\($0.id)", records: [$0]) })
            }
        }

        var owner: OwnerLine?
        /// The group's records in runs by value. One run with no heading unless
        /// the group needs headings.
        var values: [ValueGroup]
        /// Every record of the group, in order.
        var records: [Record] { values.flatMap(\.records) }

        var id: String { owner?.id ?? "" }

        init(owner: OwnerLine?, values: [ValueGroup]) {
            self.owner = owner
            self.values = values
        }

        /// A group whose records form one run with no heading.
        init(owner: OwnerLine?, records: [Record]) {
            self.init(owner: owner, values: records.isEmpty ? [] : [ValueGroup(heading: nil, records: records)])
        }
    }

    /// What a value line shows: the lead, every kept value of a multi-valued
    /// field, else the field's empty text in italic, and the state. The one
    /// derivation of it, for the Vitals row and the sheet header alike.
    struct Shown: Equatable {
        var face: PVProvenanceFace
        /// The lead value; nil when the field is empty.
        var lead: String?
        /// Every displayed value when the field keeps several (`multiple`). Empty
        /// otherwise, including a mixed field, which still discloses the rest.
        var listedValues: [Value]
        var emptyText: String
        var badge: ReconciledValueDisplay.StateBadge?
    }

    var title: String
    var shown: Shown
    /// What the content knows about the records behind it. Nil when there is nothing to say.
    var summary: String?
    var groups: [Group]

    /// Every record, in order.
    var records: [Record] { groups.flatMap(\.records) }

    /// A citation run's place in the whole table: its owner group, value run and run indices.
    struct RunPosition: Hashable {
        var group: Int
        var value: Int
        var run: Int
    }

    /// The groups a fold keeps, how many runs it hides, and the first hidden run.
    struct Folded: Equatable {
        var groups: [Group]
        var hidden: Int
        /// The first run the next page adds; nil when nothing is hidden.
        var firstRevealed: RunPosition?
    }

    /// The first citation runs of `groups` in table order (groups, then value runs, then runs),
    /// as many as `fold` shows after `pages` pages, never splitting a run. A group or value run is
    /// kept when it holds a kept run, or holds no runs and no run before it is hidden; a kept value
    /// run keeps its heading and a kept group its owner line. Positions are those of the whole
    /// table, so a kept run has the same indices as in `groups`.
    nonisolated static func folded(_ groups: [Group], by fold: PagedFold, pages: Int) -> Folded {
        let total = groups.reduce(0) { $0 + $1.values.reduce(0) { $0 + $1.citations.count } }
        let shown = fold.shownCount(count: total, pages: pages)
        var seen = 0
        var firstRevealed: RunPosition?
        var kept: [Group] = []
        for (groupIndex, group) in groups.enumerated() {
            var values: [Group.ValueGroup] = []
            for (valueIndex, value) in group.values.enumerated() {
                let before = seen
                if firstRevealed == nil, shown < before + value.citations.count {
                    firstRevealed = RunPosition(group: groupIndex, value: valueIndex, run: max(shown - before, 0))
                }
                seen += value.citations.count
                if value.citations.isEmpty ? before <= shown : before < shown {
                    var keptValue = value
                    keptValue.citations = Array(value.citations.prefix(max(shown - before, 0)))
                    values.append(keptValue)
                }
            }
            if group.values.isEmpty ? seen <= shown : !values.isEmpty {
                var keptGroup = group
                keptGroup.values = values
                kept.append(keptGroup)
            }
        }
        return Folded(groups: kept, hidden: total - shown, firstRevealed: firstRevealed)
    }

    /// The content with each record's render set and, inside each value run, the records whose
    /// Citations share the engine's group key gathered together in first-appearance order. A
    /// run never crosses a value heading or owner group. A record with no render is its own run.
    func grouped(by renders: [String: CatalogRenderedCitation]) -> PVProvenanceSheetContent {
        var content = self
        for g in content.groups.indices {
            for v in content.groups[g].values.indices {
                var runs: [Group.ValueGroup.CitationRun] = []
                var position: [String: Int] = [:]
                for var record in content.groups[g].values[v].records {
                    record.rendered = renders[record.outcome.citationID]
                    let key = record.rendered?.groupKey ?? "record:\(record.id)"
                    if let at = position[key] {
                        runs[at].records.append(record)
                    } else {
                        position[key] = runs.count
                        runs.append(.init(key: key, records: [record]))
                    }
                }
                content.groups[g].values[v].citations = runs
            }
        }
        return content
    }
}

// MARK: - Assembler

extension PVProvenanceSheetContent.Record {
    /// A record read from its field. A record with no field (a likeness: a depiction Property has
    /// none) passes nil: nothing is denied, and it reads no value, so `readAs` is "".
    init(
        outcome: CatalogReconcilerOutcome,
        in field: CatalogConclusionField?,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) {
        let citation = CitationLineDisplay.parts(outcome)
        self.init(
            id: outcome.observationID,
            readAs: field.map {
                ReconciledValueDisplay.readAs(outcome, propertyKey: $0.propertyKey, locale: locale, orders: orders)
            } ?? "",
            readAsIsPhrase: field.map {
                ReconciledValueDisplay.readAsIsPhrase(outcome, propertyKey: $0.propertyKey)
            } ?? false,
            counted: ReconciledValueDisplay.counted(outcome, in: field),
            phrase: ReconciledValueDisplay.outcomePhrase(outcome, in: field, locale: locale),
            mark: ReconciledValueDisplay.outcomeMark(outcome, in: field),
            observationRef: outcome.observationRef,
            subjectRef: outcome.subjectRef,
            outcome: outcome,
            citation: citation
        )
    }
}

extension PVProvenanceSheetContent.Shown {
    /// A shown value with no listed values; an empty lead reads as none.
    init(face: PVProvenanceFace, lead: String?, emptyText: String, badge: ReconciledValueDisplay.StateBadge?) {
        self.init(
            face: face, lead: lead.flatMap { $0.isEmpty ? nil : $0 }, listedValues: [],
            emptyText: emptyText, badge: badge
        )
    }

    /// What one reconciled field shows. A weak spelling is not displayed, so it
    /// stays out of the listed values.
    init(
        field: CatalogConclusionField,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) {
        let lead = field.displayedValues.first
            .map { ReconciledValueDisplay.string(for: $0.value, propertyKey: field.propertyKey, locale: locale, orders: orders) }
            .flatMap { $0.isEmpty ? nil : $0 }
        let listed = field.state == .multiple
            ? PVProvenanceSheetContent.listed(field.displayedValues, propertyKey: field.propertyKey, locale: locale, orders: orders)
            : []
        self.init(
            face: PVProvenanceFace(field: field),
            lead: lead,
            listedValues: listed,
            emptyText: ReconciledValueDisplay.emptyText(propertyKey: field.propertyKey),
            badge: ReconciledValueDisplay.stateBadge(field)
        )
    }
}

extension PVProvenanceSheetContent {
    /// One field's provenance: its state line, what it counts against, and its
    /// records in runs by displayed value.
    init(
        field: CatalogConclusionField,
        title: String,
        shown: Shown,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) {
        let records = Self.records([field], locale: locale, orders: orders)
        self.init(
            title: title,
            shown: shown,
            summary: Self.joinSummary([
                field.state == .single
                    ? L10n.ProvenanceSheet.stateSingle(ReconciledValueDisplay.sourceCountLine(ReconciledValueDisplay.sourceCount(field)))
                    : ReconciledValueDisplay.spokenState(field),
                ReconciledValueDisplay.againstLine(field),
                records.isEmpty ? nil : L10n.ProvenanceSheet.recordCount(records.count),
            ]),
            groups: [Group(
                owner: nil,
                values: Self.valueGroups(records, field: field, locale: locale, orders: orders)
            )]
        )
    }

    /// Every record of several fields in one group with no heading, as a row
    /// whose value spans them (a start–end date).
    static func spanning(
        fields: [CatalogConclusionField],
        title: String,
        shown: Shown,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) -> Self {
        let records = Self.records(fields, locale: locale, orders: orders)
        return Self(
            title: title,
            shown: shown,
            summary: records.isEmpty ? nil : L10n.ProvenanceSheet.recordCount(records.count),
            groups: [Group(owner: nil, records: records)]
        )
    }

    /// A row read off the canonical graph. Its records are the owning handles'
    /// fields: the shown owner's first, each under a group line when there are
    /// several or when the group is not the shown owner's, and only the shown
    /// owner's records in primary ink.
    static func derived(
        owners: [CatalogOwnerField],
        shownOwnerID: String?,
        kind: CatalogDerivedRowKind?,
        title: String,
        shown: Shown,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) -> Self {
        // One group per Place (or per other owner): the links to one Place
        // pool their records, in link order, the shown owner's group first.
        let ordered = owners.filter { $0.ownerID == shownOwnerID } + owners.filter { $0.ownerID != shownOwnerID }
        var ownerIDs: [String] = []
        var membersOf: [String: [CatalogOwnerField]] = [:]
        for owner in ordered {
            if membersOf[owner.ownerID] == nil { ownerIDs.append(owner.ownerID) }
            membersOf[owner.ownerID, default: []].append(owner)
        }
        let groups = ownerIDs.map { ownerID in
            let members = membersOf[ownerID] ?? []
            let memberRecords = members.map { member -> [Record] in
                var records = Self.records([member.field], locale: locale, orders: orders)
                if ownerID != shownOwnerID {
                    for index in records.indices { records[index].counted = false }
                }
                return records
            }
            return Group(
                owner: ownerIDs.count > 1 || ownerID != shownOwnerID
                    ? Self.ownerLine(
                        members[0], isShownOwner: ownerIDs.count > 1 && ownerID == shownOwnerID,
                        locale: locale, orders: orders
                    )
                    : nil,
                values: members.count == 1
                    ? Self.valueGroups(memberRecords[0], field: members[0].field, locale: locale, orders: orders)
                    : Self.pooledValueGroups(
                        zip(members.map(\.field), memberRecords).map { ($0, $1) }, locale: locale, orders: orders
                    )
            )
        }
        let recordCount = groups.reduce(0) { $0 + $1.records.count }
        let summary: String?
        if recordCount == 0 {
            summary = nil
        } else if groups.count > 1, let kind {
            summary = L10n.ProvenanceSheet.recordsFromOwners(records: recordCount, owners: groups.count, kind: kind)
        } else {
            summary = L10n.ProvenanceSheet.recordCount(recordCount)
        }
        return Self(title: title, shown: shown, summary: summary, groups: groups)
    }

    /// A displayed value as a line: its text and its Source count. The one
    /// builder of a `Value`.
    /// A date value worded by `role` reads as that role's line (`DateRowDisplay.line(date:role:)`).
    static func value(
        _ value: CatalogReconciledValue,
        propertyKey: String,
        role: DateRowDisplay.Role = .plain,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) -> Value {
        var text = ReconciledValueDisplay.string(for: value.value, propertyKey: propertyKey, locale: locale, orders: orders)
        var styled: AttributedString?
        if role != .plain, case .date(let date) = value.value {
            let line = DateRowDisplay.line(date: date, role: role, locale: locale)
            (text, styled) = (line.text, line.styled)
        }
        return Value(
            rank: value.rank,
            text: text,
            support: ReconciledValueDisplay.sourceCountLine(value.support),
            styled: styled,
            propertyKey: propertyKey
        )
    }

    /// Values as lines, in order: the one listing rule of a field's lines. A line that reads as
    /// nothing is left out (a weak spelling is not displayed, so it never reaches `values`).
    static func listed(
        _ values: [CatalogReconciledValue],
        propertyKey: String,
        role: DateRowDisplay.Role = .plain,
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) -> [Value] {
        values
            .map { value($0, propertyKey: propertyKey, role: role, locale: locale, orders: orders) }
            .filter { !$0.text.isEmpty }
    }

    /// A group's records in runs of equal `groupRank`, in the order Go sent them.
    /// Headings show when the group has two or more runs, and over a group whose
    /// only run counts under no displayed value; one value run needs none.
    static func valueGroups(
        _ records: [Record],
        field: CatalogConclusionField,
        locale: Locale,
        orders: NameFormatOrders
    ) -> [Group.ValueGroup] {
        let runs = Self.runs(of: records)
        let showsHeadings = runs.count > 1 || runs.first?.rank == 0
        return runs.map { run in
            let heading: Group.ValueGroup.Heading?
            if !showsHeadings {
                heading = nil
            } else if run.rank > 0, let value = field.displayedValues.first(where: { $0.rank == run.rank }) {
                heading = .value(Self.value(value, propertyKey: field.propertyKey, locale: locale, orders: orders))
            } else {
                heading = .otherRecords
            }
            return .init(heading: heading, records: run.records)
        }
    }

    /// The records in runs of equal `groupRank`, in order.
    private static func runs(of records: [Record]) -> [(rank: Int, records: [Record])] {
        var runs: [(rank: Int, records: [Record])] = []
        for record in records {
            if runs.last?.rank == record.outcome.groupRank {
                runs[runs.count - 1].records.append(record)
            } else {
                runs.append((record.outcome.groupRank, [record]))
            }
        }
        return runs
    }

    /// The records of several links to one Place, each link's own runs merged by
    /// displayed value: runs of the same value join in link order under one
    /// heading counting the distinct Sources of their outcomes, and records under no displayed
    /// value join last under one "other records" heading.
    private static func pooledValueGroups(
        _ members: [(field: CatalogConclusionField, records: [Record])],
        locale: Locale,
        orders: NameFormatOrders
    ) -> [Group.ValueGroup] {
        var valueRuns: [(value: Value, support: Int, outcomes: [CatalogReconcilerOutcome], records: [Record])] = []
        var other: [Record] = []
        for member in members {
            var counted: Set<String> = []
            for run in Self.runs(of: member.records) {
                guard run.rank > 0, let value = member.field.displayedValues.first(where: { $0.rank == run.rank }) else {
                    other += run.records
                    continue
                }
                let displayed = Self.value(value, propertyKey: member.field.propertyKey, locale: locale, orders: orders)
                let outcomes = member.field.outcomes.filter { $0.groupRank == run.rank }
                if let index = valueRuns.firstIndex(where: { $0.value.text == displayed.text }) {
                    valueRuns[index].records += run.records
                    valueRuns[index].outcomes += outcomes
                    if counted.insert(displayed.text).inserted { valueRuns[index].support += value.support }
                } else {
                    counted.insert(displayed.text)
                    valueRuns.append((displayed, value.support, outcomes, run.records))
                }
            }
        }
        let showsHeadings = valueRuns.count + (other.isEmpty ? 0 : 1) > 1 || valueRuns.isEmpty
        var groups = valueRuns.map { run -> Group.ValueGroup in
            var value = run.value
            value.support = ReconciledValueDisplay.sourceCountLine(
                ReconciledValueDisplay.distinctSourceCount(of: run.outcomes, fallback: run.support)
            )
            return .init(heading: showsHeadings ? .value(value) : nil, records: run.records)
        }
        if !other.isEmpty { groups.append(.init(heading: showsHeadings ? .otherRecords : nil, records: other)) }
        return groups
    }

    /// The group line of a derived row's owner, titled as its list titles it:
    /// an Event by its summary (else its label or ref), a Place by the kept
    /// names of the Place its link names (else its label or ref).
    private static func ownerLine(
        _ owner: CatalogOwnerField,
        isShownOwner: Bool,
        locale: Locale,
        orders: NameFormatOrders
    ) -> Group.OwnerLine {
        let title: String
        if let event = owner.event {
            title = EventTitleDisplay.title(event, locale: locale, orders: orders)
        } else if let place = owner.place {
            title = PlaceTitleDisplay.titleSource(place.titleParts).text
        } else {
            title = EventTitleDisplay.untitled(owner.entity).text
        }
        let identity = owner.place?.entity ?? owner.entity
        let ref = title == identity.ref ? nil : identity.ref
        let line = ref.map { L10n.DesignSystem.spokenJoin(title, $0) } ?? title
        let spoken = isShownOwner ? L10n.ProvenanceSheet.ownerShown(line) : line
        return .init(
            id: identity.id,
            title: title,
            ref: ref,
            spoken: spoken,
            isShownOwner: isShownOwner
        )
    }

    /// Every outcome of the fields, as records.
    private static func records(
        _ fields: [CatalogConclusionField],
        locale: Locale,
        orders: NameFormatOrders
    ) -> [Record] {
        fields.flatMap { field in
            field.outcomes.map { Record(outcome: $0, in: field, locale: locale, orders: orders) }
        }
    }

    /// The summary's parts, in order, joined with the summary separator; nil when none.
    private static func joinSummary(_ parts: [String?]) -> String? {
        let parts = parts.compactMap { $0 }
        guard let first = parts.first else { return nil }
        return parts.dropFirst().reduce(first) { L10n.ProvenanceSheet.summaryJoin($0, $1) }
    }
}

private extension CatalogOwnerField {
    /// What the content names, orders and inks the owner by: the Place, else the entity.
    var ownerID: String { place?.entity.id ?? entity.id }
}
