import SwiftUI

/// Shared DateValue create/edit form body: Kind and the qualifier on one row,
/// each side's date row and time row, and Calendar and phrase behind a link.
/// Every host shows this one form. The form shows its own field errors; the
/// host shows any other line.
struct DateValueEditorForm: View {
    @Binding var draft: DateValueDraft
    /// Prefix for control identifiers (default matches the Source page date dialog).
    var accessibilityIdentifierPrefix: String = "sources.page.date"
    /// The host's handle on the earliest Year, where Tab from the host's last field lands. The
    /// form's Tab loop (`Field`) takes its place: Shift-Tab from Kind and Tab from the last
    /// field go on to the handle's own neighbours. The form does not take focus on its own.
    var yearFocus: PVFieldFocus? = nil

    @FocusState private var focus: Field?

    /// Width of the column that names a range's side.
    private static let sideLabelWidth: CGFloat = 86

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            kindRow
            side(start: true)
            if draft.isRange {
                side(start: false)
            }
            hintLine
            if draft.showAdvanced {
                advancedSection
            }
        }
        .environment(\.pvFieldLabel, nil)
    }

    // MARK: Kind and qualifier

    private var kindRow: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space3) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: PVSpacing.space4) {
                    kindControl
                    if draft.isPoint { qualifierControl }
                }
                VStack(alignment: .leading, spacing: PVSpacing.space3) {
                    kindControl
                    if draft.isPoint { qualifierControl }
                }
            }
            if draft.isRange {
                Text(L10n.Sources.dateKindRangeHint)
                    .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                    .foregroundStyle(PVColor.textMuted)
            }
        }
    }

    private var kindControl: some View {
        PVSegmentedControl(
            L10n.Sources.dateKindLabel,
            items: [
                .init(
                    L10n.Sources.dateKindPoint,
                    value: "point",
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).kind.point"
                ),
                .init(
                    L10n.Sources.dateKindRange,
                    value: "range",
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).kind.range"
                ),
            ],
            selection: draft.kind,
            size: .sm,
            focus: handle(.kind),
            select: { value in
                let wasFocused = focus == .kind
                draft.setKind(value)
                if wasFocused { FocusClaim.claim($focus, .kind) }
            }
        )
    }

    private var qualifierControl: some View {
        PVSegmentedControl(
            L10n.Sources.dateQualifierLabel,
            items: [
                .init(
                    L10n.Sources.dateQualifierAsStated,
                    value: "",
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).qualifier.exact"
                ),
                .init(
                    L10n.Sources.dateQualifierAbout,
                    value: DateQualifier.about,
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).qualifier.abt"
                ),
                .init(
                    L10n.Sources.dateQualifierBefore,
                    value: DateQualifier.before,
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).qualifier.bef"
                ),
                .init(
                    L10n.Sources.dateQualifierAfter,
                    value: DateQualifier.after,
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).qualifier.aft"
                ),
            ],
            selection: draft.qualifier,
            size: .sm,
            focus: handle(.qualifier),
            select: { value in
                let wasFocused = focus == .qualifier
                draft.qualifier = value
                if wasFocused { FocusClaim.claim($focus, .qualifier) }
            }
        )
    }

    // MARK: A side

    private func side(start: Bool) -> some View {
        let name = start ? "start" : "end"
        return VStack(alignment: .leading, spacing: PVSpacing.space3) {
            HStack(alignment: .top, spacing: 0) {
                if draft.isRange {
                    sideLabel(start: start)
                        .frame(width: Self.sideLabelWidth, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: PVSpacing.space3) {
                    dateRow(start: start)
                    timeRow(start: start)
                }
            }
            if let error = draft.shownError(start: start) {
                PVErrorText(error)
                    .padding(.leading, draft.isRange ? Self.sideLabelWidth : 0)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(name).fieldError")
            }
        }
        .modifier(DateSideGroup(heading: draft.isRange
            ? (start ? L10n.Sources.dateEarliestHeading : L10n.Sources.dateLatestHeading)
            : nil))
    }

    private func sideLabel(start: Bool) -> some View {
        VStack(alignment: .leading, spacing: PVSpacing.space1) {
            Text(start ? L10n.Sources.dateEarliestShort : L10n.Sources.dateLatestShort)
                .font(PVFont.body(size: PVTypeScale.caption, weight: PVFontWeight.medium))
                .foregroundStyle(PVColor.textSecondary)
            Text(start ? L10n.Sources.dateEarliestNote : L10n.Sources.dateLatestNote)
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textMuted)
        }
        // The side's group already carries its spoken name; the label is only drawn.
        .accessibilityHidden(true)
        // The fields' captions sit above their inputs; the label starts level with the inputs.
        .padding(.top, PVSpacing.space6)
    }

    private func dateRow(start: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PVSpacing.space3) {
            partField(.year, start: start, width: 64)
            monthSelect(start: start)
            partField(.day, start: start, width: 48)
        }
    }

    private func timeRow(start: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PVSpacing.space3) {
            partField(.hour, start: start, width: 48)
            partField(.minute, start: start, width: 48)
            partField(.second, start: start, width: 48)
            partField(.millisecond, start: start, width: 52)
            zoneField(start: start)
        }
    }

    /// A part's caption over its input.
    private func partField(
        _ component: DateValueDraft.Part,
        start: Bool,
        width: CGFloat
    ) -> some View {
        let isInvalid = draft.isFieldInvalid(component, start: start)
        return VStack(alignment: .leading, spacing: PVSpacing.space2) {
            fieldCaption(component.label, isInvalid: isInvalid)
            PVInput(
                text: partBinding(component, start: start),
                size: .sm,
                mono: true,
                isInvalid: isInvalid,
                focus: handle(.part(component, start: start))
            )
            .environment(\.pvFieldLabel, component.label)
            .frame(width: width)
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(start ? "start" : "end").\(component.identifierName)")
        }
    }

    private func zoneField(start: Bool) -> some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            fieldCaption(L10n.Sources.dateTimeZone, isInvalid: false)
            PVInput(
                text: start ? $draft.startTZ : $draft.endTZ,
                size: .sm,
                prompt: L10n.Sources.dateTimeZonePrompt,
                focus: handle(.zone(start: start))
            )
            .environment(\.pvFieldLabel, L10n.Sources.dateTimeZone)
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(start ? "start" : "end").timezone")
        }
        .frame(minWidth: 96, maxWidth: .infinity, alignment: .leading)
    }

    private func monthSelect(start: Bool) -> some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            fieldCaption(
                L10n.Sources.dateMonth,
                isInvalid: draft.isFieldInvalid(.month, start: start)
            )
            PVSelect(
                selection: partBinding(.month, start: start),
                options: DateValueSelectOptions.months,
                size: .sm,
                menuWidth: 160,
                fillsWidth: false,
                isInvalid: draft.isFieldInvalid(.month, start: start),
                accessibilityLabel: L10n.Sources.dateMonth,
                accessibilityIdentifier: "\(accessibilityIdentifierPrefix).\(start ? "start" : "end").month",
                focus: handle(.part(.month, start: start))
            )
            .frame(width: 124)
        }
    }

    private func fieldCaption(_ label: LocalizedStringResource, isInvalid: Bool) -> some View {
        Text(label)
            .font(PVFont.body(size: PVTypeScale.micro))
            .foregroundStyle(isInvalid ? PVColor.danger : PVColor.textSecondary)
    }

    // MARK: Hint and Calendar and phrase

    private var hintLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(L10n.Sources.dateLeaveEmptyHint)
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textFaint)
            Spacer()
            PVButton(
                draft.showAdvanced ? L10n.Sources.dateHideAdvanced : L10n.Sources.dateShowAdvanced,
                variant: .link,
                size: .sm,
                focus: handle(.advancedToggle)
            ) {
                draft.showAdvanced.toggle()
            }
            .pvExpandedState(draft.showAdvanced)
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).advancedToggle")
        }
    }

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            VStack(alignment: .leading, spacing: PVSpacing.space2) {
                Text(L10n.Sources.dateCalendar)
                    .font(PVFont.body(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textSecondary)
                PVSelect(
                    selection: $draft.calendar,
                    options: DateValueSelectOptions.calendars,
                    menuWidth: 220,
                    fillsWidth: false,
                    accessibilityLabel: L10n.Sources.dateCalendar,
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).calendar",
                    focus: handle(.calendar)
                )
                .frame(width: 220)
            }
            VStack(alignment: .leading, spacing: PVSpacing.space2) {
                Text(L10n.Sources.datePhrase)
                    .font(PVFont.body(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textSecondary)
                PVInput(
                    text: $draft.phrase,
                    size: .sm,
                    prompt: L10n.Sources.datePhrasePrompt,
                    focus: handle(.phrase)
                )
                .environment(\.pvFieldLabel, L10n.Sources.datePhrase)
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix).phrase")
                Text(L10n.Sources.datePhraseHint)
                    .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                    .foregroundStyle(PVColor.textMuted)
            }
        }
    }

    // MARK: Tab loop

    /// The handle for `field`: its own focus on the form's `FocusState` (the host's handle for
    /// the earliest Year), with the neighbours `Field.neighbours` names.
    private func handle(_ field: Field) -> PVFieldFocus {
        let neighbours = Field.neighbours(of: field, isRange: draft.isRange, isAdvancedOpen: draft.showAdvanced)
        let claims = PVFieldFocus.claims(
            next: reachable(neighbours.next),
            previous: reachable(neighbours.previous)
        ) { claim($0) }
        return ownHandle(field).replacingNeighbours(next: claims.next, previous: claims.previous)
    }

    private func ownHandle(_ field: Field) -> PVFieldFocus {
        if field == .startYear, let yearFocus { return yearFocus }
        return PVFieldFocus($focus, equals: field)
    }

    /// A target that has somewhere to go: a host edge with no host neighbour is left to the key loop.
    private func reachable(_ target: Field.Target?) -> Field.Target? {
        Field.resolve(target, hostHasNext: yearFocus?.next != nil, hostHasPrevious: yearFocus?.previous != nil)
    }

    /// Resolved when the key is pressed, so no handle is built to look at it.
    private func claim(_ target: Field.Target) {
        switch target {
        case .field(let field):
            FocusClaim.claim(ownHandle(field))
        case .hostNext:
            yearFocus?.next?()
        case .hostPrevious:
            yearFocus?.previous?()
        }
    }

    // MARK: Bindings

    /// The text of one part of one side: empty is nil, a number is the part, anything else is left as it was.
    private func partBinding(_ component: DateValueDraft.Part, start: Bool) -> Binding<String> {
        let part = DateValueDraft.part(component, start: start)
        return Binding(
            get: { draft[keyPath: part].map(String.init) ?? "" },
            set: { raw in
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    draft[keyPath: part] = nil
                } else if let value = Int32(trimmed) {
                    draft[keyPath: part] = value
                }
            }
        )
    }
}

extension DateValueEditorForm {
    /// What the form's Tab loop visits. It never names a host's field: the host's neighbours
    /// are the `Target`s `.hostNext` and `.hostPrevious`.
    enum Field: Hashable {
        case kind, qualifier
        case part(DateValueDraft.Part, start: Bool)
        case zone(start: Bool)
        case advancedToggle, calendar, phrase

        /// Where Tab or Shift-Tab goes from a field.
        enum Target: Equatable {
            case field(Field)
            case hostNext, hostPrevious
        }

        static var startYear: Field { .part(.year, start: true) }

        /// A target that has somewhere to go: a host edge with no host neighbour is left to the key loop.
        static func resolve(_ target: Target?, hostHasNext: Bool, hostHasPrevious: Bool) -> Target? {
            switch target {
            case .hostNext where !hostHasNext: nil
            case .hostPrevious where !hostHasPrevious: nil
            default: target
            }
        }

        /// The fields Tab walks from the earliest Year on: each side's parts then its time zone,
        /// the earliest side then the latest on a range, then the Calendar and phrase link and,
        /// while open, Calendar and Phrase. Kind and the qualifier sit before Year, off this list.
        static func order(isRange: Bool, isAdvancedOpen: Bool) -> [Field] {
            var fields: [Field] = []
            for start in isRange ? [true, false] : [true] {
                fields += DateValueDraft.Part.allCases.map { .part($0, start: start) }
                fields.append(.zone(start: start))
            }
            fields.append(.advancedToggle)
            if isAdvancedOpen { fields += [.calendar, .phrase] }
            return fields
        }

        /// The kit's neighbours in `order`, with the form's own edges: Year's Shift-Tab goes to the
        /// qualifier (Single date) or Kind (range), Kind and the qualifier Tab to Year, Kind's
        /// Shift-Tab goes to the host, and the last field's Tab goes to the host.
        @MainActor
        static func neighbours(
            of field: Field,
            isRange: Bool,
            isAdvancedOpen: Bool
        ) -> (next: Target?, previous: Target?) {
            let fields = order(isRange: isRange, isAdvancedOpen: isAdvancedOpen)
            let base = PVFieldFocus.neighbours(of: field, in: fields)
            var next = base.next.map(Target.field)
            var previous = base.previous.map(Target.field)
            if field == fields.last { next = .hostNext }
            switch field {
            case .kind:
                next = .field(startYear)
                previous = .hostPrevious
            case .qualifier:
                next = .field(startYear)
                previous = .field(.kind)
            case startYear:
                previous = .field(isRange ? .kind : .qualifier)
            default:
                break
            }
            return (next, previous)
        }
    }
}

private extension DateValueDraft.Part {
    var label: LocalizedStringResource {
        switch self {
        case .year: L10n.Sources.dateYear
        case .month: L10n.Sources.dateMonth
        case .day: L10n.Sources.dateDay
        case .hour: L10n.Sources.dateHour
        case .minute: L10n.Sources.dateMinute
        case .second: L10n.Sources.dateSecond
        case .millisecond: L10n.Sources.dateMillisecond
        }
    }

    /// The last word of the part's accessibility identifier.
    var identifierName: String {
        switch self {
        case .year: "year"
        case .month: "month"
        case .day: "day"
        case .hour: "hour"
        case .minute: "minute"
        case .second: "second"
        case .millisecond: "millisecond"
        }
    }
}

/// A range's side reads as one group named by its full heading; a Single date's side has no group.
private struct DateSideGroup: ViewModifier {
    let heading: LocalizedStringResource?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let heading {
            content
                .accessibilityElement(children: .contain)
                .accessibilityLabel(Text(heading))
        } else {
            content
        }
    }
}

/// Calendar and month option lists for DateValue `PVSelect` remounts.
enum DateValueSelectOptions {
    static var calendars: [PVSelectOption] {
        [
            PVSelectOption(value: "gregorian", label: L10n.string(L10n.Sources.dateCalendarGregorian)),
            PVSelectOption(value: "julian", label: L10n.string(L10n.Sources.dateCalendarJulian)),
            PVSelectOption(
                value: "french-republican",
                label: L10n.string(L10n.Sources.dateCalendarFrenchRepublican)
            ),
            PVSelectOption(value: "hebrew", label: L10n.string(L10n.Sources.dateCalendarHebrew)),
        ]
    }

    static var months: [PVSelectOption] {
        [
            ("", L10n.Sources.dateMonthNone),
            ("1", L10n.Sources.dateMonthJanuary),
            ("2", L10n.Sources.dateMonthFebruary),
            ("3", L10n.Sources.dateMonthMarch),
            ("4", L10n.Sources.dateMonthApril),
            ("5", L10n.Sources.dateMonthMay),
            ("6", L10n.Sources.dateMonthJune),
            ("7", L10n.Sources.dateMonthJuly),
            ("8", L10n.Sources.dateMonthAugust),
            ("9", L10n.Sources.dateMonthSeptember),
            ("10", L10n.Sources.dateMonthOctober),
            ("11", L10n.Sources.dateMonthNovember),
            ("12", L10n.Sources.dateMonthDecember),
        ].map { PVSelectOption(value: $0.0, label: L10n.string($0.1)) }
    }
}
