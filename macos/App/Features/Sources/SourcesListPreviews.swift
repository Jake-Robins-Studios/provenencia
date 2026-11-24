import SwiftUI

/// Fixtures for the Sources list's previews: three Sources over a `FakeStore`, the first with eight
/// Evidence graphs (one links no Artifact), and the page's states built by changing what the store does.
@MainActor
enum SourcesListPreviews {
    static let projectDir = "/tmp/preview.provenencia"
    static let userID = "00000000-0000-7000-8000-000000000001"
    static let width: CGFloat = 1102

    static func store() -> FakeStore {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "census", origin: "provenencia", label: "Census", description: "")
        ]
        func source(_ id: String, _ title: String) -> CatalogSource {
            CatalogSource(
                id: id, ref: "SRC-\(id.uppercased())", sourceTypeID: "t1", title: title, description: "",
                date: CatalogDateValueInput(kind: "point", startYear: 1851),
                updated: CatalogActivity(revision: 1, at: "2026-11-21T10:00:00Z")
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

    /// The whole page at the Wide width, over a store `configure` has changed, with `expanded` Sources
    /// open and a saved status filter when `status` is set.
    static func page(
        expanded: [String] = [],
        status: SourcesModel.EvidenceStatus? = nil,
        configure: (FakeStore) -> Void = { _ in }
    ) -> some View {
        let store = store()
        configure(store)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setSourcesExpanded(expanded, true)
        let projectUuid = UUID().uuidString
        if let status {
            var settings = SourcesListSettings()
            settings.status = status
            SourcesListSettingsStore(projectUuid: projectUuid, userID: userID)?.save(settings)
        }
        return SourcesListView(session: session, userID: userID, projectUuid: projectUuid, store: store)
            .environment(session)
            .environment(WorkspaceNavigation())
            .environment(\.pvWidthClass, PVWidthClass(paneWidth: width))
            .frame(width: width, height: 640)
    }

    /// A Source's graph rows as the list draws them, one per count state, then the placeholder.
    static func graphRows(selected: Bool = false) -> some View {
        let store = store()
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.setSourcesExpanded(["s1"], true)
        let source = store.sourcesByProject[projectDir]?.last ?? CatalogSource(
            id: "s1", ref: "SRC-S1", sourceTypeID: "t1", title: "", description: "",
            updated: CatalogActivity(revision: 1)
        )
        let graphs = store.evidenceGraphsByProject[projectDir] ?? []
        return VStack(spacing: 0) {
            ForEach(Array(graphs.prefix(4)), id: \.id) { graph in
                SourcesGraphRow(content: .graph(graph), source: source)
            }
            SourcesGraphRow(content: .pending, source: source)
        }
        .padding(.horizontal, 32)
        .frame(width: width)
        .background(selected ? Color.accentColor : PVColor.surfaceCard)
        .environment(\.backgroundProminence, selected ? .increased : .standard)
        .environment(session)
        .task { _ = session.query(session.evidenceGraphsKey) as QueryHandle<[CatalogEvidenceGraph]> }
        .task { _ = session.query(session.evidenceGraphProgressKey) as QueryHandle<[String: EvidenceGraphProgress]> }
    }

    struct Failure: Error, LocalizedError {
        var errorDescription: String? { "The catalog could not be read." }
    }
}

#Preview("Closed Sources, one with no Artifact") {
    SourcesListPreviews.page()
}

#Preview("An open Source: eight graphs, one with no Artifact") {
    SourcesListPreviews.page(expanded: ["s1"])
}

#Preview("Open Source, counts loading") {
    SourcesListPreviews.page(expanded: ["s1"]) { $0.listEvidenceGraphProgressHold.isOn = true }
}

#Preview("Open Source, counts failed") {
    SourcesListPreviews.page(expanded: ["s1"]) { $0.listEvidenceGraphProgressError = SourcesListPreviews.Failure() }
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

#Preview("Graph rows: counts, no Artifact, placeholder") {
    SourcesListPreviews.graphRows()
}

#Preview("Graph rows, selected") {
    SourcesListPreviews.graphRows(selected: true)
}
