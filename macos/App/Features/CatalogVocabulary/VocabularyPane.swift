import Foundation

/// A row in one of the project's catalog vocabularies (`source_types`,
/// `source_metadata_fields`). The two vocabulary destinations browse and
/// count their rows identically; this is the shape that shared browsing hangs off.
/// Find lives in the workspace omnibar (S3-10).
protocol CatalogVocabularyRow: Identifiable where ID == String {
    var id: String { get }
    var key: String { get }
    var origin: String { get }
    var label: String { get }
    var description: String { get }
    /// How many records refer to this row — the delete gate.
    var usedBy: Int { get }
}

extension CatalogSourceType: CatalogVocabularyRow {}
extension CatalogMetadataField: CatalogVocabularyRow {}
extension CatalogProperty: CatalogVocabularyRow {}

extension Array where Element: CatalogVocabularyRow {
    // The header's count line splits the vocabulary by origin.

    var seededCount: Int { filter { $0.origin == CatalogOrigin.provenencia }.count }
    var userCount: Int { filter { $0.origin == CatalogOrigin.user }.count }
    var pluginCount: Int { filter { CatalogOrigin.isPlugin($0.origin) }.count }
}
