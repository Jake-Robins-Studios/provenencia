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
                    content: { gutter in SourcesListLoadingArea(model: model, gutter: gutter) }
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

/// The table's header over skeleton rows in their columns, for the width class: inert, so a row does not
/// shift when its cells arrive.
private struct SourcesListLoadingArea: View {
    let model: SourcesModel
    let gutter: CGFloat
    @Environment(\.pvWidthClass) private var widthClass

    var body: some View {
        SourcesTable(
            items: SourcesTableItem.skeletons, selection: .constant(nil), model: model,
            isWide: widthClass == .wide, gutter: gutter, isLoading: true
        )
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
    @Environment(\.sourcesCurrentEvent) private var currentEvent
    /// The list has taken the keyboard once, the search field has had it, or the settings changed: the
    /// list leaves focus where it is when its rows come back (a search that matched nothing, then did).
    @State private var listLeavesFocusAlone = false
    /// Which triangle the pointer is on and which row the last click pressed, for `select` and a
    /// double-click. Not observed: no view reads it to draw.
    @State private var pointer = SourcesPointer()
    /// The Source that last opened and the count of its scroll requests: an open closes the Source
    /// above it, so the rows move, and its row is scrolled back into view.
    @State private var openedSourceID: String?
    @State private var openedRequest = 0
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
                outline.setOpen(id, selecting: anchor, session: session, navigation: navigation)
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
            // Source stays open.
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
            SourcesListLoadingArea(model: model, gutter: gutter)
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
            // Navigation owns the selected row: it is the row history stamps on leaving.
            let selection = Binding(
                get: { navigation.listAnchor },
                set: { select($0, outline: outline) }
            )
            SourcesTable(
                items: outline.items, selection: selection, model: model,
                isWide: widthClass == .wide, gutter: gutter,
                toggle: { source, disclosure in
                    apply(disclosure == .expanded ? .collapse(source.id) : .expand(source.id), outline: outline)
                },
                hoverTriangle: { id, inside in pointer.note(id, inside: inside) }
            )
            .pvNativeListBehavior(
                ids: outline.rows.map(\.id),
                selection: selection,
                // The table adds its cell padding to this: a graph row is 26 + 8 pt, the wheel's step.
                minimumRowHeight: SourcesTable.graphRowHeight,
                label: L10n.Workspace.sourcesTitle,
                onActivate: { id in activate(id, outline: outline) },
                menu: { id in
                    guard let row = outline.row(id: id) else { return [] }
                    return SourcesRowMenu.items(
                        for: row, graphs: session.evidenceGraphsRead(sourceID: row.source.id),
                        actions: menuActions(outline: outline)
                    )
                },
                restartKey: model.settings,
                claimsFocus: !listLeavesFocusAlone
            )
            .pvScrollsRowIntoView(openedSourceID, animated: false, whenRequested: openedRequest)
            .onKeyPress(keys: [.rightArrow, .leftArrow], phases: .down) { press in
                handle(press.key, outline: outline)
            }
            .onAppear { listLeavesFocusAlone = true }
        }
    }

    /// → opens a closed Source, ← closes an open one or climbs from a graph row to its Source.
    private func handle(_ key: KeyEquivalent, outline: SourcesOutline) -> KeyPress.Result {
        let action = SourcesOutline.keyAction(key, selected: outline.row(id: navigation.listAnchor))
        guard action != .ignore else { return .ignored }
        apply(action, outline: outline)
        return .handled
    }

    /// Runs what a key or a click decided: the open Source and the selection move together.
    private func apply(_ action: SourcesOutlineAction, selecting: String? = nil, outline: SourcesOutline) {
        switch action {
        case .expand(let id):
            outline.setOpen(id, selecting: selecting, session: session, navigation: navigation)
            // The Source above it may have closed: the rows moved, a turn later this one is in view.
            openedSourceID = id
            openedRequest += 1
        case .collapse:
            outline.setOpen(nil, selecting: selecting, session: session, navigation: navigation)
        case .select(let id):
            navigation.noteListAnchor(id)
        case .ignore:
            break
        }
    }

    /// The write the platform list makes when its selection changes. A plain left click that lands on a
    /// Source row also opens it (or closes the open one when it has no triangle), a turn later (the write
    /// may be inside a view update) and without animation. The second press of a double-click changes
    /// nothing: the first press may have moved rows (opening a Source closes the one above), so the second
    /// lands on another row, and the double-click is still the first row's (`activate`). A second press
    /// that lands on no row writes nil and no double action follows: the first row opens here.
    private func select(_ id: String?, outline: SourcesOutline) {
        // The event being dispatched; `isPlainLeftClick` rejects a stale one (a selection nobody clicked).
        let event = currentEvent.read()
        let old = navigation.listAnchor
        if let first = secondPressRow(event, selected: old) {
            if id == nil, outline.row(id: first) != nil {
                pointer.consumePress()
                DispatchQueue.main.async { open(first, outline: outline) }
            }
            return
        }
        navigation.noteListAnchor(id)
        let age = event.map { ProcessInfo.processInfo.systemUptime - $0.timestamp } ?? 0
        let isPlainClick = SourcesOutline.isPlainLeftClick(
            type: event?.type, modifiers: event?.modifierFlags ?? [], age: age
        )
        if let event, event.type == .leftMouseDown || event.type == .leftMouseUp, event.clickCount == 1 {
            if isPlainClick, let id, id != old {
                pointer.notePress(id)
            } else {
                pointer.consumePress()
            }
        }
        let action = outline.clickAction(
            selecting: id, from: old, isPlainClick: isPlainClick,
            onTriangle: id != nil && pointer.sourceID == id
        )
        guard action != .ignore else { return }
        DispatchQueue.main.async { apply(action, selecting: id, outline: outline) }
    }

    /// The row a left-button press of `event` is the second press of a double-click on, if any: the row
    /// first pressed, while it is still `selected`.
    private func secondPressRow(_ event: NSEvent?, selected: String?) -> String? {
        guard let event, event.type == .leftMouseDown || event.type == .leftMouseUp else { return nil }
        return pointer.rowForSecondPress(
            clickCount: event.clickCount, selected: selected,
            age: ProcessInfo.processInfo.systemUptime - event.timestamp
        )
    }

    /// Opens the row: its page, or its graph's canvas. A double-click opens the row first pressed, when
    /// the outline still has it, not the row the second press landed on, and consumes the press so it
    /// opens once. Return and the menu never match.
    private func activate(_ id: String, outline: SourcesOutline) {
        var target = id
        if let first = secondPressRow(currentEvent.read(), selected: navigation.listAnchor),
           outline.row(id: first) != nil {
            target = first
            pointer.consumePress()
        }
        open(target, outline: outline)
    }

    private func open(_ id: String, outline: SourcesOutline) {
        if let row = outline.row(id: id), let location = SourcesListNavigation.location(for: row) {
            navigation.go(to: location)
        }
    }

    /// What a menu entry does: the row is selected first, so Back returns to it.
    private func menuActions(outline: SourcesOutline) -> SourcesRowMenu.Actions {
        SourcesRowMenu.Actions(
            open: { row in
                navigation.noteListAnchor(row.id)
                if let location = SourcesListNavigation.location(for: row) { navigation.go(to: location) }
            },
            openGraph: { graph, source in
                outline.setOpen(source.id, selecting: graph.id, session: session, navigation: navigation)
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

/// What the pointer did on the Sources list: the Source whose triangle it is on, and the row of the last
/// plain click's first press. A plain class, not observable: only the selection write and the open action
/// read it, so the rows never redraw for it.
final class SourcesPointer {
    private(set) var sourceID: String?
    private var pressed: String?

    func note(_ id: String, inside: Bool) {
        if inside { sourceID = id } else if sourceID == id { sourceID = nil }
    }

    /// Records the row a plain click's first press (`clickCount` 1) selected.
    func notePress(_ id: String) {
        pressed = id
    }

    /// Forgets the first press: it has opened its row, or a first press that records nothing came after it.
    func consumePress() {
        pressed = nil
    }

    /// The row a press is the second of a double-click on: the row first pressed, when the press has
    /// `clickCount` 2 or more, is under `SourcesOutline.clickMaximumAge` old, and that row is still the
    /// selection (`selected`: the first press's own write, not yet replaced by the second's). Nil otherwise.
    func rowForSecondPress(clickCount: Int, selected: String?, age: TimeInterval) -> String? {
        guard clickCount >= 2, age < SourcesOutline.clickMaximumAge, let pressed, pressed == selected else { return nil }
        return pressed
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
