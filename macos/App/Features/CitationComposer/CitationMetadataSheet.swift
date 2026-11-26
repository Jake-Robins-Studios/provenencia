import SwiftUI

extension View {
    /// The Citation metadata sheet, presented while `model` is non-nil. A
    /// successful Save closes it through the model; Cancel clears it at once;
    /// Escape and a click outside ask first when the board holds changes.
    func citationMetadataSheet(_ model: Binding<CitationMetadataSheetModel?>) -> some View {
        modifier(CitationMetadataSheetModifier(model: model))
    }
}

private struct CitationMetadataSheetModifier: ViewModifier {
    @Binding var model: CitationMetadataSheetModel?

    private var copy: PVFormDialogCopy {
        PVFormDialogCopy(
            title: L10n.CitationComposer.metadataSheetTitle,
            verbatimSubtitle: model?.subtitle,
            confirm: L10n.CitationComposer.saveMetadata,
            cancel: L10n.Sources.cancelAction
        )
    }

    func body(content: Content) -> some View {
        content.pvFormDialog(
            item: $model,
            copy: copy,
            width: 600,
            isRunning: model?.isSaving ?? false,
            isDirty: model?.isDirty ?? false,
            confirmDisabled: !(model?.canSave ?? false),
            accessibilityIdentifierPrefix: "citationComposer.metadataSheet",
            scrollsBody: true,
            onConfirm: { await $0.save() },
            form: { current in CitationMetadataSheetForm(model: current) }
        )
    }
}

/// The sheet's body: the save error, then the shared board.
private struct CitationMetadataSheetForm: View {
    @Bindable var model: CitationMetadataSheetModel

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if let saveError = model.saveError {
                PVErrorText(saveError, announces: true)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("citationComposer.metadataSheet.saveError")
            }
            DraftMetadataBoardField(
                label: L10n.CitationComposer.metadataLabel,
                board: model.board,
                accessibilityIdentifierPrefix: "citationComposer.metadata"
            )
            .disabled(model.isSaving)
        }
    }
}
