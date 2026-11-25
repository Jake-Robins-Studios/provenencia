import Foundation

/// A per-entity page value that reports what it was built from (S16-24), so a
/// key holding one follows those ids (`CatalogQueryRefresh.followsInputs`).
protocol CatalogPageValue: Sendable {
    var inputs: CatalogPageInputs { get }
}

extension CatalogConclusionDetail: CatalogPageValue {}
extension CatalogPersonClaims: CatalogPageValue {}
extension CatalogProvenanceSheetRead: CatalogPageValue {}
extension CatalogPersonFamily: CatalogPageValue {}
extension CatalogPersonTimeline: CatalogPageValue {}
extension CatalogPersonRecordLinks: CatalogPageValue {}
