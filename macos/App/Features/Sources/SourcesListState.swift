import Foundation

/// What the Sources page's list area shows, decided once: the page's area, its toolbar and its count line
/// all read this one value. Pure, so each state is tested without a view (`SourcesListState.make`).
enum SourcesListState {
    /// The Sources list failed with nothing to show: no toolbar.
    case failed(Error)
    /// The Sources list or the graph list is not read yet: the header, no toolbar, skeleton rows.
    case firstLoad
    /// No Sources: no toolbar.
    case empty
    /// A status filter's data failed: the toolbar, then the failure alone.
    case statusFailed(Error)
    /// A status filter's counts or a saved type filter's types have not arrived: the toolbar, then skeleton rows.
    case waitingForFilter
    /// The filters match nothing: the toolbar, then the no-match state.
    case noMatch
    /// The rows, with the graph list's failure above them when it failed and no status filter is set.
    case rows(graphsError: Error?)

    /// Whether the toolbar (and the header's count line) show.
    var showsToolbar: Bool {
        switch self {
        case .failed, .firstLoad, .empty: false
        case .statusFailed, .waitingForFilter, .noMatch, .rows: true
        }
    }

    /// The inputs of `make`, plain values so a test builds each state.
    struct Inputs {
        /// The Sources list's failure while it has no Sources.
        var loadError: Error?
        var sourcesAreRead: Bool
        var isCatalogEmpty: Bool
        var statusError: Error?
        var isAwaitingGraphList: Bool
        var isAwaitingFilterData: Bool
        var hasRows: Bool
        var graphListError: Error?
    }

    /// The states in the order they win: the whole list failed with nothing to show; the Sources list not
    /// read; an empty catalog; a status failure; the graph list not read; a filter's data not in; no
    /// match; then the rows.
    static func make(_ inputs: Inputs) -> SourcesListState {
        if let error = inputs.loadError { return .failed(error) }
        if !inputs.sourcesAreRead { return .firstLoad }
        if inputs.isCatalogEmpty { return .empty }
        if let error = inputs.statusError { return .statusFailed(error) }
        if inputs.isAwaitingGraphList { return .firstLoad }
        if inputs.isAwaitingFilterData { return .waitingForFilter }
        if !inputs.hasRows { return .noMatch }
        return .rows(graphsError: inputs.graphListError)
    }
}
