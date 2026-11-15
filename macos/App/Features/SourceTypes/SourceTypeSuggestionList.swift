import SwiftUI

/// One list of the fields a Source type suggests (S15-12 repeats it for the Artifact and Evidence
/// graph levels): its title and count, the hint, the numbered rows, the empty card, the loading
/// spinner or retry notice, the error callout, and the picker that assigns a field. A plugin's
/// type is read only: no hint, no remove and no picker.
struct SourceTypeSuggestionList: View {
    @Bindable var model: SourceTypePageModel
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVSectionHeader(
                title: L10n.SourceTypes.suggestedSectionLabel,
                meta: L10n.SourceTypes.assignedCount(count: model.suggestions.count)
            )
            if !isLocked {
                Text(L10n.SourceTypes.suggestedHint)
                    .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                    .foregroundStyle(PVColor.textMuted)
            }
            if let suggestionError = model.suggestionError {
                PVCallout(tone: .danger, message: suggestionError)
                    .accessibilityIdentifier("sourceTypes.suggested.error")
            }
            content
            if !isLocked {
                assignControl
            }
        }
        .accessibilityIdentifier("sourceTypes.suggested")
    }

    @ViewBuilder
    private var content: some View {
        if let handle = model.suggestionsHandle {
            switch handle.reading {
            case .loading:
                spinner
            case .failed(let error):
                PVRetryCallout(
                    title: L10n.SourceTypes.suggestionsLoadErrorTitle,
                    message: L10n.Errors.message(for: error),
                    handle: handle,
                    id: "sourceTypes.suggested.loadError",
                    onRetry: { model.rereadSuggestions() }
                )
                .accessibilityIdentifier("sourceTypes.suggested.loadError")
            case .loaded:
                if model.suggestions.isEmpty {
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
            Text(L10n.SourceTypes.noAssignedBody)
                .font(PVFont.body(size: PVTypeScale.bodySmall))
                .foregroundStyle(PVColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier("sourceTypes.suggested.empty")
    }

    /// The ordinal column makes `sort_order` legible without adding a
    /// reorder control the board deliberately left out.
    private var suggestionRows: some View {
        PVCard(cornerRadius: PVRadius.sm) {
            VStack(spacing: 0) {
                ForEach(Array(model.suggestions.enumerated()), id: \.element.id) { index, suggestion in
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
                                label: L10n.SourceTypes.removeSuggestion(label: suggestion.field.label),
                                size: .sm
                            ) {
                                Task { await model.removeSuggestion(fieldID: suggestion.field.id) }
                            }
                            .disabled(model.removingFieldID != nil)
                            .accessibilityIdentifier("sourceTypes.suggested.remove.\(suggestion.field.id)")
                        }
                    }
                    .padding(.horizontal, PVSpacing.space5)
                    .padding(.vertical, PVSpacing.space4)
                    .accessibilityElement(children: .combine)
                    if index < model.suggestions.count - 1 {
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
        let dataTypes = Dictionary(uniqueKeysWithValues: model.assignPool.map { ($0.id, $0.dataType) })
        return VStack(alignment: .leading, spacing: PVSpacing.space4) {
            HStack(spacing: PVSpacing.space5) {
                PVComboBox(
                    selection: $model.assignPick,
                    options: poolOptions,
                    placeholder: L10n.SourceTypes.assignPlaceholder,
                    emptyLabel: L10n.SourceTypes.assignNoMatch,
                    maxListHeight: Self.assignListMaxHeight,
                    label: L10n.SourceTypes.assignFieldLabel,
                    accessibilityIdentifierPrefix: "sourceTypes.suggested.pool"
                ) { option, query in
                    poolRow(option, query: query, dataTypes: dataTypes)
                }
                .disabled(model.assignPool.isEmpty || model.isAssigning)
                PVIconButton(
                    .plus,
                    label: model.assignTooltip,
                    accessibilityLabel: model.assignAccessibilityLabel
                ) {
                    Task { await model.assignPickedField() }
                }
                .disabled(!model.canAssign)
                .accessibilityIdentifier("sourceTypes.suggested.assign")
            }
            Text(model.assignPool.isEmpty ? L10n.SourceTypes.poolHintEmpty : L10n.SourceTypes.poolHint)
                .font(PVFont.body(size: PVTypeScale.micro, italic: true))
                .foregroundStyle(PVColor.textMuted)
        }
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
    private var poolOptions: [PVComboBoxOption] {
        model.assignPool.map { PVComboBoxOption(value: $0.id, label: $0.label, subtext: $0.key) }
    }
}
