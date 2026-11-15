import SwiftUI

extension View {
    /// The Evidence graph form, presented while `model` is non-nil. The Source
    /// page sets `model` (Add or Edit) and adds this one line. A successful
    /// save clears `model`.
    func sourceGraphFormDialog(_ model: Binding<SourceGraphFormModel?>) -> some View {
        modifier(SourceGraphFormDialogModifier(model: model))
    }
}

private struct SourceGraphFormDialogModifier: ViewModifier {
    @Binding var model: SourceGraphFormModel?

    private var copy: PVFormDialogCopy {
        if let graph = model?.graph {
            return PVFormDialogCopy(
                title: L10n.Sources.graphFormEditTitle,
                verbatimSubtitle: graph.ref,
                confirm: L10n.Sources.graphFormSaveConfirm,
                cancel: L10n.Sources.cancelAction
            )
        }
        return PVFormDialogCopy(
            title: L10n.Sources.graphFormAddTitle,
            subtitle: L10n.Sources.graphFormAddSubtitle,
            confirm: L10n.Sources.graphFormAddConfirm,
            cancel: L10n.Sources.cancelAction
        )
    }

    func body(content: Content) -> some View {
        content.pvFormDialog(
            item: $model,
            copy: copy,
            width: SourceOwnerForm.dialogWidth,
            isRunning: model?.isSaving ?? false,
            isDirty: model?.isDirty ?? false,
            confirmDisabled: !(model?.canSave ?? false),
            accessibilityIdentifierPrefix: "sources.graphForm",
            scrollsBody: true,
            scrollTarget: model?.scrollTarget.map { AnyHashable($0) },
            scrollRequest: model.map { AnyHashable($0.scrollRequest) },
            onConfirm: { await $0.save() },
            form: { current in
                SourceGraphForm(model: current)
            }
        )
    }
}

/// The form body, in `PVFormColumns`: the save error across the top, then two columns. Left: name,
/// description and the metadata board. Right: the Artifacts the graph links; a
/// locked one that Citations use links to the citation composer.
private struct SourceGraphForm: View {
    @Bindable var model: SourceGraphFormModel
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(\.pvSheetClose) private var close

    var body: some View {
        PVFormColumns(
            saveError: model.saveError,
            saveErrorTitle: L10n.Sources.graphFormSaveErrorTitle,
            saveErrorIdentifier: "sources.graphForm.error",
            isSaving: model.isSaving
        ) {
            fields
            metadata
        } right: {
            SourceFormLoadArea(
                state: model.loadState,
                loadingText: L10n.Sources.graphFormLoading,
                errorTitle: L10n.Sources.graphFormLoadErrorTitle,
                errorMessage: L10n.Sources.graphFormLoadErrorMessage,
                onReadAgain: { Task { await model.loadKeptLinks() } },
                accessibilityIdentifierPrefix: "sources.graphForm"
            ) {
                checklist
            }
        }
        .id(SourceGraphFormModel.Section.top)
    }

    private var metadata: some View {
        DraftMetadataBoardField(
            label: L10n.Sources.graphFormMetadataLabel,
            board: model.board,
            accessibilityIdentifierPrefix: "sources.graphForm.metadata"
        )
        .id(SourceGraphFormModel.Section.metadata)
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVTabPair { name, description in
                PVField(
                    label: L10n.Sources.graphFormName,
                    error: model.nameError,
                    marker: .required
                ) {
                    PVInput(
                        text: $model.draft.name,
                        prompt: L10n.Sources.graphFormNamePlaceholder,
                        isInvalid: model.nameError != nil,
                        focus: name,
                        activateOnAppear: model.opensAt == .top
                    )
                    .accessibilityIdentifier("sources.graphForm.name")
                    .onChange(of: model.draft.name) { _, _ in
                        if model.nameError != nil { model.nameError = nil }
                    }
                }
                PVField(
                    label: L10n.Sources.graphFormDescription,
                    hint: L10n.Sources.graphFormDescriptionHint,
                    marker: .optional
                ) {
                    PVTextArea(text: $model.draft.description, lineLimit: 3...3, focus: description)
                        .accessibilityIdentifier("sources.graphForm.description")
                }
            }
        }
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space4) {
            PVArtifactChecklist(
                artifacts: model.artifacts,
                excluded: $model.draft.excludedArtifactIDs,
                projectDir: model.projectDir,
                sourceTypeIconKey: model.sourceTypeIconKey,
                isDisabled: model.isSaving,
                locked: model.locked,
                description: L10n.Sources.graphFormArtifactsHint,
                lockedLink: PVChecklistLockedLink(
                    title: L10n.Sources.graphFormOpenInComposer,
                    accessibilityLabel: { L10n.Sources.graphFormOpenInComposerLabel(artifact: $0) },
                    shows: { model.composerLinkArtifactIDs.contains($0) },
                    action: { id in
                        guard let location = model.composerLocation(artifactID: id) else { return }
                        close(then: { navigation.go(to: location) })
                    }
                ),
                accessibilityIdentifierPrefix: "sources.graphForm.artifacts"
            )
            if model.needsArtifact {
                Text(L10n.Sources.graphFormNoneChecked)
                    .font(PVFont.body(size: PVTypeScale.caption, italic: true))
                    .foregroundStyle(PVColor.textMuted)
                    .accessibilityIdentifier("sources.graphForm.noneChecked")
            }
        }
    }
}
