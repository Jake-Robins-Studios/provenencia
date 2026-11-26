import Foundation
import Observation

/// The Citation metadata sheet: one saved Citation's board, edited and written on
/// its own. Save sends the board's draft with the Citation's stored columns as
/// they were when the sheet opened, so the write changes only metadata rows and
/// anything unsaved in the citation form stays unsaved. Cancel drops the model
/// with everything in it.
@MainActor
@Observable
final class CitationMetadataSheetModel {
    let citation: CatalogCitation
    let host: MetadataDraftHost
    let board: MetadataBoardModel
    /// Why the last Save stopped, shown at the top of the sheet; nil otherwise.
    var saveError: String?
    private(set) var isSaving = false
    /// Which part of the body a Save asks to scroll to; the save error sits at the top.
    private(set) var scrollTarget: Section?
    /// Changes each time a Save asks the body to scroll to `scrollTarget` again.
    private(set) var scrollRequest = 0

    enum Section: Hashable {
        case top
    }

    @ObservationIgnored private let context: CitationComposerContext
    @ObservationIgnored private let onSaved: @MainActor () -> Void

    /// `citation` is the cached list row's Citation; `rows` its board; `onSaved` closes the sheet.
    init(
        context: CitationComposerContext,
        citation: CatalogCitation,
        rows: [CatalogMetadataEntry],
        fields: [CatalogMetadataField],
        onSaved: @escaping @MainActor () -> Void
    ) {
        self.context = context
        self.citation = citation
        self.onSaved = onSaved
        host = MetadataDraftHost(entries: rows, fields: fields)
        board = MetadataBoardModel(host: host)
    }

    var citationID: String { citation.id }

    /// "CIT-4QJ7R · Alderwick death notice. Saves on its own; …" under the sheet's title.
    var subtitle: String {
        let label = citation.description.trimmingCharacters(in: .whitespacesAndNewlines)
        return L10n.CitationComposer.metadataSheetSubtitle(
            ref: citation.ref,
            label: label.isEmpty ? L10n.string(L10n.CitationComposer.metadataNoLabel) : label
        )
    }

    /// Typed text not yet confirmed counts: the sheet asks before it closes over it, and Save is on
    /// so it can say what is left to finish.
    var isDirty: Bool { board.hasUnsavedChanges }
    var canSave: Bool { board.hasUnsavedChanges && !isSaving }

    /// Writes the board's changes with the Citation's stored columns. True when the sheet may close.
    func save() async -> Bool {
        guard !isSaving else { return false }
        saveError = nil
        if let message = board.unconfirmedInputMessage {
            saveError = message
            scrollToTop()
            return false
        }
        guard let draft = host.draft else { return true }
        isSaving = true
        defer { isSaving = false }
        do {
            let (_, _, effects) = try await context.store.updateCitation(
                projectDir: context.projectDir,
                userID: context.userID,
                citationID: citation.id,
                locatorJSON: citation.locatorJSON,
                transcription: citation.transcription,
                description: citation.description,
                transcriptionUncertain: citation.transcriptionUncertain,
                transcriptionNote: citation.transcriptionNote,
                metadata: draft
            )
            host.markSaved()
            context.applyWrite(effects)
            onSaved()
            return true
        } catch {
            if board.showRefusal(error) { return false }
            saveError = L10n.Errors.message(for: error)
            scrollToTop()
            return false
        }
    }

    /// The save error sits at the top of the body: ask for it.
    private func scrollToTop() {
        scrollTarget = .top
        scrollRequest += 1
    }
}

extension CitationMetadataSheetModel: Equatable {
    /// Two sheets are the same dialog when they edit the same Citation.
    nonisolated static func == (lhs: CitationMetadataSheetModel, rhs: CitationMetadataSheetModel) -> Bool {
        lhs.citation.id == rhs.citation.id
    }
}
