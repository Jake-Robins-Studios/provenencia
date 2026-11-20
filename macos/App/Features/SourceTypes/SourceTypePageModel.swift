import Foundation
import Observation

/// State for one Source type's page (S15-48): its saved row, the Details draft, Save and Revert,
/// the suggested fields it assigns and removes at each of the three levels, and Delete. The page mounts once per
/// type (`PlaceRegistry` `viewIdentity`), so the draft belongs to one type. It reads the type from
/// the session's types list and writes through the declared patches (`.updatedSourceType`,
/// `.deletedSourceType`, `.wroteTypeSuggestions`); the list model never edits.
@MainActor
@Observable
final class SourceTypePageModel {
    let typeID: String

    /// The Details form's values; set from the saved type once it is known (`syncDraft()`).
    var draft: SourceTypeDraft?
    private(set) var isSaving = false
    /// The Label's error, shown under Label as the researcher edits.
    private(set) var labelCheck = SourceTypeLabelCheck()
    /// A refused or failed Save, shown beside Save and announced.
    private(set) var saveError: String?
    var toast: VocabularyToast?
    /// The Copy type sheet, while it is open (`View.sourceTypeCopyDialog`).
    var copying: SourceTypeCopyModel?
    /// The label of a copy whose move to its page the leave guard is holding; nil otherwise.
    private var heldCopyLabel: String?

    /// The one suggestion write in flight, across all three lists.
    enum SuggestionWrite: Equatable {
        case assigning(Level)
        case removing(Level, fieldID: String)
    }

    /// The field picked in each list's picker, by level; absent or empty means none.
    var assignPicks: [Level: String] = [:]
    private(set) var suggestionWrite: SuggestionWrite?
    /// A failed suggestion write's message, by the level it was at (read failures live on the
    /// level's query handle).
    private(set) var suggestionErrors: [Level: String] = [:]

    let deleteImpact = DeleteImpactFlow()
    var pendingImpact: PVDeleteImpactRequest? {
        get { deleteImpact.request }
        set { deleteImpact.applyRequest(newValue) }
    }
    var isDeleting: Bool { deleteImpact.isRunning }
    var deleteError: String? { deleteImpact.error }

    /// Set while a leave waits on the discard confirm.
    var pendingLeave: WorkspaceLeaveAsk?
    /// The navigation this page guards (`.workspaceLeaveGuard(_:)` sets it).
    @ObservationIgnored
    weak var navigation: WorkspaceNavigation?

    private let userID: String
    private let store: any GenealogyStore
    private let session: WorkspaceSession

    init(
        typeID: String,
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore
    ) {
        self.typeID = typeID
        self.session = session
        self.userID = userID
        self.store = store
    }

    // MARK: Session handles

    private var fieldsKey: CatalogQueryKey { .metadataFieldsList(project: session.projectKey) }

    private func suggestionsKey(at level: Level) -> CatalogQueryKey {
        .typeSuggestions(project: session.projectKey, typeId: typeID, level: level)
    }

    /// Starts the reads the page shows: the types list, the Metadata fields (the assign pool) and
    /// this type's suggestions at each level.
    func warm() {
        let _: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        let _: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        for key in CatalogQueryKey.typeSuggestionsKeys(project: session.projectKey, typeId: typeID) {
            let _: QueryHandle<[CatalogTypeSuggestion]> = session.query(key)
        }
    }

    var typesHandle: QueryHandle<[CatalogSourceType]>? { session.sourceTypesHandle }

    func suggestionsHandle(at level: Level) -> QueryHandle<[CatalogTypeSuggestion]>? {
        session.queryHandle(suggestionsKey(at: level))
    }

    /// Reads the types list again after a failure (Try again).
    func rereadTypes() {
        let _: QueryHandle<[CatalogSourceType]> = session.reread(session.sourceTypesKey)
    }

    /// Reads one level's suggestions again after a failure (Try again).
    func rereadSuggestions(at level: Level) {
        let _: QueryHandle<[CatalogTypeSuggestion]> = session.reread(suggestionsKey(at: level))
    }

    // MARK: The type

    /// The saved row; nil while the types list has no value or has no such type.
    var type: CatalogSourceType? { session.sourceType(id: typeID) }

    /// True once a settled types list lacks the type: the page leaves for the list.
    var isGone: Bool { session.sourceTypePresence(id: typeID).isGone }

    /// The last label the page showed, for the notice once the type is gone (the row is no longer
    /// in the list to name it).
    @ObservationIgnored
    private var lastLabel = ""

    /// Remembers the label the page shows; nil (the type is not in the list) keeps the last one.
    func noteLabel(_ label: String?) {
        if let label { lastLabel = label }
    }

    /// The notice to show as the page leaves for the list: nil unless the type is gone.
    var goneNotice: String? {
        guard isGone else { return nil }
        let label = lastLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty
            ? L10n.string(L10n.SourceTypes.goneNoticeUnnamed)
            : L10n.SourceTypes.goneNotice(label: lastLabel)
    }

    /// A plugin's type: read only.
    var isLocked: Bool {
        type.map { CatalogOrigin.isPlugin($0.origin) } ?? false
    }

    /// The level's loaded suggestions in stored order; empty until it loads.
    func suggestions(at level: Level) -> [CatalogTypeSuggestion] {
        suggestionsHandle(at: level)?.value ?? []
    }

    var fields: [CatalogMetadataField] {
        session.queryHandle(fieldsKey)?.value ?? []
    }

    // MARK: Details

    /// Sets the draft from the saved type, once. A later change to the list never touches it.
    func syncDraft() {
        guard draft == nil, let type else { return }
        draft = Self.draft(of: type)
    }

    /// Writes a pending icon pick into the draft (form-dialog confirm path).
    func applyDraftIconKey(_ key: String) {
        guard var draft else { return }
        draft.iconKey = key
        self.draft = draft
    }

    var isDirty: Bool {
        guard !isLocked, let type, let draft else { return false }
        return draft.label != type.label
            || draft.description != type.description
            || draft.iconKey != type.iconKey
    }

    var canSubmit: Bool {
        guard let draft else { return false }
        return draft.labelError == nil && !isSaving && isDirty
    }

    func editLabel(_ new: String) {
        guard var draft else { return }
        labelCheck.edit(new, in: &draft)
        self.draft = draft
    }

    func revertEdit() {
        guard let type else { return }
        draft = Self.draft(of: type)
        labelCheck.clear()
        saveError = nil
    }

    func submit() async {
        guard let draft, let type, !isLocked else { return }
        guard labelCheck.validate(draft) else { return }
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            let (updated, _, effects) = try await store.updateSourceType(
                projectDir: session.projectKey.projectDir, userID: userID, typeID: type.id,
                label: draft.trimmedLabel, description: draft.description, iconKey: draft.iconKey,
                formats: nil
            )
            session.apply(effects, .updatedSourceType(updated))
            self.draft = Self.draft(of: updated)
            toast = VocabularyToast(
                title: L10n.string(L10n.SourceTypes.toastUpdatedTitle),
                body: L10n.SourceTypes.toastUpdatedBody(label: updated.label, key: updated.key),
                tone: .success
            )
        } catch {
            saveError = L10n.Errors.message(for: error)
        }
    }

    private static func draft(of type: CatalogSourceType) -> SourceTypeDraft {
        SourceTypeDraft(label: type.label, description: type.description, iconKey: type.iconKey)
    }

    // MARK: Copy

    /// Copy is offered once the type is known and until it is gone, on every origin: copying only
    /// reads the original, and the copy is the researcher's.
    var canOpenCopy: Bool { type != nil && !isGone }

    /// Opens the Copy type sheet for the saved type. The sheet copies saved values, never the
    /// Details draft.
    func openCopy() {
        guard canOpenCopy, let type else { return }
        copying = SourceTypeCopyModel(original: type, session: session, userID: userID, store: store)
    }

    /// Opens the page of a copy just made. When unsaved Details hold the move, the copy is not
    /// lost to the researcher: Keep editing says it was made (`keepEditing()`). A move that goes
    /// through says nothing, as Add type does.
    func open(copy created: CatalogSourceType) {
        navigation?.go(to: .sourceTypePage(typeId: created.id, title: created.label))
        heldCopyLabel = navigation?.heldNavigation == nil ? nil : created.label
    }

    // MARK: Suggested fields

    var canEditAssociations: Bool {
        type != nil && !isLocked
    }

    /// True once the level's list has been read: its picker and plus show, and nothing is assigned
    /// against a list that has not.
    func isLoaded(at level: Level) -> Bool {
        if case .loaded? = suggestionsHandle(at: level)?.reading { return true }
        return false
    }

    /// The vocabulary fields not yet in the level's list, by label.
    func assignPool(at level: Level) -> [CatalogMetadataField] {
        let assigned = Set(suggestions(at: level).map(\.field.id))
        return fields
            .filter { !assigned.contains($0.id) }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    func pickedField(at level: Level) -> CatalogMetadataField? {
        guard let pick = assignPicks[level], !pick.isEmpty else { return nil }
        return assignPool(at: level).first { $0.id == pick }
    }

    func canAssign(at level: Level) -> Bool {
        isLoaded(at: level) && pickedField(at: level) != nil && suggestionWrite == nil && canEditAssociations
    }

    /// Whether a row's remove may run: no write is in flight, at any level.
    var canRemove: Bool {
        suggestionWrite == nil && canEditAssociations
    }

    /// The type's level phrase ("on each Artifact of Census Sources").
    private func levelPhrase(_ level: Level, type: CatalogSourceType) -> String {
        L10n.format(L10n.SourceTypes.level(level).phrase, type.label)
    }

    func assignTooltip(at level: Level) -> String {
        if assignPool(at: level).isEmpty { return L10n.string(L10n.SourceTypes.assignTipPoolEmpty) }
        guard let field = pickedField(at: level), let type else {
            return L10n.string(L10n.SourceTypes.assignTipChoose)
        }
        return L10n.SourceTypes.assignTipField(label: field.label, phrase: levelPhrase(level, type: type))
    }

    func assignAccessibilityLabel(at level: Level) -> String {
        // The page draws its lists once the type is known, so the picker's own label is a fallback.
        guard let type else { return L10n.string(L10n.SourceTypes.level(level).pickerLabel) }
        let phrase = levelPhrase(level, type: type)
        guard let field = pickedField(at: level) else {
            return L10n.SourceTypes.assignField(phrase: phrase)
        }
        return L10n.SourceTypes.assignFieldNamed(field: field.label, phrase: phrase)
    }

    /// A row's remove button label: it names the field and the list.
    func removeLabel(for field: CatalogMetadataField, at level: Level) -> String {
        guard let type else { return field.label }
        return L10n.SourceTypes.removeSuggestion(label: field.label, phrase: levelPhrase(level, type: type))
    }

    func assignPickedField(at level: Level) async {
        guard canAssign(at: level), let type, let field = pickedField(at: level) else { return }
        suggestionWrite = .assigning(level)
        suggestionErrors[level] = nil
        defer { suggestionWrite = nil }
        do {
            let updated = try await store.assignTypeField(
                projectDir: session.projectKey.projectDir, typeID: type.id, fieldID: field.id, level: level
            )
            session.apply(.wroteTypeSuggestions(typeId: type.id, level: level, edit: updated))
            assignPicks[level] = ""
            toast = VocabularyToast(
                title: L10n.string(L10n.SourceTypes.toastAssignedTitle),
                body: L10n.SourceTypes.toastAssignedBody(
                    field: field.label, phrase: levelPhrase(level, type: type)
                ),
                tone: .success
            )
        } catch {
            suggestionErrors[level] = L10n.Errors.message(for: error)
        }
    }

    func removeSuggestion(fieldID: String, level: Level) async {
        guard canRemove, let type else { return }
        guard let field = suggestions(at: level).first(where: { $0.field.id == fieldID })?.field else { return }
        suggestionWrite = .removing(level, fieldID: fieldID)
        suggestionErrors[level] = nil
        defer { suggestionWrite = nil }
        do {
            let updated = try await store.removeTypeField(
                projectDir: session.projectKey.projectDir, typeID: type.id, fieldID: fieldID, level: level
            )
            session.apply(.wroteTypeSuggestions(typeId: type.id, level: level, edit: updated))
            toast = VocabularyToast(
                title: L10n.string(L10n.SourceTypes.toastRemovedTitle),
                body: L10n.SourceTypes.toastRemovedBody(
                    field: field.label, phrase: levelPhrase(level, type: type), valueCount: field.usedBy
                ),
                tone: .info
            )
        } catch {
            suggestionErrors[level] = L10n.Errors.message(for: error)
        }
    }

    // MARK: Delete

    var deleteTooltip: LocalizedStringResource { L10n.SourceTypes.deleteType }

    var deleteAccessibilityLabel: String {
        guard let type else {
            return L10n.string(L10n.SourceTypes.deleteType)
        }
        return L10n.SourceTypes.deleteTypeAccessibility(label: type.label)
    }

    var pendingDeleteType: CatalogSourceType? {
        guard deleteImpact.request?.target.id == typeID else { return nil }
        return type
    }

    func askDelete() async {
        guard let type else { return }
        await deleteImpact.ask(
            kind: "source_type",
            id: type.id,
            ref: type.key,
            title: type.label
        ) {
            try await self.store.getDeleteImpact(
                projectDir: self.session.projectKey.projectDir,
                kind: "source_type",
                id: type.id
            )
        }
    }

    func cancelDelete() {
        deleteImpact.cancel()
    }

    /// Returns true when the type was deleted. `leave` runs once, inside the write's application,
    /// when it was; it moves to the list. A failed write does not run it.
    @discardableResult
    func confirmDelete(leaving leave: () -> Void) async -> Bool {
        await deleteImpact.confirm { target in
            let effects = try await store.deleteSourceType(
                projectDir: session.projectKey.projectDir, userID: userID, typeID: target.id
            )
            session.apply(effects, .deletedSourceType(id: target.id), leavingPage: leave)
        }
    }
}

extension SourceTypePageModel: WorkspaceLeaveGuard {
    /// Holds a move away while Details hold unsaved edits, unless a Save is in flight.
    func shouldHoldNavigation(_: PendingNavigation) -> Bool {
        guard isDirty, !isSaving else { return false }
        pendingLeave = WorkspaceLeaveAsk()
        return true
    }

    /// Discard: the saved values come back, and the held move runs.
    func discardAndLeave() {
        revertEdit()
        pendingLeave = nil
        heldCopyLabel = nil
        navigation?.resumeHeldNavigation()
    }

    /// Keep editing: the page stays and the held move is dropped. If the held move was to a copy
    /// just made, a toast says the copy exists.
    func keepEditing() {
        pendingLeave = nil
        if let label = heldCopyLabel {
            heldCopyLabel = nil
            session.noticeToast = VocabularyToast(
                title: L10n.SourceTypes.copyMadeKeptEditing(label), body: "", tone: .info
            )
        }
        navigation?.cancelHeldNavigation()
    }
}
