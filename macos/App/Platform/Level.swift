import Foundation

/// A layer a citation reads: the Source (the record), one of its Artifacts (the
/// copy used), one of its Evidence graphs (the item cited), or the Citation.
/// Mirrors `vocabkey.Level` in Go; `TestSwiftVocabularyMatchesGo` fails if the
/// two drift. All four hold metadata values.
enum Level: String, CaseIterable, Sendable {
    case source
    case artifact
    case graph
    case citation

    /// The levels that hold metadata; mirrors `vocabkey.MetadataLevels`.
    static let metadataLevels: [Level] = [
        .source,
        .artifact,
        .graph,
        .citation,
    ]
}
