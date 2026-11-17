import Foundation
import Observation

/// What the Copy type sheet lets the researcher choose. One value, so "did anything change" is one
/// comparison against the prefill. The Label starts blank: the key can never change, so the sheet
/// does not prefill "Copy of …".
struct SourceTypeCopyChoices: Equatable {
    var draft = SourceTypeDraft(label: "", description: "")
    var includeIcon = true
    var includeDescription = true
    var includeFormats = true
    var includedLevels: Set<Level> = Set(Level.metadataLevels)
}

/// State of the Copy type sheet: the new type's Label, which parts the original has, what the
/// researcher kept, and the copy itself. The type page presents it through
/// `View.sourceTypeCopyDialog`, held by `SourceTypePageModel.copying` as `SourceCopyModel` is by the
/// Source page. The sheet copies the original's saved values and the engine's reads, never the
/// page's draft. Which rows a copy makes is the engine's rule; this model sends the ticks.
@MainActor
@Observable
final class SourceTypeCopyModel {
    let original: CatalogSourceType
    var choices = SourceTypeCopyChoices()
    let prefill: SourceTypeCopyChoices
    private(set) var labelCheck = SourceTypeLabelCheck()
    var copyError: String?
    private(set) var isSaving = false

    /// The original's formats once read; nil until then.
    private(set) var formats: CatalogCitationFormats?
    private(set) var formatsState: PVFormLoadState = .loading

    private let session: WorkspaceSession
    private let userID: String
    private let store: any GenealogyStore

    init(
        original: CatalogSourceType,
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore
    ) {
        self.original = original
        self.session = session
        self.userID = userID
        self.store = store
        for key in CatalogQueryKey.typeSuggestionsKeys(project: session.projectKey, typeId: original.id) {
            let _: QueryHandle<[CatalogTypeSuggestion]> = session.query(key)
        }
        prefill = SourceTypeCopyChoices()
    }

    // MARK: Reads

    /// Reads the original's formats. Does nothing once they are read, so the form's `.task` can
    /// run again.
    func loadFormats() async {
        guard formatsState != .ready else { return }
        do {
            formats = try await store.citationFormats(
                projectDir: session.projectKey.projectDir, typeID: original.id
            )
            formatsState = .ready
        } catch {
            formatsState = .failed(L10n.Errors.message(for: error))
        }
    }

    /// The first failed read in the order formats, Source, Artifact, Evidence graph; else loading
    /// while any read is; else ready. A value wins: a failed refetch of a list keeps the stale
    /// list and stays ready.
    var loadState: PVFormLoadState {
        PVFormLoadState.combining(
            [formatsState] + Level.metadataLevels.map { suggestionsHandle(at: $0)?.read.formLoadState ?? .loading }
        )
    }

    private func suggestionsKey(at level: Level) -> CatalogQueryKey {
        .typeSuggestions(project: session.projectKey, typeId: original.id, level: level)
    }

    private func suggestionsHandle(at level: Level) -> QueryHandle<[CatalogTypeSuggestion]>? {
        session.queryHandle(suggestionsKey(at: level))
    }

    /// Reads again what failed: each failed list, and the formats.
    func reload() {
        for level in Level.metadataLevels where suggestionsHandle(at: level)?.read.isFailed == true {
            let _: QueryHandle<[CatalogTypeSuggestion]> = session.reread(suggestionsKey(at: level))
        }
        if case .failed = formatsState {
            formatsState = .loading
            Task { await loadFormats() }
        }
    }

    // MARK: Parts

    var iconHint: String {
        L10n.string(PVMarkKey(catalogKey: original.iconKey).typePickerTitle)
    }

    var descriptionAvailable: Bool {
        !original.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The forms the original has, in `CitationForm` order.
    var formsPresent: [CitationForm] {
        guard let formats else { return [] }
        return CitationForm.allCases.filter { !formats.text($0).isEmpty }
    }

    var formatsAvailable: Bool { !formsPresent.isEmpty }

    /// "Full note, Short note and Source-list entry".
    var formatsHint: String {
        ListFormatter.localizedString(byJoining: formsPresent.map { L10n.string(L10n.CitationForms.name($0)) })
    }

    /// How many fields the original suggests at the level; 0 until it is read.
    func suggestionCount(at level: Level) -> Int {
        suggestionsHandle(at: level)?.value?.count ?? 0
    }

    func levelAvailable(_ level: Level) -> Bool { suggestionCount(at: level) > 0 }

    func levelHint(_ level: Level) -> String {
        L10n.SourceTypes.assignedCount(count: suggestionCount(at: level))
    }

    /// The levels ticked and present, in `Level.metadataLevels` order.
    var levelsToCopy: [Level] {
        Level.metadataLevels.filter { choices.includedLevels.contains($0) && levelAvailable($0) }
    }

    // MARK: Actions

    var key: String { choices.draft.key }

    func editLabel(_ new: String) {
        labelCheck.edit(new, in: &choices.draft)
    }

    var canCopy: Bool {
        loadState == .ready && !isSaving && choices.draft.labelError == nil
    }

    var isDirty: Bool { choices != prefill }

    /// On success returns the copy for the host to open. On failure the sheet keeps every field
    /// and tick.
    func copy() async -> CatalogSourceType? {
        guard !isSaving, loadState == .ready else { return nil }
        guard labelCheck.validate(choices.draft) else { return nil }
        isSaving = true
        defer { isSaving = false }
        copyError = nil
        do {
            let (created, effects) = try await store.copySourceType(
                projectDir: session.projectKey.projectDir,
                userID: userID,
                typeID: original.id,
                label: choices.draft.trimmedLabel,
                copyIcon: choices.includeIcon,
                copyDescription: choices.includeDescription && descriptionAvailable,
                copyFormats: choices.includeFormats && formatsAvailable,
                levels: levelsToCopy
            )
            session.apply(effects, .createdSourceType(created))
            return created
        } catch {
            if !labelCheck.refuse(error) {
                copyError = L10n.Errors.message(for: error)
            }
            return nil
        }
    }
}
