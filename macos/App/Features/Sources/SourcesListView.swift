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
                // The handles arrive a turn after the page: the frame and its skeleton hold the place.
                PVListPage(
                    title: L10n.Workspace.sourcesTitle, description: L10n.Sources.description,
                    countLine: nil, identifierRoot: "sources"
                ) { gutter in
                    PVListPageArea.loadingArea(
                        gutter: gutter,
                        detailWidths: SourcesRowColumns.details(isWide: widthClass == .wide, typeLabel: { _ in "" }).map(\.width)
                    )
                }
            }
        }
        .task {
            model.warmListQueries()
        }
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

    var body: some View {
        let outline = model.outline
        let showsToolbar = model.showsToolbar
        return PVListPage(
            title: L10n.Workspace.sourcesTitle,
            description: L10n.Sources.description,
            countLine: showsToolbar ? model.countLine(visibleCount: model.visibleSources.count) : nil,
            add: .init(label: L10n.Sources.addSource) { model.openAdd() },
            identifierRoot: "sources",
            showsToolbar: showsToolbar,
            toolbar: { gutter in toolbar(gutter: gutter) },
            content: { gutter in content(outline: outline, gutter: gutter) }
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
        .pvFormDialog(
            isPresented: addPresented,
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
            addForm
        }
        .sourceCopyDialog($model.copying)
        .task(id: model.isAdding) {
            guard model.isAdding else { return }
            model.refreshTypes()
            model.selectSoleTypeIfNeeded()
        }
        .onChange(of: typesHandle.status) { _, _ in
            if model.isAdding { model.selectSoleTypeIfNeeded() }
        }
        .onChange(of: model.settings) { _, _ in
            // A sort or filter change clears the selection and puts the list at its top; the open
            // Sources stay open.
            navigation.go(to: navigation.currentLocation.withListScrollAnchor(nil))
        }
        .accessibilityIdentifier("sources")
    }

    // MARK: The list area

    /// The list area's states, in the order they win: the whole list failed, first load, an empty
    /// catalog, a failure of the data a status filter needs, waiting for the graph list or a filter's
    /// data, no match, then the rows.
    @ViewBuilder
    private func content(outline: SourcesOutline, gutter: CGFloat) -> some View {
        if let loadError = model.loadError, model.sources.isEmpty {
            PVListPageArea.failureArea(L10n.Errors.message(for: loadError), gutter: gutter)
                .accessibilityIdentifier("sources.loadError")
        } else if sourcesHandle.value == nil {
            loadingArea(gutter: gutter)
        } else if model.isCatalogEmpty {
            emptyArea
        } else if let statusError = model.statusCountsError {
            PVListPageArea.failureArea(L10n.Errors.message(for: statusError), gutter: gutter)
                .accessibilityIdentifier("sources.statusError")
        } else if model.isAwaitingGraphList || model.isAwaitingFilterData {
            loadingArea(gutter: gutter)
        } else if outline.rows.isEmpty {
            noMatchArea
        } else {
            rows(outline: outline, gutter: gutter)
        }
    }

    private func loadingArea(gutter: CGFloat) -> some View {
        PVListPageArea.loadingArea(
            gutter: gutter,
            detailWidths: SourcesRowColumns.details(isWide: widthClass == .wide, typeLabel: { _ in "" }).map(\.width)
        )
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

    private func rows(outline: SourcesOutline, gutter: CGFloat) -> some View {
        VStack(spacing: 0) {
            if let graphListError = model.graphListError {
                PVCallout(tone: .danger, message: L10n.Errors.message(for: graphListError))
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
                    set: { navigation.noteListAnchor($0) }
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
                restartKey: model.settings
            ) { row in
                outlineRow(row, outline: outline)
            }
            .onKeyPress(keys: [.rightArrow, .leftArrow], phases: .down) { press in
                handle(press.key, outline: outline)
            }
        }
    }

    /// → opens a closed Source, ← closes an open one or climbs from a graph row to its Source.
    private func handle(_ key: KeyEquivalent, outline: SourcesOutline) -> KeyPress.Result {
        switch SourcesOutline.keyAction(key, selected: outline.row(id: navigation.listAnchor)) {
        case .expand(let id):
            toggle(id, expanding: true, sources: [id], outline: outline)
        case .collapse(let id):
            toggle(id, expanding: false, sources: [id], outline: outline)
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
                        source.id, expanding: disclosure != .expanded,
                        sources: all ? outline.togglableSourceIDs : [source.id], outline: outline
                    )
                }
            )
        case .graph(let graph, let source):
            SourcesGraphRow(content: .graph(graph), source: source)
        case .pendingGraph(let source):
            SourcesGraphRow(content: .pending, source: source)
        }
    }

    /// Opens or closes `sources`. Closing a Source whose graph is selected selects the Source first.
    private func toggle(_ id: String, expanding: Bool, sources: [String], outline: SourcesOutline) {
        if !expanding {
            let selection = outline.selectionAfterCollapsing(Set(sources), selection: navigation.listAnchor)
            if selection != navigation.listAnchor { navigation.noteListAnchor(selection) }
        }
        session.setSourcesExpanded(sources, expanding)
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

    private var addPresented: Binding<Bool> {
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
            icon: .search
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

    private var addForm: some View {
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
