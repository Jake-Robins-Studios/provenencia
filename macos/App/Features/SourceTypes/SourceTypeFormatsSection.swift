import SwiftUI

/// The citation formats of one Source type, under Details on its page: the syntax strip, a Source to
/// preview with, and the three forms. An editable type's forms are text areas with completion, a
/// count, warnings and a preview above each; a plugin's are read only beside their previews. The
/// page's one Save writes them with the Details (`SourceTypePageModel.submit`).
struct SourceTypeFormatsSection: View {
    let model: SourceTypePageModel

    private var formats: SourceTypeFormatsModel { model.formats }

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVSectionHeader(title: L10n.SourceTypes.Formats.sectionTitle)
            Text(formats.isEditable ? L10n.SourceTypes.Formats.sectionHint : L10n.SourceTypes.Formats.sectionHintLocked)
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if formats.isEditable {
                SourceTypeFormatsSyntaxStrip()
            }
            PVFormLoadArea(
                state: formats.loadState,
                loadingText: L10n.SourceTypes.Formats.loading,
                errorTitle: L10n.SourceTypes.Formats.loadErrorTitle,
                errorMessage: { $0 },
                onReadAgain: { Task { await formats.load() } },
                accessibilityIdentifierPrefix: "sourceTypes.formats"
            ) {
                VStack(alignment: .leading, spacing: PVSpacing.space7) {
                    SourceTypeFormatsPreviewPicker(model: model)
                    ForEach(CitationForm.allCases, id: \.self) { form in
                        SourceTypeFormatEditor(form: form, model: model)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task { await formats.load() }
        // The type loads after the section can: a plugin's type previews its stored formats.
        .onChange(of: formats.isEditable) { _, _ in formats.rerenderAll() }
    }
}

/// The five pieces of syntax, each its mono token and a few words.
private struct SourceTypeFormatsSyntaxStrip: View {
    private let pieces: [(token: String, meaning: LocalizedStringResource)] = [
        ("{ }", L10n.SourceTypes.Formats.syntaxField),
        ("|", L10n.SourceTypes.Formats.syntaxOr),
        ("[ ]", L10n.SourceTypes.Formats.syntaxGroup),
        ("* *", L10n.SourceTypes.Formats.syntaxItalic),
        ("\\", L10n.SourceTypes.Formats.syntaxEscape),
    ]

    var body: some View {
        PVFlowLayout(spacing: PVSpacing.space6, lineSpacing: PVSpacing.space3) {
            ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                HStack(spacing: PVSpacing.space2) {
                    Text(verbatim: piece.token)
                        .font(PVFont.mono(size: PVTypeScale.caption))
                        .foregroundStyle(PVColor.textPrimary)
                    Text(piece.meaning)
                        .font(PVFont.body(size: PVTypeScale.micro))
                        .foregroundStyle(PVColor.textMuted)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sourceTypes.formats.syntax")
    }
}

/// "Preview with": the Source the previews fill in, or the note that the type has none yet. A failed
/// preview shows its retry here, in place of the three previews.
private struct SourceTypeFormatsPreviewPicker: View {
    let model: SourceTypePageModel

    private var formats: SourceTypeFormatsModel { model.formats }

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space4) {
            let sources = formats.previewSources
            let typeLabel = model.type?.label ?? ""
            if sources.isEmpty {
                PVCallout(
                    tone: .neutral,
                    message: L10n.SourceTypes.Formats.noSources(type: typeLabel),
                    compact: true
                )
                .accessibilityIdentifier("sourceTypes.formats.preview.noSources")
            } else {
                PVField(label: L10n.SourceTypes.Formats.previewWith, hint: L10n.SourceTypes.Formats.previewHint) {
                    PVComboBox(
                        selection: Binding(
                            get: { formats.effectivePickID ?? "" },
                            set: { formats.pick(sourceID: $0.isEmpty ? nil : $0) }
                        ),
                        options: sources.map { PVComboBoxOption(value: $0.id, label: $0.title, subtext: $0.ref) },
                        placeholder: L10n.SourceTypes.Formats.previewPlaceholder(type: typeLabel),
                        emptyLabel: L10n.SourceTypes.Formats.previewNoMatch,
                        label: L10n.SourceTypes.Formats.previewWith,
                        accessibilityIdentifierPrefix: "sourceTypes.formats.preview.source"
                    )
                }
            }
            if let error = formats.previewError {
                PVRetryCallout(
                    title: L10n.SourceTypes.Formats.previewFailedTitle,
                    message: error,
                    retry: L10n.Conclusions.readNoticeTryAgain,
                    isRetrying: formats.isRendering,
                    compact: true,
                    retryIdentifier: "sourceTypes.formats.preview.tryAgain",
                    onRetry: { formats.rerenderAll() }
                )
                .accessibilityIdentifier("sourceTypes.formats.preview.error")
            }
        }
        // The previews follow the pick, the Sources list landing, and a Source leaving.
        .onChange(of: formats.effectivePickID, initial: true) { _, _ in
            formats.rerenderAll()
        }
    }
}

/// One form: its title with the count, its meaning, its preview, then its text (or, on a plugin's
/// type, the stored text read only) and the warnings under it.
private struct SourceTypeFormatEditor: View {
    let form: CitationForm
    let model: SourceTypePageModel

    @State private var cursor = PVTextAreaCursor()
    @State private var completion: PVTextAreaCompletion?

    private var formats: SourceTypeFormatsModel { model.formats }

    var body: some View {
        let editable = formats.isEditable
        let shown = formats.shownDiagnostics(form)
        PVSubsectionHeader(
            title: L10n.CitationFormats.formTitle(form),
            meta: editable ? countText : nil,
            metaTone: formats.isOverLimit(form) ? .danger : .muted
        ) {
            VStack(alignment: .leading, spacing: PVSpacing.space4) {
                Text(verbatim: L10n.CitationFormats.formMeaning(form))
                    .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                    .foregroundStyle(PVColor.textMuted)
                SourceTypeFormatPreview(form: form, model: model, hasWarning: !shown.isEmpty)
                if editable {
                    textArea(isInvalid: !shown.isEmpty)
                    ForEach(Array(shown.enumerated()), id: \.offset) { index, diagnostic in
                        SourceTypeFormatWarning(
                            form: form, index: index, diagnostic: diagnostic, model: model, cursor: cursor
                        )
                    }
                } else {
                    readOnly
                }
            }
        }
        .onAppear { completion = completion ?? makeCompletion() }
    }

    private var countText: String {
        L10n.SourceTypes.Formats.countLine(
            used: L10n.CitationFormats.grouped(formats.count(form)),
            limit: L10n.CitationFormats.grouped(CitationFormatLimit.maxCharacters)
        )
    }

    private func textArea(isInvalid: Bool) -> some View {
        PVTextArea(
            text: Binding(get: { formats.draft(form) }, set: { formats.edit(form, text: $0) }),
            lineLimit: 3...10,
            prompt: placeholder,
            typography: .mono,
            isInvalid: isInvalid,
            accessibilityLabel: L10n.CitationFormats.formTitleResource(form),
            cursor: cursor,
            completion: completion
        )
        .accessibilityValue(
            L10n.SourceTypes.Formats.countSpoken(
                used: L10n.CitationFormats.grouped(formats.count(form)),
                limit: L10n.CitationFormats.grouped(CitationFormatLimit.maxCharacters)
            )
        )
        .accessibilityIdentifier("sourceTypes.formats.\(form.rawValue).text")
    }

    private var placeholder: LocalizedStringResource {
        switch form {
        case .full: L10n.SourceTypes.Formats.placeholderFull
        case .short: L10n.SourceTypes.Formats.placeholderShort
        case .list: L10n.SourceTypes.Formats.placeholderList
        }
    }

    private var readOnly: some View {
        let text = formats.draft(form)
        return PVCard(tone: .sunken) {
            Text(verbatim: text.isEmpty ? L10n.string(L10n.SourceTypes.Formats.noFormat) : text)
                .font(PVFont.mono(size: PVTypeScale.caption))
                .foregroundStyle(text.isEmpty ? PVColor.textMuted : PVColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.SourceTypes.Formats.readerLabel(form: L10n.CitationFormats.formTitle(form)))
        .accessibilityIdentifier("sourceTypes.formats.\(form.rawValue).readOnly")
    }

    /// Completion at the caret: where the placeholder starts (Swift reads the text only for that), the
    /// engine's rows narrowed by the typed query, and what taking one writes.
    private func makeCompletion() -> PVTextAreaCompletion {
        let form = form
        let formats = formats
        return PVTextAreaCompletion(
            context: { text, caret in CitationCompletionContext.at(text, caret: caret) },
            options: { formats.completionOptions(form, query: $0) },
            row: { option, _ in
                guard let row = formats.placeholder(form, id: option.value) else { return AnyView(EmptyView()) }
                return AnyView(SourceTypeFormatCompletionRow(row: row))
            },
            accept: { option, context in
                guard let row = formats.placeholder(form, id: option.value) else { return nil }
                formats.didComplete(row, into: form)
                let text = formats.draft(form) as NSString
                let nextIndex = context.range.location + context.range.length
                let next: unichar? = nextIndex < text.length ? text.character(at: nextIndex) : nil
                let ref = row.ref
                let length = (ref as NSString).length
                switch next {
                case 0x7D: // `}` already follows: keep it and step past it.
                    return (ref, context.range.location + length + 1)
                case 0x7C: // `|` follows: another option comes next.
                    return (ref, context.range.location + length)
                default:
                    return (ref + "}", context.range.location + length + 1)
                }
            },
            emptyLabel: { L10n.SourceTypes.Formats.completionEmpty(query: $0) },
            announce: { event in
                switch event {
                case .opened(let count, _):
                    count == 0
                        ? L10n.string(L10n.SourceTypes.Formats.completionOpenedEmpty)
                        : L10n.SourceTypes.Formats.completionOpened(count: count)
                case .highlighted(let option):
                    formats.placeholder(form, id: option.value).map {
                        L10n.SourceTypes.Formats.completionHighlighted(
                            name: SourceTypeFormatsModel.label(of: $0), level: L10n.CitationFormats.levelName($0.level))
                    }
                case .inserted(let option):
                    formats.placeholder(form, id: option.value).map {
                        L10n.SourceTypes.Formats.completionInserted(name: SourceTypeFormatsModel.label(of: $0))
                    }
                }
            }
        )
    }
}

/// One completion row: the name, the origin pill of a field, the level, and the whole placeholder in mono.
private struct SourceTypeFormatCompletionRow: View {
    let row: CatalogCitationPlaceholder

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: PVSpacing.space3) {
                Text(verbatim: SourceTypeFormatsModel.label(of: row))
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
                if let field = row.field {
                    OriginPill(origin: field.origin)
                }
                Spacer(minLength: 0)
                PVBadge(text: L10n.CitationFormats.levelName(row.level), subtle: true)
            }
            Text(verbatim: row.text)
                .font(PVFont.mono(size: PVTypeScale.micro))
                .foregroundStyle(PVColor.textFaint)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.SourceTypes.Formats.completionHighlighted(
                name: SourceTypeFormatsModel.label(of: row), level: L10n.CitationFormats.levelName(row.level))
        )
    }
}

/// One warning under a format: its message, then "at" and the text it is about. A button: it selects
/// that text in the format. A key two fields share also carries the Select that settles which.
private struct SourceTypeFormatWarning: View {
    let form: CitationForm
    let index: Int
    let diagnostic: CatalogCitationDiagnostic
    let model: SourceTypePageModel
    let cursor: PVTextAreaCursor

    private var formats: SourceTypeFormatsModel { model.formats }
    private var text: String { formats.draft(form) }
    private var range: Range<String.Index>? { diagnostic.range(in: text) }

    private var quote: String {
        guard let range else { return "" }
        let raw = String(text[range])
        return raw.count > 40 ? String(raw.prefix(40)) + "…" : raw
    }

    private var message: String {
        let code = CitationDiagnosticCode(rawValue: diagnostic.code)
        return L10n.CitationFormats.diagnostic(code, key: quote, characters: formats.count(form))
    }

    private var line: String {
        quote.isEmpty ? message : L10n.SourceTypes.Formats.warningAt(message: message, quote: quote)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space3) {
            Button {
                if let range { cursor.select(NSRange(range, in: text)) }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: PVSpacing.space3) {
                    PVIcon(.warning, size: 13)
                        .foregroundStyle(PVColor.danger)
                        .accessibilityHidden(true)
                    PVErrorText(line, size: .caption)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PVFocusRingButtonStyle())
            .accessibilityLabel(line)
            .accessibilityHint(L10n.string(L10n.SourceTypes.Formats.warningHint))
            .accessibilityIdentifier("sourceTypes.formats.\(form.rawValue).warning.\(index)")
            if diagnostic.code == CitationDiagnosticCode.ambiguousField.rawValue, !quote.isEmpty {
                sharedKeySelect(key: quote)
            }
        }
    }

    /// The fields that hold the key, as the engine listed them for this form.
    private func sharedKeySelect(key: String) -> some View {
        var seen = Set<String>()
        let fields = formats.placeholders(form).compactMap { $0.field }.filter {
            $0.key == key && seen.insert($0.id).inserted
        }
        return PVSelect(
            selection: Binding(
                get: { formats.fieldChoices[key] ?? "" },
                set: { formats.choose(fieldID: $0, forKey: key, in: form) }
            ),
            options: fields.map {
                PVSelectOption(
                    value: $0.id,
                    label: L10n.SourceTypes.Formats.sharedKeyOption(label: $0.label, origin: Self.originName($0.origin))
                )
            },
            placeholder: L10n.SourceTypes.Formats.sharedKeyLabel(key: key),
            accessibilityLabel: nil,
            accessibilitySpokenLabel: L10n.SourceTypes.Formats.sharedKeyLabel(key: key),
            accessibilityIdentifier: "sourceTypes.formats.\(form.rawValue).warning.\(index).choose"
        )
        .padding(.leading, 13 + PVSpacing.space3)
    }

    private static func originName(_ origin: String) -> String {
        if origin == CatalogOrigin.provenencia { return L10n.string(L10n.SourceTypes.Formats.originProvenencia) }
        if origin == CatalogOrigin.user { return L10n.string(L10n.SourceTypes.Formats.originUser) }
        return L10n.SourceTypes.Formats.originPlugin(plugin: CatalogOrigin.pluginID(from: origin))
    }
}

/// A form's preview: a sunken block with an accent rule at its left edge: the micro-caps tag (with a
/// small spinner while that form renders), the render with its italics, and what the Source lacks.
private struct SourceTypeFormatPreview: View {
    let form: CitationForm
    let model: SourceTypePageModel
    let hasWarning: Bool

    private var formats: SourceTypeFormatsModel { model.formats }

    var body: some View {
        let render = formats.render(form)
        let hasFormat = !formats.draft(form).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        VStack(alignment: .leading, spacing: PVSpacing.space3) {
            HStack(spacing: PVSpacing.space3) {
                Text(L10n.SourceTypes.Formats.previewTitle)
                    .pvMicroCaps()
                    .foregroundStyle(PVColor.textFaint)
                if formats.isRendering(form) {
                    ProgressView().controlSize(.small)
                }
            }
            if hasWarning {
                note(L10n.SourceTypes.Formats.notShown)
            } else if !hasFormat {
                note(L10n.SourceTypes.Formats.noFormat)
            } else if let render, !render.runs.isEmpty {
                CitationRunsText(render: render)
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            if !hasWarning, hasFormat {
                ForEach(Array(formats.missing(form).enumerated()), id: \.offset) { _, chain in
                    PVCallout(tone: .neutral, message: L10n.CitationFormats.missing(chain), compact: true)
                }
            }
        }
        .padding(.vertical, PVSpacing.space4)
        .padding(.horizontal, PVSpacing.space5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PVColor.surfaceSunken)
        .overlay(alignment: .leading) {
            Rectangle().fill(PVColor.accent).frame(width: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: PVRadius.sm, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sourceTypes.formats.preview.\(form.rawValue)")
    }

    private func note(_ copy: LocalizedStringResource) -> some View {
        Text(copy)
            .font(PVFont.body(size: PVTypeScale.bodySmall, italic: true))
            .foregroundStyle(PVColor.textMuted)
    }
}

/// A rendered citation as styled text: each run, italic where the engine marked it.
struct CitationRunsText: View {
    let render: CatalogCitationRender

    var body: some View {
        render.runs.reduce(Text(verbatim: "")) { text, run in
            text + (run.italic ? Text(verbatim: run.text).italic() : Text(verbatim: run.text))
        }
        .accessibilityLabel(render.plain)
    }
}
