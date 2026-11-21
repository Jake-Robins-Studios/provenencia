import SwiftUI

/// The Suggested fields section of a Source type's page: its title, the hint and the pool hint
/// once, then one list per level (Source, Artifact, Evidence graph) with a hairline between them.
/// A plugin's type is read only: no hint and no pool hint.
struct SourceTypeSuggestedFields: View {
    @Bindable var model: SourceTypePageModel

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVSectionHeader(title: L10n.SourceTypes.suggestedSectionLabel)
            if !model.isLocked {
                VStack(alignment: .leading, spacing: PVSpacing.space2) {
                    Text(L10n.SourceTypes.suggestedHint)
                        .accessibilityIdentifier("sourceTypes.suggested.hint")
                    Text(L10n.SourceTypes.poolHint)
                        .accessibilityIdentifier("sourceTypes.suggested.poolHint")
                }
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textMuted)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(Level.metadataLevels.enumerated()), id: \.element) { index, level in
                    if index > 0 {
                        PVDivider()
                            .padding(.top, PVSpacing.space5)
                            .padding(.bottom, PVSpacing.space6)
                    }
                    SourceTypeSuggestionList(model: model, level: level)
                }
            }
        }
        .accessibilityIdentifier("sourceTypes.suggested")
    }
}

/// One level's list of the fields a Source type suggests: its title, count and meaning, the
/// numbered rows, the empty card, the loading spinner or retry notice, the error callout, and the
/// picker that assigns a field. A plugin's type is read only: no remove and no picker.
struct SourceTypeSuggestionList: View {
    @Bindable var model: SourceTypePageModel
    let level: Level

    private enum PickerFocus { case picker }
    @FocusState private var focus: PickerFocus?
    /// Set by a Return-add; focus returns to the picker once the write ends and it is enabled again.
    @State private var refocusPending = false

    private var isLocked: Bool { model.isLocked }
    private var copy: L10n.SourceTypes.LevelCopy { L10n.SourceTypes.level(level) }
    private var suggestions: [CatalogTypeSuggestion] { model.suggestions(at: level) }
    private var prefix: String { "sourceTypes.suggested.\(level.rawValue)" }

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space4) {
            header
            if let error = model.suggestionErrors[level] {
                PVCallout(tone: .danger, message: error, announces: true)
                    .accessibilityIdentifier("\(prefix).error")
            }
            content
            if !isLocked, model.isLoaded(at: level) {
                assignControl
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(listAccessibilityLabel)
        .accessibilityIdentifier(prefix)
    }

    /// The spoken label: the title alone until the level is loaded, matching the visible header.
    private var listAccessibilityLabel: String {
        guard model.isLoaded(at: level) else { return L10n.string(copy.title) }
        return L10n.SourceTypes.listAccessibilityLabel(
            title: L10n.string(copy.title), count: suggestions.count
        )
    }

    /// The level title in micro caps with the count trailing once loaded, then the meaning.
    private var header: some View {
        PVSubsectionHeader(
            title: copy.title,
            meta: model.isLoaded(at: level) ? L10n.SourceTypes.assignedCount(count: suggestions.count) : nil
        ) {
            Text(copy.meaning)
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textMuted)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let handle = model.suggestionsHandle(at: level) {
            switch handle.reading {
            case .loading:
                spinner
            case .failed(let error):
                PVRetryCallout(
                    title: L10n.SourceTypes.suggestionsLoadErrorTitle,
                    message: L10n.Errors.message(for: error),
                    handle: handle,
                    id: "\(prefix).loadError",
                    onRetry: { model.rereadSuggestions(at: level) }
                )
                .accessibilityIdentifier("\(prefix).loadError")
            case .loaded:
                if suggestions.isEmpty {
                    emptySuggestions
                } else {
                    suggestionRows
                }
            }
        } else {
            spinner
        }
    }

    private var spinner: some View {
        ProgressView()
            .tint(PVColor.accent)
            .frame(maxWidth: .infinity)
            .padding(PVSpacing.space7)
    }

    private var emptySuggestions: some View {
        PVCard(
            tone: .sunken,
            border: .dashed,
            cornerRadius: PVRadius.sm,
            padding: PVSpacing.space6
        ) {
            Text(copy.emptyBody)
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("\(prefix).empty")
    }

    /// The ordinal column makes `sort_order` legible without adding a
    /// reorder control the board deliberately left out.
    private var suggestionRows: some View {
        PVCard(cornerRadius: PVRadius.sm) {
            VStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    HStack(spacing: PVSpacing.space5) {
                        Text(verbatim: "\(index + 1)")
                            .font(PVFont.mono(size: PVTypeScale.micro))
                            .foregroundStyle(PVColor.textFaint)
                            .frame(width: 18, alignment: .leading)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(suggestion.field.label)
                                .font(PVFont.body(size: PVTypeScale.bodySmall))
                                .foregroundStyle(PVColor.textPrimary)
                                .lineLimit(1)
                            Text(suggestion.field.key)
                                .font(PVFont.mono(size: PVTypeScale.micro))
                                .foregroundStyle(PVColor.textFaint)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        CatalogFieldDataTypeBadge(dataType: suggestion.field.dataType)
                        if !isLocked {
                            PVIconButton(
                                .dismiss,
                                label: model.removeLabel(for: suggestion.field, at: level),
                                size: .sm
                            ) {
                                Task { await model.removeSuggestion(fieldID: suggestion.field.id, level: level) }
                            }
                            .disabled(!model.canRemove)
                            .accessibilityIdentifier("\(prefix).remove.\(suggestion.field.id)")
                        }
                    }
                    .padding(.horizontal, PVSpacing.space5)
                    .padding(.vertical, PVSpacing.space4)
                    .accessibilityElement(children: .combine)
                    if index < suggestions.count - 1 {
                        PVDivider()
                    }
                }
            }
        }
    }

    /// The pool is the Metadata vocabulary and nothing else — no inline
    /// field creation (S2-03 T-9); the hint says where to add one instead.
    ///
    /// A combo box rather than a popup menu: the vocabulary grows without
    /// bound, and typing a label or a key beats scanning a long menu. The
    /// assign action sits to its right as an icon button, its tooltip
    /// carrying the reason when it is disabled — the same disabled-not-hidden
    /// pattern the delete affordance uses.
    private var assignControl: some View {
        // Resolved once per render, not once per row — the row builder runs
        // for every visible option and only needs the badge's data type.
        let pool = model.assignPool(at: level)
        let dataTypes = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0.dataType) })
        return VStack(alignment: .leading, spacing: PVSpacing.space4) {
            // A small form: Return in the picker with no row highlighted reaches this submit only
            // when the field shows its pick (`PVComboBoxMatch.returnAction`), and adds the picked
            // field as the plus does. The combo box itself takes no key handling.
            HStack(spacing: PVSpacing.space5) {
                PVComboBox(
                    selection: Binding(
                        get: { model.assignPicks[level] ?? "" },
                        set: { model.assignPicks[level] = $0 }
                    ),
                    options: poolOptions(pool),
                    placeholder: L10n.SourceTypes.assignPlaceholder,
                    emptyLabel: L10n.SourceTypes.assignNoMatch,
                    maxListHeight: Self.assignListMaxHeight,
                    label: copy.pickerLabel,
                    accessibilityIdentifierPrefix: "\(prefix).pool",
                    focus: PVFieldFocus($focus, equals: .picker)
                ) { option, query in
                    poolRow(option, query: query, dataTypes: dataTypes)
                }
                .disabled(pool.isEmpty || model.suggestionWrite != nil)
                PVIconButton(
                    .plus,
                    label: model.assignTooltip(at: level),
                    accessibilityLabel: model.assignAccessibilityLabel(at: level)
                ) {
                    Task { await model.assignPickedField(at: level) }
                }
                .disabled(!model.canAssign(at: level))
                .accessibilityIdentifier("\(prefix).assign")
            }
            .onSubmit { Task { await submitPick() } }
            .onChange(of: model.suggestionWrite) { _, write in
                guard write == nil, refocusPending else { return }
                refocusPending = false
                if !model.assignPool(at: level).isEmpty { focus = .picker }
            }
            if pool.isEmpty {
                Text(L10n.SourceTypes.poolHintEmpty)
                    .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                    .foregroundStyle(PVColor.textMuted)
                    .accessibilityIdentifier("\(prefix).poolEmpty")
            }
        }
    }

    /// Return in the picker: adds the picked field when there is one. The write disables the
    /// picker, which drops focus; `onChange` of the write returns it once the picker is enabled.
    private func submitPick() async {
        guard model.canAssign(at: level) else { return }
        refocusPending = true
        await model.assignPickedField(at: level)
    }

    /// The board's `max-height` for the assign list.
    private static let assignListMaxHeight: CGFloat = 220

    /// The pool row: field label over its mono key, with the data type badge
    /// trailing. Label and key both carry the match highlight, so typing
    /// either one shows you why the row matched.
    private func poolRow(_ option: PVComboBoxOption, query: String, dataTypes: [String: String]) -> some View {
        HStack(spacing: PVSpacing.space5) {
            VStack(alignment: .leading, spacing: 1) {
                Text(PVComboBoxHighlight.attributed(option.label, query: query))
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
                Text(PVComboBoxHighlight.attributed(option.subtext, query: query))
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let dataType = dataTypes[option.value] {
                CatalogFieldDataTypeBadge(dataType: dataType)
            }
        }
    }

    /// Label and key are both searchable, so the key rides along as the
    /// option's subtext rather than being flattened into the label.
    private func poolOptions(_ pool: [CatalogMetadataField]) -> [PVComboBoxOption] {
        pool.map { PVComboBoxOption(value: $0.id, label: $0.label, subtext: $0.key) }
    }
}
