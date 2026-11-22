import Foundation
@testable import Provenencia

extension CatalogSearchHit {
    /// A search hit for a test: every field defaulted, in `CatalogSearchHit`'s
    /// own order, so a test names only the fields it is about.
    static func fixture(
        kind: String = "source",
        id: String = "h",
        ref: String = "",
        title: String = "Title",
        subtitle: String = "",
        matchReason: String = "title",
        matchSnippet: String = "",
        location: WorkspaceLocation = .sectionRoot(.sources),
        iconKey: String = "",
        summary: CatalogConclusionSummary? = nil
    ) -> CatalogSearchHit {
        CatalogSearchHit(
            kind: kind, id: id, ref: ref, title: title, subtitle: subtitle, matchReason: matchReason,
            matchSnippet: matchSnippet, location: location, iconKey: iconKey, summary: summary
        )
    }
}
