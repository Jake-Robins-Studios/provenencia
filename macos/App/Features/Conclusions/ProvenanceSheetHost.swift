import SwiftUI

/// A provenance sheet with its citations: it holds the sheet's one cached read (the renders of the
/// records' Citations) while the sheet is shown, groups the records by the engine's key when the
/// renders arrive, and releases the read when the sheet goes (`WorkspaceSession.release`). The
/// `PVProvenanceSheet` recipe names no session, so this snowflake maps the read to its load state.
struct ProvenanceSheetHost: View {
    let content: PVProvenanceSheetContent
    let columns: PVProvenanceColumns
    let idPrefix: String
    let open: (PVProvenanceSheetContent.Record, PVProvenanceLink) -> Void

    @Environment(WorkspaceSession.self) private var session

    private var key: CatalogQueryKey {
        .provenanceSheet(project: session.projectKey, citationIds: content.records.map(\.outcome.citationID))
    }

    var body: some View {
        let key = key
        // A new key reads nil (loading) at once, with no stale frame.
        let handle: QueryHandle<CatalogProvenanceSheetRead>? = session.queryHandle(key)
        PVProvenanceSheet(
            content: grouped(key, handle: handle),
            columns: columns,
            idPrefix: idPrefix,
            open: open,
            load: handle?.read.formLoadState ?? .loading,
            onReadAgain: { let _: QueryHandle<CatalogProvenanceSheetRead> = session.reread(key) }
        )
        .task(id: key) { let _: QueryHandle<CatalogProvenanceSheetRead> = session.query(key) }
        .onChange(of: key) { old, _ in session.release(old) }
        .onDisappear { session.release(key) }
    }

    /// The content with the renders set and the records gathered, built once per change of the key's
    /// revision or the row's content (`conclusionContent`); the content itself until the read has a value.
    private func grouped(
        _ key: CatalogQueryKey, handle: QueryHandle<CatalogProvenanceSheetRead>?
    ) -> PVProvenanceSheetContent {
        guard let value = handle?.value else { return content }
        return session.conclusionContent(key, inputs: [key], extra: content, value: value) { value, content in
            content.grouped(by: value.citations)
        }
    }
}
