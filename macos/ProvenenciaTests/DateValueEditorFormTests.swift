import Testing
@testable import Provenencia

@Suite
@MainActor
struct DateValueEditorFormTests {
    private typealias Field = DateValueEditorForm.Field

    private func year(_ start: Bool) -> Field { .part(.year, start: start) }

    private func parts(start: Bool) -> [Field] {
        DateValueDraft.Part.allCases.map { .part($0, start: start) } + [.zone(start: start)]
    }

    /// The targets Tab reaches from the earliest Year, until it leaves the form.
    private func walkNext(isRange: Bool, isAdvancedOpen: Bool) -> [Field.Target] {
        var seen: [Field.Target] = []
        var at = Field.startYear
        while let target = Field.neighbours(of: at, isRange: isRange, isAdvancedOpen: isAdvancedOpen).next {
            seen.append(target)
            guard case .field(let field) = target else { break }
            at = field
        }
        return seen
    }

    @Test func dayAndMsShareARightEdge() {
        typealias L = DateValueEditorForm.Layout
        let dateRow = L.year + L.month + L.day + 2 * L.gap
        let timeRow = 4 * L.timePart + 3 * L.gap
        #expect(dateRow == timeRow)
        #expect(dateRow == 252)
    }

    @Test func neighbourTable() {
        #expect(Field.order(isRange: false, isAdvancedOpen: false) == parts(start: true) + [.advancedToggle])
        #expect(Field.order(isRange: false, isAdvancedOpen: true)
            == parts(start: true) + [.advancedToggle, .calendar, .phrase])
        #expect(Field.order(isRange: true, isAdvancedOpen: false)
            == parts(start: true) + parts(start: false) + [.advancedToggle])
        #expect(Field.order(isRange: true, isAdvancedOpen: true)
            == parts(start: true) + parts(start: false) + [.advancedToggle, .calendar, .phrase])

        // A Single date, Calendar and phrase closed: Year to the host, and back to Kind.
        let point = Field.neighbours(of: .startYear, isRange: false, isAdvancedOpen: false)
        #expect(point.previous == .field(.qualifier))
        #expect(
            walkNext(isRange: false, isAdvancedOpen: false)
                == (parts(start: true).dropFirst() + [.advancedToggle]).map { .field($0) } + [.hostNext]
        )
        #expect(Field.neighbours(of: .qualifier, isRange: false, isAdvancedOpen: false).previous == .field(.kind))
        #expect(Field.neighbours(of: .kind, isRange: false, isAdvancedOpen: false).previous == .hostPrevious)

        // Calendar and phrase open: the link, then Calendar, then Phrase, then out.
        #expect(
            walkNext(isRange: false, isAdvancedOpen: true)
                == (parts(start: true).dropFirst() + [.advancedToggle, .calendar, .phrase]).map { .field($0) }
                + [.hostNext]
        )

        // A range: the latest side follows the earliest zone; Year's Shift-Tab is Kind.
        let range = Field.neighbours(of: .startYear, isRange: true, isAdvancedOpen: false)
        #expect(range.previous == .field(.kind))
        #expect(
            Field.neighbours(of: .zone(start: true), isRange: true, isAdvancedOpen: false).next
                == .field(year(false))
        )
        #expect(
            Field.neighbours(of: year(false), isRange: true, isAdvancedOpen: false).previous
                == .field(.zone(start: true))
        )
        #expect(
            walkNext(isRange: true, isAdvancedOpen: false)
                == (parts(start: true).dropFirst() + parts(start: false) + [.advancedToggle]).map { .field($0) }
                + [.hostNext]
        )
        #expect(Field.neighbours(of: .kind, isRange: true, isAdvancedOpen: false).previous == .hostPrevious)
        #expect(
            Field.neighbours(of: .advancedToggle, isRange: true, isAdvancedOpen: false).next == .hostNext
        )
        #expect(
            Field.neighbours(of: .phrase, isRange: true, isAdvancedOpen: true).next == .hostNext
        )

        // Kind and the qualifier both Tab to Year.
        for isRange in [false, true] {
            #expect(Field.neighbours(of: .kind, isRange: isRange, isAdvancedOpen: false).next == .field(.startYear))
            #expect(Field.neighbours(of: .qualifier, isRange: isRange, isAdvancedOpen: false).next == .field(.startYear))
        }
    }

    @Test func hostEdgeWithNoNeighbourGoesToTheKeyLoop() {
        #expect(Field.resolve(.hostPrevious, hostHasNext: true, hostHasPrevious: false) == nil)
        #expect(Field.resolve(.hostPrevious, hostHasNext: false, hostHasPrevious: true) == .hostPrevious)
        #expect(Field.resolve(.hostNext, hostHasNext: false, hostHasPrevious: true) == nil)
        #expect(Field.resolve(.hostNext, hostHasNext: true, hostHasPrevious: false) == .hostNext)
        #expect(Field.resolve(.field(.kind), hostHasNext: false, hostHasPrevious: false) == .field(.kind))
        #expect(Field.resolve(nil, hostHasNext: true, hostHasPrevious: true) == nil)
    }
}
