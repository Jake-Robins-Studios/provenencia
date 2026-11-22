import Testing

@testable import Provenencia

@Suite
@MainActor
struct CitationFormatsCopyTests {
    private func field(_ label: String) -> CatalogMetadataField {
        CatalogMetadataField(id: "f", key: "k", origin: "provenencia", label: label, dataType: "text", description: "")
    }

    @Test func everyDiagnosticCodeAndTheUnknownOneReadsAsAMessage() {
        for code in CitationDiagnosticCode.allCases {
            #expect(!L10n.CitationFormats.diagnostic(code, key: "nope", characters: 4012).isEmpty, "\(code)")
        }
        #expect(!L10n.CitationFormats.diagnostic(nil, key: "").isEmpty)
    }

    @Test func tooLongNamesTheCountAndTheExcess() {
        #expect(L10n.CitationFormats.diagnostic(.tooLong, key: "", characters: 4012) == "Too long: 4,012 characters, 12 over")
    }

    @Test func tooLongWithinTheLimitIsTheStoredSizeNotACharacterCount() {
        #expect(L10n.CitationFormats.diagnostic(.tooLong, key: "", characters: 4000) == "Too many fields for one format")
        #expect(L10n.CitationFormats.diagnostic(.tooLong, key: "", characters: 560) == "Too many fields for one format")
    }

    @Test func keyedMessagesNameTheKey() {
        #expect(L10n.CitationFormats.diagnostic(.unknownField, key: "jurisdicton") == "No field has the key jurisdicton")
        #expect(L10n.CitationFormats.diagnostic(.ambiguousField, key: "page") == "Two fields have the key page: choose one")
    }

    @Test func everyBuiltInAndLevelHasAName() {
        for builtin in CitationBuiltin.allCases {
            #expect(!L10n.CitationFormats.builtinName(builtin).isEmpty, "\(builtin)")
        }
        #expect(L10n.CitationFormats.builtinName(.sourceDate, option: .year) == "Date, year only")
        for level in Level.allCases {
            #expect(!L10n.CitationFormats.levelName(level).isEmpty, "\(level)")
        }
        #expect(L10n.CitationFormats.levelName(.graph) == "Evidence graph")
    }

    @Test func everyFormHasATitleAndAMeaning() {
        for form in CitationForm.allCases {
            #expect(!L10n.CitationFormats.formTitle(form).isEmpty && !L10n.CitationFormats.formMeaning(form).isEmpty)
        }
    }

    @Test func theMissingLineJoinsOptionsAndSaysTheLevelAlone() {
        let line = field("Line")
        let chain = [
            CatalogCitationOption(level: .graph, field: line, builtin: nil),
            CatalogCitationOption(level: .source, field: line, builtin: nil),
        ]
        #expect(L10n.CitationFormats.missing(chain) == "Missing: Line on the Evidence graph, or on the Source")
        let jurisdiction = [CatalogCitationOption(level: .source, field: field("Jurisdiction"), builtin: nil)]
        #expect(L10n.CitationFormats.missing(jurisdiction) == "Missing: Jurisdiction on the Source")
        // A field read from the nearest level has no level to name.
        let nearest = [CatalogCitationOption(level: nil, field: field("Jurisdiction"), builtin: nil)]
        #expect(L10n.CitationFormats.missing(nearest) == "Missing: Jurisdiction")
        let title = [
            CatalogCitationOption(level: .source, field: nil, builtin: .sourceTitle),
            CatalogCitationOption(level: nil, field: field("Title"), builtin: nil),
        ]
        #expect(L10n.CitationFormats.missing(title) == "Missing: Title on the Source, or Title")
    }

    @Test func aFieldAtALevelIsAMistakeWithAMessage() {
        #expect(
            L10n.CitationFormats.diagnostic(.metaAtLevel, key: "artifact.meta.provider")
                == "Write meta. with no level: a field is read from the nearest level that has it")
    }
}
