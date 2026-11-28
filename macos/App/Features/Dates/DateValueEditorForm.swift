import SwiftUI

/// Shared DateValue create/edit form body: Kind and the qualifier on one row,
/// each side's date row and time row, and Calendar and phrase behind a link.
/// Every host shows this one form. The form shows its own field errors; the
/// host shows any other line.
struct DateValueEditorForm: View {
    @Binding var draft: DateValueDraft
    /// Prefix for control identifiers (default matches the Source page date dialog).
    var accessibilityIdentifierPrefix: String = "sources.page.date"
    /// Host focus for the earliest year field. The form does not take focus on its own.
    var yearFocus: PVFieldFocus? = nil

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
            select: { draft.setKind($0) }
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
            select: { draft.qualifier = $0 }
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
        // The fields' captions sit above their inputs; the label starts level with the inputs.
        .padding(.top, PVSpacing.space6)
    }

    private func dateRow(start: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PVSpacing.space3) {
            cascadeField(.year, start: start, width: 64, focus: start ? yearFocus : nil)
            monthSelect(start: start)
            cascadeField(.day, start: start, width: 48)
        }
    }

    private func timeRow(start: Bool) -> some View {
        HStack(alignment: .bottom, spacing: PVSpacing.space3) {
            cascadeField(.hour, start: start, width: 48)
            cascadeField(.minute, start: start, width: 48)
            cascadeField(.second, start: start, width: 48)
            cascadeField(.millisecond, start: start, width: 52)
            zoneField(start: start)
        }
    }

    /// A part's caption over its input.
    private func cascadeField(
        _ component: DateValueDraft.CascadeComponent,
        start: Bool,
        width: CGFloat,
        focus: PVFieldFocus? = nil
    ) -> some View {
        let isInvalid = draft.isFieldInvalid(component, start: start)
        return VStack(alignment: .leading, spacing: PVSpacing.space2) {
            fieldCaption(component.label, isInvalid: isInvalid)
            PVInput(
                text: partBinding(component, start: start),
                size: .sm,
                mono: true,
                isInvalid: isInvalid,
                focus: focus
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
                prompt: L10n.Sources.dateTimeZonePrompt
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
                accessibilityIdentifier: "\(accessibilityIdentifierPrefix).\(start ? "start" : "end").month"
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
                size: .sm
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
                    accessibilityIdentifier: "\(accessibilityIdentifierPrefix).calendar"
                )
                .frame(width: 220)
            }
            VStack(alignment: .leading, spacing: PVSpacing.space2) {
                Text(L10n.Sources.datePhrase)
                    .font(PVFont.body(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textSecondary)
                PVInput(text: $draft.phrase, size: .sm, prompt: L10n.Sources.datePhrasePrompt)
                .environment(\.pvFieldLabel, L10n.Sources.datePhrase)
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix).phrase")
                Text(L10n.Sources.datePhraseHint)
                    .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                    .foregroundStyle(PVColor.textMuted)
            }
        }
    }

    // MARK: Bindings

    /// The text of one part of one side: empty is nil, a number is the part, anything else is left as it was.
    private func partBinding(_ component: DateValueDraft.CascadeComponent, start: Bool) -> Binding<String> {
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

private extension DateValueDraft.CascadeComponent {
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
