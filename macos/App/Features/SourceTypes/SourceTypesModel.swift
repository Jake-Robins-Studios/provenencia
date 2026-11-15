import Foundation
import Observation

/// State for the **Source types** list (S2-03 board / S2-16 PR): browse and sort the project's
/// `source_types` vocabulary and open the Add type dialog. A type's own page edits it
/// (`SourceTypePageModel`).
@MainActor
@Observable
final class SourceTypesModel {
    enum SortColumn: String {
        case label
        case key
        case fields
    }

    private(set) var sortColumn: SortColumn = .label
    private(set) var sortAscending = true

    /// The Add type dialog's model while it is open; a fresh one per open.
    var adding: SourceTypeAddModel?

    private let userID: String
    private let store: any GenealogyStore
    private let session: WorkspaceSession

    init(
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore
    ) {
        self.session = session
        self.userID = userID
        self.store = store
    }

    // MARK: Session handles

    static func typesListKey(for session: WorkspaceSession) -> CatalogQueryKey {
        CatalogQueryKey.sourceTypesList(project: session.projectKey)
    }

    func warmListQueries() {
        let _: QueryHandle<[CatalogSourceType]> = session.query(Self.typesListKey(for: session))
    }

    var types: [CatalogSourceType] {
        session.queryHandle(Self.typesListKey(for: session))?.value ?? []
    }

    var isLoading: Bool {
        guard let handle: QueryHandle<[CatalogSourceType]> = session.queryHandle(Self.typesListKey(for: session))
        else { return true }
        return handle.status == .loading && types.isEmpty
    }

    var loadError: Error? {
        guard types.isEmpty else { return nil }
        let typesHandle: QueryHandle<[CatalogSourceType]>? = session.queryHandle(Self.typesListKey(for: session))
        return typesHandle?.failure
    }

    // MARK: Derived

    var visibleTypes: [CatalogSourceType] {
        types.sorted { a, b in
            let order = compare(a, b)
            return sortAscending ? order == .orderedAscending : order == .orderedDescending
        }
    }

    var isAdding: Bool { adding != nil }

    /// Nil until the list has a value, so the header shows no zero counts.
    var countLine: String? {
        let handle: QueryHandle<[CatalogSourceType]>? = session.queryHandle(Self.typesListKey(for: session))
        guard handle?.value != nil else { return nil }
        if types.pluginCount > 0 {
            return L10n.SourceTypes.countLineWithPlugin(
                total: types.count, seeded: types.seededCount, user: types.userCount, plugin: types.pluginCount
            )
        }
        return L10n.SourceTypes.countLine(total: types.count, seeded: types.seededCount, user: types.userCount)
    }

    func sortBy(_ columnID: String) {
        guard let column = SortColumn(rawValue: columnID) else { return }
        if column == sortColumn {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
    }

    func openAdd() {
        adding = SourceTypeAddModel(session: session, userID: userID, store: store)
    }

    private func compare(_ a: CatalogSourceType, _ b: CatalogSourceType) -> ComparisonResult {
        switch sortColumn {
        case .label:
            return a.label.localizedCaseInsensitiveCompare(b.label)
        case .key:
            return a.key.localizedCaseInsensitiveCompare(b.key)
        case .fields:
            if a.suggestedFieldCount == b.suggestedFieldCount {
                return a.label.localizedCaseInsensitiveCompare(b.label)
            }
            return a.suggestedFieldCount < b.suggestedFieldCount ? .orderedAscending : .orderedDescending
        }
    }
}
