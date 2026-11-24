import Foundation
import Observation

/// State for the **Sources** workspace destination (S2-04 board / S2-17 PR):
/// browse/filter/sort Sources as an evidence list and create via a thin dialog.
/// List rows come from `WorkspaceSession`; navigation to detail is history-driven.
@MainActor
@Observable
final class SourcesModel {
    /// Where an Evidence graph stands: no Subjects, Subjects and none promoted,
    /// or promoted (at least one Subject filed by a Promote).
    enum EvidenceStatus: String, CaseIterable, Identifiable, Codable {
        case empty
        case inProgress = "in_progress"
        case promoted

        var id: String { rawValue }

        var label: LocalizedStringResource {
            switch self {
            case .empty: L10n.Sources.statusEmpty
            case .inProgress: L10n.Sources.statusInProgress
            case .promoted: L10n.Sources.statusPromoted
            }
        }

        /// The one status a Source shows from its graphs' statuses: nil with none; the common value when
        /// all agree and it is Promoted or Not started; In progress otherwise (any mix, or all In progress).
        static func aggregate(_ statuses: [EvidenceStatus]) -> EvidenceStatus? {
            guard let first = statuses.first else { return nil }
            if statuses.allSatisfy({ $0 == first }), first != .inProgress { return first }
            return .inProgress
        }
    }

    struct Draft: Equatable {
        var sourceTypeID: String
        var title: String
        var description: String = ""

        var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

        /// The shared title and type rule for Add Source and Copy Source.
        var validation: SourceDraftValidation {
            SourceDraftValidation(
                titleError: trimmedTitle.isEmpty ? L10n.string(L10n.Sources.titleRequired) : nil,
                typeError: sourceTypeID.isEmpty ? L10n.string(L10n.Sources.typeRequired) : nil
            )
        }
    }

    struct SourceDraftValidation: Equatable {
        var titleError: String?
        var typeError: String?

        var isValid: Bool { titleError == nil && typeError == nil }
    }

    /// Sort, type (`source_types.id`, empty for all), evidence status, and
    /// search. Saved per project and user whenever it changes.
    var settings: SourcesListSettings {
        didSet {
            if settings != oldValue { settingsStore?.save(settings) }
        }
    }

    var isAdding = false
    /// The Copy Source form while it is open.
    var copying: SourceCopyModel?
    var draft = Draft(sourceTypeID: "", title: "")
    var typeError: String?
    var titleError: String?
    /// FFI / store failure on Create Source (not field validation).
    var createError: String?
    private(set) var isSaving = false

    var pageProjectDir: String { session.projectKey.projectDir }

    private let userID: String
    private let store: any GenealogyStore
    private let session: WorkspaceSession
    private let settingsStore: SourcesListSettingsStore?

    init(
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore,
        settingsStore: SourcesListSettingsStore? = nil
    ) {
        self.session = session
        self.userID = userID
        self.store = store
        self.settingsStore = settingsStore
        self.settings = settingsStore?.load() ?? SourcesListSettings()
    }

    // MARK: Session handles

    static func sourcesListKey(for session: WorkspaceSession) -> CatalogQueryKey {
        CatalogQueryKey.sourcesList(project: session.projectKey)
    }

    /// Starts list queries once (`.task` / dialog). Do not call from view `body`.
    func warmListQueries() {
        let _: QueryHandle<[CatalogSource]> = session.query(Self.sourcesListKey(for: session))
        let _: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        let _: QueryHandle<[String: EvidenceGraphProgress]> = session.query(session.evidenceGraphProgressKey)
        let _: QueryHandle<[CatalogEvidenceGraph]> = session.query(session.evidenceGraphsKey)
    }

    private var graphsHandle: QueryHandle<[CatalogEvidenceGraph]>? {
        session.evidenceGraphsHandle
    }

    /// True while the graph list or progress map can still arrive.
    var graphCountsLoading: Bool { session.evidenceGraphCountsLoading }

    private var typesHandle: QueryHandle<[CatalogSourceType]>? {
        session.queryHandle(session.sourceTypesKey)
    }

    /// The progress handle's failure while a status filter needs its counts. It
    /// reports a failure even beside a stale value, because a status filter
    /// must not apply stale counts silently.
    var statusCountsError: Error? {
        guard settings.status != nil else { return nil }
        if let failure = graphsHandle?.failure { return failure }
        return session.evidenceGraphProgressHandle?.failure
    }

    /// A status or restored type is set and the data to apply it has not arrived.
    var isAwaitingFilterData: Bool {
        if settings.status != nil, graphCountsLoading { return true }
        if !settings.typeFilterID.isEmpty {
            guard let typesHandle else { return true }
            return typesHandle.read.isLoading
        }
        return false
    }

    /// The saved type id when it is still a Source type, else all types. The
    /// stored id is left alone until the researcher changes the type.
    var effectiveTypeFilterID: String {
        types.contains { $0.id == settings.typeFilterID } ? settings.typeFilterID : ""
    }

    var isFiltering: Bool {
        !effectiveTypeFilterID.isEmpty
            || settings.status != nil
            || !trimmedQuery.isEmpty
    }

    private var trimmedQuery: String {
        settings.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func clearFilters() {
        var next = settings
        next.typeFilterID = ""
        next.status = nil
        next.query = ""
        settings = next
    }

    var sources: [CatalogSource] {
        session.queryHandle(Self.sourcesListKey(for: session))?.value ?? []
    }

    var types: [CatalogSourceType] {
        session.queryHandle(session.sourceTypesKey)?.value ?? []
    }

    var isLoading: Bool {
        guard let handle: QueryHandle<[CatalogSource]> = session.queryHandle(Self.sourcesListKey(for: session))
        else { return true }
        return handle.status == .loading && sources.isEmpty
    }

    var loadError: Error? {
        guard sources.isEmpty else { return nil }
        let sourcesHandle: QueryHandle<[CatalogSource]>? = session.queryHandle(Self.sourcesListKey(for: session))
        let typesHandle: QueryHandle<[CatalogSourceType]>? = session.sourceTypesHandle
        return sourcesHandle?.failure ?? typesHandle?.failure
    }

    // MARK: Derived

    func typeLabel(for source: CatalogSource) -> String {
        types.label(forTypeID: source.sourceTypeID) ?? ""
    }

    func typeIconKey(for source: CatalogSource) -> String? {
        types.iconKey(forTypeID: source.sourceTypeID)
    }

    /// A Source's title and ref keyed once. Two keys, so a match cannot cross fields.
    private struct SearchKey {
        let revision: Int64
        let title: String
        let ref: String
    }

    /// Keyed Sources by id, reused while a Source's revision and the locale hold.
    /// Not observed: filling it while the view reads `visibleSources` must not
    /// invalidate that view.
    @ObservationIgnored private var searchKeyCache: [String: SearchKey] = [:]
    @ObservationIgnored private var searchKeyLocale: String?

    private func searchKeys(for rows: [CatalogSource], locale: Locale) -> [String: SearchKey] {
        if searchKeyLocale != locale.identifier {
            searchKeyCache = [:]
            searchKeyLocale = locale.identifier
        }
        var next: [String: SearchKey] = [:]
        next.reserveCapacity(rows.count)
        for row in rows {
            if let hit = searchKeyCache[row.id], hit.revision == row.updated.revision {
                next[row.id] = hit
            } else {
                next[row.id] = SearchKey(
                    revision: row.updated.revision,
                    title: TextMatch.key(row.title, locale: locale),
                    ref: TextMatch.key(row.ref, locale: locale)
                )
            }
        }
        searchKeyCache = next
        return next
    }

    /// The one status a Source shows, for its badge and the status filter (`EvidenceStatus.aggregate`).
    /// Nil with no Artifact or no graph, while the Source's graphs are not loaded, or when a graph that
    /// has an Artifact has its counts loading or failed. A graph with no Artifact counts as Not started.
    func status(for source: CatalogSource) -> EvidenceStatus? {
        guard source.hasArtifact, case .loaded(let graphs) = session.evidenceGraphsRead(sourceID: source.id)
        else { return nil }
        var statuses: [EvidenceStatus] = []
        for graph in graphs {
            if graph.hasArtifact {
                guard let status = session.graphCounts(graphID: graph.id).status else { return nil }
                statuses.append(status)
            } else {
                statuses.append(.empty)
            }
        }
        return EvidenceStatus.aggregate(statuses)
    }

    /// The plain inputs `visibleSources` reads beside its handles: the
    /// settings and the locale.
    private struct VisibleRowsInputs: Equatable {
        let settings: SourcesListSettings
        let locale: String
    }

    /// The filtered, sorted rows. Built once per change of an input; typing in
    /// Add Source or reading it again changes none.
    var visibleSources: [CatalogSource] {
        let filtersByStatus = settings.status != nil
        let statusKeys = filtersByStatus ? [session.evidenceGraphsKey, session.evidenceGraphProgressKey] : []
        return session.derived(
            .visibleSources,
            inputs: ([Self.sourcesListKey(for: session), session.sourceTypesKey] + statusKeys).map(DerivedInput.key),
            extra: VisibleRowsInputs(settings: settings, locale: Locale.autoupdatingCurrent.identifier)
        ) {
            buildVisibleSources()
        }
    }

    /// The Sources list's rows: the visible Sources, and under each open Source its Evidence graphs.
    /// Built once per change of the visible Sources, the graph list or the open Source; a graph's counts
    /// are read by its row as it draws, so a counts update rebuilds nothing.
    var outline: SourcesOutline {
        // Read first, so its derived version is current when the outline stamps it.
        let rows = visibleSources
        return session.derived(
            .sourcesOutline,
            inputs: [.derived(.visibleSources), .key(session.evidenceGraphsKey)],
            extra: session.openSourceID
        ) {
            SourcesOutline(
                sources: rows,
                graphs: { session.evidenceGraphsRead(sourceID: $0) },
                open: session.openSourceID
            )
        }
    }

    /// The graph list has not been read yet (no handle, or still loading): the rows wait for it, so no
    /// triangle arrives late under the pointer. A failed read is not waiting.
    var isAwaitingGraphList: Bool {
        guard let graphsHandle else { return true }
        return graphsHandle.read.isLoading
    }

    /// The graph list's failure, when no status filter is set (a status filter reports it through
    /// `statusCountsError`): the Sources list shows its rows with no triangles and says why above them.
    var graphListError: Error? {
        guard settings.status == nil, case .failed(let error)? = graphsHandle?.read else { return nil }
        return error
    }

    /// The Sources list and the graph list are read and settled (or the graph list failed), and the
    /// counts or types a filter needs are in: the point at which a selected row that no row draws is
    /// cleared. A filter's data still on its way hides rows the selection may be on.
    var outlineIsSettled: Bool {
        guard let sourcesHandle: QueryHandle<[CatalogSource]> = session.queryHandle(Self.sourcesListKey(for: session)),
              sourcesHandle.isSettled, let graphsHandle,
              graphsHandle.isSettled || graphsHandle.failure != nil
        else { return false }
        return !isAwaitingFilterData && statusCountsError == nil
    }

    /// What the list area shows, and whether the toolbar shows with it.
    var listState: SourcesListState {
        let sourcesHandle: QueryHandle<[CatalogSource]>? = session.queryHandle(Self.sourcesListKey(for: session))
        return SourcesListState.make(SourcesListState.Inputs(
            loadError: loadError,
            sourcesAreRead: sourcesHandle?.value != nil,
            isCatalogEmpty: isCatalogEmpty,
            statusError: statusCountsError,
            isAwaitingGraphList: isAwaitingGraphList,
            isAwaitingFilterData: isAwaitingFilterData,
            hasRows: !outline.rows.isEmpty,
            graphListError: graphListError
        ))
    }

    private func buildVisibleSources() -> [CatalogSource] {
        var rows = sources
        let typeID = effectiveTypeFilterID
        if !typeID.isEmpty {
            rows = rows.filter { $0.sourceTypeID == typeID }
        }
        if let status = settings.status {
            rows = rows.filter { self.status(for: $0) == status }
        }
        let query = TextMatch.Query(trimmedQuery)
        if !query.isEmpty {
            let keys = searchKeys(for: sources, locale: query.locale)
            rows = rows.filter { row in
                guard let key = keys[row.id] else { return false }
                return query.matchesKey(key.title) || query.matchesKey(key.ref)
            }
        }
        let sort = settings.sort
        rows = rows.sorted { Self.order($0, $1, by: sort) }
        return rows
    }

    /// Whether `a` comes before `b` in `sort`. Every order ends in the id, so it is strict.
    /// Title: the title, then id newest first both ways. Published: the place in date order, undated
    /// last both ways. Added: the id (UUIDv7 byte order is create-time order). Updated: revision, then id.
    static func order(_ a: CatalogSource, _ b: CatalogSource, by sort: SourcesSort) -> Bool {
        let forward = sort.order == .forward
        switch sort.column {
        case .title: return titleOrder(a, b, descending: !forward)
        case .published: return dateOrder(a, b, newestFirst: !forward)
        case .added: return forward ? a.id < b.id : a.id > b.id
        case .updated: return forward ? updatedOrder(b, a) : updatedOrder(a, b)
        }
    }

    /// The "Updated" order, the one meaning of "most recently changed": revision,
    /// then id, both newest first.
    static func updatedOrder(_ a: CatalogSource, _ b: CatalogSource) -> Bool {
        if a.updated.revision != b.updated.revision {
            return a.updated.revision > b.updated.revision
        }
        return a.id > b.id
    }

    /// The date sorts: rows with a place in date order first, by that key; equal
    /// keys, and the rows without a key (undated, or a phrase only), by title.
    private static func dateOrder(_ a: CatalogSource, _ b: CatalogSource, newestFirst: Bool) -> Bool {
        switch (a.dateSortKey, b.dateSortKey) {
        case let (x?, y?) where x != y: return newestFirst ? x > y : x < y
        case (_?, nil): return true
        case (nil, _?): return false
        default: return titleOrder(a, b)
        }
    }

    /// The one title comparison of all four title-ordered sorts (A–Z, Z–A and the
    /// date sorts' ties and undated tail): title, flipped when `descending`, then
    /// id descending (newest added first) in both directions.
    private static func titleOrder(_ a: CatalogSource, _ b: CatalogSource, descending: Bool = false) -> Bool {
        switch a.title.localizedCaseInsensitiveCompare(b.title) {
        case .orderedAscending: !descending
        case .orderedDescending: descending
        case .orderedSame: a.id > b.id
        }
    }

    var isCatalogEmpty: Bool { sources.isEmpty }

    var filterLabel: String {
        let typeID = effectiveTypeFilterID
        if typeID.isEmpty {
            return L10n.string(L10n.Sources.filterAllTypes)
        }
        return types.label(forTypeID: typeID) ?? L10n.string(L10n.Sources.filterAllTypes)
    }

    func countLine(visibleCount visible: Int) -> String {
        if isAwaitingFilterData || statusCountsError != nil {
            return L10n.Sources.countLine(total: sources.count)
        }
        if !isFiltering || visible == sources.count {
            return L10n.Sources.countLine(total: sources.count)
        }
        return L10n.Sources.countLineFiltered(visible: visible, total: sources.count)
    }

    var canSubmitAdd: Bool {
        !isSaving && draft.validation.isValid
    }

    /// The sole auto-selected type is a seed, not an edit. A typed name,
    /// description, or a type the researcher picked counts.
    var addSheetIsDirty: Bool {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty || !description.isEmpty { return true }
        if types.count == 1 { return false }
        return !draft.sourceTypeID.isEmpty
    }

    // MARK: Actions

    /// Ensures the type pool query is warm for the Add Source dialog.
    func refreshTypes() {
        let _: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
    }

    /// Opens the Copy Source form for a row's Source.
    func openCopy(_ source: CatalogSource) {
        copying = SourceCopyModel(original: source, session: session, userID: userID, store: store)
    }

    func openAdd() {
        typeError = nil
        titleError = nil
        createError = nil
        draft = Draft(
            sourceTypeID: types.count == 1 ? (types.first?.id ?? "") : "",
            title: ""
        )
        isAdding = true
    }

    /// After a late type refresh, commit the only option so Create is one less step.
    func selectSoleTypeIfNeeded() {
        guard types.count == 1, draft.sourceTypeID.isEmpty else { return }
        draft.sourceTypeID = types[0].id
    }

    func cancelAdd() {
        guard !isSaving else { return }
        isAdding = false
        typeError = nil
        titleError = nil
        createError = nil
    }

    /// On success returns the created source for the view to `go(to:)`.
    @discardableResult
    func create() async -> CatalogSource? {
        guard !isSaving else { return nil }
        let validation = draft.validation
        typeError = validation.typeError
        titleError = validation.titleError
        createError = nil
        guard validation.isValid else { return nil }

        isSaving = true
        defer { isSaving = false }
        do {
            let (created, effects) = try await store.createSource(
                projectDir: session.projectKey.projectDir,
                userID: userID,
                sourceTypeID: draft.sourceTypeID,
                title: draft.trimmedTitle,
                description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            session.apply(effects, .createdSource(created))
            isAdding = false
            typeError = nil
            titleError = nil
            createError = nil
            session.toasts.add(
                tone: .success,
                title: L10n.Sources.toastCreatedTitle(ref: created.ref),
                message: L10n.Sources.toastCreatedBody(title: created.title)
            )
            return created
        } catch {
            createError = L10n.Errors.message(for: error)
            return nil
        }
    }
}
