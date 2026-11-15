import Foundation
import Observation

/// State of the Add type dialog: the draft, the errors it shows and the create. A fresh model per
/// open, held by `SourceTypesModel.adding` as one optional, as `SourceCopyModel` is. It writes
/// nothing on `SourceTypesModel`: selection follows the navigation to the new type.
@MainActor
@Observable
final class SourceTypeAddModel {
    var draft = SourceTypesModel.Draft(label: "", description: "")
    var labelError: String?
    var createError: String?
    private(set) var isSaving = false

    private let session: WorkspaceSession
    private let userID: String
    private let store: any GenealogyStore

    init(session: WorkspaceSession, userID: String, store: any GenealogyStore) {
        self.session = session
        self.userID = userID
        self.store = store
    }

    /// The key the engine will mint from the label.
    var key: String {
        FieldSlug.kebab(draft.label.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isDirty: Bool {
        !draft.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || draft.iconKey != PVMarkKey.defaultTypeMark.rawValue
    }

    var canAdd: Bool { !isSaving && draft.labelError == nil }

    /// On success returns the type for the host to open. On failure the dialog keeps every field.
    func create() async -> CatalogSourceType? {
        guard !isSaving else { return nil }
        labelError = draft.labelError
        guard labelError == nil else { return nil }
        isSaving = true
        defer { isSaving = false }
        createError = nil
        do {
            let (created, effects) = try await store.createSourceType(
                projectDir: session.projectKey.projectDir, userID: userID,
                label: draft.label.trimmingCharacters(in: .whitespacesAndNewlines),
                description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
                iconKey: draft.iconKey
            )
            session.apply(effects, .createdSourceType(created))
            return created
        } catch {
            if (error as? CoreInvokeError)?.engineCode == .sourceTypeDuplicateKey {
                labelError = L10n.Errors.message(for: error)
            } else {
                createError = L10n.Errors.message(for: error)
            }
            return nil
        }
    }
}
