import Foundation

/// Editable draft of a genealogical DateValue for the shared Structure/Edit date modal.
/// Validation mirrors `core/datevalue` (gaps allowed; at least one civil field or a phrase).
struct DateValueDraft: Equatable, Sendable {
    var kind: String
    var qualifier: String
    var calendar: String
    var phrase: String

    var startYear: Int32?
    var startMonth: Int32?
    var startDay: Int32?
    var startHour: Int32?
    var startMinute: Int32?
    var startSecond: Int32?
    var startMillisecond: Int32?
    var startTZ: String

    var endYear: Int32?
    var endMonth: Int32?
    var endDay: Int32?
    var endHour: Int32?
    var endMinute: Int32?
    var endSecond: Int32?
    var endMillisecond: Int32?
    var endTZ: String

    /// UI: calendar + phrase section.
    var showAdvanced: Bool

    static func empty() -> DateValueDraft {
        DateValueDraft(
            kind: "point",
            qualifier: "",
            calendar: "gregorian",
            phrase: "",
            startYear: nil,
            startMonth: nil,
            startDay: nil,
            startHour: nil,
            startMinute: nil,
            startSecond: nil,
            startMillisecond: nil,
            startTZ: "",
            endYear: nil,
            endMonth: nil,
            endDay: nil,
            endHour: nil,
            endMinute: nil,
            endSecond: nil,
            endMillisecond: nil,
            endTZ: "",
            showAdvanced: false
        )
    }

    /// No civil fields and no phrase. A transcription prefill may fill this.
    var isBlank: Bool {
        startYear == nil && startMonth == nil && startDay == nil
            && startHour == nil && startMinute == nil && startSecond == nil
            && startMillisecond == nil
            && endYear == nil && endMonth == nil && endDay == nil
            && endHour == nil && endMinute == nil && endSecond == nil
            && endMillisecond == nil
            && phrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isPoint: Bool { kind == "point" }
    var isRange: Bool { kind == "range" }

    /// Switching to range clears qualifier (Between is the hedge). Switching to point clears end_*.
    mutating func setKind(_ newKind: String) {
        kind = newKind
        if newKind == "range" {
            qualifier = ""
        } else {
            for component in CascadeComponent.allCases {
                self[keyPath: Self.part(component, start: false)] = nil
            }
            endTZ = ""
        }
    }

    // MARK: Validation

    /// Civil component that can show an out-of-range field error, in the order the form shows them.
    enum CascadeComponent: CaseIterable, Equatable, Sendable {
        case year, month, day, hour, minute, second, millisecond
    }

    /// Inline range-order message when latest falls before earliest; otherwise nil.
    var endError: String? {
        guard kind == "range" else { return nil }
        guard startSideHasYear, endSideHasYear else { return nil }
        guard !Self.sideLessOrEqual(startSide, endSide) else { return nil }
        return L10n.string(L10n.Sources.dateRangeOrderError)
    }

    /// The one mapping from a part of a side to its stored field.
    static func part(_ component: CascadeComponent, start: Bool) -> WritableKeyPath<DateValueDraft, Int32?> {
        switch (component, start) {
        case (.year, true): \.startYear
        case (.year, false): \.endYear
        case (.month, true): \.startMonth
        case (.month, false): \.endMonth
        case (.day, true): \.startDay
        case (.day, false): \.endDay
        case (.hour, true): \.startHour
        case (.hour, false): \.endHour
        case (.minute, true): \.startMinute
        case (.minute, false): \.endMinute
        case (.second, true): \.startSecond
        case (.second, false): \.endSecond
        case (.millisecond, true): \.startMillisecond
        case (.millisecond, false): \.endMillisecond
        }
    }

    /// Out-of-range message for one cascade field, if its stored value is invalid.
    func fieldError(_ component: CascadeComponent, start: Bool) -> String? {
        guard let value = self[keyPath: Self.part(component, start: start)].map(Int.init) else { return nil }
        switch component {
        case .year:
            return (1...9999).contains(value) ? nil : L10n.string(L10n.Sources.dateYearOutOfRange)
        case .month:
            return (1...12).contains(value) ? nil : L10n.string(L10n.Sources.dateMonthOutOfRange)
        case .day:
            return (1...31).contains(value) ? nil : L10n.string(L10n.Sources.dateDayOutOfRange)
        case .hour:
            return (0...23).contains(value) ? nil : L10n.string(L10n.Sources.dateHourOutOfRange)
        case .minute:
            return (0...59).contains(value) ? nil : L10n.string(L10n.Sources.dateMinuteOutOfRange)
        case .second:
            return (0...59).contains(value) ? nil : L10n.string(L10n.Sources.dateSecondOutOfRange)
        case .millisecond:
            return (0...999).contains(value) ? nil : L10n.string(L10n.Sources.dateMillisecondOutOfRange)
        }
    }

    func isFieldInvalid(_ component: CascadeComponent, start: Bool) -> Bool {
        fieldError(component, start: start) != nil
    }

    /// First out-of-range message on a side (Y/M/D then time), for group-level display.
    func cascadeFieldError(start: Bool) -> String? {
        for component in CascadeComponent.allCases {
            if let message = fieldError(component, start: start) {
                return message
            }
        }
        return nil
    }

    /// The message the date form shows for this side: an out-of-range field first, else, on the end
    /// side, the range-order message. The one place that says when the form shows an error.
    func shownError(start: Bool) -> String? {
        if let message = cascadeFieldError(start: start) { return message }
        return start ? nil : endError
    }

    /// The line for a draft that is typed into but cannot be saved, when no field shows an error:
    /// not blank, not valid, and neither side showing an error. Names the first case that applies.
    var unsavableError: String? {
        guard !isBlank, !isValid, shownError(start: true) == nil, shownError(start: false) == nil else { return nil }
        let key: LocalizedStringResource
        if isRange, !startSide.hasCivil, !endSide.hasCivil {
            key = L10n.Sources.dateUnsavableRangeBoth
        } else if isRange, !startSide.hasCivil {
            key = L10n.Sources.dateUnsavableRangeStart
        } else if isRange, !endSide.hasCivil {
            key = L10n.Sources.dateUnsavableRangeEnd
        } else if isPoint, !startSide.hasCivil, hasZone, startMillisecond != nil {
            key = L10n.Sources.dateUnsavableZoneAndMillisecond
        } else if isPoint, !startSide.hasCivil, hasZone {
            key = L10n.Sources.dateUnsavableZone
        } else if isPoint, !startSide.hasCivil, startMillisecond != nil {
            key = L10n.Sources.dateUnsavableMillisecond
        } else {
            key = L10n.Sources.dateUnsavableOther
        }
        return L10n.string(key)
    }

    private var hasZone: Bool {
        !startTZ.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// What a save sends: nil while the form is blank, else the draft as input.
    var value: CatalogDateValueInput? { isBlank ? nil : toInput() }

    var isValid: Bool {
        let q = qualifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        let startTZTrim = startTZ.trimmingCharacters(in: .whitespacesAndNewlines)
        let endTZTrim = endTZ.trimmingCharacters(in: .whitespacesAndNewlines)

        switch kind {
        case "point":
            guard Self.pointQualifierOK(q) else { return false }
            if !endSide.empty || !endTZTrim.isEmpty { return false }
            if !startSide.hasCivil {
                // Phrase-only point: no year/month/day/time; timezone alone is not enough.
                return !p.isEmpty && startTZTrim.isEmpty && startMillisecond == nil
            }
            return Self.validateComponentRanges(startSide)
        case "range":
            guard q.isEmpty else { return false }
            guard Self.validateComponentRanges(startSide) else { return false }
            guard Self.validateComponentRanges(endSide) else { return false }
            return Self.sideLessOrEqual(startSide, endSide)
        default:
            return false
        }
    }

    func toInput() -> CatalogDateValueInput {
        CatalogDateValueInput(
            kind: kind,
            qualifier: kind == "range" ? "" : qualifier.trimmingCharacters(in: .whitespacesAndNewlines),
            calendar: calendar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "gregorian"
                : calendar.trimmingCharacters(in: .whitespacesAndNewlines),
            startYear: startYear,
            startMonth: startMonth,
            startDay: startDay,
            startHour: startHour,
            startMinute: startMinute,
            startSecond: startSecond,
            startMillisecond: startMillisecond,
            startTZ: startTZ.trimmingCharacters(in: .whitespacesAndNewlines),
            endYear: kind == "range" ? endYear : nil,
            endMonth: kind == "range" ? endMonth : nil,
            endDay: kind == "range" ? endDay : nil,
            endHour: kind == "range" ? endHour : nil,
            endMinute: kind == "range" ? endMinute : nil,
            endSecond: kind == "range" ? endSecond : nil,
            endMillisecond: kind == "range" ? endMillisecond : nil,
            endTZ: kind == "range" ? endTZ.trimmingCharacters(in: .whitespacesAndNewlines) : "",
            phrase: phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    // MARK: Private sides

    private var startSide: Side { side(start: true) }

    private var endSide: Side { side(start: false) }

    private func side(start: Bool) -> Side {
        func value(_ component: CascadeComponent) -> Int? {
            self[keyPath: Self.part(component, start: start)].map(Int.init)
        }
        return Side(
            year: value(.year),
            month: value(.month),
            day: value(.day),
            hour: value(.hour),
            minute: value(.minute),
            second: value(.second),
            millisecond: value(.millisecond)
        )
    }

    private var startSideHasYear: Bool { startYear != nil }
    private var endSideHasYear: Bool { endYear != nil }

    private struct Side {
        var year, month, day, hour, minute, second, millisecond: Int?

        var empty: Bool {
            year == nil && month == nil && day == nil
                && hour == nil && minute == nil && second == nil && millisecond == nil
        }

        var hasCivil: Bool {
            year != nil || month != nil || day != nil
                || hour != nil || minute != nil || second != nil
        }
    }

    private static func pointQualifierOK(_ qual: String) -> Bool {
        switch qual {
        case "", DateQualifier.about, DateQualifier.before, DateQualifier.after: return true
        default: return false
        }
    }

    private static func validateComponentRanges(_ s: Side) -> Bool {
        guard s.hasCivil else { return false }
        if let m = s.month, !(1...12).contains(m) { return false }
        if let d = s.day, !(1...31).contains(d) { return false }
        if let y = s.year, !(1...9999).contains(y) { return false }
        if let h = s.hour, !(0...23).contains(h) { return false }
        if let mi = s.minute, !(0...59).contains(mi) { return false }
        if let sec = s.second, !(0...59).contains(sec) { return false }
        if let ms = s.millisecond, !(0...999).contains(ms) { return false }
        return true
    }

    private static func sideLessOrEqual(_ a: Side, _ b: Side) -> Bool {
        let levelsA: [Int?] = [a.year, a.month, a.day, a.hour, a.minute, a.second, a.millisecond]
        let levelsB: [Int?] = [b.year, b.month, b.day, b.hour, b.minute, b.second, b.millisecond]
        for i in levelsA.indices {
            guard let va = levelsA[i], let vb = levelsB[i] else { return true }
            if va < vb { return true }
            if va > vb { return false }
        }
        return true
    }
}

extension DateValueDraft {
    /// Rebuild a draft from a previously saved `CatalogDateValueInput` (session cache / FakeStore).
    init(from input: CatalogDateValueInput) {
        self.init(
            kind: input.kind.isEmpty ? "point" : input.kind,
            qualifier: input.qualifier,
            calendar: input.calendar.isEmpty ? "gregorian" : input.calendar,
            phrase: input.phrase,
            startYear: input.startYear,
            startMonth: input.startMonth,
            startDay: input.startDay,
            startHour: input.startHour,
            startMinute: input.startMinute,
            startSecond: input.startSecond,
            startMillisecond: input.startMillisecond,
            startTZ: input.startTZ,
            endYear: input.endYear,
            endMonth: input.endMonth,
            endDay: input.endDay,
            endHour: input.endHour,
            endMinute: input.endMinute,
            endSecond: input.endSecond,
            endMillisecond: input.endMillisecond,
            endTZ: input.endTZ,
            showAdvanced: !input.phrase.isEmpty
                || (!input.calendar.isEmpty && input.calendar != "gregorian")
        )
    }
}
