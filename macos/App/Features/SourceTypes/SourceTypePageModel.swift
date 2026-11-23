import Foundation
import Observation

/// State for one Source type's page (S15-48): its saved row, the Details draft, Save and Revert,
/// the one list of suggested fields it assigns and removes, and Delete. The page mounts once per
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
    /// The Copy type sheet, while it is open (`View.sourceTypeCopyDialog`).
    var copying: SourceTypeCopyModel?
    /// The label of a copy whose move to its page the leave guard is holding; nil otherwise.
    private var heldCopyLabel: String?

    /// The one suggestion write in flight.
    enum SuggestionWrite: Equatable {
        case assigning
        case removing(fieldID: String)
    }

    /// The field picked in the picker; empty means none.
    var assignPick: String = ""
    private(set) var suggestionWrite: SuggestionWrite?
    /// A failed suggestion write's message (a read failure lives on the list's query handle).
    private(set) var suggestionError: String?

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

    /// The citation formats' editor; a Save carries its drafts in the same write as the Details.
    let formats: SourceTypeFormatsModel

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
        self.formats = SourceTypeFormatsModel(typeID: typeID, session: session, store: store)
    }

    // MARK: Session handles

    private var fieldsKey: CatalogQueryKey { .metadataFieldsList(project: session.projectKey) }

    private var suggestionsKey: CatalogQueryKey {
        .typeSuggestions(project: session.projectKey, typeId: typeID)
    }

    /// Starts the reads the page shows: the types list, the Metadata fields (the assign pool) and
    /// this type's suggestions.
    func warm() {
        let _: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        let _: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        let _: QueryHandle<[CatalogTypeSuggestion]> = session.query(suggestionsKey)
    }

    var typesHandle: QueryHandle<[CatalogSourceType]>? { session.sourceTypesHandle }

    var suggestionsHandle: QueryHandle<[CatalogTypeSuggestion]>? {
        session.queryHandle(suggestionsKey)
    }

    /// Reads the types list again after a failure (Try again).
    func rereadTypes() {
        let _: QueryHandle<[CatalogSourceType]> = session.reread(session.sourceTypesKey)
    }

    /// Reads the suggestions again after a failure (Try again).
    func rereadSuggestions() {
        let _: QueryHandle<[CatalogTypeSuggestion]> = session.reread(suggestionsKey)
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

    /// The loaded suggestions in stored order; empty until they load.
    var suggestions: [CatalogTypeSuggestion] {
        suggestionsHandle?.value ?? []
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
        guard !isLocked else { return false }
        if formats.isDirty { return true }
        guard let type, let draft else { return false }
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
        formats.revert()
    }

    func submit() async {
        guard let draft, let type, !isLocked else { return }
        guard labelCheck.validate(draft) else { return }
        let detailsChanged = Self.draft(of: type) != draft
        let sendsFormats = formats.isDirty
        isSaving = true
        saveError = nil
        defer { isSaving = false }
        do {
            let (updated, reply, effects) = try await store.updateSourceType(
                projectDir: session.projectKey.projectDir, userID: userID, typeID: type.id,
                label: draft.trimmedLabel, description: draft.description, iconKey: draft.iconKey,
                formats: sendsFormats ? formats.draftForSave() : nil
            )
            if let reply, !reply.diagnostics.isEmpty {
                // Nothing saved, the Details included: the warnings show at the forms and every edit stays.
                formats.refused(reply)
                saveError = L10n.string(L10n.SourceTypes.Formats.saveRefused)
                return
            }
            session.apply(effects, .updatedSourceType(updated))
            self.draft = Self.draft(of: updated)
            if let reply {
                session.apply(.changedCitationFormats(typeId: type.id))
                formats.saved(reply)
            }
            addSavedToast(updated, detailsChanged: detailsChanged, formatsSaved: sendsFormats)
        } catch {
            saveError = L10n.Errors.message(for: error)
        }
    }

    /// Adds the toast naming what saved: the Details, the formats, or both.
    private func addSavedToast(_ updated: CatalogSourceType, detailsChanged: Bool, formatsSaved: Bool) {
        switch (detailsChanged, formatsSaved) {
        case (_, false):
            session.toasts.add(
                tone: .success,
                title: L10n.string(L10n.SourceTypes.toastUpdatedTitle),
                message: L10n.SourceTypes.toastUpdatedBody(label: updated.label, key: updated.key)
            )
        case (false, true):
            session.toasts.add(
                tone: .success,
                title: L10n.string(L10n.SourceTypes.Formats.toastSavedTitle),
                message: L10n.SourceTypes.Formats.toastSavedBody(label: updated.label)
            )
        case (true, true):
            session.toasts.add(
                tone: .success,
                title: L10n.string(L10n.SourceTypes.toastUpdatedTitle),
                message: L10n.SourceTypes.Formats.toastBothBody(label: updated.label)
            )
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

    /// True once the list has been read: its picker and plus show, and nothing is assigned
    /// against a list that has not.
    var isLoaded: Bool {
        if case .loaded? = suggestionsHandle?.reading { return true }
        return false
    }

    /// The vocabulary fields not yet in the list, by label.
    var assignPool: [CatalogMetadataField] {
        let assigned = Set(suggestions.map(\.field.id))
        return fields
            .filter { !assigned.contains($0.id) }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    var pickedField: CatalogMetadataField? {
        guard !assignPick.isEmpty else { return nil }
        return assignPool.first { $0.id == assignPick }
    }

    var canAssign: Bool {
        isLoaded && pickedField != nil && suggestionWrite == nil && canEditAssociations
    }

    /// Whether a row's remove may run: no write is in flight.
    var canRemove: Bool {
        suggestionWrite == nil && canEditAssociations
    }

    var assignTooltip: String {
        if assignPool.isEmpty { return L10n.string(L10n.SourceTypes.assignTipPoolEmpty) }
        guard let field = pickedField, let type else {
            return L10n.string(L10n.SourceTypes.assignTipChoose)
        }
        return L10n.SourceTypes.assignTipField(label: field.label, type: type.label)
    }

    var assignAccessibilityLabel: String {
        // The page draws its list once the type is known, so the picker's own label is a fallback.
        guard let type else { return L10n.string(L10n.SourceTypes.suggestedPickerLabel) }
        guard let field = pickedField else {
            return L10n.SourceTypes.assignField(type: type.label)
        }
        return L10n.SourceTypes.assignFieldNamed(field: field.label, type: type.label)
    }

    /// A row's remove button label: it names the field and the type.
    func removeLabel(for field: CatalogMetadataField) -> String {
        guard let type else { return field.label }
        return L10n.SourceTypes.removeSuggestion(label: field.label, type: type.label)
    }

    func assignPickedField() async {
        guard canAssign, let type, let field = pickedField else { return }
        suggestionWrite = .assigning
        suggestionError = nil
        defer { suggestionWrite = nil }
        do {
            let updated = try await store.assignTypeField(
                projectDir: session.projectKey.projectDir, typeID: type.id, fieldID: field.id
            )
            session.apply(.wroteTypeSuggestions(typeId: type.id, edit: updated))
            assignPick = ""
            session.toasts.add(
                tone: .success,
                title: L10n.string(L10n.SourceTypes.toastAssignedTitle),
                message: L10n.SourceTypes.toastAssignedBody(field: field.label, type: type.label)
            )
        } catch {
            suggestionError = L10n.Errors.message(for: error)
        }
    }

    func removeSuggestion(fieldID: String) async {
        guard canRemove, let type else { return }
        guard let field = suggestions.first(where: { $0.field.id == fieldID })?.field else { return }
        suggestionWrite = .removing(fieldID: fieldID)
        suggestionError = nil
        defer { suggestionWrite = nil }
        do {
            let updated = try await store.removeTypeField(
                projectDir: session.projectKey.projectDir, typeID: type.id, fieldID: fieldID
            )
            session.apply(.wroteTypeSuggestions(typeId: type.id, edit: updated))
            session.toasts.add(
                tone: .info,
                title: L10n.string(L10n.SourceTypes.toastRemovedTitle),
                message: L10n.SourceTypes.toastRemovedBody(
                    field: field.label, type: type.label, valueCount: field.usedBy
                )
            )
        } catch {
            suggestionError = L10n.Errors.message(for: error)
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
            session.toasts.add(
                tone: .info,
                title: L10n.SourceTypes.copyMadeKeptEditing(label),
                message: nil
            )
        }
        navigation?.cancelHeldNavigation()
    }
}
