import Foundation

/// One workspace place resolved from navigation location + registry row.
struct ResolvedPlace: Equatable, Sendable {
    let placeID: PlaceID
    let presentation: WorkspacePresentationID
    let queryKeys: [CatalogQueryKey]
    /// The id this place's view resets on: a different value remounts the destination. `nil` keeps one view across locations (list roots, master–detail places that follow `currentLocation`).
    let viewIdentity: String?
    /// Whether the place names its graph's Source in the location; see `pendingGraphSourceCorrection`.
    let followsGraphSource: Bool

    /// The location rewritten to the Source `graph` is on now, when this place follows its graph's
    /// Source and `location` still names another; see `WorkspaceLocation.correctingGraphSource`.
    /// The host observes this value, so each stale entry for one graph is corrected in turn, though
    /// the graph's own Source is the same for all of them.
    func pendingGraphSourceCorrection(for location: WorkspaceLocation, graph: CatalogEvidenceGraph?) -> WorkspaceLocation? {
        followsGraphSource ? location.correctingGraphSource(graph) : nil
    }
}
