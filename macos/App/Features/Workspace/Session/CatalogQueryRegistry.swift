import Foundation

/// One cache effect of a mutation. Keys carrying an id resolve to `allCached`
/// when the write names no single owner — a new metadata field belongs to every
/// cached Source page, not one of them.
enum CatalogQueryInvalidation: Hashable, Sendable {
    case key(CatalogQueryKey)
    case allCached(CatalogQueryKey.Kind)
}

/// What an invalidation does to a cached key that is not on screen.
enum CatalogHiddenPolicy: Sendable, Equatable {
    /// Reload now (the default).
    case revalidate
    /// Keep the old value and reload on the next `query`; nothing fetches now.
    case markStale
}

/// One catalog cache kind: its policies, how a mutation invalidates it, and
/// the in-place patches for lists and the Source page.
struct CatalogQueryDescriptor: Sendable {
    let kind: CatalogQueryKey.Kind
    let invalidateOn: Set<CatalogMutationKind>
    /// What an invalidated key that isn't on screen does when it reloads whole. The exception to
    /// cache rule 2 for lists and per-handle pages, so one trigger doesn't reload every list or
    /// page the researcher has opened. A `.run` refresh merges into a hidden key whatever this says.
    var whenHidden: CatalogHiddenPolicy = .revalidate
    /// The entity whose id `ownId` is. Its deletion evicts the hidden key
    /// (`apply`), and `.handle` keys are the pages the hidden-entity cap counts
    /// (`apply(location:)`).
    var deletedWith: CatalogDeletedEntity? = nil
    /// Whether this is a per-entity page key, one the hidden-entity cap counts
    /// and `shownOrder` orders: its `ownId` is a handle.
    var isEntityPage: Bool { deletedWith == .handle }
    /// Nil when the kind names no mutation in `invalidateOn`.
    let invalidation: (@Sendable (ProjectKey, CatalogMutation) -> CatalogQueryInvalidation)?
    /// In-place updates run, in order, before invalidation. Empty for kinds
    /// that only reload.
    var patches: [CatalogQueryPatch] = []
    /// How a warmed key follows the ids of a write's effects: which slot, and
    /// whether it revalidates the key or reloads part of its value. Empty when
    /// this kind follows none.
    var refreshes: [CatalogQueryRefresh] = []
    /// Starts the typed load for this kind. Closed over `Value` by `make`.
    let warm: @MainActor @Sendable (WorkspaceSession, CatalogQueryKey) -> Void
}

extension CatalogQueryDescriptor {
    /// One factory per kind so the loader and the warm path share `Value`.
    /// `load` reads `key.project` and the key's ids; warm runs only from
    /// `key.kind.descriptor`, so the key is the kind's own.
    static func make<Value>(
        kind: CatalogQueryKey.Kind,
        invalidateOn: Set<CatalogMutationKind> = [],
        whenHidden: CatalogHiddenPolicy = .revalidate,
        deletedWith: CatalogDeletedEntity? = nil,
        invalidation: (@Sendable (ProjectKey, CatalogMutation) -> CatalogQueryInvalidation)? = nil,
        patches: [CatalogQueryPatch] = [],
        refreshes: [CatalogQueryRefresh] = [],
        load: @escaping @Sendable (CatalogQueryKey, any GenealogyStore) async throws -> Value
    ) -> CatalogQueryDescriptor {
        precondition(
            invalidateOn.isEmpty == (invalidation == nil),
            "\(kind): a kind names mutations exactly when it says how they invalidate"
        )
        return CatalogQueryDescriptor(
            kind: kind,
            invalidateOn: invalidateOn,
            whenHidden: whenHidden,
            deletedWith: deletedWith,
            invalidation: invalidation,
            patches: patches,
            refreshes: refreshes,
            warm: { session, key in
                let store = session.store
                let _: QueryHandle<Value> = session.ensureQuery(key) {
                    try await load(key, store)
                }
            }
        )
    }
}

extension CatalogQueryDescriptor {
    /// A per-entity page key (the detail and the Person sections): it follows
    /// what its value was built from (`followsInputs`: handles, Evidence graphs
    /// and Sources) and its own handle, and is marked stale while off screen.
    static func entityPage<Value: CatalogPageValue>(
        kind: CatalogQueryKey.Kind,
        load: @escaping @Sendable (CatalogQueryKey, any GenealogyStore) async throws -> Value
    ) -> CatalogQueryDescriptor {
        .make(
            kind: kind,
            whenHidden: .markStale,
            deletedWith: .handle,
            refreshes: CatalogQueryRefresh.followsInputs(Value.self) + [
                // Kept beside `followsInputs`: a value's inputs are empty until it loads (FakeStore), so its own handle still reaches it.
                .applyHiddenPolicy(followsOwnId: .touchedHandles),
                .followsPropertyLabels,
            ],
            load: load
        )
    }
}

/// Declarative catalog read loaders and mutation invalidation map.
struct CatalogQueryRegistry: Sendable {
    static let standard = CatalogQueryRegistry()

    /// Resolves cache effects from each kind's `invalidateOn` tags + mutation payload.
    func invalidations(by mutation: CatalogMutation, project: ProjectKey) -> [CatalogQueryInvalidation] {
        guard let mutationKind = mutation.invalidationKind else { return [] }
        return CatalogQueryKey.Kind.allCases.compactMap { kind in
            let descriptor = kind.descriptor
            guard descriptor.invalidateOn.contains(mutationKind),
                  let invalidation = descriptor.invalidation else { return nil }
            return invalidation(project, mutation)
        }
    }

    /// What an invalidated `key` does while off screen.
    func hiddenPolicy(_ key: CatalogQueryKey) -> CatalogHiddenPolicy {
        descriptor(for: key).whenHidden
    }

    /// The kind's descriptor. A kind whose arm reported a different kind cannot
    /// happen with the exhaustive switch; that is a programmer error.
    private func descriptor(for key: CatalogQueryKey) -> CatalogQueryDescriptor {
        let descriptor = key.kind.descriptor
        guard descriptor.kind == key.kind else {
            preconditionFailure("missing descriptor for \(key.kind)")
        }
        return descriptor
    }
}

extension CatalogQueryKey.Kind {
    /// One arm owns this kind's policies and invalidation. Id-bearing kinds
    /// fall back to `allCached` when the mutation names no single owner.
    var descriptor: CatalogQueryDescriptor {
        switch self {
        case .sourcesList:
            // Work under a Source reports its activity in `WriteEffects`, which
            // patches the row through `lastUpdated`.
            return .make(
                kind: self,
                invalidateOn: [.deletedSource],
                whenHidden: .markStale,
                invalidation: { project, _ in .key(.sourcesList(project: project)) },
                patches: [
                    .lastUpdated([CatalogSource].self, follows: .source),
                    .sourceRow(),
                ],
                load: { key, store in
                    return try await store.listSources(projectDir: key.project.projectDir)
                }
            )
        case .sourceTypesList:
            // A type write reports `source_vocabulary`, which this key follows.
            // `usedBy` counts sources per type, so adding a source or moving one
            // restates rows no type edit touched.
            return .make(
                kind: self,
                invalidateOn: [.createdSource, .deletedSource, .changedSourceType],
                invalidation: { project, _ in .key(.sourceTypesList(project: project)) },
                patches: [.sourceTypeRow(), .typeSuggestionCount()],
                refreshes: [.applyHiddenPolicyOnAny(follows: .list(.sourceVocabulary))],
                load: { key, store in
                    return try await store.listSourceTypes(projectDir: key.project.projectDir)
                }
            )
        case .metadataFieldsList:
            // A field write reports `source_vocabulary`, which this key follows.
            // `usedBy` counts Sources, Artifacts and Evidence graphs holding a
            // value for the field and Source types naming it in a citation
            // format, and it gates Delete: a value created or released on any
            // of them reports `metadata_field_usage`; a format write reports
            // `source_vocabulary`, which this key follows.
            return .make(
                kind: self,
                refreshes: [
                    .applyHiddenPolicyOnAny(follows: .list(.sourceVocabulary)),
                    .applyHiddenPolicyOnAny(follows: .list(.metadataFieldUsage)),
                ],
                load: { key, store in
                    return try await store.listMetadataFields(projectDir: key.project.projectDir)
                }
            )
        case .credibilityGradesList:
            // Seeded vocabulary with no CRUD surface, so nothing stales it.
            return .make(
                kind: self,
                load: { key, store in
                    return try await store.listSourceCredibilityGrades(projectDir: key.project.projectDir)
                }
            )
        case .sourceWorkspace:
            // The page follows no vocabulary list: a type create, or a type
            // relabel, leaves it alone. What it holds is the metadata row set
            // the engine derives per source (suggestions ∪ values, each row
            // embedding its field), so a field relabel or delete, which a list
            // cannot tell from a field create, marks every visited page stale
            // through `.updatedMetadataField` / `.deletedMetadataField`.
            return .make(
                kind: self,
                invalidateOn: [
                    .mutatedSourceWorkspace, .changedSourceType,
                    .updatedMetadataField, .deletedMetadataField,
                    .wroteTypeSuggestions,
                    .deletedSource,
                ],
                whenHidden: .markStale,
                invalidation: { project, mutation in
                    switch mutation {
                    case .mutatedSourceWorkspace(let sourceId), .deletedSource(let sourceId):
                        return .key(.sourceWorkspace(project: project, sourceId: sourceId))
                    case .changedSourceType(let source):
                        return .key(.sourceWorkspace(project: project, sourceId: source.id))
                    default:
                        return .allCached(.sourceWorkspace)
                    }
                },
                patches: [.updatedSourceShell(), .metadataBoard()],
                load: { key, store in
                    return try await store.getSourceWorkspace(projectDir: key.project.projectDir, sourceID: key.id)
                }
            )
        case .evidenceGraph:
            // Every write that moves a graph, Promote and a Source delete
            // included, names it in `WriteEffects.evidenceGraphs`. The graph
            // on screen reloads; a visited graph that is hidden goes stale and
            // reloads when its canvas, composer or Promote is shown again.
            return .make(
                kind: self,
                whenHidden: .markStale,
                refreshes: [.applyHiddenPolicy(followsOwnId: .evidenceGraphs)],
                load: { key, store in
                    async let subjects = store.listSubjects(
                        projectDir: key.project.projectDir,
                        graphID: key.id
                    )
                    async let positions = store.listSubjectPositions(
                        projectDir: key.project.projectDir,
                        graphID: key.id
                    )
                    async let observations = store.listObservationsByEvidenceGraph(
                        projectDir: key.project.projectDir,
                        graphID: key.id
                    )
                    async let memberships = store.listSubjectMemberships(
                        projectDir: key.project.projectDir,
                        graphID: key.id
                    )
                    async let eventTitles = store.listEvidenceGraphEventTitles(
                        projectDir: key.project.projectDir,
                        graphID: key.id
                    )
                    return EvidenceGraphRows(
                        graphId: key.id,
                        subjects: try await subjects,
                        positions: try await positions,
                        observations: try await observations,
                        memberships: try await memberships,
                        eventTitles: try await eventTitles
                    )
                }
            )
        case .citationCounts:
            // Reloads follow the write's `citations` read for this key's graph.
            return .make(
                kind: self,
                whenHidden: .markStale,
                refreshes: [.applyHiddenPolicy(followsOwnId: .reads(.citations))],
                load: { key, store in
                    return try await store.citationCountsByEvidenceGraph(
                        projectDir: key.project.projectDir,
                        graphID: key.id
                    )
                }
            )
        case .typeSuggestions:
            // Each suggestion embeds a full field row, so relabelling or
            // deleting a field reaches types the edit never named: the key
            // follows `source_vocabulary`. The join is not audited and reports
            // no effects, so a suggestion write carries its reply
            // (`.wroteTypeSuggestions`), which `typeSuggestions()` patches in:
            // no invalidation, and a type that is not on screen goes stale
            // rather than reloading.
            return .make(
                kind: self,
                whenHidden: .markStale,
                patches: [.typeSuggestions()],
                refreshes: [.applyHiddenPolicyOnAny(follows: .list(.sourceVocabulary))],
                load: { key, store in
                    return try await store.listTypeSuggestions(
                        projectDir: key.project.projectDir, typeID: key.suggestionsTypeId, level: key.suggestionsLevel
                    )
                }
            )
        case .propertiesWorkspace:
            // `usedBy` counts Observations and terms per Property: a write that creates,
            // deletes or re-points an Observation reports `property_usage`, which
            // this key follows, as it follows a vocabulary label change and graph
            // structure.
            return .make(
                kind: self,
                whenHidden: .markStale,
                refreshes: [
                    .followsPropertyLabels,
                    .applyHiddenPolicyOnAny(follows: .list(.propertyUsage)),
                    .applyHiddenPolicyOnAny(follows: .structure),
                ],
                load: { key, store in
                    return try await store.getPropertiesWorkspace(projectDir: key.project.projectDir)
                }
            )
        case .connectRules:
            // Seeded product matrix with no CRUD surface.
            return .make(
                kind: self,
                load: { key, store in
                    return try await store.listConnectRules()
                }
            )
        case .propertyTerms:
            return .make(
                kind: self,
                // A term write reports the `property_terms` read for its Property.
                // The rows hold no Property label, binding or type, so the key
                // follows no vocabulary list.
                refreshes: [.applyHiddenPolicy(followsOwnId: .reads(.propertyTerms))],
                load: { key, store in
                    return try await store.listPropertyTerms(
                        projectDir: key.project.projectDir,
                        propertyID: key.id
                    )
                }
            )
        case .citationsByArtifact:
            // Reloads follow the write's `citations` read for this key's graph.
            return .make(
                kind: self,
                whenHidden: .markStale,
                refreshes: [.applyHiddenPolicy(follows: .reads(.citations)) { _, key in [key.citationGraphId] }],
                load: { key, store in
                    return try await store.listCitationsByArtifact(
                        projectDir: key.project.projectDir,
                        graphID: key.citationGraphId,
                        artifactID: key.citationArtifactId
                    )
                }
            )
        case .evidenceGraphProgress:
            // A write re-reads the counts of the graphs it names and merges them
            // into the warmed map (`.merged`); it does not restale the
            // project-wide map (or sourcesList). It keeps merging while hidden.
            return .make(
                kind: self,
                refreshes: [.merged(
                    follows: .reads(.evidenceGraphProgress),
                    as: [String: EvidenceGraphProgress].self,
                    read: { session, key, graphId in
                        try await session.store.getEvidenceGraphProgress(
                            projectDir: key.project.projectDir,
                            graphID: graphId
                        )
                    },
                    merge: { map, graphId, one in
                        if one.isZero {
                            map.removeValue(forKey: graphId)
                        } else {
                            map[graphId] = one
                        }
                    }
                )],
                load: { key, store in
                    let rows = try await store.listEvidenceGraphProgress(projectDir: key.project.projectDir)
                    var map: [String: EvidenceGraphProgress] = [:]
                    for row in rows {
                        map[row.graphId] = row
                    }
                    return map
                }
            )
        case .evidenceGraphsList:
            // Graph and link writes report the `evidence_graphs` read for their
            // Source (`WriteEffects.reads`), and the arm re-reads that Source's
            // graphs and merges them into the warmed list; `deleteSource` reports
            // it for the deleted Source too. A hidden list merges too; a whole reload of a hidden list waits
            // until it is shown.
            return .make(
                kind: self,
                whenHidden: .markStale,
                refreshes: [.merged(
                    follows: .reads(.evidenceGraphs),
                    as: [CatalogEvidenceGraph].self,
                    read: { session, key, sourceId in
                        try await session.store.listEvidenceGraphs(
                            projectDir: key.project.projectDir,
                            sourceID: sourceId
                        )
                    },
                    merge: { rows, sourceId, part in
                        rows.removeAll { $0.sourceID == sourceId }
                        rows.append(contentsOf: part)
                    },
                    afterMerge: { session, _, parts, previous in
                        session.spliceEvidenceGraphIndex(parts, previousRevision: previous)
                    }
                )],
                load: { key, store in
                    return try await store.listEvidenceGraphs(projectDir: key.project.projectDir, sourceID: nil)
                }
            )
        case .personsList:
            return .make(
                kind: self,
                whenHidden: .markStale,
                patches: [.lastUpdated(CatalogListRows<CatalogPersonSummary>.self, follows: .handle)],
                refreshes: [
                    .mergedRows(CatalogPersonSummary.self, follows: .touchedHandles) { session, key, ids in
                        try await session.store.listPersonSummaries(projectDir: key.project.projectDir, entityIDs: ids)
                    },
                    .followsPropertyLabels,
                ],
                load: { key, store in
                    return CatalogListRows(try await store.listPersonSummaries(projectDir: key.project.projectDir, entityIDs: nil))
                }
            )
        case .eventsList:
            return .make(
                kind: self,
                whenHidden: .markStale,
                patches: [.lastUpdated(CatalogListRows<CatalogEventSummary>.self, follows: .handle)],
                refreshes: [
                    .mergedRows(CatalogEventSummary.self, follows: .touchedHandles) { session, key, ids in
                        try await session.store.listEventSummaries(projectDir: key.project.projectDir, entityIDs: ids)
                    },
                    .followsPropertyLabels,
                ],
                load: { key, store in
                    return CatalogListRows(try await store.listEventSummaries(projectDir: key.project.projectDir, entityIDs: nil))
                }
            )
        case .placesList:
            return .make(
                kind: self,
                whenHidden: .markStale,
                patches: [.lastUpdated(CatalogListRows<CatalogPlaceSummary>.self, follows: .handle)],
                refreshes: [
                    .mergedRows(CatalogPlaceSummary.self, follows: .touchedHandles) { session, key, ids in
                        try await session.store.listPlaceSummaries(projectDir: key.project.projectDir, entityIDs: ids)
                    },
                    .followsPropertyLabels,
                ],
                load: { key, store in
                    return CatalogListRows(try await store.listPlaceSummaries(projectDir: key.project.projectDir, entityIDs: nil))
                }
            )
        case .conclusionDetail:
            // A rename or a Citation or Artifact label fix reaches the
            // provenance sheet, the Gallery captions and the viewer's record
            // row through the Sources and graphs its records cite.
            return .entityPage(kind: self) { (key, store) -> CatalogConclusionDetail in
                try await store.getConclusionDetail(projectDir: key.project.projectDir, entityID: key.id)
            }
        case .personClaims:
            // A Person's claims by Source (S13-01): its graphs and Sources, and
            // its own handle.
            return .entityPage(kind: self) { (key, store) -> CatalogPersonClaims in
                try await store.listPersonClaims(projectDir: key.project.projectDir, entityID: key.id)
            }
        case .personFamily:
            // A Person's family units (S13-04): the relatives and the events
            // the read was built from, and its own handle (a newly filed
            // relative names the Person).
            return .entityPage(kind: self) { (key, store) -> CatalogPersonFamily in
                try await store.getPersonFamily(projectDir: key.project.projectDir, entityID: key.id)
            }
        case .personEvents:
            // A Person's timeline (S13-05): the events and co-participants the
            // read was built from, and its own handle.
            return .entityPage(kind: self) { (key, store) -> CatalogPersonTimeline in
                try await store.listPersonEvents(projectDir: key.project.projectDir, entityID: key.id)
            }
        case .personRecordLinks:
            // A Person's Evidence graphs and the lines between them (S13-27):
            // the graphs and Sources the read was built from, and its own handle.
            return .entityPage(kind: self) { (key, store) -> CatalogPersonRecordLinks in
                try await store.getPersonRecordLinks(projectDir: key.project.projectDir, entityID: key.id)
            }
        }
    }
}
