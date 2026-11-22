import Foundation

/// Cache identity for one catalog read: its kind, project and the ids its
/// factory took. New workspace places add a `Kind` case, a factory and an arm
/// on `CatalogQueryKey.Kind.descriptor`.
struct CatalogQueryKey: Hashable, Sendable {
    let kind: Kind
    let project: ProjectKey
    /// The ids the read takes, in its factory's argument order; empty for a
    /// catalog-wide read.
    let ids: [String]

    private init(_ kind: Kind, _ project: ProjectKey, _ ids: [String] = []) {
        self.kind = kind
        self.project = project
        self.ids = ids
    }

    /// The key's single id, when it has exactly one.
    var ownId: String? { ids.count == 1 ? ids[0] : nil }

    /// `ownId`, for a loader of a kind that always has exactly one id; a
    /// programming error otherwise.
    var id: String {
        precondition(ids.count == 1, "\(kind) has \(ids.count) ids")
        return ids[0]
    }

    /// The type of a `typeSuggestions` key.
    var suggestionsTypeId: String {
        precondition(kind == .typeSuggestions, "\(kind) has no type id")
        return ids[0]
    }
    /// The level of a `typeSuggestions` key.
    var suggestionsLevel: Level {
        precondition(kind == .typeSuggestions, "\(kind) has no level")
        return Level(rawValue: ids[1])!
    }

    /// The graph of a `citationsByArtifact` key.
    var citationGraphId: String {
        precondition(kind == .citationsByArtifact, "\(kind) has no graph id")
        return ids[0]
    }
    /// The Artifact of a `citationsByArtifact` key.
    var citationArtifactId: String {
        precondition(kind == .citationsByArtifact, "\(kind) has no Artifact id")
        return ids[1]
    }

    /// What a key reads. Each kind has one
    /// `CatalogQueryDescriptor` (`Kind.descriptor`).
    enum Kind: Hashable, Sendable, CaseIterable {
        case sourcesList
        case sourceTypesList
        case metadataFieldsList
        case credibilityGradesList
        case sourceWorkspace
        case evidenceGraph
        case citationCounts
        case typeSuggestions
        case propertiesWorkspace
        case connectRules
        case propertyTerms
        case citationsByArtifact
        case evidenceGraphProgress
        case evidenceGraphsList
        case personsList
        case eventsList
        case placesList
        case conclusionDetail
        case personClaims
        case personFamily
        case personEvents
        case personRecordLinks
        case provenanceSheet
    }

    /// The renders a provenance sheet shows, for these Citation ids (sorted,
    /// distinct, none empty). Held only while the sheet is shown
    /// (`WorkspaceSession.release`).
    static func provenanceSheet(project: ProjectKey, citationIds: [String]) -> CatalogQueryKey {
        .init(.provenanceSheet, project, Set(citationIds.filter { !$0.isEmpty }).sorted())
    }

    static func sourcesList(project: ProjectKey) -> CatalogQueryKey { .init(.sourcesList, project) }
    static func sourceTypesList(project: ProjectKey) -> CatalogQueryKey { .init(.sourceTypesList, project) }
    static func metadataFieldsList(project: ProjectKey) -> CatalogQueryKey { .init(.metadataFieldsList, project) }
    static func credibilityGradesList(project: ProjectKey) -> CatalogQueryKey { .init(.credibilityGradesList, project) }
    static func sourceWorkspace(project: ProjectKey, sourceId: String) -> CatalogQueryKey {
        .init(.sourceWorkspace, project, [sourceId])
    }
    /// One Evidence graph's rows: the canvas, the composer and Promote read it.
    static func evidenceGraph(project: ProjectKey, graphId: String) -> CatalogQueryKey {
        .init(.evidenceGraph, project, [graphId])
    }
    static func citationCounts(project: ProjectKey, graphId: String) -> CatalogQueryKey {
        .init(.citationCounts, project, [graphId])
    }
    /// A type's suggested fields at one level.
    static func typeSuggestions(project: ProjectKey, typeId: String, level: Level) -> CatalogQueryKey {
        .init(.typeSuggestions, project, [typeId, level.rawValue])
    }
    /// A type's suggestion keys, one per metadata level, in `Level.metadataLevels` order.
    static func typeSuggestionsKeys(project: ProjectKey, typeId: String) -> [CatalogQueryKey] {
        Level.metadataLevels.map { typeSuggestions(project: project, typeId: typeId, level: $0) }
    }
    static func propertiesWorkspace(project: ProjectKey) -> CatalogQueryKey { .init(.propertiesWorkspace, project) }
    static func connectRules(project: ProjectKey) -> CatalogQueryKey { .init(.connectRules, project) }
    static func propertyTerms(project: ProjectKey, propertyId: String) -> CatalogQueryKey {
        .init(.propertyTerms, project, [propertyId])
    }
    static func citationsByArtifact(project: ProjectKey, graphId: String, artifactId: String) -> CatalogQueryKey {
        .init(.citationsByArtifact, project, [graphId, artifactId])
    }
    static func evidenceGraphProgress(project: ProjectKey) -> CatalogQueryKey { .init(.evidenceGraphProgress, project) }
    /// Every Evidence graph of the project with its linked Artifact ids (S12-05).
    static func evidenceGraphsList(project: ProjectKey) -> CatalogQueryKey { .init(.evidenceGraphsList, project) }
    /// Every Person summary, composed from the auto-reconciler cache (S9-07).
    static func personsList(project: ProjectKey) -> CatalogQueryKey { .init(.personsList, project) }
    /// Every Event summary, composed from the auto-reconciler cache (S9-22).
    static func eventsList(project: ProjectKey) -> CatalogQueryKey { .init(.eventsList, project) }
    /// Every Place summary, composed from the auto-reconciler cache (S9-25).
    static func placesList(project: ProjectKey) -> CatalogQueryKey { .init(.placesList, project) }
    /// One handle's detail, any kind (S9-15), with its kind's summary (birth
    /// and death, an Event's subjects and title, a Place's names) read in the
    /// same call. Marked stale, not revalidated, while off screen.
    static func conclusionDetail(project: ProjectKey, entityId: String) -> CatalogQueryKey {
        .init(.conclusionDetail, project, [entityId])
    }
    /// One Person's accepted claims grouped by Source (S13-01), read for the
    /// Sources section. Marked stale, not revalidated, while off screen.
    static func personClaims(project: ProjectKey, entityId: String) -> CatalogQueryKey {
        .init(.personClaims, project, [entityId])
    }
    /// One Person's family units (S13-04), read for the Family section.
    /// Marked stale, not revalidated, while off screen.
    static func personFamily(project: ProjectKey, entityId: String) -> CatalogQueryKey {
        .init(.personFamily, project, [entityId])
    }
    /// One Person's timeline events (S13-05), read for the Timeline section.
    /// Marked stale, not revalidated, while off screen.
    static func personEvents(project: ProjectKey, entityId: String) -> CatalogQueryKey {
        .init(.personEvents, project, [entityId])
    }
    /// One Person's Evidence graphs and the lines between them (S13-27), read
    /// for the record links view. Marked stale, not revalidated, while off screen.
    static func personRecordLinks(project: ProjectKey, entityId: String) -> CatalogQueryKey {
        .init(.personRecordLinks, project, [entityId])
    }
}
