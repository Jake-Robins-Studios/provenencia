import SwiftUI

/// Where a board sits, which decides how a researcher adds a field to it.
enum MetadataBoardPlacement {
    /// On the Source page: the section header's Add field button opens the row at the foot.
    case page
    /// In a form: the board draws its own ghost Add field button at the foot.
    case form
}

/// One owner's metadata board: saved reorderable rows, type suggestions, the
/// empty state and the inline Add field row. The page draws the section header
/// around it, and owns the clear confirm (`MetadataBoardDialogs`) the board asks for.
struct MetadataBoardView: View {
    @Bindable var board: MetadataBoardModel
    let placement: MetadataBoardPlacement
    /// Prefix of every accessibility identifier the board draws (`<prefix>.list`, `<prefix>.<fieldID>.value`, …).
    let accessibilityIdentifierPrefix: String
    let onClear: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if placement == .page, board.saved.isEmpty, board.suggested.isEmpty {
                PVEmptyState(
                    icon: .list,
                    title: L10n.Sources.metadataEmptyTitle,
                    message: L10n.string(L10n.Sources.metadataEmptyMessage),
                    compact: true
                )
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix).empty")
            } else {
                if !board.saved.isEmpty {
                    PVReorderableList(
                        items: board.saved,
                        freezesHeight: board.editingFieldID != nil,
                        onMove: { source, destination in
                            Task { await board.moveSaved(from: source, to: destination) }
                        }
                    ) { entry in
                        savedRow(entry)
                    }
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).list")
                }

                if !board.suggested.isEmpty {
                    VStack(alignment: .leading, spacing: PVSpacing.space4) {
                        Text(L10n.Sources.metadataSuggestionsHeading)
                            .font(PVFont.body(size: PVTypeScale.micro, weight: PVFontWeight.semibold))
                            .tracking(PVTypeScale.micro * PVTracking.caps)
                            .textCase(.uppercase)
                            .foregroundStyle(PVColor.textFaint)
                            .padding(.top, board.saved.isEmpty ? 0 : PVSpacing.space7)

                        ForEach(board.suggested) { entry in
                            let fieldID = entry.field.id
                            let error = board.fieldErrorID == fieldID ? board.fieldError : nil
                            let onSave: (String) -> Void = { value in
                                board.drafts[fieldID] = value
                                Task { await board.save(fieldID: fieldID) }
                            }
                            let onDismiss: () -> Void = { Task { await board.dismissSuggestion(fieldID: fieldID) } }
                            if let inherited = entry.inherited {
                                MetadataBoardInheritedRow(
                                    accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                                    entry: entry,
                                    inherited: inherited,
                                    isEditing: board.editingFieldID == fieldID,
                                    isSaving: board.savingFieldID == fieldID,
                                    error: error,
                                    onTyped: { board.setTyped($0, fieldID: fieldID) },
                                    onBeginEdit: { board.beginEdit(fieldID: fieldID) },
                                    onCancel: { board.cancelEdit() },
                                    onSave: onSave,
                                    onDismiss: onDismiss
                                )
                            } else {
                                MetadataBoardSuggestionRow(
                                    accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                                    entry: entry,
                                    isSaving: board.savingFieldID == fieldID,
                                    error: error,
                                    onTyped: { board.setTyped($0, fieldID: fieldID) },
                                    onSave: onSave,
                                    onDismiss: onDismiss
                                )
                            }
                        }
                    }
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).suggestions")
                }
            }

            if board.addRow != nil {
                MetadataBoardAddRowView(
                    board: board,
                    comboWidth: placement == .form ? 168 : 150,
                    accessibilityIdentifierPrefix: accessibilityIdentifierPrefix
                )
            } else if placement == .form {
                HStack {
                    PVButton(L10n.Sources.addMetadata, variant: .ghost, size: .sm, icon: .plus) {
                        board.openAddRow()
                    }
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).add")
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func savedRow(_ entry: CatalogMetadataEntry) -> some View {
        HStack(alignment: .top, spacing: PVSpacing.space5) {
            PVReorderHandle()
                .padding(.top, 6)
            MetadataBoardLabel(
                text: entry.field.label,
                topPadding: 6,
                emphasized: true
            )

            MetadataBoardTextEditor(
                accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                entry: entry,
                editLabel: L10n.Sources.editMetadataValueLabel(field: entry.field.label),
                startText: entry.valueText,
                isEditing: board.editingFieldID == entry.field.id,
                isSaving: board.savingFieldID == entry.field.id,
                error: board.fieldErrorID == entry.field.id
                    ? board.fieldError
                    : nil,
                onTyped: { board.setTyped($0, fieldID: entry.field.id) },
                onBeginEdit: { board.beginEdit(fieldID: entry.field.id) },
                onSave: { value in
                    board.drafts[entry.field.id] = value
                    Task { await board.save(fieldID: entry.field.id) }
                },
                onCancel: { board.cancelEdit() },
                display: {
                    VStack(alignment: .leading, spacing: PVSpacing.space1) {
                        MetadataValueText(
                            entry: entry,
                            accessibilityIdentifier: "\(accessibilityIdentifierPrefix).\(entry.field.id).value",
                            lineLimit: nil,
                            chrome: true
                        )
                        MetadataBoardOverridesCaption(
                            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix, entry: entry
                        )
                    }
                },
                restingTrailing: {
                    PVIconButton(
                        .trash,
                        label: L10n.Sources.deleteMetadataValueLabel(field: entry.field.label),
                        size: .sm,
                        tone: .danger,
                        action: { onClear(entry.field.id) }
                    )
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(entry.field.id).delete")
                }
            )
        }
        .padding(.vertical, PVSpacing.space3)
        .padding(.horizontal, PVSpacing.space4)
    }
}

/// The inline Add field row at the foot of a board: a field picker, a value
/// input, ✓ and ✕, and under them the refusal or the "taken" notice. ✓ saves at
/// once; Escape closes the row. While drawn it is the sheet's one inner edit.
private struct MetadataBoardAddRowView: View {
    @Bindable var board: MetadataBoardModel
    let comboWidth: CGFloat
    let accessibilityIdentifierPrefix: String

    private enum Field { case picker }
    @FocusState private var focus: Field?

    var body: some View {
        let prefix = "\(accessibilityIdentifierPrefix).addRow"
        VStack(alignment: .leading, spacing: PVSpacing.space2) {
            PVCard(cornerRadius: PVRadius.sm) {
                HStack(spacing: PVSpacing.space4) {
                    PVComboBox(
                        selection: Binding(
                            get: { board.addRow?.fieldID ?? "" },
                            set: { board.pickAddRowField($0) }
                        ),
                        options: board.fieldComboOptions,
                        size: .sm,
                        placeholder: L10n.Sources.metadataField,
                        emptyLabel: L10n.Sources.typeNoMatch,
                        isInvalid: false,
                        label: L10n.Sources.metadataField,
                        accessibilityIdentifierPrefix: "\(prefix).field",
                        focus: PVFieldFocus($focus, equals: .picker)
                    )
                    .onAppear { DispatchQueue.main.async { focus = .picker } }
                    .frame(width: comboWidth)
                    PVInput(
                        text: Binding(
                            get: { board.addRow?.value ?? "" },
                            set: { board.setAddRowValue($0) }
                        ),
                        size: .sm,
                        mono: true,
                        prompt: L10n.Sources.metadataValue,
                        isInvalid: board.addRow?.error != nil
                    )
                    .onSubmit { Task { await board.confirmAddRow() } }
                    .accessibilityLabel(L10n.string(L10n.Sources.metadataValue))
                    .accessibilityIdentifier("\(prefix).value")
                    PVInlineEditActions(
                        isSaving: board.isSavingAddRow,
                        saveLabel: L10n.Sources.metadataAddRowConfirmLabel,
                        cancelLabel: L10n.Sources.metadataAddRowCancelLabel,
                        saveDisabled: !board.canConfirmAddRow,
                        style: .iconRow,
                        accessibilityIdentifierPrefix: prefix,
                        onSave: { Task { await board.confirmAddRow() } },
                        onCancel: { board.closeAddRow() }
                    )
                }
                .padding(.vertical, PVSpacing.space4)
                .padding(.horizontal, PVSpacing.space5)
            }
            if let error = board.addRow?.error, !error.isEmpty {
                PVErrorText(error, size: .caption, announces: true)
            } else if let taken = board.addRow?.takenFieldLabel {
                MetadataBoardCaption(L10n.Sources.metadataAddRowFieldTaken(field: taken))
                    .pvAnnounce(L10n.Sources.metadataAddRowFieldTaken(field: taken))
            }
        }
        // The ✕ takes Escape; the enclosing sheet's own Escape stands down while the row is open.
        .pvSheetInnerEdit(true)
    }
}

/// The dashed card a suggested row sits in: a type's suggested field with nothing typed (the
/// quick-add row) or one whose value the owner inherits.
private struct MetadataBoardSuggestionCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        PVCard(border: .dashed, cornerRadius: PVRadius.sm) {
            content()
                .padding(.vertical, PVSpacing.space4)
                .padding(.horizontal, PVSpacing.space5)
        }
    }
}

/// The ✕ that dismisses a suggested row, quick-add or inherited.
private struct MetadataBoardSuggestionDismiss: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry
    let onDismiss: () -> Void

    var body: some View {
        PVIconButton(
            .dismiss,
            label: L10n.Sources.dismissMetadataSuggestionLabel(field: entry.field.label),
            size: .sm
        ) {
            onDismiss()
        }
        .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(entry.field.id).dismiss")
    }
}

/// Suggestion quick-add row with a local draft, for a field the owner inherits nothing for.
private struct MetadataBoardSuggestionRow: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry
    let isSaving: Bool
    var error: String? = nil
    let onTyped: (Bool) -> Void
    let onSave: (String) -> Void
    let onDismiss: () -> Void

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        let fieldID = entry.field.id
        return MetadataBoardSuggestionCard {
            VStack(alignment: .leading, spacing: PVSpacing.space2) {
                HStack(spacing: PVSpacing.space5) {
                    MetadataBoardLabel(
                        text: entry.field.label,
                        leadingInset: PVReorderHandle.width
                    )
                    PVInput(
                        text: $draft,
                        size: .sm,
                        mono: true,
                        prompt: L10n.Sources.metadataSuggestionPlaceholder,
                        isInvalid: error != nil,
                        focused: $isFocused
                    )
                    .onSubmit { onSave(draft) }
                    .accessibilityLabel(entry.field.label)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).value")

                    PVButton(
                        L10n.Sources.saveMetadataSuggestion,
                        variant: .ghost,
                        size: .sm,
                        loading: isSaving
                    ) {
                        onSave(draft)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).save")

                    MetadataBoardSuggestionDismiss(
                        accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                        entry: entry,
                        onDismiss: onDismiss
                    )
                }
                if let error, !error.isEmpty {
                    PVErrorText(error, size: .caption)
                }
            }
        }
        // Typed text in the focused input is an inner edit: Escape clears it before the sheet reacts.
        .pvSheetInnerEdit(isFocused && !draft.isEmpty)
        .onExitCommand { draft = "" }
        .onChange(of: draft) { _, text in onTyped(!text.isEmpty) }
    }
}

/// A suggested row whose owner inherits a value: the value read only, with the level it comes
/// from, and the board's inline edit opening empty to override it. The edit is the saved rows'
/// own, so it holds the sheet's Escape itself.
private struct MetadataBoardInheritedRow: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry
    let inherited: CatalogInheritedMetadataValue
    let isEditing: Bool
    let isSaving: Bool
    var error: String? = nil
    let onTyped: (Bool) -> Void
    let onBeginEdit: () -> Void
    let onCancel: () -> Void
    let onSave: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        let fieldID = entry.field.id
        let level = L10n.CitationFormats.levelName(inherited.level)
        let shown = inherited.shownText
        return MetadataBoardSuggestionCard {
            HStack(alignment: .top, spacing: PVSpacing.space5) {
                // The spoken label of the value carries the field's name.
                MetadataBoardLabel(
                    text: entry.field.label,
                    leadingInset: PVReorderHandle.width,
                    topPadding: 6
                )
                .accessibilityHidden(true)
                MetadataBoardTextEditor(
                    accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                    entry: entry,
                    editLabel: L10n.Sources.overrideMetadataValueLabel(field: entry.field.label),
                    editHint: L10n.Sources.metadataInheritedHint,
                    startText: "",
                    isEditing: isEditing,
                    isSaving: isSaving,
                    error: error,
                    onTyped: onTyped,
                    onBeginEdit: onBeginEdit,
                    onSave: onSave,
                    onCancel: onCancel,
                    display: {
                        VStack(alignment: .leading, spacing: PVSpacing.space1) {
                            MetadataValueText(
                                text: shown,
                                openURL: inherited.openURL,
                                accessibilityIdentifier: "\(accessibilityIdentifierPrefix).\(fieldID).inherited",
                                lineLimit: 1,
                                chrome: true,
                                secondary: true,
                                italic: inherited.isUnknown
                            )
                            // A link is its own element and speaks the same label.
                            .accessibilityLabel(
                                L10n.Sources.metadataInheritedAccessibility(
                                    field: entry.field.label, level: level, value: shown
                                )
                            )
                            // Both the label and the editor's caption say where the value comes from.
                            MetadataBoardCaption(L10n.Sources.metadataInheritedFrom(level: level))
                                .padding(.horizontal, PVInputChrome.horizontalInset)
                                .accessibilityHidden(true)
                                .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).inheritedFrom")
                        }
                    },
                    restingTrailing: {
                        MetadataBoardSuggestionDismiss(
                            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                            entry: entry,
                            onDismiss: onDismiss
                        )
                    }
                )
            }
        }
    }
}

private extension CatalogInheritedMetadataValue {
    /// The text a row draws: the engine's printed value, or "Unknown" for an unknown value that
    /// prints nothing.
    var shownText: String {
        displayText.isEmpty ? L10n.string(L10n.Sources.metadataInheritedUnknown) : displayText
    }
}

/// What a value overrides, under it at rest and in edit: nothing when the owner inherits nothing
/// for the field. At most two lines, the whole text on hover.
private struct MetadataBoardOverridesCaption: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry

    var body: some View {
        if let inherited = entry.inherited {
            MetadataBoardCaption(
                L10n.Sources.metadataOverrides(
                    level: L10n.CitationFormats.levelName(inherited.level), value: inherited.shownText
                ),
                lineLimit: 2
            )
            .padding(.horizontal, PVInputChrome.horizontalInset)
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(entry.field.id).overrides")
        }
    }
}

/// The board's one inline editor for a text value, saved or inherited, with a **local** draft so
/// keystrokes do not rewrite `MetadataBoardModel.drafts` (and rebuild the reorderable `List`) on
/// every character — that was dropping TextField focus and feeling multi-second laggy. The caller
/// supplies the resting display and trailing control, the edit label and the text an edit opens
/// with. Return is a newline; Save saves.
private struct MetadataBoardTextEditor<Display: View, RestingTrailing: View>: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry
    let editLabel: String
    var editHint: LocalizedStringResource? = nil
    /// What an edit opens with and Cancel restores: the saved value, or nothing for an inherited one.
    let startText: String
    let isEditing: Bool
    let isSaving: Bool
    var error: String? = nil
    let onTyped: (Bool) -> Void
    let onBeginEdit: () -> Void
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @ViewBuilder let display: () -> Display
    @ViewBuilder let restingTrailing: () -> RestingTrailing

    @State private var draft = ""

    private func beginEdit() {
        draft = startText
        onBeginEdit()
    }

    var body: some View {
        let fieldID = entry.field.id
        return PVInlineEdit(
            isEditing: isEditing,
            isSaving: isSaving,
            error: error,
            saveLabel: L10n.Sources.saveMetadataValue,
            cancelLabel: L10n.Sources.cancelEdit,
            editLabel: editLabel,
            editHint: editHint,
            saveDisabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            axis: .horizontal,
            actionsStyle: .iconStack,
            accessibilityIdentifierPrefix: "\(accessibilityIdentifierPrefix).\(fieldID)",
            onEdit: beginEdit,
            onSave: { onSave(draft) },
            onCancel: {
                draft = startText
                onCancel()
            },
            display: display,
            editor: {
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    PVTextArea(
                        text: $draft,
                        lineLimit: 1...6,
                        typography: .mono,
                        isInvalid: error != nil,
                        activateOnAppear: true
                    )
                    .disabled(isSaving)
                    .accessibilityLabel(entry.field.label)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).value")
                    MetadataBoardOverridesCaption(
                        accessibilityIdentifierPrefix: accessibilityIdentifierPrefix, entry: entry
                    )
                }
            },
            restingTrailing: restingTrailing,
            editingTrailing: { EmptyView() }
        )
        .onChange(of: isEditing, initial: true) { _, editing in
            if editing {
                draft = startText
            } else {
                onTyped(false)
            }
        }
        .onChange(of: draft) { _, text in onTyped(isEditing && text != startText) }
    }
}

/// One metadata value, drawn the same on a board row and in a card's read-only
/// copy details: mono caption, and a value with a safe link (`openURL`, set
/// only for a url value) as a plain underlined link button. `chrome` adds the board row's resting inset so
/// entering edit does not shift glyphs; `lineLimit` nil wraps, 1 truncates the tail.
struct MetadataValueText: View {
    let text: String
    let openURL: URL?
    let accessibilityIdentifier: String
    var lineLimit: Int?
    var chrome: Bool
    /// Quieter colour, for a value the row only inherits.
    var secondary = false
    var italic = false

    @Environment(\.openURL) private var openURLAction

    init(
        text: String, openURL: URL?, accessibilityIdentifier: String, lineLimit: Int?,
        chrome: Bool, secondary: Bool = false, italic: Bool = false
    ) {
        self.text = text
        self.openURL = openURL
        self.accessibilityIdentifier = accessibilityIdentifier
        self.lineLimit = lineLimit
        self.chrome = chrome
        self.secondary = secondary
        self.italic = italic
    }

    init(entry: CatalogMetadataEntry, accessibilityIdentifier: String, lineLimit: Int?, chrome: Bool) {
        self.init(
            text: entry.valueText, openURL: entry.openURL,
            accessibilityIdentifier: accessibilityIdentifier, lineLimit: lineLimit, chrome: chrome
        )
    }

    var body: some View {
        if let url = openURL {
            Button {
                openURLAction(url)
            } label: {
                valueText
                    .foregroundStyle(PVColor.textLink)
                    .underline(true, color: PVColor.textLink)
            }
            .buttonStyle(.plain)
            .modifier(MetadataValueChromeIf(chrome: chrome))
            .accessibilityIdentifier(accessibilityIdentifier)
            .help(lineLimit == nil
                ? L10n.string(L10n.Sources.openMetadataURL)
                : "\(L10n.string(L10n.Sources.openMetadataURL))\n\(text)")
        } else {
            valueText
                .foregroundStyle(secondary ? PVColor.textSecondary : PVColor.textPrimary)
                .modifier(MetadataValueChromeIf(chrome: chrome))
                .accessibilityIdentifier(accessibilityIdentifier)
                // A truncated value shows whole on hover.
                .help(lineLimit == nil ? "" : text)
        }
    }

    private var valueText: some View {
        Text(verbatim: text)
            .font(PVFont.mono(size: PVTypeScale.caption))
            .italic(italic)
            .lineLimit(lineLimit)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: lineLimit == nil)
    }
}

private struct MetadataValueChromeIf: ViewModifier {
    let chrome: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if chrome { content.metadataBoardValueChrome() } else { content }
    }
}

/// Resting metadata value chrome that matches `PVTextArea` `.mono` insets so
/// entering inline edit does not shift the glyphs when the border appears.
private struct MetadataBoardValueChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, PVInputChrome.horizontalInset)
            .padding(.vertical, PVTextArea.Typography.mono.verticalPadding)
            .overlay(
                RoundedRectangle(cornerRadius: PVRadius.sm, style: .continuous)
                    .stroke(Color.clear, lineWidth: 1)
            )
    }
}

private extension View {
    func metadataBoardValueChrome() -> some View {
        modifier(MetadataBoardValueChrome())
    }
}

/// Label column used by metadata saved / suggestion rows.
private struct MetadataBoardLabel: View {
    static let width: CGFloat = 132

    let text: String
    /// Leading inset so suggestion labels align with saved-row labels.
    var leadingInset: CGFloat = 0
    var topPadding: CGFloat = 0
    /// Saved rows use a stronger field name; suggestions stay a muted caption.
    var emphasized: Bool = false

    var body: some View {
        Text(verbatim: text)
            .font(
                emphasized
                    ? PVFont.body(size: PVTypeScale.bodySmall, weight: PVFontWeight.semibold)
                    : PVFont.body(size: PVTypeScale.caption)
            )
            .foregroundStyle(emphasized ? PVColor.textPrimary : PVColor.textMuted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: Self.width, alignment: .leading)
            .padding(.leading, leadingInset)
            .padding(.top, topPadding)
    }
}

/// The muted sentence under a board row's value or editor: where an inherited value comes from,
/// what a value overrides, the add row's taken notice. Text, not a Badge: it is a sentence, not
/// a status. A `lineLimit` truncates its tail and shows the whole text on hover.
private struct MetadataBoardCaption: View {
    let text: String
    let lineLimit: Int?

    init(_ text: String, lineLimit: Int? = nil) {
        self.text = text
        self.lineLimit = lineLimit
    }

    var body: some View {
        Text(verbatim: text)
            .font(PVFont.body(size: PVTypeScale.caption))
            .foregroundStyle(PVColor.textMuted)
            .lineLimit(lineLimit)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
            .help(lineLimit == nil ? "" : text)
    }
}
