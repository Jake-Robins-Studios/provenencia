import Foundation

struct GoStore: GenealogyStore {
    func installIdentity(identityDir: String) async throws -> InstallIdentity? {
        var req = Provenencia_Engine_V1_GetInstallIdentityRequest()
        req.identityDir = identityDir
        let resp: Provenencia_Engine_V1_GetInstallIdentityResponse = try await provenenciaCall(
            method: CoreMethod.getInstallIdentity,
            request: req
        )
        guard resp.found else {
            return nil
        }
        return InstallIdentity(userID: resp.userID, displayName: resp.displayName, ref: resp.ref)
    }

    func completeOnboarding(
        identityDir: String,
        parentDir: String,
        displayName: String,
        familyName: String
    ) async throws -> OnboardingResult {
        var req = Provenencia_Engine_V1_CompleteOnboardingRequest()
        req.identityDir = identityDir
        req.parentDir = parentDir
        req.displayName = displayName
        req.familyName = familyName
        let resp: Provenencia_Engine_V1_CompleteOnboardingResponse = try await provenenciaCall(
            method: CoreMethod.completeOnboarding,
            request: req
        )
        return OnboardingResult(
            projectDir: resp.projectDir,
            userID: resp.userID,
            displayName: resp.displayName,
            ref: resp.ref,
            project: Self.mapProject(resp.project)
        )
    }

    func activeProject(identityDir: String) async throws -> String? {
        var req = Provenencia_Engine_V1_GetActiveProjectRequest()
        req.identityDir = identityDir
        let resp: Provenencia_Engine_V1_GetActiveProjectResponse = try await provenenciaCall(
            method: CoreMethod.getActiveProject,
            request: req
        )
        guard resp.found else {
            return nil
        }
        return resp.projectDir
    }

    func openProject(
        identityDir: String,
        projectDir: String,
        displayName: String,
        adoptUserID: String
    ) async throws -> OnboardingResult {
        var req = Provenencia_Engine_V1_OpenProjectRequest()
        req.identityDir = identityDir
        req.projectDir = projectDir
        req.displayName = displayName
        req.adoptUserID = adoptUserID
        let resp: Provenencia_Engine_V1_OpenProjectResponse = try await provenenciaCall(
            method: CoreMethod.openProject,
            request: req
        )
        return OnboardingResult(
            projectDir: resp.projectDir,
            userID: resp.userID,
            displayName: resp.displayName,
            ref: resp.ref,
            project: Self.mapProject(resp.project)
        )
    }

    func listProjectUsers(projectDir: String) async throws -> [InstallIdentity] {
        var req = Provenencia_Engine_V1_ListProjectUsersRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_ListProjectUsersResponse = try await provenenciaCall(
            method: CoreMethod.listProjectUsers,
            request: req
        )
        return resp.users.map {
            InstallIdentity(userID: $0.userID, displayName: $0.displayName, ref: $0.ref)
        }
    }

    func removeActiveProject(identityDir: String) async throws {
        var req = Provenencia_Engine_V1_RemoveActiveProjectRequest()
        req.identityDir = identityDir
        let _: Provenencia_Engine_V1_RemoveActiveProjectResponse = try await provenenciaCall(
            method: CoreMethod.removeActiveProject,
            request: req
        )
    }

    func signOut(identityDir: String) async throws {
        var req = Provenencia_Engine_V1_SignOutRequest()
        req.identityDir = identityDir
        let _: Provenencia_Engine_V1_SignOutResponse = try await provenenciaCall(
            method: CoreMethod.signOut,
            request: req
        )
    }

    func closeCatalogSession(projectDir: String) async throws {
        var req = Provenencia_Engine_V1_CloseCatalogSessionRequest()
        req.projectDir = projectDir
        let _: Provenencia_Engine_V1_CloseCatalogSessionResponse = try await provenenciaCall(
            method: CoreMethod.closeCatalogSession,
            request: req
        )
    }

    func projectInfo(projectDir: String) async throws -> ProjectInfo {
        var req = Provenencia_Engine_V1_GetProjectInfoRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_GetProjectInfoResponse = try await provenenciaCall(
            method: CoreMethod.getProjectInfo,
            request: req
        )
        return Self.mapProject(resp.project)
    }

    func listSources(projectDir: String, sourceIDs: [String]) async throws -> [CatalogSource] {
        var req = Provenencia_Engine_V1_ListSourcesRequest()
        req.projectDir = projectDir
        req.sourceIds = sourceIDs
        let resp: Provenencia_Engine_V1_ListSourcesResponse = try await provenenciaCall(
            method: CoreMethod.listSources,
            request: req
        )
        return resp.sources.map(Self.mapSource)
    }

    func getDraftMetadataBoard(projectDir: String, parents: [MetadataOwner], level: Level) async throws
        -> [CatalogMetadataEntry]
    {
        var req = Provenencia_Engine_V1_GetDraftMetadataBoardRequest()
        req.projectDir = projectDir
        req.parents = parents.map(Self.wireOwner)
        req.level = level.rawValue
        let resp: Provenencia_Engine_V1_GetDraftMetadataBoardResponse = try await provenenciaCall(
            method: CoreMethod.getDraftMetadataBoard,
            request: req
        )
        return resp.entries.map(Self.mapMetadataEntry)
    }

    func getSourceWorkspace(projectDir: String, sourceID: String) async throws -> CatalogSourceWorkspace {
        var req = Provenencia_Engine_V1_GetSourceWorkspaceRequest()
        req.projectDir = projectDir
        req.sourceID = sourceID
        let resp: Provenencia_Engine_V1_GetSourceWorkspaceResponse = try await provenenciaCall(
            method: CoreMethod.getSourceWorkspace,
            request: req
        )
        return CatalogSourceWorkspace(
            source: Self.mapSource(resp.source),
            notes: resp.notes.map(Self.mapNote),
            metadata: resp.metadata.map(Self.mapMetadataEntry),
            artifacts: resp.artifacts.map(Self.mapArtifact),
            credibility: resp.hasCredibility ? Self.mapCredibility(resp.credibility) : nil,
            artifactMetadata: Dictionary(
                resp.artifactMetadata.map { ($0.ownerID, $0.entries.map(Self.mapMetadataEntry)) },
                uniquingKeysWith: { _, last in last }
            ),
            graphMetadata: Dictionary(
                resp.graphMetadata.map { ($0.ownerID, $0.entries.map(Self.mapMetadataEntry)) },
                uniquingKeysWith: { _, last in last }
            )
        )
    }

    func createSource(
        projectDir: String,
        userID: String,
        sourceTypeID: String,
        title: String,
        description: String
    ) async throws -> (CatalogSource, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateSourceRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceTypeID = sourceTypeID
        req.title = title
        req.description_p = description
        let resp: Provenencia_Engine_V1_CreateSourceResponse = try await provenenciaCall(
            method: CoreMethod.createSource,
            request: req
        )
        return (Self.mapSource(resp.source), Self.mapWriteEffects(resp.effects))
    }

    func copySource(
        projectDir: String,
        userID: String,
        sourceID: String,
        title: String,
        sourceTypeID: String,
        copyDescription: Bool,
        copyMetadata: Bool,
        copyCredibility: Bool,
        copyDate: Bool,
        artifactIDs: [String]
    ) async throws -> (CatalogSource, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CopySourceRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.title = title
        req.sourceTypeID = sourceTypeID
        req.copyDescription = copyDescription
        req.copyMetadata = copyMetadata
        req.copyCredibility = copyCredibility
        req.copyDate = copyDate
        req.artifactIds = artifactIDs
        let resp: Provenencia_Engine_V1_CopySourceResponse = try await provenenciaCall(
            method: CoreMethod.copySource,
            request: req
        )
        return (Self.mapSource(resp.source), Self.mapWriteEffects(resp.effects))
    }

    func updateSource(
        projectDir: String,
        userID: String,
        sourceID: String,
        sourceTypeID: String,
        title: String,
        description: String
    ) async throws -> (CatalogSource, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateSourceRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.sourceTypeID = sourceTypeID
        req.title = title
        req.description_p = description
        let resp: Provenencia_Engine_V1_UpdateSourceResponse = try await provenenciaCall(
            method: CoreMethod.updateSource,
            request: req
        )
        return (Self.mapSource(resp.source), Self.mapWriteEffects(resp.effects))
    }

    func setSourceCover(
        projectDir: String,
        userID: String,
        sourceID: String,
        coverMode: String,
        primaryArtifactID: String
    ) async throws -> (CatalogSource, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_SetSourceCoverRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.coverMode = coverMode
        req.primaryArtifactID = primaryArtifactID
        let resp: Provenencia_Engine_V1_SetSourceCoverResponse = try await provenenciaCall(
            method: CoreMethod.setSourceCover,
            request: req
        )
        return (Self.mapSource(resp.source), Self.mapWriteEffects(resp.effects))
    }

    func setSourceDate(
        projectDir: String,
        userID: String,
        sourceID: String,
        date: CatalogDateValueInput?
    ) async throws -> (CatalogSource, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_SetSourceDateRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        if let date { req.date = Self.mapDateValueToProto(date) }
        let resp: Provenencia_Engine_V1_SetSourceDateResponse = try await provenenciaCall(
            method: CoreMethod.setSourceDate,
            request: req
        )
        return (Self.mapSource(resp.source), Self.mapWriteEffects(resp.effects))
    }

    func setSourcePublic(
        projectDir: String,
        userID: String,
        sourceID: String,
        isPublic: Bool
    ) async throws -> (CatalogSource, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_SetSourcePublicRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.isPublic = isPublic
        let resp: Provenencia_Engine_V1_SetSourcePublicResponse = try await provenenciaCall(
            method: CoreMethod.setSourcePublic,
            request: req
        )
        return (Self.mapSource(resp.source), Self.mapWriteEffects(resp.effects))
    }

    func addSourceNote(projectDir: String, userID: String, sourceID: String, body: String) async throws
        -> (CatalogSourceNote, CatalogWriteEffects)
    {
        var req = Provenencia_Engine_V1_AddSourceNoteRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.body = body
        let resp: Provenencia_Engine_V1_AddSourceNoteResponse = try await provenenciaCall(
            method: CoreMethod.addSourceNote,
            request: req
        )
        return (Self.mapNote(resp.note), Self.mapWriteEffects(resp.effects))
    }

    func deleteSource(projectDir: String, userID: String, sourceID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteSourceRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        let resp: Provenencia_Engine_V1_DeleteSourceResponse = try await provenenciaCall(
            method: CoreMethod.deleteSource,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func updateSourceNote(projectDir: String, userID: String, noteID: String, body: String) async throws
        -> (CatalogSourceNote, CatalogWriteEffects)
    {
        var req = Provenencia_Engine_V1_UpdateSourceNoteRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.noteID = noteID
        req.body = body
        let resp: Provenencia_Engine_V1_UpdateSourceNoteResponse = try await provenenciaCall(
            method: CoreMethod.updateSourceNote,
            request: req
        )
        return (Self.mapNote(resp.note), Self.mapWriteEffects(resp.effects))
    }

    func deleteSourceNote(projectDir: String, userID: String, noteID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteSourceNoteRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.noteID = noteID
        let resp: Provenencia_Engine_V1_DeleteSourceNoteResponse = try await provenenciaCall(
            method: CoreMethod.deleteSourceNote,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func setMetadata(
        projectDir: String,
        userID: String,
        owner: MetadataOwner,
        fieldID: String,
        valueText: String
    ) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_SetMetadataRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.owner = Self.wireOwner(owner)
        req.fieldID = fieldID
        req.valueText = valueText
        let resp: Provenencia_Engine_V1_SetMetadataResponse = try await provenenciaCall(
            method: CoreMethod.setMetadata,
            request: req
        )
        return (resp.metadata.map(Self.mapMetadataEntry), Self.mapWriteEffects(resp.effects))
    }

    func clearMetadata(
        projectDir: String, userID: String, owner: MetadataOwner, fieldID: String
    ) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_ClearMetadataRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.owner = Self.wireOwner(owner)
        req.fieldID = fieldID
        let resp: Provenencia_Engine_V1_ClearMetadataResponse = try await provenenciaCall(
            method: CoreMethod.clearMetadata,
            request: req
        )
        return (resp.metadata.map(Self.mapMetadataEntry), Self.mapWriteEffects(resp.effects))
    }

    func dismissMetadataSuggestion(
        projectDir: String,
        userID: String,
        owner: MetadataOwner,
        fieldID: String
    ) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_DismissMetadataSuggestionRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.owner = Self.wireOwner(owner)
        req.fieldID = fieldID
        let resp: Provenencia_Engine_V1_DismissMetadataSuggestionResponse = try await provenenciaCall(
            method: CoreMethod.dismissMetadataSuggestion,
            request: req
        )
        return (resp.metadata.map(Self.mapMetadataEntry), Self.mapWriteEffects(resp.effects))
    }

    func reorderMetadata(
        projectDir: String,
        userID: String,
        owner: MetadataOwner,
        fieldIDs: [String]
    ) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_ReorderMetadataRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.owner = Self.wireOwner(owner)
        req.fieldIds = fieldIDs
        let resp: Provenencia_Engine_V1_ReorderMetadataResponse = try await provenenciaCall(
            method: CoreMethod.reorderMetadata,
            request: req
        )
        return (resp.metadata.map(Self.mapMetadataEntry), Self.mapWriteEffects(resp.effects))
    }

    func createArtifact(
        projectDir: String,
        userID: String,
        sourceID: String,
        fileID: String,
        label: String,
        description: String,
        graphIDs: [String]?,
        metadata: CatalogMetadataDraft?
    ) async throws -> (artifact: CatalogArtifact, metadata: [CatalogMetadataEntry], effects: CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateArtifactRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.fileID = fileID
        req.label = label
        req.description_p = description
        if let graphIDs {
            req.graphLinks = Provenencia_Engine_V1_GraphLinks.with { $0.graphIds = graphIDs }
        }
        if let metadata { req.metadata = Self.mapMetadataDraft(metadata) }
        let resp: Provenencia_Engine_V1_CreateArtifactResponse = try await provenenciaCall(
            method: CoreMethod.createArtifact,
            request: req
        )
        return (
            Self.mapArtifact(resp.artifact), resp.metadata.map(Self.mapMetadataEntry),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func updateArtifact(
        projectDir: String,
        userID: String,
        artifactID: String,
        label: String,
        description: String,
        graphIDs: [String]?,
        metadata: CatalogMetadataDraft?
    ) async throws -> (artifact: CatalogArtifact, metadata: [CatalogMetadataEntry], effects: CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateArtifactRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.artifactID = artifactID
        req.label = label
        req.description_p = description
        if let graphIDs {
            req.graphLinks = Provenencia_Engine_V1_GraphLinks.with { $0.graphIds = graphIDs }
        }
        if let metadata { req.metadata = Self.mapMetadataDraft(metadata) }
        let resp: Provenencia_Engine_V1_UpdateArtifactResponse = try await provenenciaCall(
            method: CoreMethod.updateArtifact,
            request: req
        )
        return (
            Self.mapArtifact(resp.artifact), resp.metadata.map(Self.mapMetadataEntry),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func deleteArtifact(projectDir: String, userID: String, artifactID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteArtifactRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.artifactID = artifactID
        let resp: Provenencia_Engine_V1_DeleteArtifactResponse = try await provenenciaCall(
            method: CoreMethod.deleteArtifact,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func ingestArtifactFile(
        projectDir: String,
        userID: String,
        artifactID: String,
        path: String
    ) async throws -> (artifact: CatalogArtifact, file: CatalogFileRef, reused: Bool, effects: CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_IngestArtifactFileRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.artifactID = artifactID
        req.path = path
        let resp: Provenencia_Engine_V1_IngestArtifactFileResponse = try await provenenciaCall(
            method: CoreMethod.ingestArtifactFile,
            request: req
        )
        return (
            Self.mapArtifact(resp.artifact), Self.mapFile(resp.file), resp.reused,
            Self.mapWriteEffects(resp.effects)
        )
    }

    func listEvidenceGraphs(projectDir: String, sourceID: String?) async throws -> [CatalogEvidenceGraph] {
        var req = Provenencia_Engine_V1_ListEvidenceGraphsRequest()
        req.projectDir = projectDir
        if let sourceID { req.sourceID = sourceID }
        let resp: Provenencia_Engine_V1_ListEvidenceGraphsResponse = try await provenenciaCall(
            method: CoreMethod.listEvidenceGraphs,
            request: req
        )
        return resp.graphs.map(Self.mapEvidenceGraph)
    }

    func createEvidenceGraph(
        projectDir: String,
        userID: String,
        sourceID: String,
        name: String,
        description: String,
        artifactIDs: [String],
        metadata: CatalogMetadataDraft?
    ) async throws -> (graph: CatalogEvidenceGraph, metadata: [CatalogMetadataEntry], effects: CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateEvidenceGraphRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.name = name
        req.description_p = description
        req.artifactIds = artifactIDs
        if let metadata { req.metadata = Self.mapMetadataDraft(metadata) }
        let resp: Provenencia_Engine_V1_CreateEvidenceGraphResponse = try await provenenciaCall(
            method: CoreMethod.createEvidenceGraph,
            request: req
        )
        return (
            Self.mapEvidenceGraph(resp.graph), resp.metadata.map(Self.mapMetadataEntry),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func updateEvidenceGraph(
        projectDir: String,
        userID: String,
        graphID: String,
        name: String,
        description: String,
        artifactIDs: [String],
        metadata: CatalogMetadataDraft?
    ) async throws -> (metadata: [CatalogMetadataEntry], effects: CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateEvidenceGraphRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.graphID = graphID
        req.name = name
        req.description_p = description
        req.artifactIds = artifactIDs
        if let metadata { req.metadata = Self.mapMetadataDraft(metadata) }
        let resp: Provenencia_Engine_V1_UpdateEvidenceGraphResponse = try await provenenciaCall(
            method: CoreMethod.updateEvidenceGraph,
            request: req
        )
        return (resp.metadata.map(Self.mapMetadataEntry), Self.mapWriteEffects(resp.effects))
    }

    func deleteEvidenceGraph(projectDir: String, userID: String, graphID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteEvidenceGraphRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_DeleteEvidenceGraphResponse = try await provenenciaCall(
            method: CoreMethod.deleteEvidenceGraph,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func getEvidenceGraphUnlinkImpact(
        projectDir: String,
        pairs: [CatalogEvidenceGraphArtifactPair]
    ) async throws -> [CatalogEvidenceGraphUnlinkBlock] {
        var req = Provenencia_Engine_V1_GetEvidenceGraphUnlinkImpactRequest()
        req.projectDir = projectDir
        req.pairs = pairs.map { pair in
            Provenencia_Engine_V1_EvidenceGraphArtifactPair.with {
                $0.graphID = pair.graphID
                $0.artifactID = pair.artifactID
            }
        }
        let resp: Provenencia_Engine_V1_GetEvidenceGraphUnlinkImpactResponse = try await provenenciaCall(
            method: CoreMethod.getEvidenceGraphUnlinkImpact,
            request: req
        )
        return resp.blocked.map {
            CatalogEvidenceGraphUnlinkBlock(
                graphID: $0.graphID,
                artifactID: $0.artifactID,
                reason: EvidenceGraphUnlinkReason(wire: $0.reasonCode),
                citationCount: Int($0.citationCount)
            )
        }
    }

    func getSourceMoveImpact(
        projectDir: String,
        seed: CatalogSourceMoveSeed,
        targetSourceID: String?
    ) async throws -> CatalogSourceMoveImpact {
        var req = Provenencia_Engine_V1_GetSourceMoveImpactRequest()
        req.projectDir = projectDir
        switch seed {
        case .artifact(let id): req.artifactID = id
        case .graph(let id): req.graphID = id
        }
        req.targetSourceID = targetSourceID ?? ""
        let resp: Provenencia_Engine_V1_GetSourceMoveImpactResponse = try await provenenciaCall(
            method: CoreMethod.getSourceMoveImpact,
            request: req
        )
        return CatalogSourceMoveImpact(
            sourceID: resp.sourceID,
            artifacts: resp.artifacts.map(Self.mapArtifact),
            graphs: resp.graphs.map(Self.mapEvidenceGraph),
            progress: resp.progress.map(Self.mapEvidenceGraphProgress),
            sourceCredibilityLabel: resp.sourceCredibilityLabel,
            targetCredibilityLabel: resp.targetCredibilityLabel,
            weighedAsLabel: resp.weighedAsLabel,
            credibilityDiffers: resp.credibilityDiffers,
            leavesSourceEmpty: resp.leavesSourceEmpty,
            leavesNoGraph: resp.leavesNoGraph
        )
    }

    func moveToSource(
        projectDir: String,
        userID: String,
        seed: CatalogSourceMoveSeed,
        targetSourceID: String
    ) async throws -> CatalogSourceMoveResult {
        var req = Provenencia_Engine_V1_MoveToSourceRequest()
        req.projectDir = projectDir
        req.userID = userID
        switch seed {
        case .artifact(let id): req.artifactID = id
        case .graph(let id): req.graphID = id
        }
        req.targetSourceID = targetSourceID
        let resp: Provenencia_Engine_V1_MoveToSourceResponse = try await provenenciaCall(
            method: CoreMethod.moveToSource,
            request: req
        )
        return CatalogSourceMoveResult(
            artifactIDs: resp.artifactIds,
            graphIDs: resp.graphIds,
            defaultGraphID: resp.defaultGraphID.isEmpty ? nil : resp.defaultGraphID,
            effects: Self.mapWriteEffects(resp.effects)
        )
    }

    func listSourceCredibilityGrades(projectDir: String) async throws -> [CatalogCredibilityGrade] {
        var req = Provenencia_Engine_V1_ListSourceCredibilityGradesRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_ListSourceCredibilityGradesResponse = try await provenenciaCall(
            method: CoreMethod.listSourceCredibilityGrades,
            request: req
        )
        return resp.grades.map(Self.mapCredibilityGrade)
    }

    func upsertSourceCredibilityAssessment(
        projectDir: String,
        userID: String,
        sourceID: String,
        gradeID: String,
        argument: String
    ) async throws -> (CatalogCredibilityAssessment, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpsertSourceCredibilityAssessmentRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.sourceID = sourceID
        req.gradeID = gradeID
        req.argument = argument
        let resp: Provenencia_Engine_V1_UpsertSourceCredibilityAssessmentResponse = try await provenenciaCall(
            method: CoreMethod.upsertSourceCredibilityAssessment,
            request: req
        )
        return (Self.mapCredibility(resp.assessment), Self.mapWriteEffects(resp.effects))
    }

    func listSourceTypes(projectDir: String) async throws -> [CatalogSourceType] {
        var req = Provenencia_Engine_V1_ListSourceTypesRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_ListSourceTypesResponse = try await provenenciaCall(
            method: CoreMethod.listSourceTypes,
            request: req
        )
        return resp.types.map(Self.mapSourceType)
    }

    func createSourceType(
        projectDir: String,
        userID: String,
        label: String,
        description: String,
        iconKey: String
    ) async throws -> (CatalogSourceType, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateSourceTypeRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.label = label
        req.description_p = description
        req.iconKey = iconKey
        let resp: Provenencia_Engine_V1_CreateSourceTypeResponse = try await provenenciaCall(
            method: CoreMethod.createSourceType,
            request: req
        )
        return (Self.mapSourceType(resp.type), Self.mapWriteEffects(resp.effects))
    }

    func copySourceType(
        projectDir: String,
        userID: String,
        typeID: String,
        label: String,
        copyIcon: Bool,
        copyDescription: Bool,
        copyFormats: Bool,
        copySuggestions: Bool
    ) async throws -> (CatalogSourceType, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CopySourceTypeRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.typeID = typeID
        req.label = label
        req.copyIcon = copyIcon
        req.copyDescription = copyDescription
        req.copyFormats = copyFormats
        req.copySuggestions = copySuggestions
        let resp: Provenencia_Engine_V1_CopySourceTypeResponse = try await provenenciaCall(
            method: CoreMethod.copySourceType,
            request: req
        )
        return (Self.mapSourceType(resp.type), Self.mapWriteEffects(resp.effects))
    }

    func citationFormats(projectDir: String, typeID: String) async throws -> CatalogCitationFormatsReply {
        var req = Provenencia_Engine_V1_GetCitationFormatsRequest()
        req.projectDir = projectDir
        req.typeID = typeID
        let resp: Provenencia_Engine_V1_GetCitationFormatsResponse = try await provenenciaCall(
            method: CoreMethod.getCitationFormats,
            request: req
        )
        return CatalogCitationFormatsReply(
            formats: Self.mapCitationFormats(resp.formats),
            diagnostics: Self.mapCitationDiagnostics(resp.diagnostics)
        )
    }

    func updateSourceType(
        projectDir: String,
        userID: String,
        typeID: String,
        label: String,
        description: String,
        iconKey: String,
        formats: CatalogCitationFormats?
    ) async throws -> (CatalogSourceType, CatalogCitationFormatsReply?, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateSourceTypeRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.typeID = typeID
        req.label = label
        req.description_p = description
        req.iconKey = iconKey
        if let formats {
            var wire = Provenencia_Engine_V1_CitationFormats()
            wire.typeID = typeID
            wire.full = formats.full
            wire.short = formats.short
            wire.list = formats.list
            wire.fieldChoices = Self.citationFieldChoices(formats.fieldChoices)
            req.formats = wire
        }
        let resp: Provenencia_Engine_V1_UpdateSourceTypeResponse = try await provenenciaCall(
            method: CoreMethod.updateSourceType,
            request: req
        )
        let reply = resp.hasFormats
            ? CatalogCitationFormatsReply(
                formats: Self.mapCitationFormats(resp.formats),
                diagnostics: Self.mapCitationDiagnostics(resp.diagnostics)
            )
            : nil
        return (Self.mapSourceType(resp.type), reply, Self.mapWriteEffects(resp.effects))
    }

    func renderCitations(projectDir: String, citationIDs: [String]) async throws -> CatalogRenderedCitations {
        if citationIDs.isEmpty { return CatalogRenderedCitations() }
        var req = Provenencia_Engine_V1_RenderCitationsRequest()
        req.projectDir = projectDir
        req.citationIds = citationIDs
        let resp: Provenencia_Engine_V1_RenderCitationsResponse = try await provenenciaCall(
            method: CoreMethod.renderCitations,
            request: req
        )
        return CatalogRenderedCitations(
            citations: resp.citations.map {
                CatalogRenderedCitation(
                    citationID: $0.citationID,
                    full: Self.mapCitationRender($0.full),
                    short: Self.mapCitationRender($0.short)
                )
            },
            inputs: Self.mapPageInputs(resp.inputs)
        )
    }

    func renderCitationPreview(
        projectDir: String,
        form: CitationForm,
        format: String?,
        fieldChoices: [String: String],
        sourceID: String?
    ) async throws -> CatalogCitationPreview {
        var req = Provenencia_Engine_V1_RenderCitationPreviewRequest()
        req.projectDir = projectDir
        req.form = form.rawValue
        if let format { req.format = format }
        req.fieldChoices = Self.citationFieldChoices(fieldChoices)
        if let sourceID { req.target = .sourceID(sourceID) }
        let resp: Provenencia_Engine_V1_RenderCitationPreviewResponse = try await provenenciaCall(
            method: CoreMethod.renderCitationPreview,
            request: req
        )
        return CatalogCitationPreview(
            render: Self.mapCitationRender(resp.render),
            missing: resp.missing.map { chain in
                chain.options.compactMap { opt -> CatalogCitationOption? in
                    var level: Level?
                    if !opt.level.isEmpty {
                        guard let known = Level(rawValue: opt.level) else { return nil }
                        level = known
                    }
                    return CatalogCitationOption(
                        level: level,
                        field: opt.hasField ? Self.mapMetadataField(opt.field) : nil,
                        builtin: CitationBuiltin(rawValue: "\(opt.level).\(opt.builtin)")
                    )
                }
            },
            diagnostics: Self.mapCitationDiagnostics(resp.diagnostics)
        )
    }

    func citationPlaceholders(projectDir: String, form: CitationForm) async throws -> [CatalogCitationPlaceholder] {
        var req = Provenencia_Engine_V1_ListCitationPlaceholdersRequest()
        req.projectDir = projectDir
        req.form = form.rawValue
        let resp: Provenencia_Engine_V1_ListCitationPlaceholdersResponse = try await provenenciaCall(
            method: CoreMethod.listCitationPlaceholders,
            request: req
        )
        return resp.placeholders.compactMap { p -> CatalogCitationPlaceholder? in
            if p.hasField {
                return CatalogCitationPlaceholder(
                    id: "meta#\(p.field.id)", level: nil, builtin: nil, option: nil,
                    field: Self.mapMetadataField(p.field), text: p.text, ref: p.ref
                )
            }
            guard let level = Level(rawValue: p.level),
                let builtin = CitationBuiltin(rawValue: "\(p.level).\(p.builtin)") else { return nil }
            var option: CitationOption?
            if !p.option.isEmpty {
                guard let known = CitationOption(rawValue: p.option) else { return nil }
                option = known
            }
            return CatalogCitationPlaceholder(
                id: "\(builtin.rawValue)" + (option.map { ":\($0.rawValue)" } ?? ""),
                level: level, builtin: builtin, option: option, field: nil, text: p.text, ref: p.ref
            )
        }
    }

    func deleteSourceType(
        projectDir: String,
        userID: String,
        typeID: String
    ) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteSourceTypeRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.typeID = typeID
        let resp: Provenencia_Engine_V1_DeleteSourceTypeResponse = try await provenenciaCall(
            method: CoreMethod.deleteSourceType,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func listTypeSuggestions(projectDir: String, typeID: String) async throws
        -> [CatalogTypeSuggestion]
    {
        var req = Provenencia_Engine_V1_ListTypeSuggestionsRequest()
        req.projectDir = projectDir
        req.typeID = typeID
        let resp: Provenencia_Engine_V1_ListTypeSuggestionsResponse = try await provenenciaCall(
            method: CoreMethod.listTypeSuggestions,
            request: req
        )
        return resp.suggestions.map(Self.mapTypeSuggestion)
    }

    func assignTypeField(
        projectDir: String,
        typeID: String,
        fieldID: String
    ) async throws -> CatalogTypeSuggestionEdit {
        var req = Provenencia_Engine_V1_AssignTypeFieldRequest()
        req.projectDir = projectDir
        req.typeID = typeID
        req.fieldID = fieldID
        let resp: Provenencia_Engine_V1_AssignTypeFieldResponse = try await provenenciaCall(
            method: CoreMethod.assignTypeField,
            request: req
        )
        return CatalogTypeSuggestionEdit(
            suggestions: resp.suggestions.map(Self.mapTypeSuggestion),
            suggestedFieldCount: Int(resp.suggestedFieldCount)
        )
    }

    func removeTypeField(
        projectDir: String,
        typeID: String,
        fieldID: String
    ) async throws -> CatalogTypeSuggestionEdit {
        var req = Provenencia_Engine_V1_RemoveTypeFieldRequest()
        req.projectDir = projectDir
        req.typeID = typeID
        req.fieldID = fieldID
        let resp: Provenencia_Engine_V1_RemoveTypeFieldResponse = try await provenenciaCall(
            method: CoreMethod.removeTypeField,
            request: req
        )
        return CatalogTypeSuggestionEdit(
            suggestions: resp.suggestions.map(Self.mapTypeSuggestion),
            suggestedFieldCount: Int(resp.suggestedFieldCount)
        )
    }

    func listMetadataFields(projectDir: String) async throws -> [CatalogMetadataField] {
        var req = Provenencia_Engine_V1_ListMetadataFieldsRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_ListMetadataFieldsResponse = try await provenenciaCall(
            method: CoreMethod.listMetadataFields,
            request: req
        )
        return resp.fields.map(Self.mapMetadataField)
    }

    func createMetadataField(
        projectDir: String,
        userID: String,
        label: String,
        dataType: String,
        description: String
    ) async throws -> (CatalogMetadataField, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateMetadataFieldRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.label = label
        req.dataType = dataType
        req.description_p = description
        let resp: Provenencia_Engine_V1_CreateMetadataFieldResponse = try await provenenciaCall(
            method: CoreMethod.createMetadataField,
            request: req
        )
        return (Self.mapMetadataField(resp.field), Self.mapWriteEffects(resp.effects))
    }

    func updateMetadataField(
        projectDir: String,
        userID: String,
        fieldID: String,
        label: String,
        dataType: String,
        description: String
    ) async throws -> (CatalogMetadataField, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateMetadataFieldRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.fieldID = fieldID
        req.label = label
        req.dataType = dataType
        req.description_p = description
        let resp: Provenencia_Engine_V1_UpdateMetadataFieldResponse = try await provenenciaCall(
            method: CoreMethod.updateMetadataField,
            request: req
        )
        return (Self.mapMetadataField(resp.field), Self.mapWriteEffects(resp.effects))
    }

    func deleteMetadataField(
        projectDir: String,
        userID: String,
        fieldID: String
    ) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteMetadataFieldRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.fieldID = fieldID
        let resp: Provenencia_Engine_V1_DeleteMetadataFieldResponse = try await provenenciaCall(
            method: CoreMethod.deleteMetadataField,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func workspaceNavCounts(projectDir: String) async throws -> WorkspaceNavCounts {
        var req = Provenencia_Engine_V1_GetWorkspaceNavCountsRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_GetWorkspaceNavCountsResponse = try await provenenciaCall(
            method: CoreMethod.getWorkspaceNavCounts,
            request: req
        )
        return WorkspaceNavCounts(
            sources: Int(resp.sources),
            persons: Int(resp.persons),
            events: Int(resp.events),
            places: Int(resp.places)
        )
    }

    func nameFormat(projectDir: String) async throws -> NameFormatOrders {
        var req = Provenencia_Engine_V1_GetNameFormatRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_GetNameFormatResponse = try await provenenciaCall(
            method: CoreMethod.getNameFormat,
            request: req
        )
        func parts(_ rows: [Provenencia_Engine_V1_NameFormatPart]) -> [NameFormatPart] {
            rows.map { NameFormatPart(partType: $0.partType, trailingSeparator: $0.trailingSeparator) }
        }
        return NameFormatOrders(natural: parts(resp.natural), sorted: parts(resp.sorted))
    }

    func searchCatalog(
        projectDir: String,
        query: String,
        location: WorkspaceLocation?,
        kinds: [String]
    ) async throws -> [CatalogSearchHit] {
        var req = Provenencia_Engine_V1_SearchCatalogRequest()
        req.projectDir = projectDir
        req.query = query
        if let location { req.location = Self.mapWorkspaceLocationToProto(location) }
        req.kinds = kinds
        let resp: Provenencia_Engine_V1_SearchCatalogResponse = try await provenenciaCall(
            method: CoreMethod.searchCatalog,
            request: req
        )
        return resp.hits.map(Self.mapSearchHit)
    }

    func createSubject(
        projectDir: String,
        userID: String,
        graphID: String,
        subjectTypeID: String,
        label: String,
        description: String,
        placement: CatalogGridCell?
    ) async throws -> (CatalogSubject, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateSubjectRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.graphID = graphID
        req.subjectTypeID = subjectTypeID
        req.label = label
        req.description_p = description
        if let placement {
            req.hasPlacement_p = true
            req.gridX = placement.gridX
            req.gridY = placement.gridY
        }
        let resp: Provenencia_Engine_V1_CreateSubjectResponse = try await provenenciaCall(
            method: CoreMethod.createSubject,
            request: req
        )
        return (Self.mapSubject(resp.subject), Self.mapWriteEffects(resp.effects))
    }

    func updateSubject(
        projectDir: String,
        userID: String,
        subjectID: String,
        label: String,
        description: String
    ) async throws -> (CatalogSubject, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateSubjectRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.subjectID = subjectID
        req.label = label
        req.description_p = description
        let resp: Provenencia_Engine_V1_UpdateSubjectResponse = try await provenenciaCall(
            method: CoreMethod.updateSubject,
            request: req
        )
        return (Self.mapSubject(resp.subject), Self.mapWriteEffects(resp.effects))
    }

    func deleteSubject(projectDir: String, userID: String, subjectID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteSubjectRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.subjectID = subjectID
        let resp: Provenencia_Engine_V1_DeleteSubjectResponse = try await provenenciaCall(
            method: CoreMethod.deleteSubject,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func unpromoteSubject(projectDir: String, userID: String, subjectID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_UnpromoteSubjectRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.subjectID = subjectID
        let resp: Provenencia_Engine_V1_UnpromoteSubjectResponse = try await provenenciaCall(
            method: CoreMethod.unpromoteSubject,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func getUnpromoteImpact(projectDir: String, subjectID: String) async throws -> CatalogUnpromoteImpact {
        var req = Provenencia_Engine_V1_GetUnpromoteImpactRequest()
        req.projectDir = projectDir
        req.subjectID = subjectID
        let resp: Provenencia_Engine_V1_GetUnpromoteImpactResponse = try await provenenciaCall(
            method: CoreMethod.getUnpromoteImpact,
            request: req
        )
        return CatalogUnpromoteImpact(
            deletes: resp.hasDeletes ? Self.mapDeleteImpactGroup(resp.deletes) : nil,
            unpromotedBridgeSubjectIDs: resp.unpromotedBridgeSubjectIds
        )
    }

    func setPreferredLikeness(
        projectDir: String,
        userID: String,
        entityID: String,
        observationID: String
    ) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_SetPreferredLikenessRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.entityID = entityID
        req.observationID = observationID
        let resp: Provenencia_Engine_V1_SetPreferredLikenessResponse = try await provenenciaCall(
            method: CoreMethod.setPreferredLikeness,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func proposePromoteGraphAlignment(
        projectDir: String,
        graphID: String,
        fixed: [CatalogPromoteGraphAlignmentFixed],
        onlySubjectID: String?
    ) async throws -> CatalogPromoteGraphAlignmentProposal {
        var req = Provenencia_Engine_V1_ProposePromoteGraphAlignmentRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        req.fixed = fixed.map(Self.mapFixed)
        req.onlySubjectID = onlySubjectID ?? ""
        let resp: Provenencia_Engine_V1_ProposePromoteGraphAlignmentResponse = try await provenenciaCall(
            method: CoreMethod.proposePromoteGraphAlignment,
            request: req
        )
        let rows: [CatalogPromoteGraphAlignmentRow] = resp.rows.map { r in
            CatalogPromoteGraphAlignmentRow(
                subjectID: r.subjectID,
                kind: r.kind,
                target: PromoteTargetCode(wire: r.target),
                handleID: r.handleID,
                handleRef: r.handleRef,
                alternatives: r.alternatives.map { a in
                    CatalogPromoteGraphAlignmentAlternative(
                        handleID: a.handleID,
                        handleRef: a.handleRef,
                        summary: Self.mapConclusionSummary(a.summary)
                    )
                },
                conflictWithFixed: r.conflictWithFixed,
                possibleDuplicate: r.possibleDuplicate,
                duplicateOfSubjectID: r.duplicateOfSubjectID,
                viaNeighborSubjectID: r.viaNeighborSubjectID,
                moveReason: r.moveReason.isEmpty ? nil : PromoteMoveReason(wire: r.moveReason),
                moveNeighborSubjectID: r.moveNeighborSubjectID,
                summary: Self.mapConclusionSummary(r.summary)
            )
        }
        let connections = resp.connections.map { c in
            CatalogPromoteGraphAlignmentConnection(
                bridgeSubjectID: c.bridgeSubjectID,
                outcome: PromoteConnectionOutcome(wire: c.outcome),
                waitingSubjectID: c.waitingSubjectID
            )
        }
        return CatalogPromoteGraphAlignmentProposal(revision: resp.revision, rows: rows, connections: connections)
    }

    private static func mapFixed(_ f: CatalogPromoteGraphAlignmentFixed) -> Provenencia_Engine_V1_PromoteGraphAlignmentFixed {
        var row = Provenencia_Engine_V1_PromoteGraphAlignmentFixed()
        row.subjectID = f.subjectID
        row.handleID = f.handleID
        row.target = f.target.wire
        return row
    }

    func applyPromoteGraphAlignment(
        projectDir: String,
        userID: String,
        graphID: String,
        seenRevision: Int64,
        rows: [CatalogPromoteGraphAlignmentFixed]
    ) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_ApplyPromoteGraphAlignmentRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.graphID = graphID
        req.seenRevision = seenRevision
        req.rows = rows.map { fixed in
            var proto = Provenencia_Engine_V1_ApplyPromoteGraphAlignmentRow()
            proto.subjectID = fixed.subjectID
            proto.target = fixed.target.wire
            if !fixed.handleID.isEmpty { proto.entityID = fixed.handleID }
            return proto
        }
        let resp: Provenencia_Engine_V1_ApplyPromoteGraphAlignmentResponse = try await provenenciaCall(
            method: CoreMethod.applyPromoteGraphAlignment,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func listEvidenceGraphEventTitles(projectDir: String, graphID: String) async throws -> [String: CatalogSourceEventTitle] {
        var req = Provenencia_Engine_V1_ListEvidenceGraphEventTitlesRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_ListEvidenceGraphEventTitlesResponse = try await provenenciaCall(
            method: CoreMethod.listEvidenceGraphEventTitles,
            request: req
        )
        return Dictionary(
            resp.titles.map {
                ($0.subjectID, CatalogSourceEventTitle(title: Self.mapEventTitle($0.title), dating: Self.mapEventDating($0.dating)))
            },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private static func mapEventDating(_ d: Provenencia_Engine_V1_EventDating) -> CatalogEventDating {
        let kind: CatalogEventDating.Kind
        switch d.kind {
        case .occurrence: kind = .occurrence
        case .span: kind = .span
        case .asOf: kind = .asOf
        case .unspecified, .UNRECOGNIZED: kind = .none
        }
        return CatalogEventDating(
            kind: kind,
            low: d.hasLow ? mapDateValue(d.low) : nil,
            high: d.hasHigh ? mapDateValue(d.high) : nil,
            openLow: d.openLow,
            openHigh: d.openHigh
        )
    }

    /// An entry with no role this client knows is dropped.
    private static func mapEventDatingProperty(
        _ p: Provenencia_Engine_V1_EventDatingProperty
    ) -> CatalogEventDatingProperty? {
        let role: CatalogEventDatingProperty.Role
        switch p.role {
        case .occurrence: role = .occurrence
        case .start: role = .start
        case .end: role = .end
        case .asOf: role = .asOf
        case .unspecified, .UNRECOGNIZED: return nil
        }
        return CatalogEventDatingProperty(key: p.propertyKey, role: role)
    }

    private static func mapEventTitle(_ t: Provenencia_Engine_V1_EventTitle) -> CatalogEventTitle {
        let rule: CatalogEventTitle.Rule
        switch t.rule {
        case .recordedName: rule = .recordedName
        case .subject: rule = .subject
        case .couple: rule = .couple
        case .subjects: rule = .subjects
        case .label: rule = .label
        case .typeAtPlace: rule = .typeAtPlace
        case .type: rule = .type
        case .ref, .unspecified, .UNRECOGNIZED: rule = .ref
        }
        return CatalogEventTitle(
            rule: rule,
            recordedName: t.recordedName,
            label: t.label,
            ref: t.ref,
            typeKey: t.typeKey,
            typeOrigin: t.typeOrigin,
            typeLabel: t.typeLabel,
            subjects: t.subjects.map { $0.hasName ? mapNameValue($0.name) : nil },
            place: t.place
        )
    }

    func listSubjectMemberships(projectDir: String, graphID: String) async throws -> [CatalogSubjectMembership] {
        var req = Provenencia_Engine_V1_ListSubjectMembershipsRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_ListSubjectMembershipsResponse = try await provenenciaCall(
            method: CoreMethod.listSubjectMemberships,
            request: req
        )
        return resp.memberships.map { m in
            CatalogSubjectMembership(
                subjectID: m.subjectID,
                claimID: m.claimID,
                entity: Self.mapCanonicalEntity(m.entity),
                kind: m.kind,
                name: m.hasName ? Self.mapNameValue(m.name) : nil
            )
        }
    }

    func listPersonSummaries(projectDir: String, entityIDs: [String]?) async throws -> [CatalogPersonSummary] {
        if entityIDs?.isEmpty == true { return [] }
        var req = Provenencia_Engine_V1_ListPersonSummariesRequest()
        req.projectDir = projectDir
        req.entityIds = entityIDs ?? []
        let resp: Provenencia_Engine_V1_ListPersonSummariesResponse = try await provenenciaCall(
            method: CoreMethod.listPersonSummaries,
            request: req
        )
        return resp.summaries.map { proto in
            var row = Self.mapPersonSummary(proto)
            row.listKey = Self.mapListKey(proto.listKey)
            return row
        }
    }

    func listEventSummaries(projectDir: String, entityIDs: [String]?) async throws -> [CatalogEventSummary] {
        if entityIDs?.isEmpty == true { return [] }
        var req = Provenencia_Engine_V1_ListEventSummariesRequest()
        req.projectDir = projectDir
        req.entityIds = entityIDs ?? []
        let resp: Provenencia_Engine_V1_ListEventSummariesResponse = try await provenenciaCall(
            method: CoreMethod.listEventSummaries,
            request: req
        )
        return resp.summaries.map { proto in
            var row = Self.mapEventSummary(proto)
            row.listKey = Self.mapListKey(proto.listKey)
            return row
        }
    }

    func listPlaceSummaries(projectDir: String, entityIDs: [String]?) async throws -> [CatalogPlaceSummary] {
        if entityIDs?.isEmpty == true { return [] }
        var req = Provenencia_Engine_V1_ListPlaceSummariesRequest()
        req.projectDir = projectDir
        req.entityIds = entityIDs ?? []
        let resp: Provenencia_Engine_V1_ListPlaceSummariesResponse = try await provenenciaCall(
            method: CoreMethod.listPlaceSummaries,
            request: req
        )
        return resp.summaries.map { proto in
            var row = Self.mapPlaceSummary(proto)
            row.listKey = Self.mapListKey(proto.listKey)
            return row
        }
    }

    private static func mapListKey(_ key: Provenencia_Engine_V1_ListKey) -> CatalogListKey {
        CatalogListKey(last: key.last, primary: key.primary, ref: key.ref)
    }

    private static func mapConclusionSummary(
        _ summary: Provenencia_Engine_V1_ConclusionSummary
    ) -> CatalogConclusionSummary? {
        switch summary.kind {
        case .person(let p): .person(mapPersonSummary(p))
        case .event(let e): .event(mapEventSummary(e))
        case .place(let p): .place(mapPlaceSummary(p))
        case nil: nil
        }
    }

    private static func mapPersonSummary(_ h: Provenencia_Engine_V1_PersonSummary) -> CatalogPersonSummary {
        CatalogPersonSummary(
            entity: mapCanonicalEntity(h.entity),
            name: h.hasName ? mapNameValue(h.name) : nil,
            nameValueCount: Int(h.nameValueCount),
            birth: mapLifeFacts(h.birth),
            death: mapLifeFacts(h.death),
            gender: mapTermFacts(h.gender),
            sexAtBirth: mapTermFacts(h.sexAtBirth),
            updated: CatalogActivity(revision: h.updatedRevision, at: h.updatedAt),
            pictureImageRelPath: h.pictureImageRelPath
        )
    }

    private static func mapTermFacts(_ f: Provenencia_Engine_V1_TermFacts) -> CatalogTermFacts {
        CatalogTermFacts(
            term: f.hasTerm ? mapConclusionTerm(f.term) : nil,
            count: Int(f.count),
            propertyLabel: f.propertyLabel
        )
    }

    private static func mapConclusionTerm(_ t: Provenencia_Engine_V1_ConclusionTerm) -> CatalogConclusionValue {
        .term(id: t.id, key: t.key, label: t.label, origin: t.origin)
    }

    private static func mapLifeFacts(_ life: Provenencia_Engine_V1_LifeFacts) -> CatalogLifeFacts {
        CatalogLifeFacts(
            event: life.hasEvent ? mapCanonicalEntity(life.event) : nil,
            eventCount: Int(life.eventCount),
            date: life.hasDate ? mapDateValue(life.date) : nil,
            dateCount: Int(life.dateCount),
            places: life.places.map(mapChainedPlace)
        )
    }

    private static func mapChainedPlace(_ place: Provenencia_Engine_V1_ChainedPlace) -> CatalogChainedPlace {
        CatalogChainedPlace(
            entity: mapCanonicalEntity(place.entity),
            names: place.names,
            parents: place.parents,
            parentsAreCandidates: place.parentsAreCandidates
        )
    }

    private static func mapEventSubject(_ subject: Provenencia_Engine_V1_EventSubject) -> CatalogEventSubject {
        CatalogEventSubject(
            entity: mapCanonicalEntity(subject.entity),
            name: subject.hasName ? mapNameValue(subject.name) : nil,
            nameValueCount: Int(subject.nameValueCount)
        )
    }

    private static func mapEventSummary(_ h: Provenencia_Engine_V1_EventSummary) -> CatalogEventSummary {
        CatalogEventSummary(
            entity: mapCanonicalEntity(h.entity),
            eventName: h.eventName,
            eventNameCount: Int(h.eventNameCount),
            eventTypeKey: h.hasEventType ? h.eventType.key : "",
            eventTypeOrigin: h.hasEventType ? h.eventType.origin : "",
            eventTypeLabel: h.hasEventType ? h.eventType.label : "",
            eventTypeCount: Int(h.eventTypeCount),
            dating: mapEventDating(h.dating),
            datingProperties: h.datingProperties.compactMap(mapEventDatingProperty),
            subjects: h.subjects.map(mapEventSubject),
            places: h.places.map(mapChainedPlace),
            title: mapEventTitle(h.title),
            updated: CatalogActivity(revision: h.updatedRevision, at: h.updatedAt),
            pictureImageRelPath: h.pictureImageRelPath
        )
    }

    private static func mapPlaceSummary(_ h: Provenencia_Engine_V1_PlaceSummary) -> CatalogPlaceSummary {
        CatalogPlaceSummary(
            entity: mapCanonicalEntity(h.entity),
            names: h.names,
            startDate: h.hasStartDate ? mapDateValue(h.startDate) : nil,
            endDate: h.hasEndDate ? mapDateValue(h.endDate) : nil,
            kind: h.kind,
            parents: h.parents,
            parentsAreCandidates: h.parentsAreCandidates,
            partOf: h.partOf.map(mapPlaceRelationship),
            contains: h.contains.map(mapPlaceRelationship),
            predecessors: h.predecessors.map(mapPlaceRelationship),
            successors: h.successors.map(mapPlaceRelationship),
            updated: CatalogActivity(revision: h.updatedRevision, at: h.updatedAt),
            pictureImageRelPath: h.pictureImageRelPath
        )
    }

    private static func mapPlaceRelationship(
        _ r: Provenencia_Engine_V1_PlaceRelationship
    ) -> CatalogPlaceRelationship {
        CatalogPlaceRelationship(
            entity: mapCanonicalEntity(r.entity),
            title: r.title,
            kind: r.kind,
            startDate: r.hasStartDate ? mapDateValue(r.startDate) : nil,
            endDate: r.hasEndDate ? mapDateValue(r.endDate) : nil
        )
    }

    func listPersonClaims(projectDir: String, entityID: String) async throws -> CatalogPersonClaims {
        var req = Provenencia_Engine_V1_ListPersonClaimsRequest()
        req.projectDir = projectDir
        req.entityID = entityID
        let resp: Provenencia_Engine_V1_ListPersonClaimsResponse = try await provenenciaCall(
            method: CoreMethod.listPersonClaims,
            request: req
        )
        let groups = resp.groups.map { group in
            CatalogPersonClaimGroup(
                sourceID: group.sourceID,
                sourceRef: group.sourceRef,
                title: group.sourceTitle,
                sourceTypeID: group.sourceTypeID,
                sourceDate: group.hasSourceDate ? Self.mapDateValue(group.sourceDate) : nil,
                claims: group.claims.map { claim in
                    CatalogPersonClaim(
                        claimID: claim.claimID,
                        graphID: claim.graphID,
                        graphRef: claim.graphRef,
                        graphName: claim.graphName,
                        subject: Self.mapSubject(claim.subject),
                        observations: claim.observations.map(Self.mapObservation)
                    )
                }
            )
        }
        return CatalogPersonClaims(groups: groups, inputs: Self.mapPageInputs(resp.inputs))
    }

    /// The wire's id lists as sets: S16-25 tests membership.
    static func mapPageInputs(_ inputs: Provenencia_Engine_V1_PageInputs) -> CatalogPageInputs {
        CatalogPageInputs(
            handles: Set(inputs.handles),
            evidenceGraphs: Set(inputs.evidenceGraphs),
            sources: Set(inputs.sources)
        )
    }

    func getPersonFamily(projectDir: String, entityID: String) async throws -> CatalogPersonFamily {
        var req = Provenencia_Engine_V1_GetPersonFamilyRequest()
        req.projectDir = projectDir
        req.entityID = entityID
        let resp: Provenencia_Engine_V1_GetPersonFamilyResponse = try await provenenciaCall(
            method: CoreMethod.getPersonFamily,
            request: req
        )
        return CatalogPersonFamily(
            units: resp.units.compactMap(Self.mapFamilyUnit),
            person: resp.hasPerson ? Self.mapPersonSummary(resp.person) : nil,
            originSiblings: resp.originSiblings.map {
                CatalogOriginSibling(member: Self.mapFamilyMember($0.member), parentSets: $0.parentSets.map(Int.init))
            },
            siblingGroups: resp.siblingGroups.map {
                CatalogSiblingGroup(
                    parents: $0.parents.map(Self.mapFamilyMember),
                    children: $0.children.map(Self.mapFamilyMember),
                    coupleIndexes: $0.coupleIndexes.map(Int.init)
                )
            },
            couples: resp.couples.map {
                CatalogFamilyCouple(
                    aEntityId: $0.aEntityID,
                    bEntityId: $0.bEntityID,
                    marriages: $0.marriages.map(Self.mapEventSummary)
                )
            },
            inputs: Self.mapPageInputs(resp.inputs)
        )
    }

    func listPersonEvents(projectDir: String, entityID: String) async throws -> CatalogPersonTimeline {
        var req = Provenencia_Engine_V1_ListPersonEventsRequest()
        req.projectDir = projectDir
        req.entityID = entityID
        let resp: Provenencia_Engine_V1_ListPersonEventsResponse = try await provenenciaCall(
            method: CoreMethod.listPersonEvents,
            request: req
        )
        let events = resp.events.map { e in
            CatalogPersonEvent(
                event: Self.mapEventSummary(e.event),
                roles: e.roles.map(Self.mapConclusionTerm),
                participants: e.participants.map {
                    CatalogEventParticipant(person: Self.mapPersonSummary($0.person), roles: $0.roles.map(Self.mapConclusionTerm))
                },
                span: e.hasSpan
                    ? CatalogTimelineSpan(from: e.span.from, to: e.span.to, openStart: e.span.openStart, openEnd: e.span.openEnd)
                    : nil,
                age: e.hasAge ? CatalogAgeRange(lo: Int(e.age.lo), hi: Int(e.age.hi), openLo: e.age.openLo, openHi: e.age.openHi) : nil
            )
        }
        return CatalogPersonTimeline(
            events: events,
            birth: Self.mapLifeMarker(resp.birth),
            death: Self.mapLifeMarker(resp.death),
            inputs: Self.mapPageInputs(resp.inputs)
        )
    }

    func getPersonRecordLinks(projectDir: String, entityID: String) async throws -> CatalogPersonRecordLinks {
        var req = Provenencia_Engine_V1_GetPersonRecordLinksRequest()
        req.projectDir = projectDir
        req.entityID = entityID
        let resp: Provenencia_Engine_V1_GetPersonRecordLinksResponse = try await provenenciaCall(
            method: CoreMethod.getPersonRecordLinks,
            request: req
        )
        return Self.mapPersonRecordLinks(resp)
    }

    static func mapPersonRecordLinks(_ resp: Provenencia_Engine_V1_GetPersonRecordLinksResponse) -> CatalogPersonRecordLinks {
        CatalogPersonRecordLinks(
            graphs: resp.graphs.map {
                CatalogRecordLinksGraph(
                    graphID: $0.graphID,
                    graphRef: $0.graphRef,
                    graphName: $0.graphName,
                    sourceID: $0.sourceID,
                    sourceTitle: $0.sourceTitle
                )
            },
            pairs: resp.pairs.map {
                CatalogRecordLinksPair(graphAID: $0.graphAID, graphBID: $0.graphBID, lines: $0.lines.compactMap(Self.mapRecordLink))
            },
            notCounted: resp.notCounted,
            linesDropped: resp.linesDropped,
            inputs: mapPageInputs(resp.inputs)
        )
    }

    /// A line of a strength this build doesn't know is dropped.
    private static func mapRecordLink(_ l: Provenencia_Engine_V1_RecordLink) -> CatalogRecordLink? {
        switch l.strength {
        case .weak: CatalogRecordLink(entityID: l.entityID, strength: .weak)
        case .strong: CatalogRecordLink(entityID: l.entityID, strength: .strong)
        default: nil
        }
    }

    /// An empty id is nil: a placeholder, or a marker with no span to sit next to.
    private static func mapLifeMarker(_ m: Provenencia_Engine_V1_LifeMarker) -> CatalogLifeMarker {
        let place: CatalogLifeMarker.Place? = switch m.place {
        case .afterEventID(let id): id.isEmpty ? nil : .after(eventId: id)
        case .beforeEventID(let id): id.isEmpty ? nil : .before(eventId: id)
        case nil: nil
        }
        return CatalogLifeMarker(eventId: m.eventID.isEmpty ? nil : m.eventID, place: place)
    }

    /// A unit of a kind this build doesn't know is dropped, as is a shape of a
    /// pattern it doesn't know.
    private static func mapFamilyUnit(_ u: Provenencia_Engine_V1_FamilyUnit) -> CatalogFamilyUnit? {
        let kind: CatalogFamilyUnit.Kind
        switch u.kind {
        case .parents: kind = .parents
        case .partner: kind = .partner
        case .oneParent: kind = .oneParent
        case .siblings: kind = .siblings
        case .unspecified, .UNRECOGNIZED: return nil
        }
        return CatalogFamilyUnit(
            kind: kind,
            partners: u.partners.map(mapFamilyMember),
            children: u.children.map(mapFamilyMember),
            coupleIndexes: u.coupleIndexes.map(Int.init)
        )
    }

    private static func mapFamilyMember(_ m: Provenencia_Engine_V1_FamilyMember) -> CatalogFamilyMember {
        CatalogFamilyMember(
            person: mapPersonSummary(m.person),
            link: m.hasLink ? mapFamilyLink(m.link) : nil
        )
    }

    private static func mapFamilyLink(_ l: Provenencia_Engine_V1_FamilyLink) -> CatalogFamilyLink {
        CatalogFamilyLink(
            recorded: l.recorded,
            associationIDs: l.associationIds,
            implied: l.implied.compactMap { shape in
                let pattern: CatalogKinshipShape.Pattern
                switch shape.pattern {
                case .marriageSpouses: pattern = .marriageSpouses
                case .birthParents: pattern = .birthParents
                case .sharedParent: pattern = .sharedParent
                case .parentOfParent: pattern = .parentOfParent
                case .unspecified, .UNRECOGNIZED: return nil
                }
                return CatalogKinshipShape(pattern: pattern, pivotID: shape.pivotID)
            }
        )
    }

    func getConclusionDetail(projectDir: String, entityID: String) async throws -> CatalogConclusionDetail {
        var req = Provenencia_Engine_V1_GetConclusionDetailRequest()
        req.projectDir = projectDir
        req.entityID = entityID
        let resp: Provenencia_Engine_V1_ConclusionDetail = try await provenenciaCall(
            method: CoreMethod.getConclusionDetail,
            request: req
        )
        return CatalogConclusionDetail(
            entity: Self.mapCanonicalEntity(resp.entity),
            fields: resp.fields.map(Self.mapConclusionField),
            memberCount: Int(resp.memberCount),
            summary: Self.mapConclusionSummary(resp.summary),
            pictures: resp.pictures.map {
                CatalogPicture(
                    imageRelPath: $0.imageRelPath,
                    record: Self.mapReconcilerOutcome($0.record),
                    preferred: $0.preferred,
                    leads: $0.leads
                )
            },
            derivedRows: resp.derivedRows.compactMap(Self.mapDerivedRow),
            inputs: Self.mapPageInputs(resp.inputs)
        )
    }

    private static func mapConclusionField(_ f: Provenencia_Engine_V1_ConclusionField) -> CatalogConclusionField {
        CatalogConclusionField(
            propertyID: f.propertyID,
            propertyKey: f.propertyKey,
            label: f.label,
            // A value type this build doesn't know is laid out as text.
            valueType: PropertyValueType(rawValue: f.valueType) ?? .text,
            state: ReconciledState(wire: f.state),
            values: f.values.map { v in
                CatalogReconciledValue(
                    rank: Int(v.rank),
                    reason: ReconcilerReason(wire: v.reason),
                    support: Int(v.support),
                    against: Int(v.against),
                    value: Self.mapConclusionValue(v.value)
                )
            },
            outcomes: f.outcomes.map(Self.mapReconcilerOutcome)
        )
    }

    /// A row of a kind this build doesn't know is dropped.
    private static func mapDerivedRow(_ r: Provenencia_Engine_V1_DerivedRow) -> CatalogDerivedRow? {
        let kind: CatalogDerivedRowKind
        switch r.kind {
        case .birthDate: kind = .birthDate
        case .birthPlace: kind = .birthPlace
        case .deathDate: kind = .deathDate
        case .deathPlace: kind = .deathPlace
        case .unspecified, .UNRECOGNIZED: return nil
        }
        return CatalogDerivedRow(
            kind: kind,
            owners: r.owners.map {
                CatalogOwnerField(
                    entity: mapCanonicalEntity($0.entity),
                    event: $0.hasEvent ? mapEventSummary($0.event) : nil,
                    place: $0.hasPlace ? mapChainedPlace($0.place) : nil,
                    field: mapConclusionField($0.field)
                )
            }
        )
    }

    private static func mapReconcilerOutcome(_ o: Provenencia_Engine_V1_ReconcilerOutcomeDetail) -> CatalogReconcilerOutcome {
        CatalogReconcilerOutcome(
            observationID: o.observationID,
            observationRef: o.observationRef,
            reason: ReconcilerReason(wire: o.reason),
            valueRank: o.valueRank > 0 ? Int(o.valueRank) : nil,
            deniedByObservationID: o.deniedByObservationID,
            recorded: mapConclusionValue(o.recorded),
            subjectID: o.subjectID,
            subjectRef: o.subjectRef,
            graphID: o.graphID,
            citationID: o.citationID,
            artifactID: o.artifactID,
            sourceID: o.sourceID,
            sourceTitle: o.sourceTitle,
            credibilityKey: o.credibilityKey,
            transcriptionUncertain: o.transcriptionUncertain,
            credibilityOffset: Int(o.credibilityOffset),
            voteSupport: Int(o.voteSupport),
            voteTotal: Int(o.voteTotal),
            artifactLabel: o.artifactLabel,
            citationLabel: o.citationLabel,
            artifactPage: Int(o.artifactPage),
            pageLabel: o.pageLabel,
            groupRank: Int(o.groupRank)
        )
    }

    static func mapConclusionValue(_ v: Provenencia_Engine_V1_ConclusionValue) -> CatalogConclusionValue {
        switch v.kind {
        case .text(let t): return .text(t)
        case .integer(let i): return .integer(i)
        case .boolean(let b): return .boolean(b)
        case .term(let t): return mapConclusionTerm(t)
        case .date(let d): return .date(mapDateValue(d))
        case .name(let n): return .name(mapNameValue(n))
        case .depiction(let d): return .depiction(mapDepictionValue(d))
        case nil: return .none
        }
    }

    private static func mapDepictionValue(_ d: Provenencia_Engine_V1_DepictionValue) -> CatalogDepictionValue {
        CatalogDepictionValue(regionJSON: d.regionJson, imageRelPath: d.imageRelPath)
    }

    private static func mapNameValue(_ n: Provenencia_Engine_V1_NameValueInput) -> CatalogNameValue {
        CatalogNameValue(form: n.form, parts: n.parts.map { CatalogNameValuePart(value: $0.value, type: $0.type) })
    }

    private static func mapCanonicalEntity(_ e: Provenencia_Engine_V1_CanonicalEntity) -> CatalogCanonicalEntity {
        CatalogCanonicalEntity(id: e.id, ref: e.ref, subjectTypeID: e.subjectTypeID, label: e.label)
    }

    func listSubjects(projectDir: String, graphID: String) async throws -> [CatalogSubject] {
        var req = Provenencia_Engine_V1_ListSubjectsRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_ListSubjectsResponse = try await provenenciaCall(
            method: CoreMethod.listSubjects,
            request: req
        )
        return resp.subjects.map(Self.mapSubject)
    }

    func setSubjectPosition(
        projectDir: String,
        subjectID: String,
        gridX: Int64,
        gridY: Int64
    ) async throws -> CatalogSubjectPosition {
        var req = Provenencia_Engine_V1_SetSubjectPositionRequest()
        req.projectDir = projectDir
        req.subjectID = subjectID
        req.gridX = gridX
        req.gridY = gridY
        let resp: Provenencia_Engine_V1_SetSubjectPositionResponse = try await provenenciaCall(
            method: CoreMethod.setSubjectPosition,
            request: req
        )
        return Self.mapSubjectPosition(resp.position)
    }

    func listSubjectPositions(projectDir: String, graphID: String) async throws -> [CatalogSubjectPosition] {
        var req = Provenencia_Engine_V1_ListSubjectPositionsRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_ListSubjectPositionsResponse = try await provenenciaCall(
            method: CoreMethod.listSubjectPositions,
            request: req
        )
        return resp.positions.map(Self.mapSubjectPosition)
    }

    func createProperty(
        projectDir: String,
        userID: String,
        label: String,
        valueType: String,
        description: String,
        cardinality: String
    ) async throws -> (CatalogProperty, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreatePropertyRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.label = label
        req.valueType = valueType
        req.description_p = description
        req.cardinality = cardinality
        let resp: Provenencia_Engine_V1_CreatePropertyResponse = try await provenenciaCall(
            method: CoreMethod.createProperty,
            request: req
        )
        return (Self.mapProperty(resp.property), Self.mapWriteEffects(resp.effects))
    }

    func updateProperty(
        projectDir: String,
        userID: String,
        propertyID: String,
        label: String,
        valueType: String,
        description: String,
        cardinality: String
    ) async throws -> (CatalogProperty, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdatePropertyRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.propertyID = propertyID
        req.label = label
        req.valueType = valueType
        req.description_p = description
        req.cardinality = cardinality
        let resp: Provenencia_Engine_V1_UpdatePropertyResponse = try await provenenciaCall(
            method: CoreMethod.updateProperty,
            request: req
        )
        return (Self.mapProperty(resp.property), Self.mapWriteEffects(resp.effects))
    }

    func deleteProperty(projectDir: String, userID: String, propertyID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeletePropertyRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.propertyID = propertyID
        let resp: Provenencia_Engine_V1_DeletePropertyResponse = try await provenenciaCall(
            method: CoreMethod.deleteProperty,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func listPropertyTerms(projectDir: String, propertyID: String) async throws -> [CatalogPropertyTerm] {
        var req = Provenencia_Engine_V1_ListPropertyTermsRequest()
        req.projectDir = projectDir
        req.propertyID = propertyID
        let resp: Provenencia_Engine_V1_ListPropertyTermsResponse = try await provenenciaCall(
            method: CoreMethod.listPropertyTerms,
            request: req
        )
        return resp.terms.map(Self.mapPropertyTerm)
    }

    func createPropertyTerm(
        projectDir: String,
        userID: String,
        propertyID: String,
        label: String,
        description: String
    ) async throws -> (CatalogPropertyTerm, CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreatePropertyTermRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.propertyID = propertyID
        req.label = label
        req.description_p = description
        let resp: Provenencia_Engine_V1_CreatePropertyTermResponse = try await provenenciaCall(
            method: CoreMethod.createPropertyTerm,
            request: req
        )
        return (Self.mapPropertyTerm(resp.term), Self.mapWriteEffects(resp.effects))
    }

    func assignSubjectTypeProperty(
        projectDir: String,
        userID: String,
        subjectTypeID: String,
        propertyID: String
    ) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_AssignSubjectTypePropertyRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.subjectTypeID = subjectTypeID
        req.propertyID = propertyID
        let resp: Provenencia_Engine_V1_AssignSubjectTypePropertyResponse = try await provenenciaCall(
            method: CoreMethod.assignSubjectTypeProperty,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func removeSubjectTypeProperty(
        projectDir: String,
        userID: String,
        subjectTypeID: String,
        propertyID: String
    ) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_RemoveSubjectTypePropertyRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.subjectTypeID = subjectTypeID
        req.propertyID = propertyID
        let resp: Provenencia_Engine_V1_RemoveSubjectTypePropertyResponse = try await provenenciaCall(
            method: CoreMethod.removeSubjectTypeProperty,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func listConnectRules() async throws -> [CatalogConnectRule] {
        let req = Provenencia_Engine_V1_ListConnectRulesRequest()
        let resp: Provenencia_Engine_V1_ListConnectRulesResponse = try await provenenciaCall(
            method: CoreMethod.listConnectRules,
            request: req
        )
        return resp.rules.map(Self.mapConnectRule)
    }

    func createCitedBridge(
        projectDir: String,
        userID: String,
        fromSubjectID: String,
        toSubjectID: String,
        bridgeTypeKey: String,
        description: String,
        artifactID: String,
        locatorJSON: String,
        transcription: String,
        citationDescription: String,
        transcriptionUncertain: Bool,
        transcriptionNote: String,
        citationNotes: [String],
        observations: [CatalogObservationDraft],
        citationID: String?
    ) async throws -> (CatalogSubject, CatalogCitation, [CatalogObservation], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateCitedBridgeRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.fromSubjectID = fromSubjectID
        req.toSubjectID = toSubjectID
        req.bridgeTypeKey = bridgeTypeKey
        req.description_p = description
        req.artifactID = artifactID
        req.locatorJson = locatorJSON
        req.transcription = transcription
        req.citationLabel = citationDescription
        req.transcriptionUncertain = transcriptionUncertain
        req.transcriptionNote = transcriptionNote
        req.citationNotes = citationNotes
        req.observations = observations.map(Self.mapObservationDraft)
        req.citationID = citationID ?? ""
        let resp: Provenencia_Engine_V1_CreateCitedBridgeResponse = try await provenenciaCall(
            method: CoreMethod.createCitedBridge,
            request: req
        )
        return (
            Self.mapSubject(resp.subject),
            Self.mapCitation(resp.citation),
            resp.observations.map(Self.mapObservation),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func createCitationWithObservations(
        projectDir: String,
        userID: String,
        graphID: String,
        artifactID: String,
        locatorJSON: String,
        transcription: String,
        description: String,
        transcriptionUncertain: Bool,
        transcriptionNote: String,
        citationNotes: [String],
        observations: [CatalogObservationDraft]
    ) async throws -> (CatalogCitation, [CatalogObservation], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_CreateCitationWithObservationsRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.graphID = graphID
        req.artifactID = artifactID
        req.locatorJson = locatorJSON
        req.transcription = transcription
        req.label = description
        req.transcriptionUncertain = transcriptionUncertain
        req.transcriptionNote = transcriptionNote
        req.citationNotes = citationNotes
        req.observations = observations.map(Self.mapObservationDraft)
        let resp: Provenencia_Engine_V1_CreateCitationWithObservationsResponse = try await provenenciaCall(
            method: CoreMethod.createCitationWithObservations,
            request: req
        )
        return (
            Self.mapCitation(resp.citation),
            resp.observations.map(Self.mapObservation),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func getCitation(
        projectDir: String,
        graphID: String,
        citationID: String
    ) async throws -> (CatalogCitation, [String], [CatalogObservation]) {
        var req = Provenencia_Engine_V1_GetCitationRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        req.citationID = citationID
        let resp: Provenencia_Engine_V1_GetCitationResponse = try await provenenciaCall(
            method: CoreMethod.getCitation,
            request: req
        )
        return (
            Self.mapCitation(resp.citation),
            resp.notes,
            resp.observations.map(Self.mapObservation)
        )
    }

    func addObservationsToCitation(
        projectDir: String,
        userID: String,
        citationID: String,
        observations: [CatalogObservationDraft]
    ) async throws -> ([CatalogObservation], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_AddObservationsToCitationRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.citationID = citationID
        req.observations = observations.map(Self.mapObservationDraft)
        let resp: Provenencia_Engine_V1_AddObservationsToCitationResponse = try await provenenciaCall(
            method: CoreMethod.addObservationsToCitation,
            request: req
        )
        return (
            resp.observations.map(Self.mapObservation),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func listObservationsByEvidenceGraph(projectDir: String, graphID: String) async throws -> [CatalogObservation] {
        var req = Provenencia_Engine_V1_ListObservationsByEvidenceGraphRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_ListObservationsByEvidenceGraphResponse = try await provenenciaCall(
            method: CoreMethod.listObservationsByEvidenceGraph,
            request: req
        )
        return resp.observations.map(Self.mapObservation)
    }

    func citationCountsByEvidenceGraph(projectDir: String, graphID: String) async throws -> [String: Int] {
        var req = Provenencia_Engine_V1_CitationCountsByEvidenceGraphRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_CitationCountsByEvidenceGraphResponse = try await provenenciaCall(
            method: CoreMethod.citationCountsByEvidenceGraph,
            request: req
        )
        var counts: [String: Int] = [:]
        for row in resp.counts {
            counts[row.artifactID] = Int(row.count)
        }
        return counts
    }

    func listEvidenceGraphProgress(projectDir: String) async throws -> [EvidenceGraphProgress] {
        var req = Provenencia_Engine_V1_ListEvidenceGraphProgressRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_ListEvidenceGraphProgressResponse = try await provenenciaCall(
            method: CoreMethod.listEvidenceGraphProgress,
            request: req
        )
        return resp.rows.map(Self.mapEvidenceGraphProgress)
    }

    func getDeleteImpact(projectDir: String, kind: String, id: String) async throws -> CatalogDeleteImpact {
        var req = Provenencia_Engine_V1_GetDeleteImpactRequest()
        req.projectDir = projectDir
        req.kind = kind
        req.id = id
        let resp: Provenencia_Engine_V1_GetDeleteImpactResponse = try await provenenciaCall(
            method: CoreMethod.getDeleteImpact,
            request: req
        )
        return CatalogDeleteImpact(
            allowed: resp.allowed,
            gate: Self.mapDeleteImpactGate(resp.gate),
            groups: resp.groups.map(Self.mapDeleteImpactGroup),
            cascades: resp.cascades.map(Self.mapDeleteImpactGroup)
        )
    }

    private static func mapDeleteImpactGroup(_ g: Provenencia_Engine_V1_DeleteImpactGroup) -> CatalogDeleteImpactGroup {
        CatalogDeleteImpactGroup(
            via: g.via,
            kind: g.kind,
            total: Int(g.total),
            listed: g.listed.map { item in
                CatalogDeleteImpactListed(
                    id: item.id,
                    ref: item.ref,
                    title: item.title,
                    location: Self.mapWorkspaceLocationFromProto(item.location)
                )
            }
        )
    }

    func getEvidenceGraphProgress(projectDir: String, graphID: String) async throws -> EvidenceGraphProgress {
        var req = Provenencia_Engine_V1_GetEvidenceGraphProgressRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        let resp: Provenencia_Engine_V1_GetEvidenceGraphProgressResponse = try await provenenciaCall(
            method: CoreMethod.getEvidenceGraphProgress,
            request: req
        )
        if resp.hasProgress {
            return Self.mapEvidenceGraphProgress(resp.progress)
        }
        return .zeros(graphId: graphID)
    }

    private static func mapEvidenceGraphProgress(_ row: Provenencia_Engine_V1_EvidenceGraphProgress) -> EvidenceGraphProgress {
        EvidenceGraphProgress(
            graphId: row.graphID,
            subjectCount: Int(row.subjectCount),
            observationCount: Int(row.observationCount),
            filedCount: Int(row.filedCount)
        )
    }

    func updateCitation(
        projectDir: String,
        userID: String,
        citationID: String,
        locatorJSON: String,
        transcription: String,
        description: String,
        transcriptionUncertain: Bool,
        transcriptionNote: String,
        metadata: CatalogMetadataDraft?
    ) async throws -> (CatalogCitation, [CatalogMetadataEntry], CatalogWriteEffects) {
        var req = Provenencia_Engine_V1_UpdateCitationRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.citationID = citationID
        req.locatorJson = locatorJSON
        req.transcription = transcription
        req.label = description
        req.transcriptionUncertain = transcriptionUncertain
        req.transcriptionNote = transcriptionNote
        if let metadata { req.metadata = Self.mapMetadataDraft(metadata) }
        let resp: Provenencia_Engine_V1_UpdateCitationResponse = try await provenenciaCall(
            method: CoreMethod.updateCitation,
            request: req
        )
        return (
            Self.mapCitation(resp.citation),
            resp.metadata.map(Self.mapMetadataEntry),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func updateObservation(
        projectDir: String,
        userID: String,
        observation: CatalogObservation,
        depictionInput: CatalogDepictionValueInput?
    ) async throws -> (CatalogObservation, CatalogWriteEffects) {
        let req = Self.updateObservationRequest(
            projectDir: projectDir,
            userID: userID,
            observation: observation,
            depictionInput: depictionInput
        )
        let resp: Provenencia_Engine_V1_UpdateObservationResponse = try await provenenciaCall(
            method: CoreMethod.updateObservation,
            request: req
        )
        return (
            Self.mapObservation(resp.observation),
            Self.mapWriteEffects(resp.effects)
        )
    }

    func deleteObservation(projectDir: String, userID: String, observationID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteObservationRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.observationID = observationID
        let resp: Provenencia_Engine_V1_DeleteObservationResponse = try await provenenciaCall(
            method: CoreMethod.deleteObservation,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    func deleteCitation(projectDir: String, userID: String, citationID: String) async throws -> CatalogWriteEffects {
        var req = Provenencia_Engine_V1_DeleteCitationRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.citationID = citationID
        let resp: Provenencia_Engine_V1_DeleteCitationResponse = try await provenenciaCall(
            method: CoreMethod.deleteCitation,
            request: req
        )
        return Self.mapWriteEffects(resp.effects)
    }

    private static func mapWriteEffects(_ effects: Provenencia_Engine_V1_WriteEffects) -> CatalogWriteEffects {
        CatalogWriteEffects(
            handles: effects.handles,
            evidenceGraphs: effects.evidenceGraphs,
            reads: effects.reads.compactMap { entry in
                CatalogRead(rawValue: entry.read).map { CatalogWriteEffectsRead(read: $0, ids: entry.ids) }
            },
            lists: Set(effects.lists.compactMap(CatalogList.init(rawValue:))),
            structure: effects.structure,
            summaryHandles: effects.summaryHandles,
            handleScopes: effects.handleScopes,
            sourceScopes: effects.sourceScopes,
            deleted: effects.deleted.compactMap { entry in
                CatalogDeletedEntity(rawValue: entry.entity).map { CatalogWriteEffectsDeleted(entity: $0, ids: entry.ids) }
            },
            activity: CatalogActivity(revision: effects.revision, at: effects.revisionAt)
        )
    }

    func getPropertiesWorkspace(projectDir: String) async throws -> PropertiesSnapshot {
        var req = Provenencia_Engine_V1_GetPropertiesWorkspaceRequest()
        req.projectDir = projectDir
        let resp: Provenencia_Engine_V1_GetPropertiesWorkspaceResponse = try await provenenciaCall(
            method: CoreMethod.getPropertiesWorkspace,
            request: req
        )
        var propertiesByTypeID: [String: [CatalogSubjectTypeProperty]] = [:]
        var presentationsByKey: [String: CatalogSubjectTypePresentation] = [:]
        for group in resp.groups {
            propertiesByTypeID[group.subjectTypeID] = group.properties.map(Self.mapSubjectTypeProperty)
            if group.hasPresentation {
                let presentation = Self.mapSubjectTypePresentation(group.presentation)
                presentationsByKey[presentation.typeKey] = presentation
            }
        }
        return PropertiesSnapshot(
            properties: resp.properties.map(Self.mapProperty),
            types: resp.types.map(Self.mapSubjectType),
            propertiesByTypeID: propertiesByTypeID,
            presentationsByKey: presentationsByKey,
            valueTypeRules: resp.valueTypes.map {
                CatalogPropertyValueTypeRule(
                    valueType: $0.valueType,
                    researcherCreatable: $0.researcherCreatable,
                    singleOnly: $0.singleOnly,
                    negatable: $0.negatable
                )
            }
        )
    }

    func listCitationsByArtifact(
        projectDir: String,
        graphID: String,
        artifactID: String
    ) async throws -> [CatalogListedCitation] {
        var req = Provenencia_Engine_V1_ListCitationsByArtifactRequest()
        req.projectDir = projectDir
        req.graphID = graphID
        req.artifactID = artifactID
        let resp: Provenencia_Engine_V1_ListCitationsByArtifactResponse = try await provenenciaCall(
            method: CoreMethod.listCitationsByArtifact,
            request: req
        )
        return resp.citations.map { row in
            CatalogListedCitation(
                citation: Self.mapCitation(row.citation),
                observationCount: Int(row.observationCount),
                subjectNames: row.subjectNames,
                metadata: row.metadata.map(Self.mapMetadataEntry),
                pageLabel: row.pageLabel
            )
        }
    }

    private static func mapWorkspaceLocationToProto(
        _ loc: WorkspaceLocation
    ) -> Provenencia_Engine_V1_WorkspaceLocation {
        var p = Provenencia_Engine_V1_WorkspaceLocation()
        p.section = loc.section.rawValue
        p.sourceID = loc.sourceId ?? ""
        p.graphID = loc.graphId ?? ""
        p.fieldID = loc.fieldId ?? ""
        p.typeID = loc.typeId ?? ""
        p.ref = loc.ref ?? ""
        p.title = loc.title ?? ""
        p.subjectID = loc.subjectId ?? ""
        p.citationID = loc.citationId ?? ""
        p.artifactID = loc.artifactId ?? ""
        p.observationID = loc.observationId ?? ""
        p.sourceSurface = loc.sourceSurface.rawValue
        p.connectFromSubjectID = loc.connectFromSubjectId ?? ""
        p.connectToSubjectID = loc.connectToSubjectId ?? ""
        p.connectBridgeTypeKey = loc.connectBridgeTypeKey ?? ""
        p.subjectTypeKey = loc.subjectTypeKey ?? ""
        p.propertyID = loc.propertyId ?? ""
        p.entityID = loc.entityId ?? ""
        p.sourceTitle = loc.sourceTitle ?? ""
        return p
    }

    /// Internal (not private) so tests can feed it engine section ids.
    static func mapWorkspaceLocationFromProto(
        _ p: Provenencia_Engine_V1_WorkspaceLocation
    ) -> WorkspaceLocation {
        WorkspaceLocation(
            section: WorkspaceSection(id: p.section) ?? .sources,
            sourceId: p.sourceID,
            graphId: p.graphID,
            fieldId: p.fieldID,
            typeId: p.typeID,
            subjectId: p.subjectID,
            citationId: p.citationID,
            artifactId: p.artifactID,
            observationId: p.observationID,
            connectFromSubjectId: p.connectFromSubjectID,
            connectToSubjectId: p.connectToSubjectID,
            connectBridgeTypeKey: p.connectBridgeTypeKey,
            subjectTypeKey: p.subjectTypeKey,
            propertyId: p.propertyID,
            entityId: p.entityID,
            sourceSurface: SourceSurface(rawValue: p.sourceSurface) ?? .page,
            ref: p.ref,
            title: p.title,
            sourceTitle: p.sourceTitle
        )
    }

    private static func mapDeleteImpactGate(
        _ g: Provenencia_Engine_V1_DeleteImpactGate
    ) -> CatalogDeleteImpactGate {
        switch g {
        case .ok: return .ok
        case .inbound: return .inbound
        case .notFound: return .notFound
        case .edgeLocked: return .edgeLocked
        case .infra: return .infra
        case .originLocked: return .originLocked
        case .lastGraph: return .lastGraph
        case .unspecified, .UNRECOGNIZED: return .ok
        }
    }

    private static func mapSearchHit(_ h: Provenencia_Engine_V1_SearchHit) -> CatalogSearchHit {
        CatalogSearchHit(
            kind: h.kind,
            id: h.id,
            ref: h.ref,
            title: h.title,
            subtitle: h.subtitle,
            matchReason: h.matchReason,
            matchSnippet: h.matchSnippet,
            location: Self.mapWorkspaceLocationFromProto(h.location),
            thumbnailRelPath: h.thumbnailRelPath,
            iconKey: h.iconKey,
            memberCount: Int(h.memberCount),
            summary: Self.mapConclusionSummary(h.summary)
        )
    }

    private static func mapProject(_ p: Provenencia_Engine_V1_ProjectInfo) -> ProjectInfo {
        ProjectInfo(
            label: p.label,
            folderName: p.folderName,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
            updatedByUserID: p.updatedByUserID,
            updatedByDisplayName: p.updatedByDisplayName,
            updatedByRef: p.updatedByRef,
            uuid: p.uuid
        )
    }

    static func mapSource(_ s: Provenencia_Engine_V1_Source) -> CatalogSource {
        CatalogSource(
            id: s.id,
            ref: s.ref,
            sourceTypeID: s.sourceTypeID,
            title: s.title,
            description: s.description_p,
            thumbnailRelPath: s.thumbnailRelPath,
            thumbnailMediaType: s.thumbnailMediaType,
            thumbnailOriginalFilename: s.thumbnailOriginalFilename,
            coverMode: s.coverMode.isEmpty ? "type_icon" : s.coverMode,
            primaryArtifactID: s.primaryArtifactID,
            hasArtifact: s.hasArtifact_p,
            date: s.hasDate ? mapDateValue(s.date) : nil,
            dateSortKey: s.hasDateSortKey ? s.dateSortKey : nil,
            isPublic: s.isPublic,
            updated: CatalogActivity(revision: s.updatedRevision, at: s.updatedAt),
            createdAt: s.createdAt
        )
    }

    private static func mapNote(_ n: Provenencia_Engine_V1_SourceNote) -> CatalogSourceNote {
        CatalogSourceNote(
            id: n.id,
            sourceID: n.sourceID,
            body: n.body,
            authorDisplayName: n.authorDisplayName,
            createdAt: n.createdAt
        )
    }

    private static func mapFile(_ f: Provenencia_Engine_V1_SourceFileRef) -> CatalogFileRef {
        CatalogFileRef(
            id: f.id,
            relPath: f.relPath,
            originalFilename: f.originalFilename,
            mediaType: f.mediaType,
            byteSize: f.byteSize,
            typeIdentifiers: f.typeIdentifiers
        )
    }

    private static func mapEvidenceGraph(_ g: Provenencia_Engine_V1_EvidenceGraph) -> CatalogEvidenceGraph {
        CatalogEvidenceGraph(
            id: g.id,
            ref: g.ref,
            sourceID: g.sourceID,
            name: g.name,
            description: g.description_p,
            artifactIDs: g.artifactIds
        )
    }

    private static func mapArtifact(_ a: Provenencia_Engine_V1_Artifact) -> CatalogArtifact {
        CatalogArtifact(
            id: a.id,
            ref: a.ref,
            sourceID: a.sourceID,
            fileID: a.fileID,
            label: a.label,
            description: a.description_p,
            file: a.hasFile ? Self.mapFile(a.file) : nil,
            thumbnailRelPath: a.thumbnailRelPath
        )
    }

    private static func mapCredibilityGrade(_ g: Provenencia_Engine_V1_SourceCredibilityGrade) -> CatalogCredibilityGrade {
        CatalogCredibilityGrade(
            id: g.id,
            key: g.key,
            origin: g.origin,
            label: g.label,
            sortOrder: Int(g.sortOrder)
        )
    }

    private static func mapCredibility(_ a: Provenencia_Engine_V1_SourceCredibilityAssessment) -> CatalogCredibilityAssessment {
        CatalogCredibilityAssessment(
            id: a.id,
            sourceID: a.sourceID,
            gradeID: a.gradeID,
            gradeKey: a.gradeKey,
            gradeLabel: a.gradeLabel,
            argument: a.argument
        )
    }

    private static func citationFieldChoices(_ choices: [String: String]) -> [Provenencia_Engine_V1_CitationFieldChoice] {
        choices.sorted { $0.key < $1.key }.map { key, id in
            var choice = Provenencia_Engine_V1_CitationFieldChoice()
            choice.key = key
            choice.fieldID = id
            return choice
        }
    }

    private static func mapCitationFormats(_ f: Provenencia_Engine_V1_CitationFormats) -> CatalogCitationFormats {
        CatalogCitationFormats(
            typeID: f.typeID,
            full: f.full,
            short: f.short,
            list: f.list,
            fieldChoices: Dictionary(f.fieldChoices.map { ($0.key, $0.fieldID) }, uniquingKeysWith: { $1 })
        )
    }

    /// A diagnostic for a form Swift does not know is dropped; an unknown code is kept.
    private static func mapCitationDiagnostics(
        _ ds: [Provenencia_Engine_V1_CitationFormatDiagnostic]
    ) -> [CatalogCitationDiagnostic] {
        ds.compactMap { d in
            guard let form = CitationForm(rawValue: d.form) else { return nil }
            return CatalogCitationDiagnostic(form: form, code: d.code, utf8Start: Int(d.start), utf8End: Int(d.end))
        }
    }

    private static func mapCitationRender(_ r: Provenencia_Engine_V1_CitationRender) -> CatalogCitationRender {
        CatalogCitationRender(runs: r.runs.map { CatalogCitationRun(text: $0.text, italic: $0.italic) }, plain: r.plain)
    }

    private static func mapSourceType(_ t: Provenencia_Engine_V1_SourceType) -> CatalogSourceType {
        CatalogSourceType(
            id: t.id,
            key: t.key,
            origin: t.origin,
            label: t.label,
            description: t.description_p,
            iconKey: t.iconKey.isEmpty ? PVMarkKey.defaultTypeMark.rawValue : t.iconKey,
            usedBy: Int(t.usedBy),
            suggestedFieldCount: Int(t.suggestedFieldCount)
        )
    }

    private static func mapSubjectType(_ t: Provenencia_Engine_V1_SubjectType) -> CatalogSubjectType {
        CatalogSubjectType(
            id: t.id,
            key: t.key,
            origin: t.origin,
            label: t.label,
            description: t.description_p,
            refPrefix: t.refPrefix,
            candidateRefPrefix: t.candidateRefPrefix
        )
    }

    static func mapSubject(_ s: Provenencia_Engine_V1_Subject) -> CatalogSubject {
        CatalogSubject(
            id: s.id,
            ref: s.ref,
            sourceID: s.sourceID,
            subjectTypeID: s.subjectTypeID,
            label: s.label,
            description: s.description_p
        )
    }

    private static func mapSubjectPosition(_ p: Provenencia_Engine_V1_SubjectPosition) -> CatalogSubjectPosition {
        CatalogSubjectPosition(subjectID: p.subjectID, gridX: p.gridX, gridY: p.gridY)
    }

    private static func mapProperty(_ p: Provenencia_Engine_V1_Property) -> CatalogProperty {
        CatalogProperty(
            id: p.id,
            key: p.key,
            origin: p.origin,
            label: p.label,
            description: p.description_p,
            valueType: p.valueType,
            cardinality: p.cardinality,
            usedBy: Int(p.usedBy)
        )
    }

    private static func mapPropertyTerm(_ t: Provenencia_Engine_V1_PropertyTerm) -> CatalogPropertyTerm {
        CatalogPropertyTerm(
            id: t.id,
            propertyID: t.propertyID,
            key: t.key,
            origin: t.origin,
            label: t.label,
            description: t.description_p
        )
    }

    private static func mapSubjectTypeProperty(_ f: Provenencia_Engine_V1_SubjectTypeProperty) -> CatalogSubjectTypeProperty {
        CatalogSubjectTypeProperty(
            property: Self.mapProperty(f.property),
            sortOrder: Int(f.sortOrder),
            locked: f.locked
        )
    }

    private static func mapSubjectTypePresentation(
        _ p: Provenencia_Engine_V1_SubjectTypePresentation
    ) -> CatalogSubjectTypePresentation {
        CatalogSubjectTypePresentation(
            typeKey: p.typeKey,
            l10nKey: p.l10NKey,
            iconSymbol: p.iconSymbol,
            inkToken: p.inkToken,
            tintToken: p.tintToken,
            chipToken: p.chipToken,
            lineToken: p.lineToken,
            edgeFromToken: p.edgeFromToken,
            edgeToToken: p.edgeToToken,
            role: p.role,
            placeable: p.placeable,
            paletteSort: Int(p.paletteSort),
            requiresCitationAtCreate: p.requiresCitationAtCreate,
            label: p.label
        )
    }

    private static func mapConnectRule(_ r: Provenencia_Engine_V1_ConnectRule) -> CatalogConnectRule {
        CatalogConnectRule(
            fromTypeKey: r.fromTypeKey,
            toTypeKey: r.toTypeKey,
            bridgeTypeKey: r.bridgeTypeKey,
            edgePropertyKeys: r.edgePropertyKeys,
            disambiguation: r.disambiguation,
            refuse: r.refuse,
            edges: r.edges.map { CatalogConnectEdge(propertyKey: $0.propertyKey, endpointTypeKey: $0.endpointTypeKey) }
        )
    }

    private static func mapCitation(_ c: Provenencia_Engine_V1_Citation) -> CatalogCitation {
        CatalogCitation(
            id: c.id,
            ref: c.ref,
            artifactID: c.artifactID,
            locatorJSON: c.locatorJson,
            transcription: c.transcription,
            description: c.label,
            transcriptionUncertain: c.transcriptionUncertain,
            transcriptionNote: c.transcriptionNote
        )
    }

    static func updateObservationRequest(
        projectDir: String,
        userID: String,
        observation: CatalogObservation,
        depictionInput: CatalogDepictionValueInput?
    ) -> Provenencia_Engine_V1_UpdateObservationRequest {
        var req = Provenencia_Engine_V1_UpdateObservationRequest()
        req.projectDir = projectDir
        req.userID = userID
        req.observation = Self.mapCatalogObservation(observation)
        if let depictionInput {
            req.depictionInput = Self.mapDepictionInput(depictionInput)
        }
        return req
    }

    private static func mapDepictionInput(_ d: CatalogDepictionValueInput) -> Provenencia_Engine_V1_DepictionValueInput {
        var p = Provenencia_Engine_V1_DepictionValueInput()
        p.regionJson = d.regionJSON
        p.imagePath = d.imagePath
        return p
    }

    static func mapObservation(_ o: Provenencia_Engine_V1_Observation) -> CatalogObservation {
        CatalogObservation(
            id: o.id,
            ref: o.ref,
            citationID: o.citationID,
            subjectID: o.subjectID,
            propertyID: o.propertyID,
            polarity: o.polarity,
            valueText: o.valueText,
            valueInteger: o.hasValueInteger ? o.valueInteger : nil,
            valueBoolean: o.hasValueBoolean ? o.valueBoolean : nil,
            valueDateID: o.valueDateID,
            date: o.hasDate ? Self.mapDateValue(o.date) : nil,
            valueNameID: o.valueNameID,
            nameForm: o.hasName ? o.name.form : "",
            nameParts: o.hasName ? o.name.parts.map { CatalogNameValuePart(value: $0.value, type: $0.type) } : [],
            valueSubjectID: o.valueSubjectID,
            valueTermID: o.valueTermID,
            propertyKey: o.propertyKey,
            propertyLabel: o.propertyLabel,
            propertyValueType: o.propertyValueType,
            valueTermKey: o.valueTermKey,
            valueTermOrigin: o.valueTermOrigin,
            valueDepictionID: o.valueDepictionID,
            depiction: o.hasDepiction ? Self.mapDepictionValue(o.depiction) : nil
        )
    }

    private static func mapCatalogObservation(_ o: CatalogObservation) -> Provenencia_Engine_V1_Observation {
        var msg = Provenencia_Engine_V1_Observation()
        msg.id = o.id
        msg.ref = o.ref
        msg.citationID = o.citationID
        msg.subjectID = o.subjectID
        msg.propertyID = o.propertyID
        msg.polarity = o.polarity
        msg.valueText = o.valueText
        if let valueInteger = o.valueInteger {
            msg.valueInteger = valueInteger
        }
        if let valueBoolean = o.valueBoolean {
            msg.valueBoolean = valueBoolean
        }
        if let date = o.date {
            msg.date = Self.mapDateValueToProto(date)
        }
        msg.valueDateID = o.valueDateID
        if !o.nameForm.isEmpty {
            var name = Provenencia_Engine_V1_NameValueInput()
            name.form = o.nameForm
            for part in o.nameParts {
                var p = Provenencia_Engine_V1_NameValuePartInput()
                p.value = part.value
                p.type = part.type
                name.parts.append(p)
            }
            msg.name = name
        }
        msg.valueNameID = o.valueNameID
        msg.valueSubjectID = o.valueSubjectID
        msg.valueTermID = o.valueTermID
        msg.propertyKey = o.propertyKey
        msg.propertyLabel = o.propertyLabel
        msg.propertyValueType = o.propertyValueType
        msg.valueDepictionID = o.valueDepictionID
        return msg
    }

    static func mapObservationDraft(_ d: CatalogObservationDraft) -> Provenencia_Engine_V1_ObservationDraft {
        var o = Provenencia_Engine_V1_ObservationDraft()
        o.subjectID = d.subjectID
        o.propertyID = d.propertyID
        o.polarity = d.polarity
        o.valueText = d.valueText
        if let valueInteger = d.valueInteger {
            o.valueInteger = valueInteger
        }
        if let valueBoolean = d.valueBoolean {
            o.valueBoolean = valueBoolean
        }
        if let date = d.date {
            o.date = Self.mapDateValueToProto(date)
        }
        o.valueDateID = d.valueDateID
        if !d.nameForm.isEmpty {
            var name = Provenencia_Engine_V1_NameValueInput()
            name.form = d.nameForm
            for part in d.nameParts {
                var p = Provenencia_Engine_V1_NameValuePartInput()
                p.value = part.value
                p.type = part.type
                name.parts.append(p)
            }
            o.name = name
        }
        o.valueNameID = d.valueNameID
        o.valueSubjectID = d.valueSubjectID
        o.valueTermID = d.valueTermID
        o.notes = d.notes
        if let depiction = d.depiction {
            o.depiction = Self.mapDepictionInput(depiction)
        }
        return o
    }

    private static func mapDateValueToProto(_ d: CatalogDateValueInput) -> Provenencia_Engine_V1_DateValueInput {
        var p = Provenencia_Engine_V1_DateValueInput()
        p.kind = d.kind
        p.qualifier = d.qualifier
        p.calendar = d.calendar
        if let startYear = d.startYear { p.startYear = startYear }
        if let startMonth = d.startMonth { p.startMonth = startMonth }
        if let startDay = d.startDay { p.startDay = startDay }
        if let startHour = d.startHour { p.startHour = startHour }
        if let startMinute = d.startMinute { p.startMinute = startMinute }
        if let startSecond = d.startSecond { p.startSecond = startSecond }
        if let startMillisecond = d.startMillisecond { p.startMillisecond = startMillisecond }
        p.startTz = d.startTZ
        if let endYear = d.endYear { p.endYear = endYear }
        if let endMonth = d.endMonth { p.endMonth = endMonth }
        if let endDay = d.endDay { p.endDay = endDay }
        if let endHour = d.endHour { p.endHour = endHour }
        if let endMinute = d.endMinute { p.endMinute = endMinute }
        if let endSecond = d.endSecond { p.endSecond = endSecond }
        if let endMillisecond = d.endMillisecond { p.endMillisecond = endMillisecond }
        p.endTz = d.endTZ
        p.phrase = d.phrase
        return p
    }

    private static func mapTypeSuggestion(_ s: Provenencia_Engine_V1_TypeSuggestion) -> CatalogTypeSuggestion {
        CatalogTypeSuggestion(field: Self.mapMetadataField(s.field), sortOrder: Int(s.sortOrder))
    }

    private static func mapMetadataField(_ f: Provenencia_Engine_V1_MetadataField) -> CatalogMetadataField {
        CatalogMetadataField(
            id: f.id,
            key: f.key,
            origin: f.origin,
            label: f.label,
            dataType: f.dataType,
            description: f.description_p,
            usedBy: Int(f.usedBy)
        )
    }

    private static func wireOwner(_ owner: MetadataOwner) -> Provenencia_Engine_V1_MetadataOwner {
        var wire = Provenencia_Engine_V1_MetadataOwner()
        wire.level = owner.level.rawValue
        wire.id = owner.id
        return wire
    }

    private static func mapMetadataEntry(_ e: Provenencia_Engine_V1_MetadataWorkspaceEntry) -> CatalogMetadataEntry {
        CatalogMetadataEntry(
            field: Self.mapMetadataField(e.field),
            valueText: e.valueText,
            hasValue: e.hasValue_p,
            suggested: e.suggested,
            sortOrder: e.sortOrder,
            openHref: e.openHref,
            inherited: e.hasInherited ? Self.mapInheritedMetadataValue(e.inherited) : nil,
            staysWithoutValue: e.staysWithoutValue
        )
    }

    /// A level this build does not know maps to nil: `Level` mirrors the engine's
    /// metadata levels, so an unknown one is a version skew.
    private static func mapInheritedMetadataValue(_ v: Provenencia_Engine_V1_InheritedMetadataValue) -> CatalogInheritedMetadataValue? {
        guard let level = Level(rawValue: v.owner.level) else { return nil }
        return CatalogInheritedMetadataValue(
            displayText: v.displayText,
            isUnknown: v.mark.unknown,
            level: level,
            openHref: v.openHref
        )
    }

    private static func mapMetadataDraft(_ d: CatalogMetadataDraft) -> Provenencia_Engine_V1_MetadataDraft {
        Provenencia_Engine_V1_MetadataDraft.with {
            $0.values = d.values.map { v in
                Provenencia_Engine_V1_MetadataValue.with {
                    $0.fieldID = v.fieldID
                    $0.valueText = v.valueText
                }
            }
            $0.layout = d.layout.map { r in
                Provenencia_Engine_V1_MetadataLayoutRow.with {
                    $0.fieldID = r.fieldID
                    $0.sortOrder = r.sortOrder
                    $0.dismissed = r.dismissed
                }
            }
        }
    }

    private static func mapDateValue(_ d: Provenencia_Engine_V1_DateValueInput) -> CatalogDateValueInput {
        CatalogDateValueInput(
            kind: d.kind,
            qualifier: d.qualifier,
            calendar: d.calendar,
            startYear: d.hasStartYear ? d.startYear : nil,
            startMonth: d.hasStartMonth ? d.startMonth : nil,
            startDay: d.hasStartDay ? d.startDay : nil,
            startHour: d.hasStartHour ? d.startHour : nil,
            startMinute: d.hasStartMinute ? d.startMinute : nil,
            startSecond: d.hasStartSecond ? d.startSecond : nil,
            startMillisecond: d.hasStartMillisecond ? d.startMillisecond : nil,
            startTZ: d.startTz,
            endYear: d.hasEndYear ? d.endYear : nil,
            endMonth: d.hasEndMonth ? d.endMonth : nil,
            endDay: d.hasEndDay ? d.endDay : nil,
            endHour: d.hasEndHour ? d.endHour : nil,
            endMinute: d.hasEndMinute ? d.endMinute : nil,
            endSecond: d.hasEndSecond ? d.endSecond : nil,
            endMillisecond: d.hasEndMillisecond ? d.endMillisecond : nil,
            endTZ: d.endTz,
            phrase: d.phrase
        )
    }
}
