import Foundation

/// One of a Source type's three citation formats. Mirrors
/// `citationformat.Forms()` in Go, in order; `TestSwiftVocabularyMatchesGo`
/// fails if the two drift.
enum CitationForm: String, CaseIterable, Sendable {
    case full
    case short
    case list
}
