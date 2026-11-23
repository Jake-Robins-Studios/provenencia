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
                            MetadataBoardSuggestionRow(
                                accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                                entry: entry,
                                isEditing: board.editingFieldID == entry.field.id,
                                isSaving: board.savingFieldID == entry.field.id,
                                error: board.fieldErrorID == entry.field.id
                                    ? board.fieldError
                                    : nil,
                                onTyped: { board.setTyped($0, fieldID: entry.field.id) },
                                onBeginEdit: { board.beginEdit(fieldID: entry.field.id) },
                                onCancel: { board.cancelEdit() },
                                onSave: { value in
                                    board.drafts[entry.field.id] = value
                                    Task { await board.save(fieldID: entry.field.id) }
                                },
                                onDismiss: {
                                    Task { await board.dismissSuggestion(fieldID: entry.field.id) }
                                }
                            )
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
                onClear: { onClear(entry.field.id) }
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

/// Suggestion quick-add row with a local draft. A row whose owner inherits a
/// value shows it read only, with the level it comes from, and opens an empty
/// editor to override it.
private struct MetadataBoardSuggestionRow: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry
    let isEditing: Bool
    let isSaving: Bool
    var error: String? = nil
    let onTyped: (Bool) -> Void
    let onBeginEdit: () -> Void
    let onCancel: () -> Void
    let onSave: (String) -> Void
    let onDismiss: () -> Void

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        let fieldID = entry.field.id
        return PVCard(border: .dashed, cornerRadius: PVRadius.sm) {
            VStack(alignment: .leading, spacing: PVSpacing.space2) {
                HStack(alignment: .top, spacing: PVSpacing.space5) {
                    MetadataBoardLabel(
                        text: entry.field.label,
                        leadingInset: PVReorderHandle.width
                    )
                    if let inherited = entry.inherited {
                        inheritedValue(inherited)
                    } else {
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

                        dismissButton
                    }
                }
                if entry.inherited == nil, let error, !error.isEmpty {
                    PVErrorText(error, size: .caption)
                }
            }
            .padding(.vertical, PVSpacing.space4)
            .padding(.horizontal, PVSpacing.space5)
        }
        // Typed text in the focused input is an inner edit: Escape clears it before the sheet reacts.
        .pvSheetInnerEdit(isFocused && !draft.isEmpty)
        .onExitCommand { draft = "" }
        .onChange(of: draft) { _, text in onTyped(!text.isEmpty) }
        .onChange(of: isEditing) { _, editing in
            if !editing { draft = "" }
        }
    }

    private var dismissButton: some View {
        PVIconButton(
            .dismiss,
            label: L10n.Sources.dismissMetadataSuggestionLabel(field: entry.field.label),
            size: .sm
        ) {
            onDismiss()
        }
        .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(entry.field.id).dismiss")
    }

    /// The inherited value at rest and the empty editor that overrides it: the saved row's inline
    /// edit, so the board has one open-to-edit control.
    private func inheritedValue(_ inherited: CatalogInheritedMetadataValue) -> some View {
        let fieldID = entry.field.id
        let level = L10n.CitationFormats.levelName(inherited.level)
        let shown = inherited.shownText
        return PVInlineEdit(
            isEditing: isEditing,
            isSaving: isSaving,
            error: error,
            saveLabel: L10n.Sources.saveMetadataValue,
            cancelLabel: L10n.Sources.cancelEdit,
            editLabel: L10n.Sources.overrideMetadataValueLabel(field: entry.field.label),
            saveDisabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            axis: .horizontal,
            actionsStyle: .iconStack,
            accessibilityIdentifierPrefix: "\(accessibilityIdentifierPrefix).\(fieldID)",
            onEdit: {
                draft = ""
                onBeginEdit()
            },
            onSave: { onSave(draft) },
            onCancel: {
                draft = ""
                onCancel()
            },
            display: {
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    inheritedText(inherited, shown: shown, level: level)
                    MetadataBoardCaption(L10n.Sources.metadataInheritedFrom(level: level))
                        .padding(.horizontal, PVInputChrome.horizontalInset)
                        .accessibilityHidden(true)
                        .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).inheritedFrom")
                }
            },
            editor: {
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    PVTextArea(
                        text: $draft,
                        lineLimit: 1...6,
                        typography: .mono,
                        isInvalid: error != nil,
                        activateOnAppear: true
                    )
                    .onSubmit { onSave(draft) }
                    .disabled(isSaving)
                    .accessibilityLabel(entry.field.label)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).value")
                    MetadataBoardCaption(L10n.Sources.metadataOverrides(level: level, value: shown))
                        .padding(.horizontal, PVInputChrome.horizontalInset)
                }
            },
            restingTrailing: { dismissButton },
            editingTrailing: { EmptyView() }
        )
    }

    /// The value read only, drawn as a saved value is, quieter. A value that is not a link reads as
    /// one element with its field label; a link is its own element.
    @ViewBuilder
    private func inheritedText(_ inherited: CatalogInheritedMetadataValue, shown: String, level: String) -> some View {
        let text = MetadataValueText(
            text: shown,
            openURL: inherited.openURL,
            isURL: entry.field.dataType == CatalogFieldDataType.url,
            accessibilityIdentifier: "\(accessibilityIdentifierPrefix).\(entry.field.id).inherited",
            lineLimit: 1,
            chrome: true,
            secondary: true,
            italic: inherited.isUnknown
        )
        if inherited.openURL != nil, entry.field.dataType == CatalogFieldDataType.url {
            text
        } else {
            text
                .accessibilityLabel(L10n.Sources.metadataInheritedAccessibility(level: level, value: shown))
                .accessibilityHint(L10n.string(L10n.Sources.metadataInheritedHint))
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

/// Text metadata row editor with a **local** draft so keystrokes do not rewrite
/// `MetadataBoardModel.drafts` (and rebuild the reorderable `List`) on every
/// character — that was dropping TextField focus and feeling multi-second laggy.
private struct MetadataBoardTextEditor: View {
    let accessibilityIdentifierPrefix: String
    let entry: CatalogMetadataEntry
    let isEditing: Bool
    let isSaving: Bool
    var error: String? = nil
    let onTyped: (Bool) -> Void
    let onBeginEdit: () -> Void
    let onSave: (String) -> Void
    let onCancel: () -> Void
    let onClear: () -> Void

    @State private var draft = ""

    private func beginEdit() {
        draft = entry.valueText
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
            editLabel: L10n.Sources.editMetadataValueLabel(field: entry.field.label),
            saveDisabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            axis: .horizontal,
            actionsStyle: .iconStack,
            accessibilityIdentifierPrefix: "\(accessibilityIdentifierPrefix).\(fieldID)",
            onEdit: beginEdit,
            onSave: { onSave(draft) },
            onCancel: {
                draft = entry.valueText
                onCancel()
            },
            display: {
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    displayValue
                    overridesCaption
                }
            },
            editor: {
                VStack(alignment: .leading, spacing: PVSpacing.space1) {
                    PVTextArea(
                        text: $draft,
                        lineLimit: 1...6,
                        typography: .mono,
                        isInvalid: error != nil,
                        activateOnAppear: true
                    )
                    .onSubmit { onSave(draft) }
                    .disabled(isSaving)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).value")
                    overridesCaption
                }
            },
            restingTrailing: {
                PVIconButton(
                    .trash,
                    label: L10n.Sources.deleteMetadataValueLabel(field: entry.field.label),
                    size: .sm,
                    tone: .danger,
                    action: onClear
                )
                .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(fieldID).delete")
            },
            editingTrailing: { EmptyView() }
        )
        .onChange(of: isEditing, initial: true) { _, editing in
            if editing {
                draft = entry.valueText
            } else {
                onTyped(false)
            }
        }
        .onChange(of: draft) { _, text in onTyped(isEditing && text != entry.valueText) }
    }

    private var displayValue: some View {
        MetadataValueText(
            entry: entry,
            accessibilityIdentifier: "\(accessibilityIdentifierPrefix).\(entry.field.id).value",
            lineLimit: nil,
            chrome: true
        )
    }

    /// What the saved value overrides, under it at rest and in edit; nothing when the owner
    /// inherits nothing for the field.
    @ViewBuilder
    private var overridesCaption: some View {
        if let inherited = entry.inherited {
            MetadataBoardCaption(
                L10n.Sources.metadataOverrides(
                    level: L10n.CitationFormats.levelName(inherited.level), value: inherited.shownText
                )
            )
            .padding(.horizontal, PVInputChrome.horizontalInset)
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).\(entry.field.id).overrides")
        }
    }
}

/// One metadata value, drawn the same on a board row and in a card's read-only
/// copy details: mono caption, and a URL value with a safe link as a plain
/// underlined link button. `chrome` adds the board row's resting inset so
/// entering edit does not shift glyphs; `lineLimit` nil wraps, 1 truncates the tail.
struct MetadataValueText: View {
    let text: String
    let openURL: URL?
    let isURL: Bool
    let accessibilityIdentifier: String
    var lineLimit: Int?
    var chrome: Bool
    /// Quieter colour, for a value the row only inherits.
    var secondary = false
    var italic = false

    @Environment(\.openURL) private var openURLAction

    init(
        text: String, openURL: URL?, isURL: Bool, accessibilityIdentifier: String, lineLimit: Int?,
        chrome: Bool, secondary: Bool = false, italic: Bool = false
    ) {
        self.text = text
        self.openURL = openURL
        self.isURL = isURL
        self.accessibilityIdentifier = accessibilityIdentifier
        self.lineLimit = lineLimit
        self.chrome = chrome
        self.secondary = secondary
        self.italic = italic
    }

    init(entry: CatalogMetadataEntry, accessibilityIdentifier: String, lineLimit: Int?, chrome: Bool) {
        self.init(
            text: entry.valueText, openURL: entry.openURL,
            isURL: entry.field.dataType == CatalogFieldDataType.url,
            accessibilityIdentifier: accessibilityIdentifier, lineLimit: lineLimit, chrome: chrome
        )
    }

    var body: some View {
        if isURL, let url = openURL {
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

/// The one-line muted sentence under a board row's value or editor: where an inherited value
/// comes from, what a value overrides, the add row's taken notice. Text, not a Badge: it is a
/// sentence, not a status.
private struct MetadataBoardCaption: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(verbatim: text)
            .font(PVFont.body(size: PVTypeScale.caption))
            .foregroundStyle(PVColor.textMuted)
            .fixedSize(horizontal: false, vertical: true)
    }
}
