import SwiftUI

extension PVColumnSplit {
    /// The Source type page: Details (440 – 560pt) beside Suggested fields (340 – 480pt) at every
    /// width, the pair centred; the side column goes under Details only when the pane is too
    /// narrow for both (S15-D27 TP-W1).
    static let sourceTypePage = PVColumnSplit(
        mainMin: 440, mainMax: 560, sideMin: 340, sideMax: 480, stacking: .whenNarrow
    )
}

/// One Source type's page (S15-48, S15-D27): a pinned header with Delete, Details (Label, Icon,
/// Description, Save, Revert) or the locked note on a plugin's type, and the Source-level suggested
/// fields beside them, on Page columns. It mounts once per type, so the draft belongs to one type;
/// it leaves for the list when the type is gone, and asks before leaving with unsaved details.
struct SourceTypePageView: View {
    @Environment(WorkspaceNavigation.self) private var navigation
    let typeID: String
    @State private var model: SourceTypePageModel

    init(
        typeID: String,
        session: WorkspaceSession,
        userID: String,
        store: any GenealogyStore
    ) {
        self.typeID = typeID
        _model = State(
            initialValue: SourceTypePageModel(
                typeID: typeID,
                session: session,
                userID: userID,
                store: store
            )
        )
    }

    var body: some View {
        @Bindable var model = model
        Group {
            if let typesHandle = model.typesHandle {
                SourceTypePageContent(typeID: typeID, typesHandle: typesHandle, model: model)
            } else {
                SourceTypePageLoadingShell(typeID: typeID, model: model)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PVColor.surfacePage)
        .vocabularyToastOverlay($model.toast, identifier: "sourceTypes.page.toast")
        .workspaceLeaveGuard(model)
        .leavesForSectionRoot(when: model.isGone)
        .pvConfirm(
            item: leaveBinding,
            copy: { _ in .discardChanges },
            tone: .danger,
            accessibilityIdentifierPrefix: "sourceTypes.page.leave",
            onConfirm: { model.discardAndLeave() },
            detail: { _ in EmptyView() }
        )
        .pvDeleteImpact(
            flow: model.deleteImpact,
            accessibilityIdentifierPrefix: "sourceTypes.deleteImpact",
            onConfirm: {
                Task { await model.confirmDelete(leaving: navigation.fallbackToSectionRoot) }
            },
            onNavigate: { location in
                navigation.go(to: location)
            }
        )
        .task { model.warm() }
        .accessibilityIdentifier("sourceTypes.page")
    }

    /// Cancel and Escape on the discard confirm keep the edit and drop the held move.
    private var leaveBinding: Binding<SourceTypePageModel.PendingLeave?> {
        Binding(
            get: { model.pendingLeave },
            set: { newValue in
                if newValue == nil {
                    model.keepEditing()
                } else {
                    model.pendingLeave = newValue
                }
            }
        )
    }
}

/// Spinner-only shell before the types list has a handle.
private struct SourceTypePageLoadingShell: View {
    let typeID: String
    let model: SourceTypePageModel

    var body: some View {
        PVPageColumns(
            headerPinned: true,
            scrollResetKey: typeID,
            split: .sourceTypePage,
            header: { SourceTypePageHeader(model: model) },
            primary: {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, PVSpacing.space9)
            }
        )
    }
}

/// Observes the types handle so a load or a write repaints the page.
private struct SourceTypePageContent: View {
    let typeID: String
    @Bindable var typesHandle: QueryHandle<[CatalogSourceType]>
    @Bindable var model: SourceTypePageModel
    @State private var iconPickerOpen = false
    /// Pending selection while the sheet is open: the draft changes only on Use icon.
    @State private var pendingIconKey = PVMarkKey.defaultTypeMark.rawValue

    var body: some View {
        Group {
            if model.type != nil {
                loaded
            } else if case .failed(let error) = typesHandle.reading {
                PVPageColumns(
                    headerPinned: true,
                    scrollResetKey: typeID,
                    split: .sourceTypePage,
                    header: { SourceTypePageHeader(model: model) },
                    primary: {
                        PVRetryCallout(
                            title: L10n.SourceTypes.pageLoadErrorTitle,
                            message: L10n.Errors.message(for: error),
                            handle: typesHandle,
                            id: "sourceTypes.page.loadError",
                            onRetry: { model.rereadTypes() }
                        )
                        .accessibilityIdentifier("sourceTypes.page.loadError")
                    }
                )
            } else {
                // Loading, or the type is gone and the page is leaving for the list.
                PVPageColumns(
                    headerPinned: true,
                    scrollResetKey: typeID,
                    split: .sourceTypePage,
                    header: { SourceTypePageHeader(model: model) },
                    primary: {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, PVSpacing.space9)
                    }
                )
            }
        }
        .onChange(of: model.type?.id, initial: true) { _, _ in
            model.syncDraft()
        }
    }

    private var loaded: some View {
        PVPageColumns(
            headerPinned: true,
            scrollResetKey: typeID,
            split: .sourceTypePage,
            header: { SourceTypePageHeader(model: model) },
            primary: { details },
            secondary: { SourceTypeSuggestionList(model: model, isLocked: model.isLocked) }
        )
        .pvFormDialog(
            isPresented: $iconPickerOpen,
            copy: PVFormDialogCopy(
                title: L10n.SourceTypes.iconPickerTitle,
                subtitle: L10n.SourceTypes.iconPickerSubtitle,
                confirm: L10n.SourceTypes.iconPickerConfirm,
                cancel: L10n.SourceTypes.iconPickerCancel
            ),
            width: 660,
            isDirty: pendingIconKey != (model.draft?.iconKey ?? pendingIconKey),
            accessibilityIdentifierPrefix: "sourceTypes.iconPicker",
            onConfirm: {
                model.applyDraftIconKey(pendingIconKey)
                iconPickerOpen = false
            }
        ) {
            SourceTypeIconGrid(
                selection: $pendingIconKey,
                columns: 6,
                groupLabel: L10n.SourceTypes.iconPickerGroupLabel
            )
        }
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVSectionHeader(title: L10n.SourceTypes.detailsSectionLabel)
            if model.isLocked {
                lockedNote
            } else {
                form
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var lockedNote: some View {
        if let type = model.type {
            VStack(alignment: .leading, spacing: PVSpacing.space7) {
                PVCallout(
                    tone: .neutral,
                    icon: .lock,
                    message: L10n.SourceTypes.lockedNotePlugin(pluginID: CatalogOrigin.pluginID(from: type.origin)),
                    compact: true
                )
                VocabularyLabeledSection(label: L10n.SourceTypes.descriptionSectionLabel) {
                    Text(type.description.isEmpty
                        ? L10n.string(L10n.SourceTypes.descriptionEmptyPlaceholder)
                        : type.description)
                        .font(PVFont.body(size: PVTypeScale.bodySmall))
                        .foregroundStyle(PVColor.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var form: some View {
        if let draft = Binding($model.draft) {
            VStack(alignment: .leading, spacing: PVSpacing.space7) {
                PVField(label: L10n.SourceTypes.formLabel, error: model.formError, marker: .required) {
                    PVInput(
                        text: draft.label,
                        isInvalid: model.formError != nil
                    )
                    .accessibilityIdentifier("sourceTypes.form.label")
                }
                PVField(
                    label: L10n.SourceTypes.formIcon,
                    hint: L10n.SourceTypes.formIconHint,
                    marker: .required
                ) {
                    iconRow(key: PVMarkKey(catalogKey: draft.wrappedValue.iconKey))
                }
                PVField(label: L10n.SourceTypes.formDescription, hint: L10n.SourceTypes.formDescriptionHint) {
                    PVTextArea(
                        text: draft.description,
                        lineLimit: 4...8,
                        prompt: L10n.SourceTypes.formDescriptionPlaceholder
                    )
                    .accessibilityIdentifier("sourceTypes.form.description")
                }
                VocabularyFormActions(
                    primaryLabel: model.isSaving ? L10n.SourceTypes.saveSaving : L10n.SourceTypes.saveChanges,
                    secondaryLabel: L10n.SourceTypes.revert,
                    isSaving: model.isSaving,
                    canSubmit: model.canSubmit,
                    isSecondaryDisabled: model.isSaving || !model.isDirty,
                    identifierPrefix: "sourceTypes",
                    onPrimary: {
                        Task { await model.submit() }
                    },
                    onSecondary: { model.revertEdit() }
                )
            }
            .disabled(model.isSaving)
        }
    }

    /// The draft's mark, its name over its mono key, and the button that opens the icon sheet.
    private func iconRow(key: PVMarkKey) -> some View {
        HStack(spacing: PVSpacing.space5) {
            PVThumbnail(.init(glyph: .mark(key)))
            VStack(alignment: .leading, spacing: 1) {
                Text(key.typePickerTitle)
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.textPrimary)
                    .lineLimit(1)
                Text(key.rawValue)
                    .font(PVFont.mono(size: PVTypeScale.micro))
                    .foregroundStyle(PVColor.textFaint)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PVButton(L10n.SourceTypes.formIconChange, variant: .secondary, size: .sm) {
                pendingIconKey = model.draft?.iconKey ?? pendingIconKey
                iconPickerOpen = true
            }
            .accessibilityLabel(
                Text(verbatim: L10n.SourceTypes.formIconChangeAccessibility(name: L10n.string(key.typePickerTitle)))
            )
            .accessibilityIdentifier("sourceTypes.form.icon")
        }
    }
}

#if DEBUG
#Preview("Source type page") {
    let store = FakeStore()
    let projectDir = "/tmp/preview.provenencia"
    let fields = [
        CatalogMetadataField(id: "f1", key: "author", origin: CatalogOrigin.provenencia, label: "Author", dataType: "text", description: ""),
        CatalogMetadataField(id: "f2", key: "publication-date", origin: CatalogOrigin.provenencia, label: "Publication date", dataType: "date", description: ""),
        CatalogMetadataField(id: "f3", key: "publisher", origin: CatalogOrigin.provenencia, label: "Publisher", dataType: "text", description: ""),
    ]
    store.fieldsByProject[projectDir] = fields
    store.sourceTypesByProject[projectDir] = [
        CatalogSourceType(id: "t1", key: "census", origin: CatalogOrigin.provenencia, label: "Census", description: "A household count taken by a government.", usedBy: 41),
    ]
    store.suggestionsByType["t1"] = [
        CatalogTypeSuggestion(field: fields[0], sortOrder: 0),
        CatalogTypeSuggestion(field: fields[2], sortOrder: 1),
        CatalogTypeSuggestion(field: fields[1], sortOrder: 2),
    ]
    let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    return SourceTypePageView(
        typeID: "t1",
        session: session,
        userID: "00000000-0000-7000-8000-000000000001",
        store: store
    )
    .environment(WorkspaceNavigation())
    .environment(session)
    .frame(width: 1102, height: 760)
}
#endif
