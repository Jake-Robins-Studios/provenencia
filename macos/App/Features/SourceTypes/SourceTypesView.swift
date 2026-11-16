import SwiftUI

/// The **Source types** list (S2-03 board / S2-16 PR): browse the project's `source_types`
/// vocabulary and add a type. A row opens the type's own page (`SourceTypePageView`).
struct SourceTypesView: View {
    @Environment(WorkspaceSession.self) private var session
    @State private var model: SourceTypesModel

    init(
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore
    ) {
        _model = State(
            initialValue: SourceTypesModel(
                session: session,
                userID: userID,
                store: store
            )
        )
    }

    var body: some View {
        Group {
            if let typesHandle = session.sourceTypesHandle {
                SourceTypesContent(
                    typesHandle: typesHandle,
                    model: model
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            model.warmListQueries()
        }
    }
}

private struct SourceTypesContent: View {
    @Bindable var typesHandle: QueryHandle<[CatalogSourceType]>
    @Bindable var model: SourceTypesModel
    @Environment(\.pvWidthClass) private var widthClass

    var body: some View {
        VStack(spacing: 0) {
            header
            PVDivider()
            if let loadError = model.loadError, model.types.isEmpty {
                PVCallout(tone: .danger, message: L10n.Errors.message(for: loadError), announces: true)
                    .padding(.horizontal, PVSpacing.gutterPage)
                    .padding(.top, PVSpacing.space8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .accessibilityIdentifier("sourceTypes.loadError")
            } else {
                SourceTypesListPane(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pvListBand(widthClass)
        .background(PVColor.surfacePage)
        .sourceTypeAddDialog($model.adding)
        .accessibilityIdentifier("sourceTypes")
    }

    private var header: some View {
        VocabularyHeader(
            title: L10n.Workspace.sourceTypesTitle,
            description: L10n.SourceTypes.description,
            countLine: model.countLine,
            addLabel: L10n.SourceTypes.addType,
            isAddDisabled: model.isAdding,
            identifierPrefix: "sourceTypes",
            onAdd: { model.openAdd() }
        )
    }
}

#if DEBUG
#Preview {
    let store = FakeStore()
    let projectDir = "/tmp/preview.provenencia"
    store.fieldsByProject[projectDir] = [
        CatalogMetadataField(id: "f1", key: "author", origin: CatalogOrigin.provenencia, label: "Author", dataType: "text", description: "Person or body responsible for the content."),
        CatalogMetadataField(id: "f2", key: "publication-date", origin: CatalogOrigin.provenencia, label: "Publication date", dataType: "date", description: "Date the source was published."),
        CatalogMetadataField(id: "f3", key: "publisher", origin: CatalogOrigin.provenencia, label: "Publisher", dataType: "text", description: "Who issued it."),
        CatalogMetadataField(id: "f4", key: "grandmas-album-code", origin: "user", label: "Grandma's album code", dataType: "text", description: "Pencil code on the back of prints."),
    ]
    store.sourceTypesByProject[projectDir] = [
        CatalogSourceType(id: "t1", key: "photograph", origin: CatalogOrigin.provenencia, label: "Photograph", description: "A photographic image of people, places or objects.", usedBy: 41),
        CatalogSourceType(id: "t2", key: "book", origin: CatalogOrigin.provenencia, label: "Book", description: "A published monograph.", usedBy: 18),
        CatalogSourceType(id: "t3", key: "letter", origin: CatalogOrigin.provenencia, label: "Letter", description: "Private correspondence.", usedBy: 0),
        CatalogSourceType(id: "t4", key: "family-scrapbook", origin: "user", label: "Family scrapbook", description: "Nan's albums.", usedBy: 3),
        CatalogSourceType(id: "t5", key: "grave-memorial", origin: "plugin:findagrave", label: "Grave memorial", description: "A memorial page.", usedBy: 5),
    ]
    store.suggestionsByLevel[.source] = ["t2": [
        CatalogTypeSuggestion(field: store.fieldsByProject[projectDir]![0], sortOrder: 0),
        CatalogTypeSuggestion(field: store.fieldsByProject[projectDir]![2], sortOrder: 1),
        CatalogTypeSuggestion(field: store.fieldsByProject[projectDir]![1], sortOrder: 2),
    ], "t4": [
        CatalogTypeSuggestion(field: store.fieldsByProject[projectDir]![3], sortOrder: 0),
    ]]
    store.suggestedFieldCounts = ["t2": 3, "t4": 1]
    let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    return SourceTypesView(
        session: session,
        userID: "00000000-0000-7000-8000-000000000001",
        store: store
    )
    .environment(WorkspaceNavigation())
    .environment(session)
    .frame(width: 1180, height: 760)
}
#endif
