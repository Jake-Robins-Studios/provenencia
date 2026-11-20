import Foundation
import Testing

@testable import Provenencia

@Suite
@MainActor
struct SourceTypeFormatsModelTests {
    private let projectDir = "/tmp/formats.provenencia"

    private func field(_ id: String, _ key: String, _ label: String, origin: String = "provenencia") -> CatalogMetadataField {
        CatalogMetadataField(id: id, key: key, origin: origin, label: label, dataType: "text", description: "")
    }

    private func builtin(_ b: CitationBuiltin, option: CitationOption? = nil) -> CatalogCitationPlaceholder {
        let level = Level(rawValue: String(b.rawValue.split(separator: ".")[0]))!
        return CatalogCitationPlaceholder(
            id: b.rawValue + (option.map { ":" + $0.rawValue } ?? ""), level: level, builtin: b, option: option,
            field: nil, text: "{" + b.rawValue + "}", ref: b.rawValue
        )
    }

    private func fieldRow(_ f: CatalogMetadataField, at level: Level) -> CatalogCitationPlaceholder {
        CatalogCitationPlaceholder(
            id: "\(level.rawValue)#\(f.id)", level: level, builtin: nil, option: nil, field: f,
            text: "{\(level.rawValue).meta.\(f.key)}", ref: "\(level.rawValue).meta.\(f.key)"
        )
    }

    private func source(_ id: String, revision: Int64, type: String = "t1") -> CatalogSource {
        var s = CatalogSource(id: id, ref: "SRC-\(id)", sourceTypeID: type, title: "Source \(id)", description: "")
        s.updated = CatalogActivity(revision: revision, at: "")
        return s
    }

    /// A model for type `t1` (editable unless `types` says otherwise), loaded.
    private func makeModel(
        types: [CatalogSourceType]? = nil,
        sources: [CatalogSource] = [],
        formats: CatalogCitationFormats? = nil,
        diagnostics: [CatalogCitationDiagnostic] = [],
        placeholders: [CitationForm: [CatalogCitationPlaceholder]] = [:]
    ) async -> (SourceTypeFormatsModel, FakeStore, WorkspaceSession) {
        let store = FakeStore()
        store.sourceTypesByProject[projectDir] = types ?? [seededSourceType()]
        store.sourcesByProject[projectDir] = sources
        store.citationFormatsByType["t1"] = CatalogCitationFormatsReply(
            formats: formats ?? CatalogCitationFormats(typeID: "t1", full: "{source.title}", short: "", list: ""),
            diagnostics: diagnostics
        )
        store.placeholdersByForm = placeholders
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        let typesHandle: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        await waitForQuery(typesHandle)
        let model = SourceTypeFormatsModel(typeID: "t1", session: session, store: store, debounce: .zero)
        await model.load()
        if let handle: QueryHandle<[CatalogSource]> = session.queryHandle(SourcesModel.sourcesListKey(for: session)) {
            await waitForQuery(handle)
        }
        // The previews `load()` asked for have landed, so a test counts only its own calls.
        _ = await waitFor { !model.isRendering }
        return (model, store, session)
    }

    // MARK: Completion context (T-6b)

    @Test func completionContextFindsWhereThePlaceholderStarts() {
        let typed = CitationCompletionContext.at("{li", caret: 3)
        #expect(typed?.query == "li")
        #expect(typed?.range == NSRange(location: 1, length: 2))

        let chained = CitationCompletionContext.at("{graph.meta.line_number|so", caret: 26)
        #expect(chained?.query == "so")
        #expect(chained?.range == NSRange(location: 24, length: 2))

        #expect(CitationCompletionContext.at("\\{li", caret: 4) == nil)
        #expect(CitationCompletionContext.at("\\\\{li", caret: 5)?.query == "li")
        #expect(CitationCompletionContext.at("{li ", caret: 4) == nil)
        #expect(CitationCompletionContext.at("{a}b", caret: 4) == nil)
        #expect(CitationCompletionContext.at("{a}|b", caret: 5) == nil)
    }

    @Test func completionContextRangeRunsPastTheCaretToTheEndOfTheOptionText() {
        let context = CitationCompletionContext.at("{lineXY}", caret: 5)
        #expect(context?.query == "line")
        #expect(context?.range == NSRange(location: 1, length: 6))
    }

    @Test func acceptAddsAClosingBraceOnlyWhenNoneOrPipeFollows() throws {
        func accept(_ text: String, caret: Int, ref: String) throws -> (text: String, caretAfter: Int) {
            let context = try #require(CitationCompletionContext.at(text, caret: caret))
            return CitationCompletionContext.accept(ref: ref, in: text, context: context)
        }
        let open = try accept("{li", caret: 3, ref: "graph.meta.line_number")
        #expect(open.text == "graph.meta.line_number}")
        #expect(open.caretAfter == 1 + open.text.utf16.count)

        // A `}` already follows: kept, and the caret steps past it.
        let closed = try accept("{li}", caret: 3, ref: "graph.meta.line_number")
        #expect(closed.text == "graph.meta.line_number")
        #expect(closed.caretAfter == 1 + closed.text.utf16.count + 1)

        // A `|` follows: another option comes next, so no `}` and the caret stays before the pipe.
        let piped = try accept("{li|x}", caret: 3, ref: "graph.meta.line_number")
        #expect(piped.text == "graph.meta.line_number")
        #expect(piped.caretAfter == 1 + piped.text.utf16.count)

        let chained = try accept("{graph.meta.line_number|so", caret: 26, ref: "source.meta.line_number")
        #expect(chained.text == "source.meta.line_number}")
        #expect(chained.caretAfter == 24 + chained.text.utf16.count)
    }

    // MARK: Completion rows (T-6b)

    @Test func completionRowsComeFromTheFormsPlaceholdersRankedByTheTypedQueryAlone() async {
        let line = field("f1", "line_number", "Line")
        let (model, _, _) = await makeModel(placeholders: [
            .full: [
                builtin(.sourceTitle), fieldRow(line, at: .source), fieldRow(line, at: .artifact), fieldRow(line, at: .graph),
            ],
            .list: [builtin(.sourceTitle), fieldRow(line, at: .source)],
        ])
        #expect(model.completionOptions(.full, query: "graph li").first?.value == "graph#f1")
        #expect(model.completionOptions(.full, query: "li").map(\.value) == ["source#f1", "artifact#f1", "graph#f1"])
        #expect(Set(model.completionOptions(.list, query: "").map(\.value)) == ["source.title", "source#f1"])
    }

    // MARK: Choices (T-7)

    @Test func completingAFieldRecordsItsChoiceAndABuiltInDoesNot() async {
        let page = field("f9", "page", "Page", origin: "user")
        let (model, store, _) = await makeModel(sources: [source("s1", revision: 1)])
        model.didComplete(fieldRow(page, at: .source), into: .full)
        #expect(model.fieldChoices == ["page": "f9"])
        model.didComplete(builtin(.sourceTitle), into: .full)
        #expect(model.fieldChoices == ["page": "f9"])
        #expect(model.draftForSave().fieldChoices == ["page": "f9"])

        model.choose(fieldID: "f10", forKey: "page", in: .short)
        #expect(model.fieldChoices == ["page": "f10"])
        #expect(await waitFor {
            store.previewCalls.contains { $0.form == .short && $0.fieldChoices == ["page": "f10"] }
        })
    }

    // MARK: Warnings and count (T-8)

    @Test func aWarningStaysStaleAfterAnEditUntilTheNextReplyReplacesIt() async {
        let unclosed = CatalogCitationDiagnostic(form: .short, code: "unclosed_group", utf8Start: 0, utf8End: 1)
        let (model, store, _) = await makeModel(
            formats: CatalogCitationFormats(typeID: "t1", full: "", short: "[x", list: ""),
            diagnostics: [unclosed]
        )
        store.previewReplies[.short] = CatalogCitationPreview(diagnostics: [unclosed])
        model.rerenderAll()
        #expect(await waitFor { !model.isRendering })
        #expect(model.shownDiagnostics(.short) == [unclosed])
        #expect(!model.areDiagnosticsStale(.short))

        // The reply for the next draft has no warning: until it lands the last one stays, stale.
        store.previewReplies[.short] = CatalogCitationPreview(diagnostics: [])
        model.edit(.short, text: "[xy")
        #expect(model.shownDiagnostics(.short) == [unclosed])
        #expect(model.areDiagnosticsStale(.short))

        #expect(await waitFor { !model.isRendering })
        #expect(model.shownDiagnostics(.short).isEmpty)
        #expect(!model.areDiagnosticsStale(.short))
    }

    @Test func aSpanIsUTF8BytesAndRefusesOneOffACharacterBoundary() {
        let text = "é{"
        let brace = CatalogCitationDiagnostic(form: .full, code: "stray_close_brace", utf8Start: 2, utf8End: 3)
        #expect(brace.range(in: text).map { String(text[$0]) } == "{")
        let inside = CatalogCitationDiagnostic(form: .full, code: "stray_close_brace", utf8Start: 1, utf8End: 2)
        #expect(inside.range(in: text) == nil)
        let past = CatalogCitationDiagnostic(form: .full, code: "stray_close_brace", utf8Start: 2, utf8End: 9)
        #expect(past.range(in: text) == nil)
    }

    @Test func theCountIsUnicodeScalarsAndGoesOverTheLimit() async {
        let (model, _, _) = await makeModel()
        model.edit(.full, text: String(repeating: "a", count: CitationFormatLimit.maxCharacters))
        #expect(!model.isOverLimit(.full))
        model.edit(.full, text: String(repeating: "a", count: CitationFormatLimit.maxCharacters + 1))
        #expect(model.isOverLimit(.full) && model.count(.full) == 4001)
        model.edit(.full, text: "👨‍👩‍👧")
        #expect(model.count(.full) == 5)
    }

    // MARK: Preview (T-9)

    @Test func withNoSourcesThePreviewAsksForWarningsAlone() async {
        let (model, store, _) = await makeModel()
        #expect(model.effectivePickID == nil)
        #expect(store.previewCalls.count == 3)
        #expect(store.previewCalls.allSatisfy { $0.sourceID == nil && $0.format != nil })
        _ = model
    }

    @Test func theListLandingPicksTheLatestSourceAndRendersAllThree() async {
        let (model, store, _) = await makeModel(sources: [source("s1", revision: 3), source("s2", revision: 9), source("s0", revision: 1)])
        #expect(model.effectivePickID == "s2")
        store.resetPreviewCalls()
        model.rerenderAll()
        #expect(await waitFor { store.previewCalls.count == 3 })
        #expect(store.previewCalls.allSatisfy { $0.sourceID == "s2" })
    }

    @Test func anEditRendersOnlyThatFormWithTheDraftAndThePick() async {
        let (model, store, _) = await makeModel(sources: [source("s1", revision: 3)])
        store.resetPreviewCalls()
        model.edit(.full, text: "{source.title} Test.")
        #expect(await waitFor { !store.previewCalls.isEmpty })
        #expect(store.previewCalls == [RenderCitationPreviewCall(form: .full, format: "{source.title} Test.", fieldChoices: [:], sourceID: "s1")])
    }

    @Test func pickingASourceRendersAllThreeForIt() async {
        let (model, store, _) = await makeModel(sources: [source("s1", revision: 3), source("s2", revision: 9)])
        model.pick(sourceID: "s1")
        store.resetPreviewCalls()
        model.rerenderAll()
        #expect(await waitFor { store.previewCalls.count == 3 })
        #expect(store.previewCalls.allSatisfy { $0.sourceID == "s1" })
    }

    @Test func aMissingSourceClearsThePick() async {
        let (model, store, _) = await makeModel(sources: [source("s1", revision: 3), source("s2", revision: 9)])
        model.pick(sourceID: "s1")
        store.previewError = CoreInvokeError.coded(status: 1, code: "sources.not_found", kind: .user, params: [])
        model.rerenderAll()
        #expect(await waitFor { model.pickedSourceID == nil })
    }

    @Test func aLockedTypeSendsItsStoredFormatAndHasNothingToSave() async {
        let (model, store, _) = await makeModel(types: [pluginSourceType(id: "t1")], sources: [source("s1", revision: 1)])
        #expect(!model.isEditable)
        store.resetPreviewCalls()
        model.edit(.full, text: "ignored")
        #expect(!model.isDirty)
        model.rerenderAll()
        #expect(await waitFor { store.previewCalls.count == 3 })
        #expect(store.previewCalls.allSatisfy { $0.format == nil })
        #expect(model.shownDiagnostics(.full).isEmpty)
    }

    @Test func aFailedPreviewIsKeptUntilItsOwnFormRendersAgain() async {
        let (model, store, _) = await makeModel(sources: [source("s1", revision: 1)])
        store.previewError = CoreInvokeError.failed(status: 3)
        model.rerenderAll()
        #expect(await waitFor { model.previewError != nil && !model.isRendering })
        #expect(model.isPreviewFailed)
        // Another form's success does not clear a failure it did not cause.
        store.previewError = nil
        store.resetPreviewCalls()
        model.edit(.short, text: "{source.title}!")
        #expect(await waitFor { !store.previewCalls.isEmpty && !model.isRendering })
        #expect(model.previewError != nil && model.isPreviewFailed)
        // A retry keeps the failure until each reply lands, then every form has cleared its own.
        model.rerenderAll()
        #expect(model.previewError != nil)
        #expect(await waitFor { model.previewError == nil })
        #expect(!model.isPreviewFailed)
    }

    // MARK: Draft, revert

    @Test func revertPutsTheSavedTextAndChoicesBack() async {
        let (model, _, _) = await makeModel()
        model.edit(.full, text: "changed")
        model.choose(fieldID: "f1", forKey: "page")
        #expect(model.isDirty)
        model.revert()
        #expect(!model.isDirty && model.draft(.full) == "{source.title}" && model.fieldChoices.isEmpty)
    }
}

/// Polls the main actor until `condition` holds or about two seconds pass.
@MainActor
private func waitFor(_ condition: () -> Bool) async -> Bool {
    for _ in 0 ..< 200 {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}
