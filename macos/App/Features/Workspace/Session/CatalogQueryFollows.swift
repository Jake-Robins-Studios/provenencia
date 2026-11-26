import Foundation

/// Which ids of a write a patch or refresh follows: row or key ids, or one
/// token for a catalog-wide slot. Each slot carries its own.
enum CatalogQueryFollows: Sendable, Hashable {
    /// `CatalogWriteEffects.handleScopes`: Person, Event, and Place handles.
    case handle
    /// `CatalogWriteEffects.sourceScopes`.
    case source
    /// The key ids of one entry of `CatalogWriteEffects.reads`.
    case reads(CatalogRead)
    /// `CatalogWriteEffects.touchedHandles`: every handle a write changed or
    /// whose summary it changed.
    case touchedHandles
    /// `CatalogWriteEffects.evidenceGraphs`.
    case evidenceGraphs
    /// One catalog-wide list of `CatalogWriteEffects.lists`. A catalog-wide slot
    /// names no row, so it reports one token when the write moved it and is
    /// used only with `applyHiddenPolicyOnAny(follows:)`.
    case list(CatalogList)
    /// `CatalogWriteEffects.structure`. Catalog-wide, as `list(_:)`.
    case structure
    /// `CatalogWriteEffects.deleted`: the ids of one entity a write deleted.
    case deleted(CatalogDeletedEntity)

    /// Whether the slot names no row: it reports one token when the write moved
    /// it. The constructors that read a slot as row or key ids refuse one.
    var isCatalogWide: Bool {
        switch self {
        case .list, .structure:
            return true
        case .handle, .source, .reads, .touchedHandles, .evidenceGraphs, .deleted:
            return false
        }
    }

    /// The ids of a write that this slot follows.
    func ids(in effects: CatalogWriteEffects) -> [String] {
        switch self {
        case .handle:
            return effects.handleScopes
        case .source:
            return effects.sourceScopes
        case .reads(let read):
            return effects.reads.first { $0.read == read }?.ids ?? []
        case .touchedHandles:
            return effects.touchedHandles
        case .evidenceGraphs:
            return effects.evidenceGraphs
        case .list(let list):
            return effects.lists.contains(list) ? [list.rawValue] : []
        case .structure:
            return effects.structure ? ["structure"] : []
        case .deleted(let entity):
            return effects.deleted.first { $0.entity == entity }?.ids ?? []
        }
    }

    /// Row-id slots name ids; a catalog-wide slot names none.
    func requireRowIDs() {
        precondition(!isCatalogWide, "a catalog-wide slot names no ids; use applyHiddenPolicyOnAny(follows:)")
    }
}
