import Foundation

/// The session's cached Source types list: the one place its key and handle are
/// looked up, and one type read from it.
extension WorkspaceSession {
    var sourceTypesKey: CatalogQueryKey { .sourceTypesList(project: projectKey) }

    var sourceTypesHandle: QueryHandle<[CatalogSourceType]>? {
        queryHandle(sourceTypesKey)
    }

    /// One Source type by id; `nil` while the list has no value or has no such type.
    func sourceType(id: String) -> CatalogSourceType? {
        sourceTypesHandle?.value?.first { $0.id == id }
    }

    /// Whether the types list has type `id`; see `CatalogRowPresence`.
    func sourceTypePresence(id: String) -> CatalogRowPresence<CatalogSourceType> {
        .of(sourceType(id: id), in: sourceTypesHandle)
    }
}
