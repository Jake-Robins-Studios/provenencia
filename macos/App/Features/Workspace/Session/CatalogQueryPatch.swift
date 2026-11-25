import Foundation

/// One in-place update of a warmed cache key. `follows == nil` means the patch
/// reads the mutation (an enriched Source); otherwise the session passes the
/// ids that `follows` names. Array order on a descriptor is composition order.
struct CatalogQueryPatch: Sendable {
    var follows: CatalogQueryFollows?
    let apply: @MainActor @Sendable (
        WorkspaceSession, CatalogQueryKey, Set<String>, CatalogActivity, CatalogMutation?
    ) -> CatalogPatchResult

    /// Moves each row whose id is in the set and whose revision is older than
    /// the write's. A row only moves forward; nothing is fetched.
    static func lastUpdated<Rows: CatalogLastUpdatedRows>(
        _: Rows.Type,
        follows: CatalogQueryFollows
    ) -> Self {
        follows.requireRowIDs()
        return Self(follows: follows) { session, key, ids, activity, _ in
            session.patchCached(key, as: Rows.self) { rows in
                rows.moveActivity(ids: ids, activity: activity)
            }
        }
    }

    /// Puts the mutation's Source into the Sources list: it replaces the row
    /// with the same id, and a `.createdSource(source)` appends its row when the list
    /// lacks it (the list sorts for display). An update or type change of a
    /// row the list lacks adds nothing. Leaves any stale flag: other rows may
    /// still owe a reload.
    static func sourceRow() -> Self {
        row(
            CatalogSource.self,
            patched: { $0.patchedSource },
            appendsOn: { if case .createdSource(_) = $0 { return true } else { return false } }
        )
    }

    /// Writes the mutation's Source type onto the cached types list: replaces the row with the
    /// same id (`.createdSourceType`, `.updatedSourceType`), a `.createdSourceType` appends its
    /// row when the list lacks it (the list sorts for display), and a `.deletedSourceType` removes
    /// its row. Leaves any stale flag.
    static func sourceTypeRow() -> Self {
        row(
            CatalogSourceType.self,
            patched: { $0.patchedSourceType },
            appendsOn: { if case .createdSourceType(_) = $0 { return true } else { return false } },
            removes: { if case .deletedSourceType(let id) = $0 { return id } else { return nil } }
        )
    }

    /// The row patch of a cached list: replaces the row with the same id, and appends the
    /// mutation's row when the list lacks it only if `appendsOn` says the mutation creates it;
    /// otherwise a row the list lacks adds nothing. A mutation `removes` names the id of a row to
    /// drop; it carries no row, so it is checked first.
    static func row<Row: Identifiable & Sendable>(
        _: Row.Type,
        patched: @escaping @Sendable (CatalogMutation) -> Row?,
        appendsOn: @escaping @Sendable (CatalogMutation) -> Bool,
        removes: @escaping @Sendable (CatalogMutation) -> String? = { _ in nil }
    ) -> Self where Row.ID == String {
        Self(follows: nil) { session, key, _, _, mutation in
            guard let mutation else { return .unchanged }
            if let removedID = removes(mutation) {
                return session.patchCached(key, as: [Row].self) { rows in
                    let before = rows.count
                    rows.removeAll { $0.id == removedID }
                    return rows.count != before
                }
            }
            guard let row = patched(mutation) else { return .unchanged }
            let appends = appendsOn(mutation)
            return session.patchCached(key, as: [Row].self) { rows in
                if let index = rows.firstIndex(where: { $0.id == row.id }) {
                    rows[index] = row
                    return true
                }
                guard appends else { return false }
                rows.append(row)
                return true
            }
        }
    }

    /// Writes the mutation's Source onto the cached page shell. A partial
    /// patch: a page marked stale stays stale and reloads on its next visit.
    static func updatedSourceShell() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard let source = mutation?.patchedSource else { return .unchanged }
            guard key.kind == .sourceWorkspace, key.ownId == source.id else { return .unchanged }
            return session.patchCached(key, as: CatalogSourceWorkspace.self) { workspace in
                workspace.source = source
                return true
            }
        }
    }

    /// Writes a suggestion write's reply onto the cached suggestions of the type it names.
    /// A key of another type, or one with no value, is left alone.
    static func typeSuggestions() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard case .wroteTypeSuggestions(let typeId, let edit)? = mutation else { return .unchanged }
            guard key.kind == .typeSuggestions, key.ownId == typeId else { return .unchanged }
            return session.patchCached(key, as: [CatalogTypeSuggestion].self) { suggestions in
                guard suggestions != edit.suggestions else { return false }
                suggestions = edit.suggestions
                return true
            }
        }
    }

    /// Writes a suggestion write's count onto the type's row of the cached types list, so the
    /// list's Fields column follows with no reload. A type the list lacks adds nothing.
    static func typeSuggestionCount() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard case .wroteTypeSuggestions(let typeId, let edit)? = mutation else { return .unchanged }
            return session.patchCached(key, as: [CatalogSourceType].self) { rows in
                guard let index = rows.firstIndex(where: { $0.id == typeId }),
                      rows[index].suggestedFieldCount != edit.suggestedFieldCount
                else { return false }
                rows[index].suggestedFieldCount = edit.suggestedFieldCount
                return true
            }
        }
    }

    /// Writes a board write's rows onto the cached Source page, for the owner
    /// the write named. A partial patch like `updatedSourceShell()`: an owner the
    /// page cannot place leaves it unchanged.
    static func metadataBoard() -> Self {
        Self(follows: nil) { session, key, _, _, mutation in
            guard case .wroteMetadataBoard(let sourceId, let owner, let entries)? = mutation else { return .unchanged }
            guard key.kind == .sourceWorkspace, key.ownId == sourceId else { return .unchanged }
            return session.patchCached(key, as: CatalogSourceWorkspace.self) { workspace in
                workspace.setMetadataRows(entries, for: owner)
            }
        }
    }
}
