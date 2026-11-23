import SwiftUI

/// The Suggested fields section of a Source type's page: the title with the count trailing it, three
/// italic lines under it (the hint, the meaning and the pool hint; the first and last on an editable type
/// only), then the one list: the numbered rows, the empty card, the loading spinner or retry notice, the
/// error callout, and the picker that assigns a field. A plugin's type is read only: no remove, no picker.
struct SourceTypeSuggestedFields: View {
    @Bindable var model: SourceTypePageModel

    private enum PickerFocus { case picker }
    @FocusState private var focus: PickerFocus?
    /// Set by a Return-add; focus returns to the picker once the write ends and it is enabled again.
    @State private var refocusPending = false

    private var isLocked: Bool { model.isLocked }
    private var suggestions: [CatalogTypeSuggestion] { model.suggestions }
    private let prefix = "sourceTypes.suggested"

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVSectionHeader(
                title: L10n.SourceTypes.suggestedSectionLabel,
                meta: model.isLoaded ? L10n.SourceTypes.assignedCount(count: suggestions.count) : nil
            )
            notes
            VStack(alignment: .leading, spacing: PVSpacing.space4) {
                if let error = model.suggestionError {
                    PVCallout(tone: .danger, message: error, announces: true)
                        .accessibilityIdentifier("\(prefix).error")
                }
                content
                if !isLocked, model.isLoaded {
                    assignControl
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(listAccessibilityLabel)
            .accessibilityIdentifier("\(prefix).list")
        }
        .accessibilityIdentifier(prefix)
    }

    /// The hint, the meaning (always) and the pool hint, in italic micro lines.
    private var notes: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            if !isLocked {
                Text(L10n.SourceTypes.suggestedHint)
                    .accessibilityIdentifier("\(prefix).hint")
            }
            Text(L10n.SourceTypes.suggestedMeaning)
                .accessibilityIdentifier("\(prefix).meaning")
            if !isLocked {
                Text(L10n.SourceTypes.poolHint)
                    .accessibilityIdentifier("\(prefix).poolHint")
            }
        }
        .font(PVFont.body(size: PVTypeScale.micro, italic: true))
        .foregroundStyle(PVColor.textMuted)
    }

    /// The spoken label: the title alone until the list is loaded, matching the visible header.
    private var listAccessibilityLabel: String {
        guard model.isLoaded else { return L10n.string(L10n.SourceTypes.suggestedSectionLabel) }
        return L10n.SourceTypes.listAccessibilityLabel(
            title: L10n.string(L10n.SourceTypes.suggestedSectionLabel), count: suggestions.count
        )
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
                    id: "\(prefix).loadError",
                    onRetry: { model.rereadSuggestions() }
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
            Text(L10n.SourceTypes.suggestedEmpty)
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
                                label: model.removeLabel(for: suggestion.field),
                                size: .sm
                            ) {
                                Task { await model.removeSuggestion(fieldID: suggestion.field.id) }
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
        let pool = model.assignPool
        let dataTypes = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0.dataType) })
        return VStack(alignment: .leading, spacing: PVSpacing.space4) {
            // A small form: Return in the picker with no row highlighted reaches this submit only
            // when the field shows its pick (`PVComboBoxMatch.returnAction`), and adds the picked
            // field as the plus does. The combo box itself takes no key handling.
            HStack(spacing: PVSpacing.space5) {
                PVComboBox(
                    selection: $model.assignPick,
                    options: poolOptions(pool),
                    placeholder: L10n.SourceTypes.assignPlaceholder,
                    emptyLabel: L10n.SourceTypes.assignNoMatch,
                    maxListHeight: Self.assignListMaxHeight,
                    label: L10n.SourceTypes.suggestedPickerLabel,
                    accessibilityIdentifierPrefix: "\(prefix).pool",
                    focus: PVFieldFocus($focus, equals: .picker)
                ) { option, query in
                    poolRow(option, query: query, dataTypes: dataTypes)
                }
                .disabled(pool.isEmpty || model.suggestionWrite != nil)
                PVIconButton(
                    .plus,
                    label: model.assignTooltip,
                    accessibilityLabel: model.assignAccessibilityLabel
                ) {
                    Task { await model.assignPickedField() }
                }
                .disabled(!model.canAssign)
                .accessibilityIdentifier("\(prefix).assign")
            }
            .onSubmit { Task { await submitPick() } }
            .onChange(of: model.suggestionWrite) { _, write in
                guard write == nil, refocusPending else { return }
                refocusPending = false
                if !model.assignPool.isEmpty { focus = .picker }
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
        guard model.canAssign else { return }
        refocusPending = true
        await model.assignPickedField()
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
