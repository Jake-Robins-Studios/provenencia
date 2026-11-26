import Foundation

/// The citation form's metadata line and the sheet behind it. The composer
/// stores no rows of a saved Citation: they are the open Citation's entry in
/// the cached Citation list, so the line follows every reload of that list (a
/// sheet save, a Citation create, a value moved at any level). A new Citation
/// reads the board it would start with once, when it is opened.
extension CitationComposerModel {
    /// The cached Citation list of the selected Artifact; nil until it first loads.
    private var listedCitationsValue: [CatalogListedCitation]? {
        guard let artifactID = selectedArtifactID else { return nil }
        let handle: QueryHandle<[CatalogListedCitation]>? = session.queryHandle(
            context.citationsKey(artifactID: artifactID)
        )
        return handle?.value
    }

    /// Every metadata field the researcher can add to a board.
    var metadataFields: [CatalogMetadataField] { context.metadataFields }

    /// The open Citation's board as the cached list holds it; nil for a new Citation, and while the
    /// list has no row for the open one.
    var metadataRows: [CatalogMetadataEntry]? {
        guard let id = activeCitationID else { return nil }
        return listedCitationsValue?.first { $0.id == id }?.metadata
    }

    /// Why the line shows an error in place of its button, or nil. A new Citation fails when its
    /// board could not be read; a saved one when the cached list is loaded and lacks it, unless its
    /// first save is still running (its id is set before the list reload ends).
    var metadataLineError: String? {
        guard let id = activeCitationID else { return draftMetadataFailure }
        guard let list = listedCitationsValue else { return nil }
        if list.contains(where: { $0.id == id }) || context.isCreatingCitation { return nil }
        return L10n.string(L10n.CitationComposer.metadataBoardUnavailable)
    }

    /// The count beside the button, or nil while the rows are not known. A saved Citation counts the
    /// board as saved; a new one counts the values it would inherit.
    var metadataCount: String? {
        guard activeCitationID != nil else {
            guard let rows = draftMetadataRows else { return nil }
            return L10n.CitationComposer.metadataInheritsNew(count: rows.filter { $0.inherited != nil }.count)
        }
        guard let rows = metadataRows else { return nil }
        let own = rows.filter(\.hasValue).count
        let inherited = rows.filter { !$0.hasValue && $0.inherited != nil }.count
        switch (own, inherited) {
        case (0, 0): return L10n.string(L10n.CitationComposer.metadataNone)
        case (_, 0): return L10n.CitationComposer.metadataCountOwn(own)
        case (0, _): return L10n.CitationComposer.metadataCountInherited(inherited)
        default: return L10n.CitationComposer.metadataCount(own: own, inherited: inherited)
        }
    }

    /// True when Edit metadata… can open: a saved Citation whose board the list holds, with nothing
    /// that owns the viewer running.
    var canEditMetadata: Bool {
        metadataRows != nil && metadataLineError == nil && !isTranscribing && !isDrawingDepiction
    }

    /// The Citation metadata sheet while it is the dialog on screen.
    var metadataSheet: CitationMetadataSheetModel? {
        get {
            if case .metadata(let sheet) = presented { return sheet }
            return nil
        }
        set {
            if let newValue {
                show(.metadata(newValue))
            } else if case .metadata = presented {
                show(nil)
            }
        }
    }

    /// True when the sheet, shown or stepped aside for a leave confirm, holds changes.
    var metadataSheetIsChanged: Bool {
        sheet(in: presented)?.host.isChanged ?? false
    }

    private func sheet(in dialog: ComposerPresented?) -> CitationMetadataSheetModel? {
        switch dialog {
        case .metadata(let sheet):
            return sheet
        case .leave(_, let returnTo), .transcription(_, let returnTo), .deleteImpact(let returnTo):
            return sheet(in: returnTo)
        default:
            return nil
        }
    }

    /// Opens the Citation metadata sheet over the open Citation's cached board.
    func requestEditMetadata() {
        guard canEditMetadata, let id = activeCitationID, let listed = listedCitation(id) else { return }
        metadataSheet = CitationMetadataSheetModel(
            context: context,
            citation: listed.citation,
            rows: listed.metadata,
            fields: metadataFields,
            onSaved: { [weak self] in self?.metadataSheet = nil }
        )
    }

    func clearDraftMetadata() {
        draftMetadataReadID += 1
        draftMetadataRows = nil
        draftMetadataFailure = nil
    }

    /// Reads the board a new Citation on the selected Artifact would start with. The answer is kept
    /// only if no newer read began, the same Artifact is selected, and no Citation opened meanwhile.
    func refreshDraftMetadata() {
        clearDraftMetadata()
        guard activeCitationID == nil, let artifactID = selectedArtifactID, !artifactID.isEmpty else { return }
        let readID = draftMetadataReadID
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let rows = try await store.getDraftMetadataBoard(
                    projectDir: session.projectKey.projectDir,
                    parents: [
                        MetadataOwner(level: .graph, id: graphID),
                        MetadataOwner(level: .artifact, id: artifactID),
                    ],
                    level: .citation
                )
                guard isCurrentDraftRead(readID, artifactID: artifactID) else { return }
                draftMetadataRows = rows
            } catch {
                guard isCurrentDraftRead(readID, artifactID: artifactID) else { return }
                draftMetadataFailure = (error as? CoreInvokeError)?.engineCode == .sourceMetadataInvalid
                    ? L10n.string(L10n.CitationComposer.metadataBoardUnavailable)
                    : L10n.Errors.message(for: error)
            }
        }
    }

    private func isCurrentDraftRead(_ readID: Int, artifactID: String) -> Bool {
        readID == draftMetadataReadID && activeCitationID == nil && selectedArtifactID == artifactID
    }
}
