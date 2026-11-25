import SwiftUI

/// Fixtures for the Sources list's previews: three Sources over a `FakeStore`, the first with eight
/// Evidence graphs (one links no Artifact), and the page's states built by changing what the store does.
@MainActor
enum SourcesListPreviews {
    static let projectDir = "/tmp/preview.provenencia"
    static let userID = "00000000-0000-7000-8000-000000000001"
    static let width: CGFloat = 1102
    static let wideWidth: CGFloat = 2296

    static func store() -> FakeStore {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: "")
        ]
        func source(_ id: String, _ title: String) -> CatalogSource {
            CatalogSource(
                id: id, ref: "SRC-\(id.uppercased())", sourceTypeID: "t1", title: title, description: "",
                date: CatalogDateValueInput(kind: "point", startYear: 1851),
                updated: CatalogActivity(revision: 1, at: "2026-11-21T10:00:00Z"),
                createdAt: "2026-11-19T10:00:00Z"
            )
        }
        store.sourcesByProject[projectDir] = [
            source("s3", "Passport of J. Robins"),
            source("s2", "1851 Census, Robins household"),
            source("s1", "Parish register, Lyon"),
        ]
        for id in ["s1", "s2"] {
            store.artifactsBySource[id] = [CatalogArtifact(
                id: "a-\(id)", ref: "ART-AAAAA", sourceID: id, fileID: "", label: "Scan", description: "", file: nil
            )]
        }
        store.evidenceGraphsByProject[projectDir] = (0 ..< 8).map { index in
            CatalogEvidenceGraph(
                id: "g1-\(index)", ref: "GPH-\(index)", sourceID: "s1", name: "Household of Jean Robins, Lyon, \(index)",
                description: "", artifactIDs: index == 3 ? [] : ["a-s1"]
            )
        } + [CatalogEvidenceGraph(
            id: "g2-0", ref: "GPH-20", sourceID: "s2", name: "Default", description: "", artifactIDs: ["a-s2"]
        )]
        store.graphProgressByGraph["g1-0"] = EvidenceGraphProgress(graphId: "g1-0", subjectCount: 12, observationCount: 40)
        store.graphProgressByGraph["g1-1"] = EvidenceGraphProgress(
            graphId: "g1-1", subjectCount: 5, observationCount: 17, filedCount: 2
        )
        return store
    }

    /// The whole page, over a store `configure` has changed, with the Source `open` open and a
    /// saved status filter when `status` is set.
    static func page(
        paneWidth: CGFloat = width,
        open: String? = nil,
        status: SourcesModel.EvidenceStatus? = nil,
        configure: (FakeStore) -> Void = { _ in }
    ) -> some View {
        let store = store()
        configure(store)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setOpenSource(open)
        let projectUuid = UUID().uuidString
        if let status {
            var settings = SourcesListSettings()
            settings.status = status
            SourcesListSettingsStore(projectUuid: projectUuid, userID: userID)?.save(settings)
        }
        return SourcesListView(session: session, userID: userID, projectUuid: projectUuid, store: store)
            .environment(session)
            .environment(WorkspaceNavigation())
            .environment(\.pvWidthClass, PVWidthClass(paneWidth: paneWidth))
            .frame(width: paneWidth, height: 640)
    }

    /// The table's rows as the page draws them: Source rows with each badge, an open Source with its
    /// graphs (one links no Artifact), and one row selected (`selected`, the system's bar, focused).
    static func table(paneWidth: CGFloat = width, selected: String? = nil) -> some View {
        let store = store()
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setOpenSource("s1")
        let model = SourcesModel(session: session, userID: userID, store: store)
        return SourcesTablePreview(model: model, session: session, paneWidth: paneWidth, selected: selected)
            .task { model.warmListQueries() }
    }

    struct Failure: Error, LocalizedError {
        var errorDescription: String? { "The catalog could not be read." }
    }
}

#Preview("Closed Sources, one with no Artifact") {
    SourcesListPreviews.page()
}

#Preview("An open Source: eight graphs, one with no Artifact") {
    SourcesListPreviews.page(open: "s1")
}

#Preview("Open Source, counts loading") {
    SourcesListPreviews.page(open: "s1") { $0.listEvidenceGraphProgressHold.isOn = true }
}

#Preview("Open Source, counts failed") {
    SourcesListPreviews.page(open: "s1") { $0.listEvidenceGraphProgressError = SourcesListPreviews.Failure() }
}

#Preview("Graph list failed, no status filter") {
    SourcesListPreviews.page { $0.listEvidenceGraphsError = SourcesListPreviews.Failure() }
}

#Preview("Graph list failed, status filter set") {
    SourcesListPreviews.page(status: .inProgress) { $0.listEvidenceGraphsError = SourcesListPreviews.Failure() }
}

#Preview("Counts failed, status filter set") {
    SourcesListPreviews.page(status: .inProgress) { $0.listEvidenceGraphProgressError = SourcesListPreviews.Failure() }
}

#Preview("Whole list failure") {
    SourcesListPreviews.page { $0.listSourcesError = SourcesListPreviews.Failure() }
}

#Preview("Wide: an open Source") {
    SourcesListPreviews.page(paneWidth: SourcesListPreviews.wideWidth, open: "s1")
}

#Preview("Rows: badges, graphs, one selected") {
    SourcesListPreviews.table(selected: "s2")
}

#Preview("Rows, Wide, a graph selected") {
    SourcesListPreviews.table(paneWidth: SourcesListPreviews.wideWidth, selected: "g1-1")
}

/// The table over a model that reads its outline as the lists arrive.
private struct SourcesTablePreview: View {
    let model: SourcesModel
    let session: WorkspaceSession
    let paneWidth: CGFloat
    let selected: String?

    var body: some View {
        let widthClass = PVWidthClass(paneWidth: paneWidth)
        SourcesTable(items: model.outline.items, selection: .constant(selected), model: model)
            .padding(.horizontal, SourcesTable.inset(gutter: widthClass.fullPaneGutter))
            .frame(width: paneWidth, height: 640)
            .background(PVColor.surfaceCard)
            .environment(session)
            .environment(\.pvWidthClass, widthClass)
    }
}
