import SwiftUI

/// A provenance sheet with its records: it holds the sheet's one cached read, its row's records with
/// their citations, while the sheet is shown, and releases the read when the sheet goes
/// (`WorkspaceSession.release`). The `PVProvenanceSheet` recipe names no session, so this snowflake
/// maps the read to its load state; the header draws from the row before the read answers.
struct ProvenanceSheetHost: View {
    let row: ReconciledValueRowModel
    let request: CatalogProvenanceRequest
    let columns: PVProvenanceColumns
    let idPrefix: String
    let open: (PVProvenanceSheetContent.Record, PVProvenanceLink) -> Void

    @Environment(WorkspaceSession.self) private var session

    private var key: CatalogQueryKey {
        .provenanceSheet(project: session.projectKey, request: request)
    }

    var body: some View {
        let key = key
        // A new key reads nil (loading) at once, with no stale frame.
        let handle: QueryHandle<CatalogProvenanceSheetRead>? = session.queryHandle(key)
        PVProvenanceSheet(
            content: content(key, handle: handle),
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

    /// The content with the read's records and renders, built once per change of the key's
    /// revision or the row (`conclusionContent`); the row's header alone until the read has a value.
    private func content(
        _ key: CatalogQueryKey, handle: QueryHandle<CatalogProvenanceSheetRead>?
    ) -> PVProvenanceSheetContent {
        guard let value = handle?.value else { return row.provenanceContent(records: []) }
        return session.conclusionContent(key, inputs: [key], extra: row, value: value) { value, row in
            row.provenanceContent(records: value.owners).withRenders(value.citations)
        }
    }
}
