import Foundation
import Observation

/// Where the placeholder being typed starts, for the editor's completion. Swift reads the text
/// around the caret only to find that start; it never judges whether a format is valid (the engine's
/// warnings do).
enum CitationCompletionContext {
    /// The characters a placeholder's option may hold, as far back as the opener.
    private static let optionCharacters: Set<UInt16> = {
        var set = Set<UInt16>()
        for scalar in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-.:#".utf16 { set.insert(scalar) }
        return set
    }()

    private static let openBrace: UInt16 = 0x7B
    private static let closeBrace: UInt16 = 0x7D
    private static let pipe: UInt16 = 0x7C
    private static let backslash: UInt16 = 0x5C

    /// The context at `caret` (a UTF-16 offset in `text`), or nil when nothing completable sits there.
    /// From the caret, steps back over option characters to the opener: a `{` with an even number of
    /// backslashes before it, or a `|` inside such a `{` (stepping back over earlier options and `|` to
    /// it, with no `}` between). Anything else, a space or `}` or `[` or the start, is nil. The query is
    /// the characters from after the opener to the caret; the range runs from after the opener to the
    /// end of the option characters after the caret.
    static func at(_ text: String, caret: Int) -> PVTextAreaCompletion.Context? {
        let units = Array(text.utf16)
        guard caret >= 0, caret <= units.count else { return nil }
        var start = caret
        while start > 0, optionCharacters.contains(units[start - 1]) { start -= 1 }
        guard start > 0 else { return nil }
        switch units[start - 1] {
        case openBrace:
            guard isUnescaped(units, at: start - 1) else { return nil }
        case pipe:
            guard insideBrace(units, pipeAt: start - 1) else { return nil }
        default:
            return nil
        }
        var end = caret
        while end < units.count, optionCharacters.contains(units[end]) { end += 1 }
        let query = String(decoding: units[start ..< caret], as: UTF16.self)
        return PVTextAreaCompletion.Context(range: NSRange(location: start, length: end - start), query: query)
    }

    /// What taking the row `ref` writes over `context`'s range in `text`, and where the caret goes (a
    /// UTF-16 offset in the new text). A `}` already after the range is kept and the caret steps past
    /// it; a `|` after it means another option comes, so nothing is added; otherwise a `}` closes the
    /// placeholder.
    static func accept(
        ref: String, in text: String, context: PVTextAreaCompletion.Context
    ) -> (text: String, caretAfter: Int) {
        let units = Array(text.utf16)
        let after = context.range.location + context.range.length
        let next: UInt16? = after < units.count ? units[after] : nil
        let end = context.range.location + ref.utf16.count
        switch next {
        case closeBrace: return (ref, end + 1)
        case pipe: return (ref, end)
        default: return (ref + String(UnicodeScalar(closeBrace)!), end + 1)
        }
    }

    /// True when an even number of backslashes (none included) sit before `index`.
    private static func isUnescaped(_ units: [UInt16], at index: Int) -> Bool {
        var slashes = 0
        var i = index - 1
        while i >= 0, units[i] == backslash {
            slashes += 1
            i -= 1
        }
        return slashes % 2 == 0
    }

    /// True when the `|` at `index` belongs to an open `{`: stepping back over options and `|` reaches
    /// an unescaped `{` with no `}` between.
    private static func insideBrace(_ units: [UInt16], pipeAt index: Int) -> Bool {
        var i = index - 1
        while i >= 0, optionCharacters.contains(units[i]) || units[i] == pipe { i -= 1 }
        return i >= 0 && units[i] == openBrace && isUnescaped(units, at: i)
    }
}

/// The citation format editor of one Source type's page: the three formats' saved and draft texts, the
/// warnings the engine reported for them, the completion rows, and the preview of each form for one
/// Source of the type. It holds form state only and never touches a text view (the view owns the
/// `PVTextAreaCursor`s); renders, warnings and completion rows come from the engine. A Save carries the
/// drafts through the page model, in one write with the Details.
@MainActor
@Observable
final class SourceTypeFormatsModel {
    let typeID: String

    private(set) var loadState: PVFormLoadState = .loading

    private var saved: [CitationForm: String] = [:]
    private var savedChoices: [String: String] = [:]
    private var drafts: [CitationForm: String] = [:]
    /// Which field each shared key means (key to field id): what was read back, plus every pick.
    private(set) var fieldChoices: [String: String] = [:]
    private var placeholdersByForm: [CitationForm: [CatalogCitationPlaceholder]] = [:]

    /// A form's warnings, with the text they were found in: they show only while the draft is that text.
    private struct Diagnosed: Equatable {
        var text: String
        var diagnostics: [CatalogCitationDiagnostic]
    }

    private var diagnosed: [CitationForm: Diagnosed] = [:]
    /// The drafts a Save sent, so a refusal's warnings belong to the text that was sent.
    private var lastSent: [CitationForm: String] = [:]

    /// The Source the researcher picked; nil follows the latest (`effectivePickID`).
    private(set) var pickedSourceID: String?
    private var renders: [CitationForm: CatalogCitationRender] = [:]
    private var missingByForm: [CitationForm: [[CatalogCitationOption]]] = [:]
    private var renderingForms: Set<CitationForm> = []
    /// Each form's failed preview call; a form's own next success clears only its entry.
    private var previewErrors: [CitationForm: String] = [:]

    private let session: WorkspaceSession
    private let store: any GenealogyStore
    private let debounce: Duration
    @ObservationIgnored private var calls: [CitationForm: LatestCall] = [:]

    init(
        typeID: String,
        session: WorkspaceSession,
        store: any GenealogyStore,
        debounce: Duration = .milliseconds(250)
    ) {
        self.typeID = typeID
        self.session = session
        self.store = store
        self.debounce = debounce
    }

    // MARK: Reading

    /// Whether the type's formats can be changed: not a plugin's, and not before the type is known.
    var isEditable: Bool {
        session.sourceType(id: typeID).map { !CatalogOrigin.isPlugin($0.origin) } ?? false
    }

    /// Reads the formats and the completion rows of each form, together, and the Sources the preview picks
    /// from. Does nothing once read, so the page's `.task` can run again.
    func load() async {
        guard loadState != .ready else { return }
        let _: QueryHandle<[CatalogSource]> = session.query(SourcesModel.sourcesListKey(for: session))
        let _: QueryHandle<[CatalogSourceType]> = session.query(session.sourceTypesKey)
        loadState = .loading
        let projectDir = session.projectKey.projectDir
        do {
            async let reply = store.citationFormats(projectDir: projectDir, typeID: typeID)
            async let full = store.citationPlaceholders(projectDir: projectDir, form: .full)
            async let short = store.citationPlaceholders(projectDir: projectDir, form: .short)
            async let list = store.citationPlaceholders(projectDir: projectDir, form: .list)
            let (read, fullRows, shortRows, listRows) = try await (reply, full, short, list)
            placeholdersByForm = [.full: fullRows, .short: shortRows, .list: listRows]
            adopt(read)
            loadState = .ready
        } catch {
            loadState = .failed(L10n.Errors.message(for: error))
            return
        }
        rerenderAll()
    }

    /// Sets saved and draft texts from what the engine stores.
    private func adopt(_ reply: CatalogCitationFormatsReply) {
        for form in CitationForm.allCases {
            let text = reply.formats.text(form)
            saved[form] = text
            drafts[form] = text
            diagnosed[form] = Diagnosed(text: text, diagnostics: reply.diagnostics.filter { $0.form == form })
        }
        savedChoices = reply.formats.fieldChoices
        fieldChoices = reply.formats.fieldChoices
    }

    // MARK: Drafts

    func draft(_ form: CitationForm) -> String { drafts[form] ?? "" }

    /// A typed edit: sets the draft and renders that form after the pause.
    func edit(_ form: CitationForm, text: String) {
        guard isEditable, drafts[form] != text else { return }
        drafts[form] = text
        schedule(form, after: debounce)
    }

    var isDirty: Bool {
        guard isEditable else { return false }
        return CitationForm.allCases.contains { draft($0) != (saved[$0] ?? "") }
    }

    /// Puts the saved formats and choices back.
    func revert() {
        guard isDirty || fieldChoices != savedChoices else { return }
        for form in CitationForm.allCases { drafts[form] = saved[form] ?? "" }
        fieldChoices = savedChoices
        rerenderAll()
    }

    /// The formats a Save sends: every draft and every recorded choice.
    func draftForSave() -> CatalogCitationFormats {
        lastSent = drafts
        return CatalogCitationFormats(
            typeID: typeID, full: draft(.full), short: draft(.short), list: draft(.list), fieldChoices: fieldChoices
        )
    }

    /// A Save the engine refused: its warnings show at the forms, for the text that was sent. Nothing else
    /// changes; every edit stays.
    func refused(_ reply: CatalogCitationFormatsReply) {
        for form in CitationForm.allCases {
            diagnosed[form] = Diagnosed(
                text: lastSent[form] ?? draft(form), diagnostics: reply.diagnostics.filter { $0.form == form }
            )
        }
    }

    /// A Save that stored the formats: what the engine stored becomes the saved and draft text, and the
    /// previews render again.
    func saved(_ reply: CatalogCitationFormatsReply) {
        adopt(reply)
        rerenderAll()
    }

    // MARK: Warnings and count

    /// The form's warnings while the draft is the text they were found in; none for a locked type.
    func shownDiagnostics(_ form: CitationForm) -> [CatalogCitationDiagnostic] {
        guard isEditable, let found = diagnosed[form], found.text == draft(form) else { return [] }
        return found.diagnostics
    }

    /// The draft's length in Unicode scalars, which is how the engine counts.
    func count(_ form: CitationForm) -> Int { draft(form).unicodeScalars.count }

    func isOverLimit(_ form: CitationForm) -> Bool { count(form) > CitationFormatLimit.maxCharacters }

    // MARK: Completion

    func placeholders(_ form: CitationForm) -> [CatalogCitationPlaceholder] { placeholdersByForm[form] ?? [] }

    /// The rows of `form` matching `query`, as the completion list shows them: the engine's order
    /// inside each band, ranked by the typed query alone. Each matches on its label, key, level
    /// name and placeholder.
    func completionOptions(_ form: CitationForm, query: String) -> [PVComboBoxOption] {
        let rows = placeholders(form).map { row in
            PVComboBoxOption(
                value: row.id,
                label: Self.label(of: row),
                subtext: [L10n.CitationFormats.levelName(row.level), row.field?.key, row.ref]
                    .compactMap { $0 }.joined(separator: " ")
            )
        }
        return PVComboBoxMatch.filter(rows, query: query)
    }

    /// A row's name: a field's label, or the built-in's name.
    static func label(of row: CatalogCitationPlaceholder) -> String {
        if let field = row.field { return field.label }
        return row.builtin.map { L10n.CitationFormats.builtinName($0, option: row.option) } ?? row.ref
    }

    /// The placeholder row behind a completion option.
    func placeholder(_ form: CitationForm, id: String) -> CatalogCitationPlaceholder? {
        placeholders(form).first { $0.id == id }
    }

    /// Records the field a completed field row means, so the save does not ask which one.
    func didComplete(_ row: CatalogCitationPlaceholder, into form: CitationForm) {
        guard isEditable, let field = row.field else { return }
        fieldChoices[field.key] = field.id
        schedule(form, after: .zero)
    }

    /// The field a shared key means, chosen on its warning; renders that form again.
    func choose(fieldID: String, forKey key: String, in form: CitationForm? = nil) {
        guard isEditable else { return }
        fieldChoices[key] = fieldID
        if let form { schedule(form, after: .zero) } else { rerenderAll() }
    }

    // MARK: Preview

    /// The type's Sources, most recently changed first.
    var previewSources: [CatalogSource] {
        let typeID = typeID
        let key = SourcesModel.sourcesListKey(for: session)
        return session.derived(.sourcesOfType(typeID: typeID), inputs: [.key(key)]) {
            let rows: [CatalogSource] = session.queryHandle(key)?.value ?? []
            return rows.filter { $0.sourceTypeID == typeID }.sorted(by: SourcesModel.updatedOrder)
        }
    }

    /// The Source the previews use: the pick while it is in the list, else the list's first.
    var effectivePickID: String? {
        let sources = previewSources
        if let pickedSourceID, sources.contains(where: { $0.id == pickedSourceID }) { return pickedSourceID }
        return sources.first?.id
    }

    func pick(sourceID: String?) {
        pickedSourceID = sourceID
    }

    func render(_ form: CitationForm) -> CatalogCitationRender? { renders[form] }

    func missing(_ form: CitationForm) -> [[CatalogCitationOption]] { missingByForm[form] ?? [] }

    var isRendering: Bool { !renderingForms.isEmpty }

    /// The failed preview's text, shown under "Preview with": the first failed form's, in form order.
    var previewError: String? { CitationForm.allCases.lazy.compactMap { self.previewErrors[$0] }.first }

    /// Whether any form's preview failed: the section draws no preview while one has.
    var isPreviewFailed: Bool { !previewErrors.isEmpty }

    func isRendering(_ form: CitationForm) -> Bool { renderingForms.contains(form) }

    /// Renders all three forms now, for the effective pick.
    func rerenderAll() {
        for form in CitationForm.allCases { schedule(form, after: .zero) }
    }

    private func latest(_ form: CitationForm) -> LatestCall {
        if let call = calls[form] { return call }
        let call = LatestCall()
        calls[form] = call
        return call
    }

    /// One form's preview: the draft (the stored format for a locked type), the recorded choices and the
    /// effective pick, after `delay`. A call with neither a Source nor a format has nothing to ask.
    private func schedule(_ form: CitationForm, after delay: Duration) {
        let editable = isEditable
        let format: String? = editable ? draft(form) : nil
        let choices = editable ? fieldChoices : [:]
        let sourceID = effectivePickID
        guard format != nil || sourceID != nil else {
            latest(form).cancel()
            renderingForms.remove(form)
            renders[form] = nil
            missingByForm[form] = nil
            return
        }
        renderingForms.insert(form)
        let store = store
        let projectDir = session.projectKey.projectDir
        latest(form).start(
            after: delay,
            {
                try await store.renderCitationPreview(
                    projectDir: projectDir, form: form, format: format, fieldChoices: choices, sourceID: sourceID
                )
            },
            apply: { [weak self] result in
                self?.applyPreview(form, sent: format, sourceID: sourceID, result)
            }
        )
    }

    private func applyPreview(
        _ form: CitationForm, sent: String?, sourceID: String?, _ result: Result<CatalogCitationPreview, Error>
    ) {
        renderingForms.remove(form)
        switch result {
        case .success(let preview):
            previewErrors[form] = nil
            renders[form] = preview.render
            missingByForm[form] = preview.missing
            if let sent {
                diagnosed[form] = Diagnosed(text: sent, diagnostics: preview.diagnostics.filter { $0.form == form })
            }
        case .failure(let error):
            if let coded = error as? CoreInvokeError, coded.code == "sources.not_found", pickedSourceID != nil {
                pickedSourceID = nil
                return
            }
            previewErrors[form] = L10n.Errors.message(for: error)
        }
    }
}
