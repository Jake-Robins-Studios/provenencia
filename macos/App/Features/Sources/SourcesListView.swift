import SwiftUI

/// The **Sources** list workspace destination (S2-04 / S4-06): evidence list,
/// Add Source dialog, and row navigation to the Source page via history.
struct SourcesListView: View {
    @Environment(WorkspaceSession.self) private var session
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(\.pvWidthClass) private var widthClass
    @State private var model: SourcesModel

    init(
        session: WorkspaceSession,
        userID: String,
        projectUuid: String,
        store: any GenealogyStore
    ) {
        _model = State(
            initialValue: SourcesModel(
                session: session,
                userID: userID,
                store: store,
                settingsStore: SourcesListSettingsStore(projectUuid: projectUuid, userID: userID)
            )
        )
    }

    var body: some View {
        Group {
            if let sourcesHandle: QueryHandle<[CatalogSource]> = session.queryHandle(
                SourcesModel.sourcesListKey(for: session)
            ),
            let typesHandle: QueryHandle<[CatalogSourceType]> = session.sourceTypesHandle {
                SourcesListContent(
                    sourcesHandle: sourcesHandle,
                    typesHandle: typesHandle,
                    model: model
                )
            } else {
                // The handles arrive a turn after the page: the first-load page holds the place.
                SourcesPage.frame(
                    model: model, state: .firstLoad,
                    toolbar: { _ in EmptyView() },
                    content: { gutter in SourcesListLoadingArea(gutter: gutter) }
                )
            }
        }
        .task {
            model.warmListQueries()
        }
    }
}

/// The Sources page's frame, one place for the first-load page and the loaded one: the header with its
/// Add Source button, then the toolbar and the list area the state allows.
@MainActor
private enum SourcesPage {
    static func frame<Toolbar: View, Content: View>(
        model: SourcesModel,
        state: SourcesListState,
        @ViewBuilder toolbar: @escaping (CGFloat) -> Toolbar,
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) -> some View {
        PVListPage(
            title: L10n.Workspace.sourcesTitle,
            description: L10n.Sources.description,
            countLine: state.showsToolbar ? model.countLine(visibleCount: model.visibleSources.count) : nil,
            add: .init(label: L10n.Sources.addSource) { model.openAdd() },
            identifierRoot: "sources",
            showsToolbar: state.showsToolbar,
            toolbar: toolbar,
            content: content
        )
    }
}

/// The skeleton Source rows, with a bar for each column the width class draws.
private struct SourcesListLoadingArea: View {
    let gutter: CGFloat
    @Environment(\.pvWidthClass) private var widthClass

    var body: some View {
        PVListPageArea.loadingArea(gutter: gutter, detailWidths: SourcesRowColumns.widths(isWide: widthClass == .wide))
    }
}

/// Observes query handles directly so list loads repaint when cache settles.
private struct SourcesListContent: View {
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(WorkspaceSession.self) private var session
    @Bindable var sourcesHandle: QueryHandle<[CatalogSource]>
    @Bindable var typesHandle: QueryHandle<[CatalogSourceType]>
    @Bindable var model: SourcesModel
    @Environment(\.pvWidthClass) private var widthClass
    /// The list has taken the keyboard once, the search field has had it, or the settings changed: the
    /// list leaves focus where it is when its rows come back (a search that matched nothing, then did).
    @Environment(\.sourcesCurrentEvent) private var currentEvent
    @State private var listLeavesFocusAlone = false
    /// Which triangle the pointer is on, for `select`. Not observed: no view reads it to draw.
    @State private var triangleHover = SourcesTriangleHover()
    @FocusState private var searchFocused: Bool

    var body: some View {
        let outline = model.outline
        let state = model.listState
        return SourcesPage.frame(
            model: model, state: state,
            toolbar: { gutter in toolbar(gutter: gutter) },
            content: { gutter in content(state: state, outline: outline, gutter: gutter) }
        )
        .modifier(ListSelectionAnchorModifier(
            rowIDs: outline.rows.map(\.id),
            isSettled: model.outlineIsSettled,
            reveal: { anchor in
                guard let id = outline.sourceToReveal(anchor) else { return false }
                session.setSourcesExpanded([id], true)
                return true
            }
        ))
        .modifier(SourcesAddDialog(model: model, typesHandle: typesHandle))
        .sourceCopyDialog($model.copying)
        .onChange(of: searchFocused) { _, focused in
            if focused { listLeavesFocusAlone = true }
        }
        .onChange(of: model.settings) { _, _ in
            listLeavesFocusAlone = true
            // A sort or filter change clears the selection and puts the list at its top; the open
            // Sources stay open.
            navigation.go(to: navigation.currentLocation.withListScrollAnchor(nil))
        }
        .accessibilityIdentifier("sources")
    }

    // MARK: The list area

    /// The list area for the page's one state (`SourcesListState`).
    @ViewBuilder
    private func content(state: SourcesListState, outline: SourcesOutline, gutter: CGFloat) -> some View {
        switch state {
        case .failed(let error):
            PVListPageArea.failureArea(L10n.Errors.message(for: error), gutter: gutter)
                .accessibilityIdentifier("sources.loadError")
        case .firstLoad, .waitingForFilter:
            SourcesListLoadingArea(gutter: gutter)
        case .empty:
            emptyArea
        case .statusFailed(let error):
            PVListPageArea.failureArea(L10n.Errors.message(for: error), gutter: gutter)
                .accessibilityIdentifier("sources.statusError")
        case .noMatch:
            noMatchArea
        case .rows(let graphsError):
            rows(outline: outline, graphsError: graphsError, gutter: gutter)
        }
    }

    private var emptyArea: some View {
        PVEmptyState(
            icon: .scrollText,
            title: L10n.Sources.emptyTitle,
            message: L10n.string(L10n.Sources.emptyMessage)
        )
        .accessibilityIdentifier("sources.empty")
    }

    private var noMatchArea: some View {
        PVEmptyState(
            icon: .filter,
            title: L10n.Sources.noFilterMatchesTitle,
            message: L10n.string(L10n.Sources.noFilterMatchesMessage),
            compact: true
        ) {
            PVButton(L10n.Sources.clearFilters, variant: .secondary) {
                model.clearFilters()
            }
            .accessibilityIdentifier("sources.clearFilters")
        }
        .accessibilityIdentifier("sources.filterEmpty")
    }

    private func rows(outline: SourcesOutline, graphsError: Error?, gutter: CGFloat) -> some View {
        VStack(spacing: 0) {
            if let graphsError {
                PVCallout(tone: .danger, message: L10n.Errors.message(for: graphsError))
                    .padding(.horizontal, gutter)
                    .padding(.top, PVSpacing.space6)
                    .padding(.bottom, PVSpacing.space5)
                    .accessibilityIdentifier("sources.graphsError")
            }
            PVListBody(
                items: outline.rows,
                // Navigation owns the selected row: it is the row history stamps on leaving.
                selection: Binding(
                    get: { navigation.listAnchor },
                    set: { select($0, outline: outline) }
                ),
                minimumRowHeight: SourcesGraphRow.height,
                horizontalInset: gutter,
                leadingHang: PVListMetrics.hang(leadingWidth: SourcesSourceRow.triangleWidth),
                label: L10n.Workspace.sourcesTitle,
                onActivate: { row in
                    if let location = SourcesListNavigation.location(for: row) { navigation.go(to: location) }
                },
                menu: { row in
                    SourcesRowMenu.items(
                        for: row, graphs: session.evidenceGraphsRead(sourceID: row.source.id), actions: menuActions
                    )
                },
                separator: { $0.endsGroup ? .visible : .hidden },
                restartKey: model.settings,
                claimsFocus: !listLeavesFocusAlone
            ) { row in
                outlineRow(row, outline: outline)
            }
            .onKeyPress(keys: [.rightArrow, .leftArrow], phases: .down) { press in
                handle(press.key, outline: outline)
            }
            .onAppear { listLeavesFocusAlone = true }
        }
    }

    /// → opens a closed Source, ← closes an open one or climbs from a graph row to its Source.
    private func handle(_ key: KeyEquivalent, outline: SourcesOutline) -> KeyPress.Result {
        switch SourcesOutline.keyAction(key, selected: outline.row(id: navigation.listAnchor)) {
        case .expand(let id):
            toggle([id], expanding: true, outline: outline)
        case .collapse(let id):
            toggle([id], expanding: false, outline: outline)
        case .select(let id):
            navigation.noteListAnchor(id)
        case .ignore:
            return .ignored
        }
        return .handled
    }

    @ViewBuilder
    private func outlineRow(_ row: SourcesOutlineRow, outline: SourcesOutline) -> some View {
        switch row.kind {
        case .source(let source, let disclosure):
            SourcesSourceRow(
                source: source, disclosure: disclosure, model: model, isWide: widthClass == .wide,
                toggle: { all in
                    toggle(
                        all ? outline.togglableSourceIDs : [source.id], expanding: disclosure != .expanded,
                        outline: outline
                    )
                },
                hoverTriangle: { id, inside in triangleHover.note(id, inside: inside) }
            )
        case .graph(let graph, let source):
            SourcesGraphRow(content: .graph(graph), source: source)
        case .pendingGraph(let source):
            SourcesGraphRow(content: .pending, source: source)
        }
    }

    /// The list's one write of the selection. A plain left click that lands on a closed Source also opens
    /// it, a turn later (the write may be inside a view update) and without animation.
    private func select(_ id: String?, outline: SourcesOutline) {
        let old = navigation.listAnchor
        navigation.noteListAnchor(id)
        // The event being dispatched, unless it is stale (a selection nobody clicked).
        let event = currentEvent.read().flatMap { ProcessInfo.processInfo.systemUptime - $0.timestamp < 1 ? $0 : nil }
        guard let open = outline.sourceToOpen(
            selecting: id, from: old,
            plainLeftClick: SourcesOutline.isPlainLeftClick(type: event?.type, modifiers: event?.modifierFlags ?? []),
            onTriangle: id != nil && triangleHover.sourceID == id
        ) else { return }
        DispatchQueue.main.async { toggle([open], expanding: true, outline: outline) }
    }

    /// Opens or closes `sources`; the triangle, ⌥-click, the keys and the row's action all come here.
    private func toggle(_ sources: [String], expanding: Bool, outline: SourcesOutline) {
        outline.setExpanded(sources, expanding, session: session, navigation: navigation)
    }

    /// What a menu entry does: the row is selected first, so Back returns to it.
    private var menuActions: SourcesRowMenu.Actions {
        SourcesRowMenu.Actions(
            open: { row in
                navigation.noteListAnchor(row.id)
                if let location = SourcesListNavigation.location(for: row) { navigation.go(to: location) }
            },
            openGraph: { graph, source in
                session.setSourcesExpanded([source.id], true)
                navigation.noteListAnchor(graph.id)
                if let location = SourcesListNavigation.graphLocation(for: source, graph: graph) {
                    navigation.go(to: location)
                }
            },
            copy: { source in
                navigation.noteListAnchor(source.id)
                model.openCopy(source)
            }
        )
    }

    private func toolbar(gutter: CGFloat) -> some View {
        HStack(spacing: PVSpacing.space5) {
            searchField
            filterMenu
            statusMenu
            sortMenu
            Spacer(minLength: 0)
        }
        .padding(.horizontal, gutter)
        .padding(.vertical, PVSpacing.space6)
    }

    private var searchField: some View {
        PVInput(
            text: $model.settings.query,
            prompt: L10n.Sources.searchPrompt,
            icon: .search,
            focused: $searchFocused
        )
        .frame(minWidth: 160, maxWidth: 280)
        .accessibilityIdentifier("sources.search")
    }

    private var statusMenu: some View {
        let options = [PVSelectOption(
            value: "",
            label: L10n.string(L10n.Sources.statusAll),
            accessibilityIdentifier: "sources.status.all"
        )] + SourcesModel.EvidenceStatus.allCases.map {
            PVSelectOption(
                value: $0.rawValue,
                label: L10n.string($0.label),
                accessibilityIdentifier: "sources.status.\($0.rawValue)"
            )
        }
        return PVSelect(
            selection: Binding(
                get: { model.settings.status?.rawValue ?? "" },
                set: { model.settings.status = SourcesModel.EvidenceStatus(rawValue: $0) }
            ),
            options: options,
            icon: .network,
            menuWidth: 220,
            fillsWidth: false,
            accessibilityLabel: L10n.Sources.statusMenu,
            accessibilityIdentifier: "sources.status"
        )
    }

    private var filterMenu: some View {
        let options = [PVSelectOption(
            value: "",
            label: L10n.string(L10n.Sources.filterAllTypes),
            accessibilityIdentifier: "sources.filter.all"
        )] + model.types.map {
            PVSelectOption(
                value: $0.id,
                label: $0.label,
                accessibilityIdentifier: "sources.filter.\($0.id)"
            )
        }
        return PVSelect(
            selection: Binding(
                get: { model.effectiveTypeFilterID },
                set: { model.settings.typeFilterID = $0 }
            ),
            options: options,
            icon: .filter,
            menuWidth: 220,
            fillsWidth: false,
            accessibilityLabel: L10n.Sources.filterMenu,
            accessibilityIdentifier: "sources.filter"
        )
    }

    private var sortMenu: some View {
        let options = SourcesModel.Sort.allCases.map {
            PVSelectOption(
                value: $0.rawValue,
                label: L10n.string($0.label),
                accessibilityIdentifier: "sources.sort.\($0.rawValue)"
            )
        }
        return PVSelect(
            selection: Binding(
                get: { model.settings.sort.rawValue },
                set: { if let sort = SourcesModel.Sort(rawValue: $0) { model.settings.sort = sort } }
            ),
            options: options,
            icon: .sort,
            displayLabel: model.sortControlLabel,
            menuWidth: 240,
            fillsWidth: false,
            accessibilityLabel: L10n.Sources.sortMenu,
            accessibilityIdentifier: "sources.sort"
        )
    }
}

/// The Add Source dialog, a modifier of its own: typing in it re-evaluates this body and not the list
/// page's, which would otherwise rebuild every row on each keystroke.
private struct SourcesAddDialog: ViewModifier {
    @Environment(WorkspaceNavigation.self) private var navigation
    @Bindable var model: SourcesModel
    let typesHandle: QueryHandle<[CatalogSourceType]>

    func body(content: Content) -> some View {
        content
            .pvFormDialog(
                isPresented: presented,
                copy: PVFormDialogCopy(
                    title: L10n.Sources.addDialogTitle,
                    subtitle: L10n.Sources.addDialogSubtitle,
                    confirm: L10n.Sources.createAction,
                    cancel: L10n.Sources.cancelAction
                ),
                isRunning: model.isSaving,
                isDirty: model.addSheetIsDirty,
                confirmDisabled: !model.canSubmitAdd,
                accessibilityIdentifierPrefix: "sources.add",
                onConfirm: {
                    Task {
                        if let created = await model.create() {
                            navigation.go(to: SourcesListNavigation.pageLocation(for: created))
                        }
                    }
                }
            ) {
                form
            }
            .task(id: model.isAdding) {
                guard model.isAdding else { return }
                model.refreshTypes()
                model.selectSoleTypeIfNeeded()
            }
            .onChange(of: typesHandle.status) { _, _ in
                if model.isAdding { model.selectSoleTypeIfNeeded() }
            }
    }

    private var presented: Binding<Bool> {
        Binding(
            get: { model.isAdding },
            set: { presented in
                if presented {
                    model.openAdd()
                } else {
                    model.cancelAdd()
                }
            }
        )
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if let createError = model.createError {
                PVCallout(tone: .danger, message: createError)
                    .accessibilityIdentifier("sources.add.error")
            } else if let loadError = model.loadError, model.types.isEmpty {
                PVCallout(
                    tone: .danger,
                    message: L10n.Errors.message(for: loadError)
                )
                .accessibilityIdentifier("sources.add.loadError")
            }
            SourceTitleTypeFields(
                draft: $model.draft,
                titleError: $model.titleError,
                typeError: $model.typeError,
                types: model.types,
                accessibilityIdentifierPrefix: "sources.add"
            )
            PVField(
                label: L10n.Sources.formDescription,
                hint: L10n.Sources.formDescriptionHint
            ) {
                PVInput(text: $model.draft.description)
                    .accessibilityIdentifier("sources.add.description")
            }
        }
    }
}

/// The Source whose triangle the pointer is on, if any. A plain class, not observable: only the
/// selection write reads it, so the rows never redraw for it.
final class SourcesTriangleHover {
    private(set) var sourceID: String?

    func note(_ id: String, inside: Bool) {
        if inside { sourceID = id } else if sourceID == id { sourceID = nil }
    }
}

extension EnvironmentValues {
    /// The event the application is dispatching: what the Sources list reads to tell a click from a key.
    /// A hosted test replaces it, since a window that is never shown is sent no real events.
    @Entry var sourcesCurrentEvent = SourcesEventSource.live
}

/// Where the Sources list reads the event being dispatched.
final class SourcesEventSource: Sendable {
    let read: @MainActor @Sendable () -> NSEvent?

    init(_ read: @escaping @MainActor @Sendable () -> NSEvent?) { self.read = read }

    static let live = SourcesEventSource { NSApp.currentEvent }
}
