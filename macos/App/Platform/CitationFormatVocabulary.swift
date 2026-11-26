import Foundation

/// One of a Source type's three citation formats. Mirrors
/// `citationformat.Forms()` in Go, in order; `TestSwiftVocabularyMatchesGo`
/// fails if the two drift.
enum CitationForm: String, CaseIterable, Sendable {
    case full
    case short
    case list
}

/// What follows the colon of a placeholder: how a date is written. Mirrors
/// `citationformat.OptionYear` and `OptionFull`; `TestSwiftVocabularyMatchesGo`
/// fails if the two drift.
enum CitationOption: String, CaseIterable, Sendable {
    case year
    case full
}

/// One mistake in a format, as `CitationFormatDiagnostic.code` carries it.
/// Mirrors `citationformat.DiagnosticCodes()` in Go; `TestSwiftVocabularyMatchesGo`
/// fails if the two drift.
enum CitationDiagnosticCode: String, CaseIterable, Sendable {
    case unknownForm = "unknown_form"
    case tooLong = "too_long"
    case tooDeep = "too_deep"
    case unclosedPlaceholder = "unclosed_placeholder"
    case strayCloseBrace = "stray_close_brace"
    case unclosedGroup = "unclosed_group"
    case strayCloseBracket = "stray_close_bracket"
    case unclosedItalic = "unclosed_italic"
    case badEscape = "bad_escape"
    case groupWithoutPlaceholder = "group_without_placeholder"
    case emptyOption = "empty_option"
    case badCharacter = "bad_character"
    case metaAtLevel = "meta_at_level"
    case unknownLevel = "unknown_level"
    case badField = "bad_field"
    case unknownBuiltin = "unknown_builtin"
    case unknownOption = "unknown_option"
    case notInListForm = "not_in_list_form"
    case unknownField = "unknown_field"
    case ambiguousField = "ambiguous_field"
}

/// A built-in placeholder, written `level.name` as `CitationBuiltin.level` and
/// `.name` carry it. Mirrors `citationformat.Builtins()` in Go;
/// `TestSwiftVocabularyMatchesGo` fails if the two drift.
enum CitationBuiltin: String, CaseIterable, Sendable {
    case sourceTitle = "source.title"
    case sourceType = "source.type"
    case sourceDate = "source.date"
    case artifactLabel = "artifact.label"
    case graphName = "graph.name"
    case citationImage = "citation.image"
    case citationLabel = "citation.label"
}

/// How long a format the editor accepts, as the researcher counts it: Unicode
/// scalars, which `String.unicodeScalars.count` gives and Go counts as code
/// points. Mirrors `citationformat.MaxFormatChars`; `TestSwiftVocabularyMatchesGo`
/// fails if the two drift.
enum CitationFormatLimit {
    static let maxCharacters = 4000
}
