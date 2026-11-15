import Foundation
import Observation

/// State for one Source type's page (S15-48): its saved row, the Details draft, Save and Revert,
/// the Source-level suggested fields it assigns and removes, and Delete. The page mounts once per
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
    var formError: String?
    var toast: VocabularyToast?

    var suggestionError: String?
    var assignPick = ""
    private(set) var isAssigning = false
    private(set) var removingFieldID: String?

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

    private var suggestionsKey: CatalogQueryKey {
        .typeSuggestions(project: session.projectKey, typeId: typeID)
    }

    /// Starts the three reads the page shows: the types list, the Metadata fields (the assign pool)
    /// and this type's suggestions.
    func warm() {
        let _: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        let _: QueryHandle<[CatalogMetadataField]> = session.query(fieldsKey)
        let _: QueryHandle<[CatalogTypeSuggestion]> = session.query(suggestionsKey)
    }

    var typesHandle: QueryHandle<[CatalogSourceType]>? { session.sourceTypesHandle }

    var suggestionsHandle: QueryHandle<[CatalogTypeSuggestion]>? { session.queryHandle(suggestionsKey) }

    /// Reads the types list again after a failure (Try again).
    func rereadTypes() {
        let _: QueryHandle<[CatalogSourceType]> = session.reread(session.sourceTypesKey)
    }

    /// Reads this type's suggestions again after a failure (Try again).
    func rereadSuggestions() {
        let _: QueryHandle<[CatalogTypeSuggestion]> = session.reread(suggestionsKey)
    }

    // MARK: The type

    /// The saved row; nil while the types list has no value or has no such type.
    var type: CatalogSourceType? { session.sourceType(id: typeID) }

    /// True once a settled types list lacks the type: the page leaves for the list.
    var isGone: Bool {
        if case .gone = session.sourceTypePresence(id: typeID) { return true }
        return false
    }

    /// A plugin's type: read only.
    var isLocked: Bool {
        type.map { CatalogOrigin.isPlugin($0.origin) } ?? false
    }

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
        guard !isLocked, let type, let draft else { return false }
        return draft.label != type.label
            || draft.description != type.description
            || draft.iconKey != type.iconKey
    }

    var canSubmit: Bool {
        guard let draft else { return false }
        return draft.labelError == nil && !isSaving && isDirty
    }

    func revertEdit() {
        guard let type else { return }
        draft = Self.draft(of: type)
        formError = nil
    }

    func submit() async {
        guard let draft, let type, !isLocked else { return }
        guard draft.labelError == nil else {
            formError = draft.labelError
            return
        }
        isSaving = true
        formError = nil
        defer { isSaving = false }
        do {
            let (updated, effects) = try await store.updateSourceType(
                projectDir: session.projectKey.projectDir, userID: userID, typeID: type.id,
                label: draft.trimmedLabel, description: draft.description, iconKey: draft.iconKey
            )
            session.apply(effects, .updatedSourceType(updated))
            self.draft = Self.draft(of: updated)
            toast = VocabularyToast(
                title: L10n.string(L10n.SourceTypes.toastUpdatedTitle),
                body: L10n.SourceTypes.toastUpdatedBody(label: updated.label, key: updated.key),
                tone: .success
            )
        } catch {
            formError = L10n.Errors.message(for: error)
        }
    }

    private static func draft(of type: CatalogSourceType) -> SourceTypeDraft {
        SourceTypeDraft(label: type.label, description: type.description, iconKey: type.iconKey)
    }

    // MARK: Suggested fields

    var canEditAssociations: Bool {
        type != nil && !isLocked
    }

    var assignPool: [CatalogMetadataField] {
        let assigned = Set(suggestions.map(\.field.id))
        return fields
            .filter { !assigned.contains($0.id) }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    var canAssign: Bool {
        !assignPick.isEmpty && !isAssigning && canEditAssociations
    }

    var pickedField: CatalogMetadataField? {
        assignPool.first { $0.id == assignPick }
    }

    var assignTooltip: String {
        if assignPool.isEmpty { return L10n.string(L10n.SourceTypes.assignTipPoolEmpty) }
        guard let field = pickedField else { return L10n.string(L10n.SourceTypes.assignTipChoose) }
        return L10n.SourceTypes.assignTipField(label: field.label)
    }

    var assignAccessibilityLabel: String {
        guard let field = pickedField, let type else {
            return L10n.string(L10n.SourceTypes.assignField)
        }
        return L10n.SourceTypes.assignFieldNamed(field: field.label, type: type.label)
    }

    func assignPickedField() async {
        guard canAssign, let type else { return }
        let fieldID = assignPick
        guard let field = fields.first(where: { $0.id == fieldID }) else { return }
        isAssigning = true
        suggestionError = nil
        defer { isAssigning = false }
        do {
            let updated = try await store.assignTypeField(
                projectDir: session.projectKey.projectDir, typeID: type.id, fieldID: fieldID, level: .source
            )
            session.apply(.wroteTypeSuggestions(typeId: type.id, edit: updated))
            assignPick = ""
            toast = VocabularyToast(
                title: L10n.string(L10n.SourceTypes.toastAssignedTitle),
                body: L10n.SourceTypes.toastAssignedBody(field: field.label, type: type.label),
                tone: .success
            )
        } catch {
            suggestionError = L10n.Errors.message(for: error)
        }
    }

    func removeSuggestion(fieldID: String) async {
        guard canEditAssociations, removingFieldID == nil, let type else { return }
        guard let field = suggestions.first(where: { $0.field.id == fieldID })?.field else { return }
        removingFieldID = fieldID
        suggestionError = nil
        defer { removingFieldID = nil }
        do {
            let updated = try await store.removeTypeField(
                projectDir: session.projectKey.projectDir, typeID: type.id, fieldID: fieldID, level: .source
            )
            session.apply(.wroteTypeSuggestions(typeId: type.id, edit: updated))
            toast = VocabularyToast(
                title: L10n.string(L10n.SourceTypes.toastRemovedTitle),
                body: L10n.SourceTypes.toastRemovedBody(
                    field: field.label, type: type.label, valueCount: field.usedBy
                ),
                tone: .info
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
    func shouldHoldNavigation(_ pending: PendingNavigation) -> Bool {
        _ = pending
        guard isDirty, !isSaving else { return false }
        pendingLeave = WorkspaceLeaveAsk()
        return true
    }

    /// Discard: the saved values come back, and the held move runs.
    func discardAndLeave() {
        revertEdit()
        pendingLeave = nil
        navigation?.resumeHeldNavigation()
    }

    /// Keep editing: the page stays and the held move is dropped.
    func keepEditing() {
        pendingLeave = nil
        navigation?.cancelHeldNavigation()
    }
}
