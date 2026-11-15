import Foundation

/// The graph list indexed for reads: by graph id and grouped by Source, each
/// Source's graphs in list order (sorted by name), plus the Artifact ids each
/// Source's graphs link. Built from one value of the graph list.
struct EvidenceGraphIndex {
    let byID: [String: CatalogEvidenceGraph]
    let bySource: [String: [CatalogEvidenceGraph]]
    let linkedArtifactIDsBySource: [String: Set<String>]

    init(rows: [CatalogEvidenceGraph]) {
        byID = Dictionary(rows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        bySource = Dictionary(grouping: rows, by: \.sourceID)
        linkedArtifactIDsBySource = bySource.mapValues { Set($0.flatMap(\.artifactIDs)) }
    }

    private init(
        byID: [String: CatalogEvidenceGraph],
        bySource: [String: [CatalogEvidenceGraph]],
        linkedArtifactIDsBySource: [String: Set<String>]
    ) {
        self.byID = byID
        self.bySource = bySource
        self.linkedArtifactIDsBySource = linkedArtifactIDsBySource
    }

    /// The index after each given Source's graphs were replaced by the listed
    /// ones (in that order); no other Source is touched.
    func replacing(sources: [String: [CatalogEvidenceGraph]]) -> EvidenceGraphIndex {
        var byID = byID
        var bySource = bySource
        var linked = linkedArtifactIDsBySource
        for (sourceID, graphs) in sources {
            for old in bySource[sourceID] ?? [] {
                byID[old.id] = nil
            }
            for graph in graphs where byID[graph.id] == nil {
                byID[graph.id] = graph
            }
            bySource[sourceID] = graphs.isEmpty ? nil : graphs
            linked[sourceID] = graphs.isEmpty ? nil : Set(graphs.flatMap(\.artifactIDs))
        }
        return EvidenceGraphIndex(byID: byID, bySource: bySource, linkedArtifactIDsBySource: linked)
    }
}

/// Whether the graph list has a graph; see `CatalogRowPresence`.
typealias EvidenceGraphPresence = CatalogRowPresence<CatalogEvidenceGraph>

/// The session's cached Evidence graph list and graph progress: the one place
/// their keys and handles are looked up, and the graph's linked Artifacts read
/// from them.
extension WorkspaceSession {
    var evidenceGraphsKey: CatalogQueryKey { .evidenceGraphsList(project: projectKey) }

    var evidenceGraphsHandle: QueryHandle<[CatalogEvidenceGraph]>? {
        queryHandle(evidenceGraphsKey)
    }

    var evidenceGraphProgressKey: CatalogQueryKey { .evidenceGraphProgress(project: projectKey) }

    var evidenceGraphProgressHandle: QueryHandle<[String: EvidenceGraphProgress]>? {
        queryHandle(evidenceGraphProgressKey)
    }

    /// The counts of one Evidence graph, by graph id; `nil` while the progress
    /// map has no value or omits the graph (Go omits a graph with zero counts).
    func evidenceGraphProgress(graphID: String) -> EvidenceGraphProgress? {
        evidenceGraphProgressHandle?.value?[graphID]
    }

    /// True while the progress map or the graph list is missing or still
    /// loading, so a graph's counts can still arrive.
    var evidenceGraphCountsLoading: Bool {
        guard let progress = evidenceGraphProgressHandle, let graphs = evidenceGraphsHandle else { return true }
        return progress.read.isLoading || graphs.read.isLoading
    }

    /// The progress map's failure while it has no value to show; `nil` otherwise.
    var evidenceGraphCountsError: Error? {
        if case .failed(let error) = evidenceGraphProgressHandle?.read { return error }
        return nil
    }

    /// The Artifacts of `artifacts` that the graph links, in `artifacts` order.
    /// `nil` while the graph list has no value; empty when the list has no graph
    /// with that id.
    func linkedArtifacts(graphID: String, artifacts: [CatalogArtifact]) -> [CatalogArtifact]? {
        guard evidenceGraphsHandle?.value != nil else { return nil }
        return evidenceGraph(id: graphID)?.linkedArtifacts(artifacts) ?? []
    }

    /// The index of the list's current value, rebuilt only when the list moved;
    /// `nil` while the list has no value.
    private var currentEvidenceGraphIndex: EvidenceGraphIndex? {
        guard let rows = evidenceGraphsHandle?.value else { return nil }
        return derived(.evidenceGraphIndex, inputs: [.key(evidenceGraphsKey)]) {
            EvidenceGraphIndex(rows: rows)
        }
    }

    /// Carries the stored index across a merged re-read of some Sources'
    /// graphs: when the index was current just before the merge and the merge
    /// was the handle's only revision move, the index takes those Sources'
    /// graphs in place. Otherwise nothing happens and the next read builds in
    /// full.
    func spliceEvidenceGraphIndex(_ parts: [String: [CatalogEvidenceGraph]], previousRevision: Int) {
        carryDerived(.evidenceGraphIndex, across: evidenceGraphsKey, from: previousRevision) { (index: EvidenceGraphIndex) in
            index.replacing(sources: parts)
        }
    }

    /// One graph by id; `nil` while the graph list has no value or has no such graph.
    func evidenceGraph(id: String) -> CatalogEvidenceGraph? {
        currentEvidenceGraphIndex?.byID[id]
    }

    /// Whether the graph list has graph `id`; see `EvidenceGraphPresence`.
    func evidenceGraphPresence(id: String) -> EvidenceGraphPresence {
        .of(evidenceGraph(id: id), in: evidenceGraphsHandle)
    }

    /// One Source's graphs in list order (sorted by name); `nil` while the graph
    /// list has no value.
    func evidenceGraphs(sourceID: String) -> [CatalogEvidenceGraph]? {
        guard let index = currentEvidenceGraphIndex else { return nil }
        return index.bySource[sourceID] ?? []
    }

    /// The whole list grouped by Source, each Source's graphs in list order;
    /// empty while the list has no value.
    var evidenceGraphsBySource: [String: [CatalogEvidenceGraph]] {
        currentEvidenceGraphIndex?.bySource ?? [:]
    }

    /// One Source's graphs as a read. A loaded list with no graph for the
    /// Source reads `.loading`: every Source has a Default graph from creation,
    /// so that is a list not yet refreshed.
    func evidenceGraphsRead(sourceID: String) -> QueryRead<[CatalogEvidenceGraph]> {
        guard let handle = evidenceGraphsHandle else { return .loading }
        switch handle.read {
        case .loading: return .loading
        case .failed(let error): return .failed(error)
        case .loaded:
            guard let graphs = evidenceGraphs(sourceID: sourceID), !graphs.isEmpty else { return .loading }
            return .loaded(graphs)
        }
    }

    /// The ids of `artifactIDs` that none of the Source's graphs links. `nil`
    /// unless the Source's graphs are loaded (`evidenceGraphsRead`) and the list
    /// has settled, so a list not yet refreshed, or refetching after a write,
    /// marks nothing.
    func artifactIDsInNoGraph(sourceID: String, artifactIDs: [String]) -> Set<String>? {
        guard evidenceGraphsHandle?.isSettled == true,
              case .loaded = evidenceGraphsRead(sourceID: sourceID),
              let index = currentEvidenceGraphIndex
        else { return nil }
        let linked = index.linkedArtifactIDsBySource[sourceID] ?? []
        return Set(artifactIDs.filter { !linked.contains($0) })
    }

    /// The three reads one graph's snapshot is built from: its rows, the
    /// Subject types and the connect rules.
    private func evidenceGraphSnapshotKeys(graphID: String) -> [CatalogQueryKey] {
        [
            .evidenceGraph(project: projectKey, graphId: graphID),
            .propertiesWorkspace(project: projectKey),
            .connectRules(project: projectKey),
        ]
    }

    /// One graph as a snapshot, built once per change of its rows, the Subject
    /// types and the connect rules. Neither loads nor waits: rows not read yet
    /// are empty, and missing types or rules read as empty.
    func cachedEvidenceGraphSnapshot(graphID: String) -> EvidenceGraphSnapshot {
        let keys = evidenceGraphSnapshotKeys(graphID: graphID)
        return derived(.evidenceGraphSnapshot(graphID: graphID), inputs: keys.map(DerivedInput.key)) {
            let rows: QueryHandle<EvidenceGraphRows>? = queryHandle(keys[0])
            let properties: QueryHandle<PropertiesSnapshot>? = queryHandle(keys[1])
            let rules: QueryHandle<[CatalogConnectRule]>? = queryHandle(keys[2])
            return EvidenceGraphSnapshot.build(
                rows: rows?.value ?? EvidenceGraphRows(graphId: graphID),
                types: properties?.value?.types ?? [],
                rules: rules?.value ?? []
            )
        }
    }

    /// One graph as a snapshot: its rows, the Subject types and the connect
    /// rules, each warmed when cold or stale and awaited. Nil when the rows
    /// could not be read.
    func evidenceGraphSnapshot(graphID: String) async -> EvidenceGraphSnapshot? {
        let keys = evidenceGraphSnapshotKeys(graphID: graphID)
        let _: QueryHandle<EvidenceGraphRows> = query(keys[0])
        let _: QueryHandle<PropertiesSnapshot> = query(keys[1])
        let _: QueryHandle<[CatalogConnectRule]> = query(keys[2])
        let rows: EvidenceGraphRows? = await readyValue(keys[0])
        let _: PropertiesSnapshot? = await readyValue(keys[1])
        let _: [CatalogConnectRule]? = await readyValue(keys[2])
        guard rows != nil else { return nil }
        return cachedEvidenceGraphSnapshot(graphID: graphID)
    }
}
