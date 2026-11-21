import Foundation
import Observation

/// What a catalog search's results show.
enum CatalogSearchLine: Equatable {
    case rows
    case searching
    case noMatches
    case failed(message: String)
}

/// Debounced SearchCatalog state shared by every find-a-record surface: the
/// toolbar omnibar and pickers. `kinds` is fixed for the model's life (empty:
/// every searchable kind); the location is per search (nil: no section nudge).
@MainActor
@Observable
final class CatalogSearchModel {
    static let minQueryLength = 2
    static let debounceNanoseconds: UInt64 = 180_000_000

    let kinds: [String]

    var query = ""
    var hits: [CatalogSearchHit] = []
    var isLoading = false
    var hasSearched = false
    /// Non-nil when the last completed search failed (not "no matches").
    var searchError: String?
    var selectedIndex = 0

    private let latest = LatestCall()

    init(kinds: [String] = []) {
        self.kinds = kinds
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The query is too short to search.
    var isBelowMinimumQuery: Bool {
        trimmedQuery.count < Self.minQueryLength
    }

    /// Results show once the query is long enough and a search has run (or is in flight).
    var showsResults: Bool {
        !isBelowMinimumQuery && (hasSearched || isLoading)
    }

    /// What the results show: the one decision every find-a-record surface
    /// reads. A failure is never drawn as no match, and hits already in stay
    /// on screen while the next search runs.
    var line: CatalogSearchLine {
        if let message = searchError, !isLoading { return .failed(message: message) }
        switch PVPopupListLineKind.of(rowCount: hits.count, isLoading: isLoading) {
        case .rows: return .rows
        case .loading: return .searching
        case .empty: return .noMatches
        }
    }

    /// Stops any pending or in-flight search; keeps the query and the hits on screen.
    func cancel() {
        latest.cancel()
        isLoading = false
    }

    func dismiss() {
        cancel()
        hits = []
        hasSearched = false
        searchError = nil
        selectedIndex = 0
    }

    func scheduleSearch(
        projectDir: String,
        location: WorkspaceLocation?,
        store: any GenealogyStore
    ) {
        let q = trimmedQuery
        guard !isBelowMinimumQuery else {
            dismiss()
            return
        }

        searchError = nil
        isLoading = true
        let kinds = kinds
        latest.start(
            after: .nanoseconds(Self.debounceNanoseconds),
            {
                try await store.searchCatalog(projectDir: projectDir, query: q, location: location, kinds: kinds)
            },
            apply: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let results):
                    hits = results
                    searchError = nil
                case .failure(let error):
                    hits = []
                    searchError = L10n.Errors.message(for: error)
                }
                hasSearched = true
                isLoading = false
                selectedIndex = 0
            }
        )
    }

    /// Returns once the latest scheduled search has finished or been cancelled,
    /// following any search scheduled while it waited. Tests await this instead
    /// of polling against a deadline, which a busy main actor can outlast.
    func settle() async {
        await latest.settle()
    }

    func moveSelection(delta: Int) {
        selectedIndex = PVFloatingMenuSelection.moveIndex(
            from: selectedIndex, delta: delta, count: hits.count
        )
    }

    func selectedHit() -> CatalogSearchHit? {
        guard hits.indices.contains(selectedIndex) else { return nil }
        return hits[selectedIndex]
    }
}
