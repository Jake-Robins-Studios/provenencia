import SwiftUI

extension View {
    /// The Artifact sheet, presented while `model` is non-nil. The Source page
    /// sets `model` through `SourceArtifactsSection.openSheet`. A successful
    /// Save clears it; Cancel clears it at once; Escape and a click outside ask
    /// first when the sheet holds changes.
    func artifactSheet(_ model: Binding<ArtifactSheetModel?>) -> some View {
        modifier(ArtifactSheetModifier(model: model))
    }
}

private struct ArtifactSheetModifier: ViewModifier {
    @Binding var model: ArtifactSheetModel?

    private var copy: PVFormDialogCopy {
        switch model?.mode {
        case .create:
            PVFormDialogCopy(
                title: L10n.Sources.addArtifactDialogTitle,
                verbatimSubtitle: model?.subtitle,
                confirm: L10n.Sources.addArtifactConfirm,
                cancel: L10n.Sources.cancelAction
            )
        case .edit(let art):
            editCopy(ref: art.ref)
        case nil:
            editCopy(ref: "")
        }
    }

    private func editCopy(ref: String) -> PVFormDialogCopy {
        PVFormDialogCopy(
            verbatimTitle: L10n.Sources.editArtifactLabel(ref: ref),
            verbatimSubtitle: model?.subtitle,
            confirm: L10n.Sources.saveArtifact,
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
            accessibilityIdentifierPrefix: "sources.page.artifactSheet",
            scrollsBody: true,
            scrollTarget: model?.scrollTarget.map { AnyHashable($0) },
            scrollRequest: model.map { AnyHashable($0.scrollRequest) },
            onConfirm: { await $0.save() },
            form: { current in ArtifactSheetForm(model: current) }
        )
    }
}

/// The sheet's body, in `PVFormColumns`: the save error, then two columns. Left: in add
/// mode the file, then label, description and copy details. Right: the Evidence graphs the
/// Artifact is in. Each section carries its `.id` for the scroll target.
private struct ArtifactSheetForm: View {
    @Bindable var model: ArtifactSheetModel

    private let prefix = "sources.page.artifactSheet"
    @FocusState private var focus: Field?

    private enum Field: Hashable { case label, description }

    var body: some View {
        PVFormColumns(
            saveError: model.saveError,
            saveErrorTitle: L10n.Sources.artifactCardSaveErrorTitle,
            saveErrorIdentifier: "\(prefix).saveError",
            isSaving: model.isSaving
        ) {
            if model.isCreate {
                fileField
            }
            fields
            DraftMetadataBoardField(
                label: L10n.Sources.artifactCopyDetailsLabel,
                board: model.board,
                accessibilityIdentifierPrefix: "\(prefix).copyDetails"
            )
            .id(ArtifactSheetModel.Section.copyDetails)
        } right: {
            graphLinks
                .id(ArtifactSheetModel.Section.graphs)
        }
        .id(ArtifactSheetModel.Section.top)
    }

    private var fileField: some View {
        PVField(label: L10n.Sources.optionalFile) {
            IngestFileDropRow(
                file: $model.file,
                isBusy: model.isSaving,
                idleHint: L10n.Sources.ingestDropIdleCreate,
                rejectAccessibilityIdentifier: "\(prefix).ingestReject"
            )
        }
    }

    @ViewBuilder
    private var fields: some View {
        let order: [Field] = [.label, .description]
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            PVField(
                label: L10n.Sources.artifactLabel,
                error: model.labelError,
                marker: .required
            ) {
                PVInput(
                    text: $model.draft.label,
                    isInvalid: model.labelError != nil,
                    focus: PVFieldFocus($focus, equals: .label, in: order),
                    activateOnAppear: model.opensAt == .top
                )
                .accessibilityIdentifier("\(prefix).label")
                .onChange(of: model.draft.label) { _, _ in
                    if model.labelError != nil { model.labelError = nil }
                }
            }
            PVField(
                label: L10n.Sources.artifactDescription,
                hint: L10n.Sources.artifactDescriptionHint
            ) {
                PVTextArea(
                    text: $model.draft.description,
                    lineLimit: 3...8,
                    focus: PVFieldFocus($focus, equals: .description, in: order)
                )
                    .accessibilityIdentifier("\(prefix).description")
            }
        }
    }

    @ViewBuilder
    private var graphLinks: some View {
        Group {
            if model.awaitingGraphs {
                PVField(
                    label: L10n.Sources.artifactGraphsLabel,
                    hint: L10n.Sources.artifactGraphsHint
                ) {
                    PVFormLoadArea(
                        state: .loading,
                        loadingText: L10n.Sources.artifactGraphsLoading,
                        errorTitle: L10n.Sources.artifactGraphsLoadErrorTitle,
                        errorMessage: L10n.Sources.artifactGraphsLoadErrorMessage,
                        onReadAgain: {},
                        compact: true,
                        accessibilityIdentifierPrefix: "\(prefix).graphs"
                    ) {
                        EmptyView()
                    }
                }
            } else if model.graphIDs != nil {
                PVField(
                    label: L10n.Sources.artifactGraphsLabel,
                    hint: L10n.Sources.artifactGraphsHint
                ) {
                    PVFormLoadArea(
                        state: model.linkLoadState,
                        loadingText: L10n.Sources.artifactGraphsLoading,
                        errorTitle: L10n.Sources.artifactGraphsLoadErrorTitle,
                        errorMessage: L10n.Sources.artifactGraphsLoadErrorMessage,
                        onReadAgain: { Task { await model.loadLinkLocks() } },
                        compact: true,
                        accessibilityIdentifierPrefix: "\(prefix).graphs"
                    ) {
                        SourceArtifactGraphLinks(
                            graphs: model.graphs,
                            excluded: $model.excludedGraphIDs,
                            locked: model.lockedGraphs,
                            isDisabled: model.isSaving || model.graphsLocked,
                            accessibilityIdentifierPrefix: "\(prefix).graphs"
                        )
                    }
                    if model.inNoGraph {
                        SourceArtifactNoGraphLine(accessibilityIdentifier: "\(prefix).graphs.none")
                    }
                }
            }
        }
        .onChange(of: model.visibleGraphs?.map(\.id)) { _, _ in
            model.graphsChanged()
        }
    }
}
