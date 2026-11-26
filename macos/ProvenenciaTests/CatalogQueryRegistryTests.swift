import Foundation
import Testing
@testable import Provenencia

@Suite(.serialized)
@MainActor
struct CatalogQueryRegistryTests {
    private let projectDir = "/tmp/catalog-query-registry.provenencia"
    private let author = catalogMetadataField("f1", label: "Author")

    private func makeSession(store: FakeStore = FakeStore()) -> WorkspaceSession {
        WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    }

    private func seedStore(_ store: FakeStore) {
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
        ]
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "book", origin: "user", label: "Book", description: ""),
        ]
        store.fieldsByProject[projectDir] = [
            CatalogMetadataField(
                id: "f1", key: "author", origin: "user", label: "Author", dataType: "text", description: ""
            ),
        ]
        store.suggestionsByType = ["t1": [
            CatalogTypeSuggestion(
                field: CatalogMetadataField(
                    id: "f1", key: "author", origin: "user", label: "Author", dataType: "text", description: ""
                ),
                sortOrder: 0
            ),
        ]]
        store.evidenceGraphsByProject[projectDir] = [
            CatalogEvidenceGraph(
                id: "g1", ref: "GPH-1", sourceID: "s1", name: "Default", description: "", artifactIDs: ["art-0"]
            ),
        ]
    }

    @Test func registryLoadsEveryKey() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey

        let sourcesHandle: QueryHandle<[CatalogSource]> = session.query(
            CatalogQueryKey.sourcesList(project: project)
        )
        let typesHandle: QueryHandle<[CatalogSourceType]> = session.query(
            CatalogQueryKey.sourceTypesList(project: project)
        )
        let fieldsHandle: QueryHandle<[CatalogMetadataField]> = session.query(
            CatalogQueryKey.metadataFieldsList(project: project)
        )
        let workspaceHandle: QueryHandle<CatalogSourceWorkspace> = session.query(
            CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        )
        let suggestionsHandle: QueryHandle<[CatalogTypeSuggestion]> = session.query(
            CatalogQueryKey.typeSuggestions(project: project, typeId: "t1")
        )

        await waitForQuery(sourcesHandle)
        await waitForQuery(typesHandle)
        await waitForQuery(fieldsHandle)
        await waitForQuery(workspaceHandle)
        await waitForQuery(suggestionsHandle)

        #expect(sourcesHandle.value?.first?.title == "Alpha")
        #expect(typesHandle.value?.first?.label == "Book")
        #expect(fieldsHandle.value?.first?.label == "Author")
        #expect(workspaceHandle.value?.source.id == "s1")
        #expect(suggestionsHandle.value?.count == 1)
    }

    @Test func citationCountsLoadByEvidenceGraph() async {
        let store = FakeStore()
        seedStore(store)
        store.artifactsBySource["s1"] = [
            CatalogArtifact(
                id: "art-0",
                ref: "ART-0",
                sourceID: "s1",
                fileID: "file-0",
                label: "Scan 1",
                description: ""
            ),
            CatalogArtifact(
                id: "art-1",
                ref: "ART-1",
                sourceID: "s1",
                fileID: "file-1",
                label: "Scan 2",
                description: ""
            ),
        ]
        store.citationsByID["cit-1"] = CatalogCitation(
            id: "cit-1",
            ref: "CIT-1",
            artifactID: "art-0",
            locatorJSON: "{}",
            transcription: "",
            description: "",
            transcriptionUncertain: false,
            transcriptionNote: ""
        )
        store.citationsByID["cit-2"] = CatalogCitation(
            id: "cit-2",
            ref: "CIT-2",
            artifactID: "art-0",
            locatorJSON: "{}",
            transcription: "",
            description: "",
            transcriptionUncertain: false,
            transcriptionNote: ""
        )
        let session = makeSession(store: store)
        let handle: QueryHandle<[String: Int]> = session.query(
            CatalogQueryKey.citationCounts(project: session.projectKey, graphId: "g1")
        )
        await waitForQuery(handle)
        #expect(handle.value?["art-0"] == 2)
        #expect(handle.value?["art-1"] == nil)
    }

    @Test func evidenceGraphProgressLoadsMap() async {
        let store = FakeStore()
        seedStore(store)
        store.graphProgressByGraph["g-1"] = EvidenceGraphProgress(
            graphId: "g-1", subjectCount: 12, observationCount: 48
        )
        let session = makeSession(store: store)
        let handle: QueryHandle<[String: EvidenceGraphProgress]> = session.query(
            CatalogQueryKey.evidenceGraphProgress(project: session.projectKey)
        )
        await waitForQuery(handle)
        #expect(handle.value?["g-1"]?.subjectCount == 12)
        #expect(handle.value?["g-1"]?.observationCount == 48)
        #expect(handle.value?["s1"] == nil)
    }

    @Test func connectRulesLoadFromStore() async {
        let store = FakeStore()
        store.connectRules = CatalogConnectRule.productMatrix
        let session = makeSession(store: store)
        let handle: QueryHandle<[CatalogConnectRule]> = session.query(
            CatalogQueryKey.connectRules(project: session.projectKey)
        )
        await waitForQuery(handle)
        #expect(handle.value?.isEmpty == false)
    }

    @Test func applyCreatedPropertyTermReloadsTerms() async {
        let store = FakeStore()
        store.propertyTermsByProperty["p1"] = [
            CatalogPropertyTerm(
                id: "t1",
                propertyID: "p1",
                key: "witness",
                origin: "provenencia",
                label: "Witness",
                description: ""
            ),
        ]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.propertyTerms(project: session.projectKey, propertyId: "p1")
        let handle: QueryHandle<[CatalogPropertyTerm]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.count == 1)

        store.propertyTermsByProperty["p1"]?.append(
            CatalogPropertyTerm(
                id: "t2",
                propertyID: "p1",
                key: "neighbor",
                origin: "user",
                label: "Neighbor",
                description: ""
            )
        )
        session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .propertyTerms, ids: ["p1"])]))
        await waitForQuery(handle)
        #expect(handle.value?.count == 2)
    }

    @Test func citationsByArtifactLoadsListedRows() async {
        let store = FakeStore()
        store.citationsByID["cit-1"] = CatalogCitation(
            id: "cit-1",
            ref: "CIT-1",
            artifactID: "art-0",
            locatorJSON: "{}",
            transcription: "",
            description: "",
            transcriptionUncertain: false,
            transcriptionNote: ""
        )
        let session = makeSession(store: store)
        let handle: QueryHandle<[CatalogListedCitation]> = session.query(
            CatalogQueryKey.citationsByArtifact(project: session.projectKey, graphId: "g1", artifactId: "art-0")
        )
        await waitForQuery(handle)
        #expect(handle.value?.map(\.id) == ["cit-1"])
    }

    /// The composer place warms the field list its metadata sheet offers (S15-56 D-8).
    @Test func composerWarmsMetadataFields() {
        let project = ProjectKey(projectDir: projectDir)
        let location = WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g1", subjectId: "sub-1",
            artifactId: "art-0", sourceSurface: .citationComposer
        )
        let keys = PlaceRegistry.standard.resolve(location, project: project)?.queryKeys ?? []
        #expect(keys.contains(.metadataFieldsList(project: project)))
        #expect(keys.contains(.citationsByArtifact(project: project, graphId: "g1", artifactId: "art-0")))
    }

    /// D-5: a `citation_boards` read revalidates the graph's Citation lists and never a count key.
    @Test func citationBoardsReloadCitationList() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let listKey = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g1", artifactId: "art-0")
        let otherGraph = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g2", artifactId: "art-0")
        let countsKey = CatalogQueryKey.citationCounts(project: project, graphId: "g1")
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g1", subjectId: "sub-1",
            artifactId: "art-0", sourceSurface: .citationComposer
        ))
        let list: QueryHandle<[CatalogListedCitation]> = session.query(listKey)
        let other: QueryHandle<[CatalogListedCitation]> = session.query(otherGraph)
        let counts: QueryHandle<[String: Int]> = session.query(countsKey)
        await waitForQuery(list)
        await waitForQuery(other)
        await waitForQuery(counts)

        let effects = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .citationBoards, ids: ["g1"])])
        let keys = session.revalidatedKeys(for: effects)
        #expect(keys.contains(listKey))
        #expect(!keys.contains(otherGraph))
        #expect(!keys.contains(countsKey))
        #expect(CatalogQueryKey.Kind.citationCounts.descriptor.refreshes.map(\.follows) == [.reads(.citations)])
    }

    /// D-17: the edits that change a board's labels, suggestions or annotations mark a hidden
    /// Citation list stale.
    @Test func boardVocabularyStalesCitationLists() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let listKey = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g1", artifactId: "art-0")
        let list: QueryHandle<[CatalogListedCitation]> = session.query(listKey)
        await waitForQuery(list)

        let source = CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: "")
        for mutation: CatalogMutation in [
            .changedSourceType(source), .updatedMetadataField(id: "f1"), .deletedMetadataField(id: "f1"),
            .changedCitationFormats(typeId: "t1"),
            .wroteTypeSuggestions(typeId: "t1", edit: CatalogTypeSuggestionEdit(suggestions: [], suggestedFieldCount: 0)),
        ] {
            #expect(session.registry.invalidations(by: mutation, project: project).contains(.allCached(.citationsByArtifact)))
            session.apply(mutation)
            await session.settleWrites()
            #expect(list.isStale, "\(mutation)")
            let _: QueryHandle<[CatalogListedCitation]> = session.query(listKey)
            await waitForQuery(list)
        }
        #expect(CatalogMutationKind.boardVocabulary.isSuperset(of: [.changedSourceType, .changedCitationFormats]))
    }

    @Test func evidenceGraphLoadsPlacedPrimaries() async {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person",
                key: "person",
                origin: "provenencia",
                label: "Person",
                description: "",
                refPrefix: "PER",
                candidateRefPrefix: "CPR"
            ),
            CatalogSubjectType(
                id: "type-location",
                key: "location",
                origin: "provenencia",
                label: "Location",
                description: "",
                refPrefix: "LOC",
                candidateRefPrefix: "CLO"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(
                id: "sub-1",
                ref: "CPR-1",
                sourceID: "s1",
                subjectTypeID: "type-person",
                label: "Alice",
                description: ""
            ),
            CatalogSubject(
                id: "sub-bridge",
                ref: "CLO-1",
                sourceID: "s1",
                subjectTypeID: "type-location",
                label: "Somewhere",
                description: ""
            ),
        ]
        store.subjectPositionsBySubject["sub-1"] = CatalogSubjectPosition(
            subjectID: "sub-1",
            gridX: 2,
            gridY: 3
        )
        store.subjectPositionsBySubject["sub-bridge"] = CatalogSubjectPosition(
            subjectID: "sub-bridge",
            gridX: 4,
            gridY: 5
        )

        let session = makeSession(store: store)
        let handle: QueryHandle<EvidenceGraphRows> = session.query(
            CatalogQueryKey.evidenceGraph(project: session.projectKey, graphId: "g-1")
        )
        await waitForQuery(handle)

        #expect(handle.value?.graphId == "g-1")
        #expect(handle.value?.subjects.count == 2)
        #expect(handle.value?.subjects.map(\.id).sorted() == ["sub-1", "sub-bridge"])
        #expect(handle.value?.positions.first { $0.subjectID == "sub-1" }?.gridX == 2)
        let snapshot = EvidenceGraphSnapshot.build(
            rows: handle.value ?? EvidenceGraphRows(graphId: "g-1"),
            types: store.subjectTypesByProject[projectDir] ?? [],
            rules: CatalogConnectRule.productMatrix
        )
        #expect(snapshot.subjects.count == 1)
        #expect(snapshot.subjects.first?.kind == .person)
        #expect(snapshot.bridges.count == 1)
        #expect(snapshot.bridges.first?.kind == .location)
        #expect(snapshot.subjects.first?.membership == nil)
    }

    @Test func evidenceGraphLoadsMembershipOfPromotedSubjects() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "Alice", description: ""),
            CatalogSubject(id: "sub-2", ref: "CPR-2", sourceID: "s1", subjectTypeID: "type-person", label: "Bob", description: ""),
        ]
        for (id, x) in [("sub-1", Int64(1)), ("sub-2", Int64(4))] {
            store.subjectPositionsBySubject[id] = CatalogSubjectPosition(subjectID: id, gridX: x, gridY: 1)
        }
        let promoted = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")

        let session = makeSession(store: store)
        let handle: QueryHandle<EvidenceGraphRows> = session.query(
            CatalogQueryKey.evidenceGraph(project: session.projectKey, graphId: "g-1")
        )
        await waitForQuery(handle)

        #expect(handle.value?.memberships.map(\.subjectID) == ["sub-1"])
        let snapshot = EvidenceGraphSnapshot.build(
            rows: handle.value ?? EvidenceGraphRows(graphId: "g-1"),
            types: store.subjectTypesByProject[projectDir] ?? [],
            rules: []
        )
        let alice = snapshot.subjects.first { $0.id == "sub-1" }
        let bob = snapshot.subjects.first { $0.id == "sub-2" }
        #expect(alice?.membership?.entity.ref == promoted.entity.ref)
        #expect(alice?.membership?.kind == "person")
        #expect(alice?.membership?.claimID == promoted.claim.id)
        #expect(bob != nil && bob?.membership == nil)
    }

    @Test func personsListLoadsSummariesOfPromotedPersons() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
            CatalogSubject(id: "sub-2", ref: "CPR-2", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
        ]
        store.observationsByGraph["g-1"] = [
            nameObservation(id: "o1", subjectID: "sub-1", form: "James Robins",
                            parts: [part("James", "given"), part("Robins", "surname")]),
            nameObservation(id: "o2", subjectID: "sub-1", form: "Jim Robins",
                            parts: [part("Jim", "given"), part("Robins", "surname")]),
            nameObservation(id: "o3", subjectID: "sub-1", form: "ROBINS, James",
                            parts: [part("ROBINS", "surname"), part("James", "given")]),
        ]
        let james = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")
        let bare = store.seedPromotion(projectDir: projectDir, subjectID: "sub-2")

        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(
            CatalogQueryKey.personsList(project: session.projectKey)
        )
        await waitForQuery(handle)

        let summaries = try #require(handle.value)
        #expect(summaries.map(\.entity.ref) == [james.entity.ref, bare.entity.ref])
        #expect(summaries[0].name == CatalogNameValue(
            form: "James Robins", parts: [part("James", "given"), part("Robins", "surname")]
        ))
        #expect(summaries[0].nameValueCount == 2)
        #expect(summaries[1].name == nil && PersonTitleDisplay.title(summaries[1]) == bare.entity.ref)
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func personsListKeepsAccentVariantsApart() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
        ]
        store.observationsByGraph["g-1"] = [
            nameObservation(id: "o1", subjectID: "sub-1", form: "José Robins",
                            parts: [part("José", "given"), part("Robins", "surname")]),
            nameObservation(id: "o2", subjectID: "sub-1", form: "Jose Robins",
                            parts: [part("Jose", "given"), part("Robins", "surname")]),
        ]
        _ = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")

        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogListRows<CatalogPersonSummary>> = session.query(
            CatalogQueryKey.personsList(project: session.projectKey)
        )
        await waitForQuery(handle)

        #expect(try #require(handle.value)[0].nameValueCount == 2)
    }

    @Test func conclusionDetailLoadsAPersonsNameValuesAndOutcomes() async throws {
        let store = FakeStore()
        seedStore(store)
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.evidenceGraphsByProject[projectDir] = [
            CatalogEvidenceGraph(id: "g-1", ref: "GPH-1", sourceID: "s1", name: "Default", description: "", artifactIDs: []),
        ]
        store.subjectsByGraph["g-1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
        ]
        store.observationsByGraph["g-1"] = [
            nameObservation(id: "o1", subjectID: "sub-1", form: "James Robins",
                            parts: [part("James", "given"), part("Robins", "surname")]),
            nameObservation(id: "o2", subjectID: "sub-1", form: "Jim Robins",
                            parts: [part("Jim", "given"), part("Robins", "surname")]),
            nameObservation(id: "o3", subjectID: "sub-1", form: "ROBINS, James",
                            parts: [part("ROBINS", "surname"), part("James", "given")]),
            nameObservation(id: "o4", subjectID: "sub-1", form: "J. Robins", parts: []),
        ]
        let james = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")

        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogConclusionDetail> = session.query(
            CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: james.entity.id)
        )
        await waitForQuery(handle)

        let detail = try #require(handle.value)
        #expect(detail.entity == james.entity)
        let name = try #require(detail.fields.first { $0.propertyKey == "name" })
        // One Source: o1 and o3 are one value by parts, o2 another; o4 has no parts.
        #expect(name.state == .single)
        #expect(name.values.map(\.reason) == [.kept, .outvoted])
        let james1 = CatalogNameValue(form: "James Robins", parts: [part("James", "given"), part("Robins", "surname")])
        #expect(name.displayedValues.map(\.value) == [.name(james1)])
        #expect(name.outcomes.map(\.observationRef) == ["OBS-o1", "OBS-o3", "OBS-o2", "OBS-o4"])
        #expect(name.outcomes.map(\.valueRank) == [1, 1, 2, nil])
        #expect(name.outcomes.map(\.reason) == [.kept, .kept, .outvoted, .noEvidence])
        #expect(name.outcomes.allSatisfy { $0.subjectRef == "CPR-1" && $0.sourceID == "s1" })
        // One Source voted, so the outvoted Jim lost 1 of 1.
        #expect(name.outcomes.map(\.voteSupport) == [0, 0, 1, 0])
        #expect(name.outcomes.map(\.voteTotal) == [0, 0, 1, 0])
        #expect(detail.memberCount == 1)
        #expect(store.heldCatalogProjectDir == projectDir)
    }

    @Test func hiddenPolicies() {
        let registry = CatalogQueryRegistry.standard
        let project = ProjectKey(projectDir: projectDir)
        #expect(registry.hiddenPolicy(.conclusionDetail(project: project, entityId: "e1")) == .markStale)
        #expect(registry.hiddenPolicy(.personsList(project: project)) == .markStale)
        #expect(registry.hiddenPolicy(.eventsList(project: project)) == .markStale)
        #expect(registry.hiddenPolicy(.placesList(project: project)) == .markStale)
        #expect(registry.hiddenPolicy(.sourcesList(project: project)) == .markStale)
        #expect(registry.hiddenPolicy(.sourceWorkspace(project: project, sourceId: "s1")) == .markStale)
    }

    @Test func ownIdNamesTheKeysOneRow() {
        let project = ProjectKey(projectDir: projectDir)
        #expect(CatalogQueryKey.conclusionDetail(project: project, entityId: "e1").ownId == "e1")
        #expect(CatalogQueryKey.personClaims(project: project, entityId: "e1").ownId == "e1")
        #expect(CatalogQueryKey.personFamily(project: project, entityId: "e1").ownId == "e1")
        #expect(CatalogQueryKey.personEvents(project: project, entityId: "e1").ownId == "e1")
        #expect(CatalogQueryKey.personRecordLinks(project: project, entityId: "e1").ownId == "e1")
        #expect(CatalogQueryKey.evidenceGraph(project: project, graphId: "g1").ownId == "g1")
        #expect(CatalogQueryKey.citationCounts(project: project, graphId: "g1").ownId == "g1")
        #expect(CatalogQueryKey.propertyTerms(project: project, propertyId: "p1").ownId == "p1")
        #expect(CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1").ownId == "s1")
        #expect(CatalogQueryKey.typeSuggestions(project: project, typeId: "t1").ownId == "t1")
        #expect(CatalogQueryKey.personsList(project: project).ownId == nil)
        #expect(CatalogQueryKey.citationsByArtifact(project: project, graphId: "g1", artifactId: "a1").ownId == nil)

        for key in [
            CatalogQueryKey.conclusionDetail(project: project, entityId: "e1"),
            .personClaims(project: project, entityId: "e1"),
            .personFamily(project: project, entityId: "e1"),
            .personEvents(project: project, entityId: "e1"),
            .personRecordLinks(project: project, entityId: "e1"),
        ] {
            #expect(key.kind.descriptor.deletedWith == .handle)
        }
        #expect(CatalogQueryKey.Kind.sourceWorkspace.descriptor.deletedWith == .source)
        #expect(CatalogQueryKey.Kind.typeSuggestions.descriptor.deletedWith == .sourceType)
        #expect(!CatalogQueryKey.Kind.sourceWorkspace.descriptor.isEntityPage)
        #expect(!CatalogQueryKey.Kind.typeSuggestions.descriptor.isEntityPage)
        #expect(CatalogQueryKey.Kind.sourcesList.descriptor.invalidateOn.isEmpty)
        #expect(CatalogQueryKey.Kind.sourceTypesList.descriptor.invalidateOn.isEmpty)
        let deleted = CatalogQueryFollows.deleted(.source)
        let effects = CatalogWriteEffects(deleted: [
            CatalogWriteEffectsDeleted(entity: .source, ids: ["s1"]),
            CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["t1"]),
        ])
        #expect(!deleted.isCatalogWide)
        #expect(deleted.ids(in: effects) == ["s1"])
        #expect(CatalogQueryFollows.deleted(.handle).ids(in: effects).isEmpty)
    }

    /// T-4 (AC-3.1): a key is a value: kind, project and the factory's ids.
    @Test func keysAreValues() {
        let project = ProjectKey(projectDir: projectDir)
        let key = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g1", artifactId: "a1")
        #expect(key.kind == .citationsByArtifact)
        #expect(key.project == project)
        #expect(key.ids == ["g1", "a1"])
        #expect(key.ownId == nil)
        #expect(key.citationGraphId == "g1" && key.citationArtifactId == "a1")
        let same = CatalogQueryKey.citationsByArtifact(project: project, graphId: "g1", artifactId: "a1")
        #expect(key == same)
        #expect(key.hashValue == same.hashValue)
        #expect(key != CatalogQueryKey.citationsByArtifact(project: project, graphId: "g1", artifactId: "a2"))
        #expect(CatalogQueryKey.conclusionDetail(project: project, entityId: "e1").id == "e1")
        #expect(CatalogQueryKey.personsList(project: project).ids.isEmpty)
    }

    @Test func everyKindHasOneDescriptor() {
        let kinds = CatalogQueryKey.Kind.allCases
        let described = kinds.map { kind -> CatalogQueryKey.Kind in
            let descriptor = kind.descriptor
            #expect(descriptor.kind == kind)
            return descriptor.kind
        }
        #expect(Set(described) == Set(kinds))

        // Omitting one kind from the observed set fails the same equality and names it.
        let planted = Set(described.filter { $0 != .sourcesList })
        let missing = Set(kinds).subtracting(planted)
        #expect(missing == [.sourcesList])
        #expect(planted != Set(kinds))
    }

    @Test func lastUpdatedPatchesAreDeclaredOnTheFourLists() {
        let project = ProjectKey(projectDir: projectDir)
        func follows(_ key: CatalogQueryKey) -> CatalogQueryFollows? {
            key.kind.descriptor.patches.compactMap(\.follows).first
        }
        for key in [CatalogQueryKey.personsList(project: project), .eventsList(project: project), .placesList(project: project)] {
            #expect(follows(key) == .handle, "\(key)")
        }
        let sourcesList = CatalogQueryKey.sourcesList(project: project)
        let sourcePatches = sourcesList.kind.descriptor.patches
        #expect(sourcePatches.count == 2)
        #expect(sourcePatches[0].follows == .source)
        #expect(sourcePatches[1].follows == nil)
        #expect(follows(.sourceTypesList(project: project)) == .deleted(.sourceType))
    }

    @Test func conclusionDetailOfAnUnknownHandleIsCodedNotFound() async throws {
        let store = FakeStore()
        seedStore(store)
        await #expect(throws: CoreInvokeError.coded(status: 1, code: "conclusiondetails.not_found", kind: .user, params: [])) {
            _ = try await store.getConclusionDetail(projectDir: projectDir, entityID: "nope")
        }
        #expect(
            CoreInvokeError.coded(status: 1, code: "conclusiondetails.not_found", kind: .user, params: []).localizedDescription
                == "This record no longer exists. It may have been merged into another."
        )
    }

    @Test func eventAndPlaceListsAreGosRowsAsGiven() async throws {
        let store = FakeStore()
        let late = CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: "e2", ref: "EVT-2", subjectTypeID: "t", label: ""),
            title: CatalogEventTitle(rule: .ref, ref: "EVT-2")
        )
        let early = CatalogEventSummary(
            entity: CatalogCanonicalEntity(id: "e1", ref: "EVT-1", subjectTypeID: "t", label: ""),
            title: CatalogEventTitle(rule: .ref, ref: "EVT-1")
        )
        store.seededEventSummaries = [late, early]
        let place = CatalogPlaceSummary(
            entity: CatalogCanonicalEntity(id: "p1", ref: "PLC-1", subjectTypeID: "t", label: ""),
            names: ["Montréal", "Montreal"]
        )
        store.seededPlaceSummaries = [place]
        let detail = CatalogConclusionDetail(entity: early.entity, fields: [], memberCount: 1, summary: .event(early))
        store.seededConclusionDetails = [early.entity.id: detail]
        let session = makeSession(store: store)

        let events: QueryHandle<CatalogListRows<CatalogEventSummary>> = session.query(.eventsList(project: session.projectKey))
        let places: QueryHandle<CatalogListRows<CatalogPlaceSummary>> = session.query(.placesList(project: session.projectKey))
        let page: QueryHandle<CatalogConclusionDetail> = session.query(
            .conclusionDetail(project: session.projectKey, entityId: early.entity.id)
        )
        await waitForQuery(events)
        await waitForQuery(places)
        await waitForQuery(page)
        // Order is Go's; the fake does not re-sort or re-derive.
        #expect(events.value == [late, early])
        #expect(places.value == [place])
        #expect(page.value?.summary?.event == early)
    }

    private func part(_ value: String, _ type: String) -> CatalogNameValuePart {
        CatalogNameValuePart(value: value, type: type)
    }

    private func nameObservation(
        id: String, subjectID: String, form: String, parts: [CatalogNameValuePart]
    ) -> CatalogObservation {
        var observation = CatalogObservation(
            id: id, ref: "OBS-\(id)", citationID: "c1", subjectID: subjectID, propertyID: "p-name",
            polarity: "positive", valueText: form, valueInteger: nil, valueDateID: "",
            valueNameID: "n-\(id)", nameForm: form, valueSubjectID: "", valueTermID: "",
            propertyKey: "name", propertyLabel: "Name", propertyValueType: "name"
        )
        observation.nameParts = parts
        return observation
    }

    @Test func registryBackedQueryDoesNotRecallLoader() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)

        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)

        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "", title: "Beta", description: ""),
        ]

        let _: QueryHandle<[CatalogSource]> = session.query(key)
        await Task.yield()
        #expect(handle.value?.first?.title == "Alpha")
    }

    @Test func setQueryValueSkipsLoader() async {
        let store = FakeStore()
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let seeded = [
            CatalogSource(id: "seed", ref: "SRC-SEED", sourceTypeID: "", title: "Seeded", description: ""),
        ]

        session.setQueryValue(key, value: seeded)
        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await Task.yield()
        #expect(handle.status == .ready)
        #expect(handle.value == seeded)
        #expect(store.heldCatalogProjectDir == nil)
    }

    @Test func applyUpdatedSourceLeavesOtherCachedWorkspacesUntouched() async {
        let store = FakeStore()
        seedStore(store)
        store.sourcesByProject[projectDir]?.append(
            CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "Beta", description: "")
        )
        let session = makeSession(store: store)
        let project = session.projectKey
        let firstKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        let secondKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s2")

        let firstHandle: QueryHandle<CatalogSourceWorkspace> = session.query(firstKey)
        let secondHandle: QueryHandle<CatalogSourceWorkspace> = session.query(secondKey)
        await waitForQuery(firstHandle)
        await waitForQuery(secondHandle)
        #expect(firstHandle.value?.source.title == "Alpha")
        #expect(secondHandle.value?.source.title == "Beta")

        let updated = CatalogSource(
            id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Renamed", description: "New desc"
        )
        session.apply(.updatedSource(updated))

        #expect(firstHandle.value?.source.title == "Renamed")
        #expect(secondHandle.value?.source.title == "Beta")
    }

    @Test func applyUpdatedSourcePatchesListAndWorkspace() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let listKey = CatalogQueryKey.sourcesList(project: project)
        let workspaceKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")

        let listHandle: QueryHandle<[CatalogSource]> = session.query(listKey)
        let workspaceHandle: QueryHandle<CatalogSourceWorkspace> = session.query(workspaceKey)
        await waitForQuery(listHandle)
        await waitForQuery(workspaceHandle)
        store.heldCatalogProjectDir = nil

        let updated = CatalogSource(
            id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Renamed", description: "New desc"
        )
        session.apply(.updatedSource(updated))

        #expect(listHandle.value?.first?.title == "Renamed")
        #expect(workspaceHandle.value?.source.title == "Renamed")
        #expect(store.heldCatalogProjectDir == nil)
    }

    /// T-2: a board write puts the owner's rows on the cached page and reloads nothing.
    @Test func metadataBoardWritePatchesTheWorkspace() async {
        let store = FakeStore()
        seedStore(store)
        store.sourcesByProject[projectDir]?.append(
            CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "Beta", description: "")
        )
        store.artifactsBySource["s1"] = [catalogArtifact("a1"), catalogArtifact("a2")]
        store.metadataByOwner[MetadataOwner(level: .artifact, id: "a1")] = [catalogMetadataEntry(author, "old")]
        let session = makeSession(store: store)
        let project = session.projectKey
        let first: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s1"))
        let second: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s2"))
        await waitForQuery(first)
        await waitForQuery(second)
        let calls = store.getSourceWorkspaceCalls
        let x = [catalogMetadataEntry(author, "new")]

        session.apply(
            .empty, .wroteMetadataBoard(sourceId: "s1", owner: MetadataOwner(level: .artifact, id: "a1"), entries: x)
        )
        await session.settleWrites()
        #expect(first.value?.artifactMetadata["a1"] == x)
        #expect(first.value?.metadata.isEmpty == true)
        #expect(first.value?.artifactMetadata["a2"] == [])
        #expect(second.value?.artifactMetadata.isEmpty == true)

        session.apply(
            .empty, .wroteMetadataBoard(sourceId: "s1", owner: MetadataOwner(level: .source, id: "s1"), entries: x)
        )
        await session.settleWrites()
        #expect(first.value?.metadata == x)
        #expect(store.getSourceWorkspaceCalls == calls)
    }

    /// T-3: an owner the page cannot place changes nothing and invalidates nothing.
    @Test func metadataBoardPatchIgnoresOwnersItCannotPlace() async {
        let store = FakeStore()
        seedStore(store)
        store.artifactsBySource["s1"] = [catalogArtifact("a1")]
        let session = makeSession(store: store)
        let project = session.projectKey
        let handle: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s1"))
        await waitForQuery(handle)
        let before = handle.value
        for owner in [MetadataOwner(level: .artifact, id: "a9"), MetadataOwner(level: .citation, id: "c1")] {
            let mutation = CatalogMutation.wroteMetadataBoard(
                sourceId: "s1", owner: owner, entries: [catalogMetadataEntry(author, "x")]
            )
            session.apply(.empty, mutation)
            await session.settleWrites()
            #expect(handle.value == before)
            #expect(CatalogQueryRegistry.standard.invalidations(by: mutation, project: project).isEmpty)
        }
    }

    /// An Evidence graph's rows are stored whatever graphs the workspace lists (it lists none),
    /// and invalidate nothing.
    @Test func metadataBoardPatchStoresAGraphsRows() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let handle: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s1"))
        await waitForQuery(handle)
        let rows = [catalogMetadataEntry(author, "x")]
        let mutation = CatalogMutation.wroteMetadataBoard(
            sourceId: "s1", owner: MetadataOwner(level: .graph, id: "g1"), entries: rows
        )
        session.apply(.empty, mutation)
        await session.settleWrites()
        #expect(handle.value?.graphMetadata["g1"] == rows)
        #expect(CatalogQueryRegistry.standard.invalidations(by: mutation, project: project).isEmpty)
    }

    @Test func applyCreatedSourceInsertsRow() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)

        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)

        let callsBefore = store.listSourcesCalls

        session.apply(.createdSource(CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "", title: "New Row", description: "")))
        let _: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)
        // The returned row is appended (the Sources list sorts for display); nothing reloads.
        #expect(handle.value?.map(\.title) == ["Alpha", "New Row"])
        #expect(store.listSourcesCalls == callsBefore)
    }

    /// T-14: a write's effects name the Evidence graphs to reload, one warmed key each
    /// (`revalidatedKeys`); no mutation names a graph, a Source delete included.
    @Test func evidenceGraphEffectsReloadOnlyThatGraph() {
        let registry = CatalogQueryRegistry.standard
        let session = makeSession()
        let project = session.projectKey
        let graph1Key = CatalogQueryKey.evidenceGraph(project: project, graphId: "g-1")
        let graph2Key = CatalogQueryKey.evidenceGraph(project: project, graphId: "g-2")
        session.setQueryValue(graph1Key, value: EvidenceGraphRows(graphId: "g-1"))
        session.setQueryValue(graph2Key, value: EvidenceGraphRows(graphId: "g-2"))
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(evidenceGraphs: ["g-2"])) == [graph2Key])
        // A Source delete names its graphs in its effects, not in a mutation.
        #expect(!registry.invalidations(by: .changedSourceType(CatalogSource(id: "src-1", ref: "SRC-1", sourceTypeID: "t1", title: "T", description: "")), project: project)
            .contains(.allCached(.evidenceGraph)))
        #expect(CatalogQueryKey.Kind.evidenceGraph.descriptor.invalidateOn.isEmpty)
    }

    /// Work under a Source moves its "Updated" revision. The write reports its
    /// activity, so the cached row is patched in place: no reload, no stale mark.
    @Test func applySourceWriteEffectsPatchesTheListRowWithoutReloading() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)

        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)
        store.heldCatalogProjectDir = nil

        let activity = CatalogActivity(revision: 42, at: "2026-10-15T16:00:00Z")
        session.apply(CatalogWriteEffects(sourceScopes: ["s1"], activity: activity))
        await Task.yield()
        #expect(handle.value?.first?.updated == activity)
        #expect(!handle.isFetching)
        #expect(store.heldCatalogProjectDir == nil)

        // Not stale either: the next `query` is served from the patched value.
        let _: QueryHandle<[CatalogSource]> = session.query(key)
        #expect(!handle.isFetching)
        #expect(handle.value?.first?.updated == activity)
    }

    /// Writes under a Source report their activity in `WriteEffects`, so no
    /// mutation reloads the Sources list; the row is patched instead.
    @Test func sourceWritesDoNotInvalidateTheSourcesList() {
        let registry = CatalogQueryRegistry.standard
        let project = ProjectKey(projectDir: projectDir)
        let list = CatalogQueryInvalidation.key(.sourcesList(project: project))
        let writes: [CatalogMutation] = [
            .mutatedSourceWorkspace(sourceId: "s1"),
        ]
        for mutation in writes {
            #expect(!registry.invalidations(by: mutation, project: project).contains(list), "\(mutation)")
        }
    }

    /// T-17 (AC-2.14): Source-page and graph writes no longer ride the blanket
    /// Conclusion triggers; their effects name the handles they moved.
    @Test func blanketTriggersAreGone() {
        let registry = CatalogQueryRegistry.standard
        let project = ProjectKey(projectDir: projectDir)
        let conclusionKeys: [CatalogQueryInvalidation] = [
            .key(.personsList(project: project)), .key(.eventsList(project: project)),
            .key(.placesList(project: project)), .allCached(.conclusionDetail),
        ]
        for mutation: CatalogMutation in [
            .mutatedSourceWorkspace(sourceId: "s1"),
        ] {
            let invalidations = registry.invalidations(by: mutation, project: project)
            for key in conclusionKeys {
                #expect(!invalidations.contains(key), "\(mutation) \(key)")
            }
        }
    }

    @Test func applyFieldCRUDInvalidatesMetadataList() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let fieldsKey = CatalogQueryKey.metadataFieldsList(project: project)
        let typesKey = CatalogQueryKey.sourceTypesList(project: project)

        let fieldsHandle: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        let typesHandle: QueryHandle<[CatalogSourceType]> = session.query(typesKey)
        await waitForQuery(fieldsHandle)
        await waitForQuery(typesHandle)

        store.fieldsByProject[projectDir] = [
            CatalogMetadataField(
                id: "f2", key: "date", origin: "user", label: "Date", dataType: "date", description: ""
            ),
        ]
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t9", key: "map", origin: "user", label: "Map", description: ""),
        ]

        // A field write reports `source_vocabulary`; the field relabel and
        // delete also name the Source pages through their mutation.
        let effects = CatalogWriteEffects(lists: [.sourceVocabulary])
        for mutation in [nil, .updatedMetadataField(id: "f1"), .deletedMetadataField(id: "f1")] as [CatalogMutation?] {
            session.apply(effects, mutation)
            let _: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
            await waitForQuery(fieldsHandle)
            #expect(fieldsHandle.value?.first?.label == "Date")
        }
        let _: QueryHandle<[CatalogSourceType]> = session.query(typesKey)
        await waitForQuery(typesHandle)
        #expect(typesHandle.value?.first?.label == "Map")
    }

    @Test func applyTypeCRUDInvalidatesTypesList() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let typesKey = CatalogQueryKey.sourceTypesList(project: project)
        let fieldsKey = CatalogQueryKey.metadataFieldsList(project: project)

        let typesHandle: QueryHandle<[CatalogSourceType]> = session.query(typesKey)
        let fieldsHandle: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        await waitForQuery(typesHandle)
        await waitForQuery(fieldsHandle)

        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t2", key: "photo", origin: "user", label: "Photo", description: ""),
        ]
        store.fieldsByProject[projectDir] = [
            CatalogMetadataField(
                id: "f9", key: "place", origin: "user", label: "Place", dataType: "text", description: ""
            ),
        ]

        // A type write reports `source_vocabulary`, which both Source
        // vocabulary lists follow; no Source page follows it.
        session.apply(CatalogWriteEffects(lists: [.sourceVocabulary]))
        let _: QueryHandle<[CatalogSourceType]> = session.query(typesKey)
        await waitForQuery(typesHandle)
        #expect(typesHandle.value?.first?.label == "Photo")
        let _: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        await waitForQuery(fieldsHandle)
        #expect(fieldsHandle.value?.first?.label == "Place")
    }

    /// STEP-3 (D-7): a suggestion write patches its type's suggestions and the list's count, and
    /// invalidates only the Source pages; no other key reloads.
    @Test func wroteTypeSuggestionsInvalidatesOnlySourcePages() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let suggestionsKey = CatalogQueryKey.typeSuggestions(project: project, typeId: "t1")
        let otherSuggestionsKey = CatalogQueryKey.typeSuggestions(project: project, typeId: "t2")
        let typesKey = CatalogQueryKey.sourceTypesList(project: project)

        store.suggestionsByType["t2"] = []

        let suggestionsHandle: QueryHandle<[CatalogTypeSuggestion]> = session.query(suggestionsKey)
        let otherHandle: QueryHandle<[CatalogTypeSuggestion]> = session.query(otherSuggestionsKey)
        let typesHandle: QueryHandle<[CatalogSourceType]> = session.query(typesKey)
        await waitForQuery(suggestionsHandle)
        await waitForQuery(otherHandle)
        await waitForQuery(typesHandle)
        let loads = store.listTypeSuggestionsTypeIDs.count

        let date = CatalogMetadataField(
            id: "f2", key: "date", origin: "user", label: "Date", dataType: "date", description: ""
        )
        let edit = CatalogTypeSuggestionEdit(
            suggestions: [CatalogTypeSuggestion(field: date, sortOrder: 0)], suggestedFieldCount: 1
        )
        session.apply(.wroteTypeSuggestions(typeId: "t1", edit: edit))
        await session.settleWrites()

        #expect(suggestionsHandle.value == edit.suggestions)
        #expect(otherHandle.value?.isEmpty == true)
        #expect(typesHandle.value?.first?.label == "Book")
        #expect(store.listTypeSuggestionsTypeIDs.count == loads)
        #expect(!suggestionsHandle.isStale && !otherHandle.isStale && !typesHandle.isStale)
    }

    /// STEP-5 (D-19): a Save that carried citation formats marks every cached Source page stale
    /// and leaves the types list alone; a Details-only Save applies no such mutation.
    @Test func changedCitationFormatsInvalidatesSourcePages() async {
        let store = FakeStore()
        seedStore(store)
        store.sourcesByProject[projectDir]?.append(
            CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "Beta", description: "")
        )
        let session = makeSession(store: store)
        let project = session.projectKey
        let first: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s1"))
        let second: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s2"))
        let types: QueryHandle<[CatalogSourceType]> = session.query(.sourceTypesList(project: project))
        await waitForQuery(first)
        await waitForQuery(second)
        await waitForQuery(types)

        #expect(session.registry.invalidations(by: .changedCitationFormats(typeId: "t1"), project: project) == [
            .allCached(.sourceWorkspace), .allCached(.citationsByArtifact),
        ])
        session.apply(.changedCitationFormats(typeId: "t1"))
        await session.settleWrites()

        #expect(first.isStale && second.isStale)
        #expect(!types.isStale)
    }

    @Test func sessionUsesStandardRegistryByDefault() {
        let session = makeSession()
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        #expect(session.registry.hiddenPolicy(key) == .markStale)
    }

    @Test func invalidationsComeFromRegistrySpecs() {
        let registry = CatalogQueryRegistry.standard
        let project = ProjectKey(projectDir: projectDir)
        let source = CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t2", title: "T", description: "")

        #expect(registry.invalidations(by: .updatedSource(source), project: project).isEmpty)

        // A new source moves a type's `usedBy` through the engine's `source_type_usage`, not a mutation.
        #expect(registry.invalidations(by: .createdSource(source), project: project).isEmpty)
        #expect(registry.invalidations(by: .changedSourceType(source), project: project) == [
            .key(.sourceWorkspace(project: project, sourceId: "s1")),
            .allCached(.citationsByArtifact),
        ])
        // A vocabulary write names its lists through its effects, not a
        // mutation. A field relabel or delete restates a *derived* row on every
        // Source page, which a list cannot tell from a field create, so those
        // two mutations still name the pages, and only the pages.
        #expect(registry.invalidations(by: .deletedMetadataField(id: "f1"), project: project) == [
            .allCached(.sourceWorkspace), .allCached(.citationsByArtifact),
        ])
        #expect(registry.invalidations(by: .updatedMetadataField(id: "f1"), project: project) == [
            .allCached(.sourceWorkspace), .allCached(.citationsByArtifact),
        ])
        #expect(registry.invalidations(
            by: .wroteTypeSuggestions(typeId: "t1", edit: CatalogTypeSuggestionEdit(suggestions: [], suggestedFieldCount: 0)),
            project: project
        ) == [.allCached(.sourceWorkspace), .allCached(.citationsByArtifact)])
        // A mutation names no graph key: the graph is reached through each kind's
        // `refreshes` (pinned by `propertyUsageAndGraphEffectsReloadEachOnce`).
        let updated = registry.invalidations(by: .updatedMetadataField(id: "f1"), project: project)
        #expect(!updated.contains(.key(.evidenceGraph(project: project, graphId: "g-1"))))
        // Keyed reads invalidate nothing: each kind's `refresh` follows them.
        #expect(CatalogQueryKey.Kind.citationCounts.descriptor.refreshes.map(\.follows) == [.reads(.citations)])
        #expect(
            CatalogQueryKey.Kind.citationsByArtifact.descriptor.refreshes.map(\.follows)
                == [.reads(.citations), .reads(.citationBoards)]
        )
        #expect(
            CatalogQueryKey.Kind.evidenceGraphProgress.descriptor.refreshes.map(\.follows)
                == [.reads(.evidenceGraphProgress)]
        )
        #expect(
            CatalogQueryKey.Kind.evidenceGraphsList.descriptor.refreshes.map(\.follows)
                == [.reads(.evidenceGraphs)]
        )
        // The effect slots a key follows are declared on its kind.
        #expect(CatalogQueryKey.Kind.evidenceGraph.descriptor.refreshes.map(\.follows) == [.evidenceGraphs])
        for kind in [CatalogQueryKey.Kind.personsList, .eventsList, .placesList] {
            #expect(kind.descriptor.refreshes.map(\.follows) == [.touchedHandles, .list(.propertyVocabulary)], "\(kind)")
            guard case .run = kind.descriptor.refreshes[0].action else {
                Issue.record("\(kind)'s first refresh is not a partial re-read")
                continue
            }
        }
        // T-5 (AC-3.3): the five per-entity kinds follow their inputs and their own handle.
        for kind in [
            CatalogQueryKey.Kind.conclusionDetail, .personClaims, .personFamily, .personEvents, .personRecordLinks,
        ] {
            let descriptor = kind.descriptor
            #expect(
                descriptor.refreshes.map(\.follows)
                    == [.touchedHandles, .evidenceGraphs, .reads(.sourceRecords), .touchedHandles, .list(.propertyVocabulary)],
                "\(kind)"
            )
            #expect(descriptor.whenHidden == .markStale, "\(kind)")
            #expect(descriptor.deletedWith == .handle, "\(kind)")
        }
        // A read follows only its own entry of the effects.
        let reads = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .citations, ids: ["g-1"])])
        #expect(CatalogQueryFollows.reads(.citations).ids(in: reads) == ["g-1"])
        #expect(CatalogQueryFollows.reads(.evidenceGraphProgress).ids(in: reads).isEmpty)
        #expect(registry.hiddenPolicy(.citationCounts(project: project, graphId: "g1")) == .markStale)
        // Grades are seeded vocabulary with no CRUD surface, so nothing stales them.
        let everyMutation: [CatalogMutation] = [
            .updatedSource(source), .changedSourceType(source), .createdSource(source),
            .updatedMetadataField(id: "f1"), .deletedMetadataField(id: "f1"),
            .wroteTypeSuggestions(typeId: "t1", edit: CatalogTypeSuggestionEdit(suggestions: [], suggestedFieldCount: 0)),
            .mutatedSourceWorkspace(sourceId: "s1"),
            .wroteMetadataBoard(sourceId: "s1", owner: MetadataOwner(level: .source, id: "s1"), entries: []),
        ]
        #expect(everyMutation.allSatisfy { mutation in
            !registry.invalidations(by: mutation, project: project).contains(
                .key(.credibilityGradesList(project: project))
            )
        })
        // Writes that name their source stay narrow: a Source-page write reports
        // its handles in `WriteEffects`, so the mutation names only the page.
        #expect(registry.invalidations(by: .mutatedSourceWorkspace(sourceId: "s1"), project: project) == [
            .key(.sourceWorkspace(project: project, sourceId: "s1")),
        ])
        #expect(registry.invalidations(by: .changedSourceType(source), project: project) == [
            .key(.sourceWorkspace(project: project, sourceId: "s1")),
            .allCached(.citationsByArtifact),
        ])
    }

    /// A scope move (a note save) changes a row's last-updated time, not what
    /// the lists or detail pages show, so it invalidates nothing; the session
    /// patches the row from the write's activity.
    @Test func handleScopesInvalidateNothing() {
        let project = ProjectKey(projectDir: projectDir)
        let session = makeSession()
        session.setQueryValue(CatalogQueryKey.personsList(project: project), value: CatalogListRows<CatalogPersonSummary>())
        session.setQueryValue(CatalogQueryKey.eventsList(project: project), value: CatalogListRows<CatalogEventSummary>())
        session.setQueryValue(CatalogQueryKey.placesList(project: project), value: CatalogListRows<CatalogPlaceSummary>())
        let detailKey = CatalogQueryKey.conclusionDetail(project: project, entityId: "e1")
        let otherKey = CatalogQueryKey.conclusionDetail(project: project, entityId: "e2")
        session.setQueryValue(detailKey, value: CatalogConclusionDetail(entity: entity("e1"), fields: []))
        session.setQueryValue(otherKey, value: CatalogConclusionDetail(entity: entity("e2"), fields: []))
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handleScopes: ["e1"])).isEmpty)
        // A write that changed e1 revalidates e1's detail, not e2's; the lists merge e1's row
        // through a `.run` refresh, so they are not revalidated.
        let effects = CatalogWriteEffects(handles: ["e1"], handleScopes: ["e1", "e2"])
        #expect(session.revalidatedKeys(for: effects) == [detailKey])
    }

    private func entity(_ id: String) -> CatalogCanonicalEntity {
        CatalogCanonicalEntity(id: id, ref: "PER-\(id)", subjectTypeID: "t", label: "")
    }

    /// Adding vocabulary no longer disturbs open Source pages: the page reads the
    /// shared lists, so there is nothing stale on it to refetch.
    @Test func addingVocabularyLeavesCachedSourcePagesAlone() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let workspaceKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        let fieldsKey = CatalogQueryKey.metadataFieldsList(project: project)

        // The fields list is read on the Source page, so it is visible there and reloads at once.
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", title: "Alpha"
        ))
        #expect(session.visibleKeys.contains(fieldsKey))
        let workspaceHandle: QueryHandle<CatalogSourceWorkspace> = session.query(workspaceKey)
        let fieldsHandle: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        await waitForQuery(workspaceHandle)
        await waitForQuery(fieldsHandle)
        await session.settleWrites()
        store.heldCatalogProjectDir = nil

        store.fieldsByProject[projectDir]?.append(
            CatalogMetadataField(
                id: "f2", key: "folio", origin: "user", label: "Folio", dataType: "text", description: ""
            )
        )
        session.apply(CatalogWriteEffects(lists: [.sourceVocabulary]))
        await waitForQuery(fieldsHandle)
        #expect(fieldsHandle.value?.map(\.label) == ["Author", "Folio"])
        #expect(workspaceHandle.isFetching == false)

        // The page is untouched — re-querying it opens no catalog.
        store.heldCatalogProjectDir = nil
        let _: QueryHandle<CatalogSourceWorkspace> = session.query(workspaceKey)
        await Task.yield()
        #expect(store.heldCatalogProjectDir == nil)
    }

    /// Edits that restate a derived metadata row still reach every cached page,
    /// because the mutation cannot name which sources hold that field or type.
    @Test func derivedMetadataEditsStillInvalidateEveryCachedPage() async {
        let store = FakeStore()
        seedStore(store)
        store.sourcesByProject[projectDir]?.append(
            CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "Beta", description: "")
        )
        store.metadataByOwner[MetadataOwner(level: .source, id: "s1")] = [
            catalogMetadataEntry(catalogMetadataField("f1", label: "Author", key: "author"), suggested: true),
        ]
        store.metadataByOwner[MetadataOwner(level: .source, id: "s2")] = [
            catalogMetadataEntry(catalogMetadataField("f1", label: "Author", key: "author"), suggested: true),
        ]
        let session = makeSession(store: store)
        let project = session.projectKey
        let firstKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")
        let secondKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s2")

        let firstHandle: QueryHandle<CatalogSourceWorkspace> = session.query(firstKey)
        let secondHandle: QueryHandle<CatalogSourceWorkspace> = session.query(secondKey)
        await waitForQuery(firstHandle)
        await waitForQuery(secondHandle)

        store.metadataByOwner[MetadataOwner(level: .source, id: "s1")] = [
            catalogMetadataEntry(catalogMetadataField("f1", label: "Author name", key: "author"), suggested: true),
        ]
        store.metadataByOwner[MetadataOwner(level: .source, id: "s2")] = [
            catalogMetadataEntry(catalogMetadataField("f1", label: "Author name", key: "author"), suggested: true),
        ]
        session.apply(CatalogWriteEffects(lists: [.sourceVocabulary]), .updatedMetadataField(id: "f1"))

        let _: QueryHandle<CatalogSourceWorkspace> = session.query(firstKey)
        let _: QueryHandle<CatalogSourceWorkspace> = session.query(secondKey)
        await waitForQuery(firstHandle)
        await waitForQuery(secondHandle)
        #expect(firstHandle.value?.metadata.first?.field.label == "Author name")
        #expect(secondHandle.value?.metadata.first?.field.label == "Author name")
    }

    /// Suggestions embed a whole field row, so a relabel reaches types the edit
    /// never named: every cached list follows `source_vocabulary`.
    @Test func fieldRelabelInvalidatesEveryCachedSuggestionList() async {
        let store = FakeStore()
        seedStore(store)
        let first = store.suggestionsByType["t1"]
        store.suggestionsByType["t2"] = first
        let session = makeSession(store: store)
        let project = session.projectKey
        let firstKey = CatalogQueryKey.typeSuggestions(project: project, typeId: "t1")
        let secondKey = CatalogQueryKey.typeSuggestions(project: project, typeId: "t2")

        let firstHandle: QueryHandle<[CatalogTypeSuggestion]> = session.query(firstKey)
        let secondHandle: QueryHandle<[CatalogTypeSuggestion]> = session.query(secondKey)
        await waitForQuery(firstHandle)
        await waitForQuery(secondHandle)

        let renamed = CatalogTypeSuggestion(
            field: CatalogMetadataField(
                id: "f1", key: "author", origin: "user", label: "Author name",
                dataType: "text", description: ""
            ),
            sortOrder: 0
        )
        store.suggestionsByType["t1"] = [renamed]
        store.suggestionsByType["t2"] = [renamed]
        session.apply(CatalogWriteEffects(lists: [.sourceVocabulary]), .updatedMetadataField(id: "f1"))

        let _: QueryHandle<[CatalogTypeSuggestion]> = session.query(firstKey)
        let _: QueryHandle<[CatalogTypeSuggestion]> = session.query(secondKey)
        await waitForQuery(firstHandle)
        await waitForQuery(secondHandle)
        #expect(firstHandle.value?.first?.field.label == "Author name")
        #expect(secondHandle.value?.first?.field.label == "Author name")
    }

    /// `usedBy` gates Delete on the Metadata page, and it moves whenever a
    /// Source, Artifact, Evidence graph or Citation gains or loses a value: the
    /// write reports `metadata_field_usage`. A visible list reloads at once.
    @Test func metadataFieldUsageRevalidatesAVisibleFieldsList() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        session.apply(location: WorkspaceLocation(section: .metadata))
        let key = CatalogQueryKey.metadataFieldsList(project: session.projectKey)
        #expect(session.visibleKeys.contains(key))

        let handle: QueryHandle<[CatalogMetadataField]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.first?.usedBy == 0)

        store.fieldsByProject[projectDir]?[0].usedBy = 1
        session.apply(CatalogWriteEffects(lists: [.metadataFieldUsage]))
        await session.settleWrites()
        #expect(handle.value?.first?.usedBy == 1)
        #expect(!handle.isStale)
    }

    /// A hidden list is not read for a usage write (a Citation value save is
    /// one): it keeps its value, is marked stale, and reloads on the next query.
    @Test func metadataFieldUsageMarksAHiddenFieldsListStale() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.metadataFieldsList(project: session.projectKey)
        #expect(!session.visibleKeys.contains(key))
        #expect(session.registry.hiddenPolicy(key) == .markStale)

        let handle: QueryHandle<[CatalogMetadataField]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.first?.usedBy == 0)

        store.fieldsByProject[projectDir]?[0].usedBy = 1
        session.apply(CatalogWriteEffects(lists: [.metadataFieldUsage]))
        await session.settleWrites()
        #expect(handle.value?.first?.usedBy == 0)
        #expect(handle.isStale)

        let _: QueryHandle<[CatalogMetadataField]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.first?.usedBy == 1)
        #expect(!handle.isStale)
    }

    /// A Source create, delete or type change reports `source_type_usage`, which restates the
    /// types list's `usedBy`; a handle write's `counts` and a mutation do not.
    @Test func sourceTypeUsageRestatesTheTypesList() async {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "book", origin: "user", label: "Book", description: "", usedBy: 2),
            CatalogSourceType(id: "t2", key: "census", origin: "user", label: "Census", description: ""),
        ]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourceTypesList(project: session.projectKey)
        let handle: QueryHandle<[CatalogSourceType]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.first { $0.id == "t1" }?.usedBy == 2)

        store.sourceTypesByProject[projectDir]?[0].usedBy = 1
        session.apply(CatalogWriteEffects(lists: [.sourceTypeUsage, .counts]))
        await session.settleWrites()
        #expect(handle.value?.first { $0.id == "t1" }?.usedBy == 1)

        store.sourceTypesByProject[projectDir]?[0].usedBy = 5
        session.apply(CatalogWriteEffects(lists: [.counts]))
        session.apply(.createdSource(CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "N", description: "")))
        session.apply(.changedSourceType(CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t2", title: "N", description: "")))
        await session.settleWrites()
        #expect(handle.value?.first { $0.id == "t1" }?.usedBy == 1)
    }

    /// A Source delete reports `source_holdings` for the Source: the Sources list's re-read returns no
    /// row for it and drops it, with no whole reload and no stale mark.
    @Test func deletedSourceDropsTheListRowByItsReRead() async {
        let store = FakeStore()
        let s1 = CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: "")
        let s2 = CatalogSource(id: "s2", ref: "SRC-2", sourceTypeID: "t1", title: "Beta", description: "")
        store.sourcesByProject[projectDir] = [s1, s2]
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourcesList(project: session.projectKey)
        let handle: QueryHandle<[CatalogSource]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value?.map(\.id).sorted() == ["s1", "s2"])
        store.sourcesByProject[projectDir] = [s2]
        let callsBefore = store.listSourcesCalls

        session.apply(CatalogWriteEffects(
            reads: [CatalogWriteEffectsRead(read: .sourceHoldings, ids: ["s1"])],
            deleted: [CatalogWriteEffectsDeleted(entity: .source, ids: ["s1"])],
            activity: CatalogActivity(revision: 7, at: "2026-01-01T00:00:00Z")
        ))
        await session.settleWrites()
        #expect(handle.value?.map(\.id) == ["s2"])
        #expect(!handle.isStale)
        #expect(store.listSourcesByIDCalls == [["s1"]])
        #expect(store.listSourcesCalls == callsBefore)
    }

    /// T-10: a created Source type is appended to the warmed types list at once (a declared
    /// patch, no reload), and applying it again leaves one row.
    @Test func createdSourceTypePatchesTheTypesList() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourceTypesList(project: session.projectKey)
        let handle: QueryHandle<[CatalogSourceType]> = session.query(key)
        await waitForQuery(handle)
        let before = handle.value?.count ?? 0

        let row = CatalogSourceType(id: "t-new", key: "parish-register", origin: "user", label: "Parish register", description: "")
        session.apply(.empty, .createdSourceType(row))
        #expect(handle.value?.last == row)
        #expect(handle.value?.count == before + 1)
        #expect(!handle.isFetching)

        session.apply(.empty, .createdSourceType(row))
        #expect(handle.value?.filter { $0.id == "t-new" }.count == 1)
    }

    /// T-5 (D-3): a saved type replaces its row, a deleted type drops it, an unknown id is not
    /// appended, and neither write invalidates a key.
    @Test func updatedAndDeletedSourceTypePatchTheTypesList() async {
        let store = FakeStore()
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourceTypesList(project: session.projectKey)
        let book = CatalogSourceType(id: "t-book", key: "book", origin: "user", label: "Book", description: "")
        let census = CatalogSourceType(id: "t-census", key: "census", origin: "user", label: "Census", description: "")
        store.sourceTypesByProject[projectDir] = [book, census]
        let handle: QueryHandle<[CatalogSourceType]> = session.query(key)
        await waitForQuery(handle)
        #expect(handle.value == [book, census])

        var renamed = census
        renamed.label = "Population census"
        session.apply(.empty, .updatedSourceType(renamed))
        #expect(handle.value == [book, renamed])

        let stranger = CatalogSourceType(id: "t-new", key: "map", origin: "user", label: "Map", description: "")
        session.apply(.empty, .updatedSourceType(stranger))
        #expect(handle.value == [book, renamed])

        let bookDeleted = CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["t-book"])])
        session.apply(bookDeleted)
        #expect(handle.value == [renamed])
        session.apply(bookDeleted)
        #expect(handle.value == [renamed])
        session.apply(CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .sourceType, ids: ["gone"])]))
        #expect(handle.value == [renamed])
        #expect(!handle.isFetching)
        #expect(!handle.isStale)
        let registry = CatalogQueryRegistry.standard
        #expect(registry.invalidations(by: .updatedSourceType(renamed), project: session.projectKey).isEmpty)
    }

    /// T-7 (D-7): a suggestion write patches the type's one key and the row's count with no load,
    /// leaves another type's key alone, and marks a cached Source page stale.
    @Test func wroteTypeSuggestionsPatchesTheListAndTheCount() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let project = session.projectKey
        let publisher = CatalogMetadataField(
            id: "f2", key: "publisher", origin: "user", label: "Publisher", dataType: "text", description: ""
        )
        store.fieldsByProject[projectDir]?.append(publisher)
        store.sourceTypesByProject[projectDir] = [
            CatalogSourceType(id: "t1", key: "book", origin: "user", label: "Book", description: ""),
            CatalogSourceType(id: "t2", key: "letter", origin: "user", label: "Letter", description: ""),
        ]
        store.suggestedFieldCounts["t1"] = 1
        let book: QueryHandle<[CatalogTypeSuggestion]> = session.query(
            .typeSuggestions(project: project, typeId: "t1")
        )
        let letter: QueryHandle<[CatalogTypeSuggestion]> = session.query(
            .typeSuggestions(project: project, typeId: "t2")
        )
        let types: QueryHandle<[CatalogSourceType]> = session.query(.sourceTypesList(project: project))
        let page: QueryHandle<CatalogSourceWorkspace> = session.query(.sourceWorkspace(project: project, sourceId: "s1"))
        await waitForQuery(book)
        await waitForQuery(letter)
        await waitForQuery(types)
        await waitForQuery(page)
        #expect(book.value?.map(\.field.id) == ["f1"])
        #expect(letter.value?.isEmpty == true)
        #expect(types.value?.first?.suggestedFieldCount == 1)
        let loads = store.listTypeSuggestionsTypeIDs.count
        #expect(!page.isStale)
        // A reload of the list would now read no types.
        store.sourceTypesByProject[projectDir] = []

        let edit = CatalogTypeSuggestionEdit(
            suggestions: [CatalogTypeSuggestion(field: publisher, sortOrder: 0)], suggestedFieldCount: 2
        )
        session.apply(.wroteTypeSuggestions(typeId: "t1", edit: edit))
        await session.settleWrites()

        #expect(book.value == edit.suggestions)
        #expect(letter.value?.isEmpty == true)
        #expect(types.value?.first?.suggestedFieldCount == 2)
        #expect(store.listTypeSuggestionsTypeIDs.count == loads)
        #expect(page.isStale)
    }

    /// F-1: the generic row patch appends a row the list lacks only when `appendsOn` says so.
    @Test func aNonCreateSourceTypeMutationForAMissingRowAddsNothing() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        let key = CatalogQueryKey.sourceTypesList(project: session.projectKey)
        let handle: QueryHandle<[CatalogSourceType]> = session.query(key)
        await waitForQuery(handle)
        let before = handle.value

        let row = CatalogSourceType(id: "t-new", key: "parish-register", origin: "user", label: "Parish register", description: "")
        let patch = CatalogQueryPatch.row(
            CatalogSourceType.self,
            patched: { $0.patchedSourceType },
            appendsOn: { _ in false }
        )
        let result = patch.apply(session, key, [], CatalogActivity(), .createdSourceType(row))
        #expect(result == .unchanged)
        #expect(handle.value == before)
    }

    /// Moving a source to another type patches the list row for an instant
    /// repaint, then refetches the page because the engine derives suggested
    /// metadata rows from the type.
    @Test func changedSourceTypePatchesRowThenRefetchesPage() async {
        let store = FakeStore()
        seedStore(store)
        store.sourceTypesByProject[projectDir]?.append(
            CatalogSourceType(id: "t2", key: "photo", origin: "user", label: "Photo", description: "")
        )
        let session = makeSession(store: store)
        let project = session.projectKey
        let listKey = CatalogQueryKey.sourcesList(project: project)
        let workspaceKey = CatalogQueryKey.sourceWorkspace(project: project, sourceId: "s1")

        let listHandle: QueryHandle<[CatalogSource]> = session.query(listKey)
        let workspaceHandle: QueryHandle<CatalogSourceWorkspace> = session.query(workspaceKey)
        await waitForQuery(listHandle)
        await waitForQuery(workspaceHandle)

        let moved = CatalogSource(
            id: "s1", ref: "SRC-1", sourceTypeID: "t2", title: "Alpha", description: ""
        )
        store.sourcesByProject[projectDir] = [moved]
        store.metadataByOwner[MetadataOwner(level: .source, id: "s1")] = [
            catalogMetadataEntry(author, suggested: true),
        ]
        session.apply(.changedSourceType(moved))

        // Patched synchronously — no refetch needed for the row itself.
        #expect(listHandle.value?.first?.sourceTypeID == "t2")

        let _: QueryHandle<CatalogSourceWorkspace> = session.query(workspaceKey)
        await waitForQuery(workspaceHandle)
        #expect(workspaceHandle.value?.source.sourceTypeID == "t2")
        #expect(workspaceHandle.value?.metadata.count == 1)
    }

    /// A catalog-wide slot reports one token when the write moved it.
    @Test func catalogWideSlotsReportOneToken() {
        #expect(CatalogQueryFollows.list(.propertyVocabulary).ids(in: CatalogWriteEffects(lists: [.propertyVocabulary])) == ["property_vocabulary"])
        #expect(CatalogQueryFollows.list(.propertyVocabulary).ids(in: CatalogWriteEffects(lists: [.propertyUsage])).isEmpty)
        #expect(CatalogQueryFollows.structure.ids(in: CatalogWriteEffects(structure: true)) == ["structure"])
        #expect(CatalogQueryFollows.structure.ids(in: CatalogWriteEffects(structure: false)).isEmpty)
        #expect(CatalogQueryFollows.list(.propertyVocabulary).isCatalogWide)
        #expect(CatalogQueryFollows.structure.isCatalogWide)
        #expect(!CatalogQueryFollows.touchedHandles.isCatalogWide)
    }

    /// The Properties workspace follows the lists and structure on its own
    /// descriptor, and revalidates when a write reports one.
    @Test func propertiesWorkspaceFollowsListsAndStructure() {
        #expect(
            CatalogQueryKey.Kind.propertiesWorkspace.descriptor.refreshes.map(\.follows)
                == [.list(.propertyVocabulary), .list(.propertyUsage), .structure]
        )
        let session = makeSession()
        let key = CatalogQueryKey.propertiesWorkspace(project: session.projectKey)
        session.setQueryValue(key, value: PropertiesSnapshot.empty)
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(lists: [.propertyVocabulary])) == [key])
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(structure: true)) == [key])
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(
            handles: ["e1"],
            evidenceGraphs: ["g-1"],
            reads: [
                CatalogWriteEffectsRead(read: .citations, ids: ["g-1"]),
                CatalogWriteEffectsRead(read: .evidenceGraphProgress, ids: ["g-1"]),
            ],
            lists: [.propertyUsage],
            summaryHandles: ["e2"]
        )) == [key])
    }

    private struct ListsAndStructureCase: CustomTestStringConvertible, Sendable {
        let name: String
        let lists: Set<CatalogList>
        let structure: Bool

        var testDescription: String { name }
    }

    nonisolated private static let listsAndStructureCases: [ListsAndStructureCase] = [
        ListsAndStructureCase(name: "property vocabulary", lists: [.propertyVocabulary], structure: false),
        ListsAndStructureCase(name: "property usage", lists: [.propertyUsage], structure: false),
        ListsAndStructureCase(name: "property vocabulary and usage", lists: [.propertyVocabulary, .propertyUsage], structure: false),
        ListsAndStructureCase(name: "structure alone", lists: [], structure: true),
        ListsAndStructureCase(name: "property vocabulary and structure", lists: [.propertyVocabulary], structure: true),
    ]

    @Test(arguments: listsAndStructureCases)
    private func listsAndStructureRevalidatePropertiesOnce(_ tc: ListsAndStructureCase) async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g1", sourceSurface: .graph, title: "Alpha"
        ))
        let key = CatalogQueryKey.propertiesWorkspace(project: session.projectKey)
        #expect(session.visibleKeys.contains(key))
        let handle: QueryHandle<PropertiesSnapshot> = session.query(key)
        await waitForQuery(handle)
        let baseline = store.getPropertiesWorkspaceCalls

        session.apply(CatalogWriteEffects(lists: tc.lists, structure: tc.structure))
        await session.settleWrites()
        #expect(store.getPropertiesWorkspaceCalls == baseline + 1)
    }

    @Test func hiddenPropertiesWorkspaceIsMarkedStaleByAList() {
        let store = FakeStore()
        let session = makeSession(store: store)
        let key = CatalogQueryKey.propertiesWorkspace(project: session.projectKey)
        session.setQueryValue(key, value: PropertiesSnapshot.empty)
        let baseline = store.getPropertiesWorkspaceCalls
        session.apply(CatalogWriteEffects(lists: [.propertyVocabulary]))
        let handle: QueryHandle<PropertiesSnapshot>? = session.queryHandle(key)
        #expect(handle?.isStale == true)
        #expect(store.getPropertiesWorkspaceCalls == baseline)
    }

    /// A Subject delete's effects reload the Properties `usedBy` and the graph
    /// once each, with no mutation.
    @Test func propertyUsageAndGraphEffectsReloadEachOnce() async {
        let store = FakeStore()
        seedStore(store)
        let session = makeSession(store: store)
        session.apply(location: WorkspaceLocation(
            section: .sources, sourceId: "s1", graphId: "g1", sourceSurface: .graph, title: "Alpha"
        ))
        let propertiesKey = CatalogQueryKey.propertiesWorkspace(project: session.projectKey)
        let graphKey = CatalogQueryKey.evidenceGraph(project: session.projectKey, graphId: "g1")
        let properties: QueryHandle<PropertiesSnapshot> = session.query(propertiesKey)
        let graph: QueryHandle<EvidenceGraphRows> = session.query(graphKey)
        await waitForQuery(properties)
        await waitForQuery(graph)
        let baseline = store.getPropertiesWorkspaceCalls

        session.apply(CatalogWriteEffects(evidenceGraphs: ["g1"], lists: [.propertyUsage]))
        #expect(properties.isFetching && graph.isFetching)
        await session.settleWrites()
        #expect(store.getPropertiesWorkspaceCalls == baseline + 1)
    }

    /// The sidebar recount is not a cache key: no descriptor follows `counts`,
    /// and a catalog-wide slot reaches only a `.revalidate` refresh.
    @Test func noDescriptorFollowsCounts() {
        for kind in CatalogQueryKey.Kind.allCases {
            let descriptor = kind.descriptor
            #expect(!descriptor.refreshes.contains { $0.follows == .list(.counts) }, "\(kind)")
            for refresh in descriptor.refreshes {
                if case .run = refresh.action {
                    #expect(!refresh.follows.isCatalogWide, "\(kind)")
                }
            }
            #expect(!descriptor.patches.contains { $0.follows?.isCatalogWide == true }, "\(kind)")
        }
    }

    /// Warms one key of every kind a vocabulary family or the term read can
    /// reach, and of three it must not reach.
    private func warmedVocabularySession() -> (WorkspaceSession, [String: CatalogQueryKey]) {
        let session = makeSession()
        let project = session.projectKey
        let keys: [String: CatalogQueryKey] = [
            "sourceTypesList": .sourceTypesList(project: project),
            "metadataFieldsList": .metadataFieldsList(project: project),
            "typeSuggestions": .typeSuggestions(project: project, typeId: "t1"),
            "propertiesWorkspace": .propertiesWorkspace(project: project),
            "personsList": .personsList(project: project),
            "eventsList": .eventsList(project: project),
            "placesList": .placesList(project: project),
            "conclusionDetail": .conclusionDetail(project: project, entityId: "e1"),
            "personClaims": .personClaims(project: project, entityId: "e1"),
            "personFamily": .personFamily(project: project, entityId: "e1"),
            "personEvents": .personEvents(project: project, entityId: "e1"),
            "personRecordLinks": .personRecordLinks(project: project, entityId: "e1"),
            "propertyTerms(p1)": .propertyTerms(project: project, propertyId: "p1"),
            "propertyTerms(p2)": .propertyTerms(project: project, propertyId: "p2"),
            "sourceWorkspace": .sourceWorkspace(project: project, sourceId: "s1"),
            "evidenceGraph": .evidenceGraph(project: project, graphId: "g1"),
            "citationsByArtifact": .citationsByArtifact(project: project, graphId: "g1", artifactId: "a1"),
        ]
        session.setQueryValue(keys["sourceTypesList"]!, value: [CatalogSourceType]())
        session.setQueryValue(keys["metadataFieldsList"]!, value: [CatalogMetadataField]())
        session.setQueryValue(keys["typeSuggestions"]!, value: [CatalogTypeSuggestion]())
        session.setQueryValue(keys["propertiesWorkspace"]!, value: PropertiesSnapshot.empty)
        session.setQueryValue(keys["personsList"]!, value: CatalogListRows<CatalogPersonSummary>())
        session.setQueryValue(keys["eventsList"]!, value: CatalogListRows<CatalogEventSummary>())
        session.setQueryValue(keys["placesList"]!, value: CatalogListRows<CatalogPlaceSummary>())
        session.setQueryValue(keys["conclusionDetail"]!, value: CatalogConclusionDetail(entity: entity("e1"), fields: []))
        session.setQueryValue(keys["personClaims"]!, value: CatalogPersonClaims())
        session.setQueryValue(keys["personFamily"]!, value: CatalogPersonFamily(units: []))
        session.setQueryValue(keys["personEvents"]!, value: CatalogPersonTimeline())
        session.setQueryValue(keys["personRecordLinks"]!, value: CatalogPersonRecordLinks())
        session.setQueryValue(keys["propertyTerms(p1)"]!, value: [CatalogPropertyTerm]())
        session.setQueryValue(keys["propertyTerms(p2)"]!, value: [CatalogPropertyTerm]())
        session.setQueryValue(keys["sourceWorkspace"]!, value: CatalogSourceWorkspace(
            source: CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "t1", title: "Alpha", description: ""),
            notes: [], metadata: [], artifacts: [], credibility: nil
        ))
        session.setQueryValue(keys["evidenceGraph"]!, value: EvidenceGraphRows(
            graphId: "g1"
        ))
        session.setQueryValue(keys["citationsByArtifact"]!, value: [CatalogListedCitation]())
        return (session, keys)
    }

    private struct FamilyCase: CustomTestStringConvertible, Sendable {
        let name: String
        let effects: CatalogWriteEffects
        let reached: Set<String>

        var testDescription: String { name }
    }

    nonisolated private static let familyCases: [FamilyCase] = [
        FamilyCase(
            name: "source vocabulary",
            effects: CatalogWriteEffects(lists: [.sourceVocabulary]),
            reached: ["sourceTypesList", "metadataFieldsList", "typeSuggestions"]
        ),
        FamilyCase(
            name: "property vocabulary",
            effects: CatalogWriteEffects(lists: [.propertyVocabulary]),
            reached: [
                "propertiesWorkspace", "personsList", "eventsList", "placesList",
                "conclusionDetail", "personClaims", "personFamily", "personEvents", "personRecordLinks",
            ]
        ),
        FamilyCase(
            name: "the term read of one Property",
            effects: CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .propertyTerms, ids: ["p1"])]),
            reached: ["propertyTerms(p1)"]
        ),
    ]

    /// T-5: each vocabulary family reaches exactly the keys that hold its
    /// labels, and a term write only its Property's term list. No family
    /// reaches a Source page or a canvas.
    @Test(arguments: familyCases)
    private func listFamiliesReachTheirKeys(_ tc: FamilyCase) {
        let (session, keys) = warmedVocabularySession()
        let reached = Set(session.revalidatedKeys(for: tc.effects))
        #expect(reached == Set(tc.reached.map { keys[$0]! }))
    }

    /// T-6: no remaining mutation reaches a Conclusion key; Conclusion keys
    /// follow their effects.
    @Test func noMutationReachesAConclusionKey() {
        let registry = CatalogQueryRegistry.standard
        let project = ProjectKey(projectDir: projectDir)
        let source = CatalogSource(id: "s1", ref: "SRC-1", sourceTypeID: "", title: "T", description: "")
        let conclusionKinds: Set<CatalogQueryKey.Kind> = [
            .personsList, .eventsList, .placesList, .conclusionDetail, .personClaims, .personFamily, .personEvents,
            .personRecordLinks,
        ]
        let mutations: [CatalogMutation] = [
            .updatedSource(source), .changedSourceType(source), .createdSource(source),
            .updatedMetadataField(id: "f1"), .deletedMetadataField(id: "f1"),
            .wroteTypeSuggestions(typeId: "t1", edit: CatalogTypeSuggestionEdit(suggestions: [], suggestedFieldCount: 0)),
            .mutatedSourceWorkspace(sourceId: "s1"),
            .wroteMetadataBoard(sourceId: "s1", owner: MetadataOwner(level: .source, id: "s1"), entries: []),
        ]
        for mutation in mutations {
            for invalidation in registry.invalidations(by: mutation, project: project) {
                switch invalidation {
                case .key(let key):
                    #expect(!conclusionKinds.contains(key.kind), "\(mutation) \(key)")
                case .allCached(let kind):
                    #expect(!conclusionKinds.contains(kind), "\(mutation) \(kind)")
                }
            }
        }
    }

    @Test func evidenceGraphsListLoadsFromStore() async throws {
        let store = FakeStore()
        let graph = CatalogEvidenceGraph(
            id: "g1", ref: "GPH-AAAAA", sourceID: "s1", name: "Default", description: "", artifactIDs: ["a1"]
        )
        store.evidenceGraphsByProject[projectDir] = [graph]
        let session = makeSession(store: store)
        let handle: QueryHandle<[CatalogEvidenceGraph]> = session.query(
            .evidenceGraphsList(project: session.projectKey)
        )
        await waitForQuery(handle)
        #expect(handle.value == [graph])
    }

    /// T-14: a hidden graph canvas and a hidden Source page go stale; they do not reload.
    @Test func graphAndSourcePageKeysMarkStaleWhenHidden() {
        let project = ProjectKey(projectDir: projectDir)
        let registry = CatalogQueryRegistry.standard
        #expect(registry.hiddenPolicy(.evidenceGraph(project: project, graphId: "g-1")) == .markStale)
        #expect(registry.hiddenPolicy(.sourceWorkspace(project: project, sourceId: "s1")) == .markStale)
    }

    @Test func evidenceGraphsListMarksStaleWhenHidden() {
        let project = ProjectKey(projectDir: projectDir)
        #expect(CatalogQueryRegistry.standard.hiddenPolicy(.evidenceGraphsList(project: project)) == .markStale)
    }

    /// A write that touches a handle revalidates the cached `personClaims` key through `touchedHandles`;
    /// the key is marked stale while hidden.
    @Test func personClaimsRevalidateOnTouchedHandle() {
        let session = makeSession()
        let project = session.projectKey
        let key = CatalogQueryKey.personClaims(project: project, entityId: "e1")
        session.setQueryValue(key, value: CatalogPersonClaims())
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e1"])) == [key])
        #expect(key.kind == .personClaims)
        #expect(key.project == project)
        #expect(CatalogQueryRegistry.standard.hiddenPolicy(key) == .markStale)
    }

    /// T-11 (AC-2.4): the key loads through the store; an unseeded handle is
    /// coded not found, as Go answers for an unknown handle.
    @Test func personClaimsLoadThroughTheStore() async throws {
        let store = FakeStore()
        let group = CatalogPersonClaimGroup(
            sourceID: "s1", sourceRef: "SRC-1", title: "Alpha", sourceTypeID: "t1", claims: []
        )
        store.seededPersonClaims = ["e1": [group], "e2": []]
        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogPersonClaims> = session.query(
            .personClaims(project: session.projectKey, entityId: "e1")
        )
        await waitForQuery(handle)
        #expect(handle.value?.groups == [group])
        let none = try await store.listPersonClaims(projectDir: projectDir, entityID: "e2")
        #expect(none.groups.isEmpty)
        await #expect(throws: CoreInvokeError.coded(status: 1, code: "conclusiondetails.not_found", kind: .user, params: [])) {
            _ = try await store.listPersonClaims(projectDir: projectDir, entityID: "e9")
        }
    }

    /// A write that touches a handle revalidates the cached `personFamily` key through its own handle;
    /// the key is marked stale while hidden.
    @Test func personFamilyRevalidateOnTouchedHandle() {
        let session = makeSession()
        let project = session.projectKey
        let key = CatalogQueryKey.personFamily(project: project, entityId: "e1")
        session.setQueryValue(key, value: CatalogPersonFamily(units: []))
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e1"])) == [key])
        #expect(key.kind == .personFamily)
        #expect(key.project == project)
        #expect(CatalogQueryRegistry.standard.hiddenPolicy(key) == .markStale)
        #expect(CatalogQueryKey.Kind.personFamily.descriptor.refreshes.map(\.follows) == [
            .touchedHandles, .evidenceGraphs, .reads(.sourceRecords), .touchedHandles, .list(.propertyVocabulary),
        ])
    }

    /// T-7 (AC-4.1): the key loads through the store; an unseeded handle is
    /// coded not found, as Go answers for an unknown handle.
    @Test func personFamilyLoadsThroughTheStore() async throws {
        let store = FakeStore()
        let entity = CatalogCanonicalEntity(id: "e2", ref: "PER-2", subjectTypeID: "t-person", label: "")
        let family = CatalogPersonFamily(units: [
            CatalogFamilyUnit(
                kind: .partner,
                partners: [CatalogFamilyMember(
                    person: CatalogPersonSummary(entity: entity, name: nil, nameValueCount: 0),
                    link: CatalogFamilyLink(
                        recorded: false,
                        associationIDs: ["a1"],
                        implied: [CatalogKinshipShape(pattern: .marriageSpouses, pivotID: "m1")]
                    )
                )],
                children: []
            ),
        ])
        store.seededPersonFamilies = ["e1": family]
        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogPersonFamily> = session.query(
            .personFamily(project: session.projectKey, entityId: "e1")
        )
        await waitForQuery(handle)
        #expect(handle.value == family)
        await #expect(throws: CoreInvokeError.coded(status: 1, code: "conclusiondetails.not_found", kind: .user, params: [])) {
            _ = try await store.getPersonFamily(projectDir: projectDir, entityID: "e9")
        }
    }

    /// A write that touches a handle revalidates the cached `personEvents` key through its own handle;
    /// the key is marked stale while hidden.
    @Test func personEventsRevalidateOnTouchedHandle() {
        let session = makeSession()
        let project = session.projectKey
        let key = CatalogQueryKey.personEvents(project: project, entityId: "e1")
        session.setQueryValue(key, value: CatalogPersonTimeline())
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e1"])) == [key])
        #expect(key.kind == .personEvents)
        #expect(key.project == project)
        #expect(CatalogQueryRegistry.standard.hiddenPolicy(key) == .markStale)
        #expect(CatalogQueryKey.Kind.personEvents.descriptor.refreshes.map(\.follows) == [
            .touchedHandles, .evidenceGraphs, .reads(.sourceRecords), .touchedHandles, .list(.propertyVocabulary),
        ])
    }

    /// A write that names a graph or Source the value holds, or the Person's own handle,
    /// revalidates the cached `personRecordLinks` key; a write that names only a
    /// handle and a graph it does not hold does not, and a Source's activity
    /// without its words does not either. The key is marked stale while hidden.
    @Test func personRecordLinksRevalidate() {
        let session = makeSession()
        let project = session.projectKey
        let key = CatalogQueryKey.personRecordLinks(project: project, entityId: "e1")
        session.setQueryValue(key, value: CatalogPersonRecordLinks(
            graphs: [
                CatalogRecordLinksGraph(graphID: "g1", graphRef: "", graphName: "", sourceID: "s1", sourceTitle: ""),
                CatalogRecordLinksGraph(graphID: "g2", graphRef: "", graphName: "", sourceID: "s2", sourceTitle: ""),
            ],
            inputs: CatalogPageInputs(handles: ["e1"], evidenceGraphs: ["g1", "g2"], sources: ["s1", "s2"])
        ))
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(evidenceGraphs: ["g1"])) == [key])
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e1"])) == [key])
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(handles: ["e7"], evidenceGraphs: ["g9"])).isEmpty)
        let words = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1"])])
        #expect(session.revalidatedKeys(for: words) == [key])
        let otherWords = CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s9"])])
        #expect(session.revalidatedKeys(for: otherWords).isEmpty)
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(sourceScopes: ["s1"])).isEmpty)
        #expect(session.revalidatedKeys(for: CatalogWriteEffects(lists: [.propertyVocabulary])).contains(key))
        #expect(key.kind == .personRecordLinks)
        #expect(key.project == project)
        #expect(CatalogQueryRegistry.standard.hiddenPolicy(key) == .markStale)
        #expect(
            CatalogQueryKey.Kind.personRecordLinks.descriptor.refreshes.map(\.follows)
                == [.touchedHandles, .evidenceGraphs, .reads(.sourceRecords), .touchedHandles, .list(.propertyVocabulary)]
        )
    }

    /// The key loads through the store; an unseeded handle is coded not found,
    /// as Go answers for an unknown handle.
    @Test func personRecordLinksLoadThroughTheStore() async throws {
        let store = FakeStore()
        let links = CatalogPersonRecordLinks(
            graphs: [
                CatalogRecordLinksGraph(graphID: "g1", graphRef: "EG-1", graphName: "Default", sourceID: "s1", sourceTitle: "A"),
                CatalogRecordLinksGraph(graphID: "g2", graphRef: "", graphName: "Default", sourceID: "s2", sourceTitle: "B"),
            ],
            pairs: [CatalogRecordLinksPair(
                graphAID: "g1", graphBID: "g2",
                lines: [CatalogRecordLink(entityID: "e2", strength: .weak), CatalogRecordLink(entityID: "e3", strength: .strong)]
            )]
        )
        store.seededPersonRecordLinks = ["e1": links]
        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogPersonRecordLinks> = session.query(
            .personRecordLinks(project: session.projectKey, entityId: "e1")
        )
        await waitForQuery(handle)
        #expect(handle.value == links)
        await #expect(throws: CoreInvokeError.coded(status: 1, code: "conclusiondetails.not_found", kind: .user, params: [])) {
            _ = try await store.getPersonRecordLinks(projectDir: projectDir, entityID: "e9")
        }
    }

    /// T-7 (AC-4.1): the key loads through the store; an unseeded handle is
    /// coded not found, as Go answers for an unknown handle.
    @Test func personEventsLoadThroughTheStore() async throws {
        let store = FakeStore()
        let person = CatalogCanonicalEntity(id: "e2", ref: "PER-2", subjectTypeID: "t-person", label: "")
        let event = CatalogCanonicalEntity(id: "ev1", ref: "EVT-1", subjectTypeID: "t-event", label: "")
        let witness = CatalogConclusionValue.term(id: "r1", key: "witness", label: "Witness", origin: CatalogOrigin.provenencia)
        let events = [
            CatalogPersonEvent(
                event: CatalogEventSummary(entity: event, title: CatalogEventTitle(rule: .ref, ref: "EVT-1")),
                roles: [witness],
                participants: [CatalogEventParticipant(
                    person: CatalogPersonSummary(entity: person, name: nil, nameValueCount: 0),
                    roles: [witness]
                )],
                span: CatalogTimelineSpan(from: 1880, to: 1881, openStart: true, openEnd: false)
            ),
            CatalogPersonEvent(
                event: CatalogEventSummary(entity: event, title: CatalogEventTitle(rule: .ref, ref: "EVT-2")),
                roles: [],
                participants: []
            ),
        ]
        let timeline = CatalogPersonTimeline(
            events: events,
            birth: CatalogLifeMarker(eventId: nil, place: .before(eventId: "ev1")),
            death: CatalogLifeMarker(eventId: "ev1", place: nil)
        )
        store.seededPersonEvents = ["e1": timeline]
        let session = makeSession(store: store)
        let handle: QueryHandle<CatalogPersonTimeline> = session.query(
            .personEvents(project: session.projectKey, entityId: "e1")
        )
        await waitForQuery(handle)
        #expect(handle.value == timeline)
        #expect(handle.value?.events.map(\.dated) == [true, false])
        #expect(CatalogPersonTimeline().birth == CatalogLifeMarker(eventId: nil, place: nil))
        #expect(CatalogPersonTimeline().death == CatalogLifeMarker(eventId: nil, place: nil))
        await #expect(throws: CoreInvokeError.coded(status: 1, code: "conclusiondetails.not_found", kind: .user, params: [])) {
            _ = try await store.listPersonEvents(projectDir: projectDir, entityID: "e9")
        }
    }
}

@Suite(.serialized)
@MainActor
struct ProvenanceSheetKeyTests {
    private let projectKey = ProjectKey(projectDir: "/tmp/provenance-sheet-key.provenencia")

    /// T-2 (D-2): the key's ids are sorted and distinct; a reply with an id twice builds one entry; a write
    /// reaching the value's Sources reloads it.
    @Test func provenanceSheetKeySortsAndFollowsInputs() async {
        let key = CatalogQueryKey.provenanceSheet(project: projectKey, citationIds: ["b", "a", "a", ""])
        #expect(key.ids == ["a", "b"])

        let reply = CatalogRenderedCitations(
            citations: [renderedCitation("a"), renderedCitation("a", key: "other")], inputs: .init())
        #expect(CatalogProvenanceSheetRead(reply).citations.count == 1)
        #expect(CatalogProvenanceSheetRead(reply).citations["a"]?.groupKey == "full:a")

        let store = FakeStore()
        store.renderCitationsReplies = ["a": renderedCitation("a"), "b": renderedCitation("b")]
        store.renderCitationsInputs = CatalogPageInputs(sources: ["s1"])
        let session = WorkspaceSession(projectKey: projectKey, store: store)
        let handle: QueryHandle<CatalogProvenanceSheetRead> = session.query(key)
        await waitForQuery(handle)
        #expect(store.renderCitationsCalls == [["a", "b"]])

        session.apply(CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1"])]))
        await session.settleWrites()
        #expect(store.renderCitationsCalls.count == 2)
    }
}

@Suite
struct CatalogWriteEffectsDeletedTests {
    @Test func deletedHandlesReadsTheHandleEntry() {
        let effects = CatalogWriteEffects(deleted: [CatalogWriteEffectsDeleted(entity: .handle, ids: ["a", "b"])])
        #expect(effects.deletedHandles == ["a", "b"])
    }

    @Test func deletedHandlesIsEmptyWithoutAnEntry() {
        #expect(CatalogWriteEffects().deletedHandles.isEmpty)
    }
}
