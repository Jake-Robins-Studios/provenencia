import Foundation
import Observation
import SwiftUI

/// The toolbar omnibar's results: the highlight, the keys and the width around a shared `CatalogSearchModel`.
@MainActor
@Observable
final class OmnibarResultsModel {
    /// The list's preferred width; it narrows to stay inside the content column.
    static let listWidth: CGFloat = 640
    /// The list scrolls past this height.
    static let maxListHeight: CGFloat = 420

    let search = CatalogSearchModel()
    /// The highlighted hit. The keyboard and the pointer drive the same value.
    private(set) var highlight = PVPopupListHighlight()
    /// Set when Esc / outside click closes the list without clearing the query.
    var userDismissed = false
    /// The field's frame in the content column's space.
    var fieldFrame: CGRect = .zero

    /// The list is shown once the query is long enough and a search has run (or is in flight).
    var isPresented: Bool {
        !userDismissed && search.showsResults
    }

    /// The hit under the highlight, if any.
    var highlightedHit: CatalogSearchHit? {
        highlight.current(count: search.hits.count).map { search.hits[$0] }
    }

    func closePanel() {
        userDismissed = true
        search.cancel()
    }

    func dismiss() {
        search.dismiss()
        highlight.clear()
        userDismissed = false
    }

    func clearAfterNavigate() {
        search.query = ""
        dismiss()
    }

    /// Return / click on a hit: commit navigation and clear the results chrome.
    func activate(_ hit: CatalogSearchHit, navigation: WorkspaceNavigation) {
        navigation.go(to: hit.location)
        clearAfterNavigate()
    }

    /// The pointer is over `row`.
    func hover(at row: Int) {
        highlight.hover(at: row, count: search.hits.count, isDisabled: { _ in false })
    }

    /// One key in the field. While the list is closed every key is the field's.
    /// Return (and keypad Enter) opens the highlighted hit and is taken even with
    /// none; Escape closes the list and keeps the query.
    func handleKey(
        _ key: KeyEquivalent,
        command: Bool,
        activate: (CatalogSearchHit) -> Void
    ) -> KeyPress.Result {
        guard isPresented else { return .ignored }
        if PVPopupListHighlight.isMovementKey(key) {
            highlight.move(key, command: command, count: search.hits.count, isDisabled: { _ in false })
            return .handled
        }
        switch key {
        case .return, KeyEquivalent("\u{3}"):
            if let hit = highlightedHit { activate(hit) }
            return .handled
        case .escape:
            closePanel()
            return .handled
        default:
            return .ignored
        }
    }

    func scheduleSearch(
        projectDir: String,
        location: WorkspaceLocation,
        store: any GenealogyStore
    ) {
        userDismissed = false
        search.scheduleSearch(
            projectDir: projectDir, location: location, store: store,
            onResults: { [weak self] in self?.landHighlight() }
        )
        if search.isBelowMinimumQuery { highlight.clear() }
    }

    /// New results arrive with the first hit highlighted.
    private func landHighlight() {
        highlight.land(count: search.hits.count, isDisabled: { _ in false })
    }
}
