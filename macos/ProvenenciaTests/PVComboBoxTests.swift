import Foundation
import SwiftUI
import Testing
@testable import Provenencia

@Suite
struct PVComboBoxTests {
    private func option(_ value: String, _ label: String, subtext: String = "", disabled: Bool = false) -> PVComboBoxOption {
        PVComboBoxOption(value: value, label: label, subtext: subtext, isDisabled: disabled)
    }

    private var pool: [PVComboBoxOption] {
        [
            option("f1", "Author", subtext: "author"),
            option("f2", "Publication date", subtext: "publication-date"),
            option("f3", "Publisher", subtext: "publisher"),
        ]
    }

    // MARK: Filtering

    @Test func emptyQueryKeepsEveryRow() {
        #expect(PVComboBoxMatch.filter(pool, query: "   ").map(\.value) == ["f1", "f2", "f3"])
    }

    @Test func filterMatchesLabelOrSubtextAsSubstring() {
        // "date" is only reachable mid-token, so this must not be a prefix match.
        #expect(PVComboBoxMatch.filter(pool, query: "date").map(\.value) == ["f2"])
        #expect(PVComboBoxMatch.filter(pool, query: "publi").map(\.value) == ["f2", "f3"])
        // The key alone finds the row, even though the label reads differently.
        #expect(PVComboBoxMatch.filter(pool, query: "publication-").map(\.value) == ["f2"])
    }

    @Test func filterIgnoresCaseAndDiacritics() {
        let accented = [option("p1", "Ó Riain"), option("p2", "Smith")]
        #expect(PVComboBoxMatch.filter(accented, query: "o ri").map(\.value) == ["p1"])
        #expect(PVComboBoxMatch.filter(accented, query: "SMITH").map(\.value) == ["p2"])
    }

    @Test func filterIgnoresWordBreaksAndPunctuation() {
        let rows = [option("a", "Godfather"), option("b", "Godmother")]
        #expect(PVComboBoxMatch.filter(rows, query: "god-f").map(\.value) == ["a"])
        #expect(PVComboBoxMatch.filter(rows, query: "-").map(\.value) == ["a", "b"])
    }

    @Test func filterWithNoHitsReturnsNothing() {
        #expect(PVComboBoxMatch.filter(pool, query: "nomatch").isEmpty)
    }

    @Test func prefixOutranksALaterWordWhichOutranksAMidWordMatch() {
        let rows = [
            option("g", "grandparent"),
            option("p", "parent"),
            option("s", "step-parent"),
            option("k", "kinship", subtext: "parental"),
        ]
        #expect(PVComboBoxMatch.filter(rows, query: "par").map(\.value) == ["p", "s", "g", "k"])
    }

    @Test func orderInsideABandStaysTheCallerOrder() {
        let rows = [
            option("a", "parentage"),
            option("b", "parent"),
            option("c", "step parent"),
            option("d", "foster-parent"),
        ]
        #expect(PVComboBoxMatch.filter(rows, query: "par").map(\.value) == ["a", "b", "c", "d"])
    }

    // MARK: Remote results

    @Test func searchingLineShowsOnlyWhileLoadingWithNothingIn() {
        #expect(PVComboBoxMatch.listLine(optionCount: 0, isLoading: true) == .loading)
    }

    @Test func optionsAlreadyInStayWhileANewSearchRuns() {
        #expect(PVComboBoxMatch.listLine(optionCount: 3, isLoading: true) == .rows)
    }

    @Test func noOptionsAndNoSearchShowsTheEmptyLine() {
        #expect(PVComboBoxMatch.listLine(optionCount: 0, isLoading: false) == .empty)
        #expect(PVComboBoxMatch.listLine(optionCount: 2, isLoading: false) == .rows)
    }

    @Test func aRestoreIsReportedOnlyToRemoteCallers() {
        #expect(PVComboBoxMatch.reportsRestore(isRemote: true, old: "Pol", new: ""))
        #expect(PVComboBoxMatch.reportsRestore(isRemote: true, old: "", new: "") == false)
        #expect(PVComboBoxMatch.reportsRestore(isRemote: false, old: "Pol", new: "") == false)
    }

    // MARK: Return

    /// Return commits a highlighted row, reaches the form only when the field
    /// shows its pick, and otherwise does nothing.
    @Test(arguments: [
        ("highlighted row", 1, "pub", "Author", PVComboBoxMatch.ReturnAction.commit(1)),
        ("untouched, or typed back to the label", -1, "Author", "Author", .submit),
        ("cleared with a pick", -1, "", "Author", .swallow),
        ("cleared with no pick", -1, "", "", .submit),
        ("text matching nothing", -1, "zzz", "Author", .swallow),
        ("text matching nothing, no pick", -1, "zzz", "", .swallow),
    ])
    func returnPassesOnOnlyWhenTheFieldShowsItsPick(
        _ name: String, _ activeIndex: Int, _ query: String, _ committedLabel: String,
        _ expected: PVComboBoxMatch.ReturnAction
    ) {
        let action = PVComboBoxMatch.returnAction(
            activeIndex: activeIndex, optionCount: 3, query: query, committedLabel: committedLabel
        )
        #expect(action == expected, "\(name)")
    }

    // MARK: Highlight

    @Test func highlightMarksTheMatchedSpanOnly() {
        let marked = PVComboBoxHighlight.attributed("Publication date", query: "date")
        let runs = marked.runs.map { run in
            (
                String(marked[run.range].characters),
                run[AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.self]
            )
        }
        #expect(runs.map(\.0) == ["Publication ", "date"])
        #expect(runs[0].1 == nil)
        #expect(runs[1].1 == PVColor.markBackground)
    }

    @Test func highlightMarksTheKeyedSpan() {
        let marked = PVComboBoxHighlight.attributed("God-father", query: "godf")
        let runs = marked.runs.map { run in
            (
                String(marked[run.range].characters),
                run[AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.self]
            )
        }
        #expect(runs.filter { $0.1 != nil }.map(\.0) == ["God-f"])
    }

    @Test func highlightMatchesCaseInsensitively() {
        let marked = PVComboBoxHighlight.attributed("Author", query: "AUTH")
        let runs = marked.runs.map { String(marked[$0.range].characters) }
        #expect(runs == ["Auth", "or"])
    }

    @Test func highlightLeavesTextAloneWithoutAQuery() {
        let marked = PVComboBoxHighlight.attributed("Author", query: "  ")
        #expect(marked.runs.count == 1)
        #expect(String(marked.characters) == "Author")
    }

    @Test func highlightLeavesTextAloneWhenTheQueryIsAbsent() {
        let marked = PVComboBoxHighlight.attributed("Author", query: "zz")
        #expect(marked.runs.count == 1)
    }
}
