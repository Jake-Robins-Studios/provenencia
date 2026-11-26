import Foundation

/// A host over the Source page: the Source's own rows inside the page's
/// workspace, its writes through the page's store, and its failures in the
/// page banner.
@MainActor
final class SourcePageMetadataHost: MetadataBoardHost {
    private let context: SourcePageContext
    private let owner: MetadataOwner

    init(context: SourcePageContext) {
        self.context = context
        self.owner = MetadataOwner(level: .source, id: context.sourceID)
    }

    var entries: [CatalogMetadataEntry] {
        get { context.metadataRows(for: owner) }
        set {
            guard var workspace = context.workspace else { return }
            workspace.setMetadataRows(newValue, for: owner)
            context.workspace = workspace
        }
    }

    var fields: [CatalogMetadataField] { context.fields }
    var confirmsClear: Bool { true }
    var isChanged: Bool { false }

    func set(fieldID: String, valueText: String) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        try await context.store.setMetadata(
            projectDir: context.projectDir, userID: context.userID, owner: owner,
            fieldID: fieldID, valueText: valueText
        )
    }

    func clear(fieldID: String) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        try await context.store.clearMetadata(
            projectDir: context.projectDir, userID: context.userID, owner: owner, fieldID: fieldID
        )
    }

    func dismissSuggestion(fieldID: String) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        try await context.store.dismissMetadataSuggestion(
            projectDir: context.projectDir, userID: context.userID, owner: owner, fieldID: fieldID
        )
    }

    func reorder(fieldIDs: [String]) async throws -> ([CatalogMetadataEntry], CatalogWriteEffects) {
        try await context.store.reorderMetadata(
            projectDir: context.projectDir, userID: context.userID, owner: owner, fieldIDs: fieldIDs
        )
    }

    func didWrite(_ effects: CatalogWriteEffects) {
        context.applySavedMetadata(entries, owner: owner, effects: effects)
    }
    func clearFailure() { context.clearPageError() }
    func failureMessage(for error: Error) -> String? { context.fail(error) }
    func showFailure(_ message: String) { context.showPageError(message) }
}
