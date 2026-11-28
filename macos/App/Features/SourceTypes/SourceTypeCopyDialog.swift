import SwiftUI

extension View {
    /// The Copy type sheet, presented while `model` is non-nil. A successful copy clears `model`
    /// and hands the copy to `onCopied`, which opens the new type's page.
    func sourceTypeCopyDialog(
        _ model: Binding<SourceTypeCopyModel?>,
        onCopied: @escaping (CatalogSourceType) -> Void
    ) -> some View {
        modifier(SourceTypeCopyDialogModifier(model: model, onCopied: onCopied))
    }
}

private struct SourceTypeCopyDialogModifier: ViewModifier {
    @Binding var model: SourceTypeCopyModel?
    let onCopied: (CatalogSourceType) -> Void

    func body(content: Content) -> some View {
        content.pvFormDialog(
            item: $model,
            copy: PVFormDialogCopy(
                title: L10n.SourceTypes.copyDialogTitle,
                verbatimSubtitle: model.map { L10n.SourceTypes.copyDialogSubtitle($0.original.label) },
                confirm: L10n.SourceTypes.copyConfirm,
                cancel: L10n.SourceTypes.cancel
            ),
            width: 520,
            isRunning: model?.isSaving ?? false,
            isDirty: model?.isDirty ?? false,
            confirmDisabled: !(model?.canCopy ?? false),
            accessibilityIdentifierPrefix: "sourceTypes.copy",
            onConfirm: { current in
                guard let created = await current.copy() else { return false }
                onCopied(created)
                return true
            },
            form: { SourceTypeCopyForm(model: $0) }
        )
    }
}

/// The form body: save error, Label and Key, then the parts the researcher can bring over from the
/// original.
private struct SourceTypeCopyForm: View {
    @Bindable var model: SourceTypeCopyModel

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if let copyError = model.copyError {
                PVCallout(tone: .danger, title: L10n.SourceTypes.copyErrorTitle, message: copyError, announces: true)
                    .accessibilityIdentifier("sourceTypes.copy.error")
            }
            VStack(alignment: .leading, spacing: PVSpacing.space6) {
                SourceTypeLabelKeyFields(
                    label: Binding(get: { model.choices.draft.label }, set: { model.editLabel($0) }),
                    check: model.labelCheck,
                    key: model.key,
                    placeholder: L10n.SourceTypes.copyLabelPlaceholder,
                    accessibilityIdentifierPrefix: "sourceTypes.copy"
                )
            }
            PVDivider()
            parts
        }
        .task { await model.loadFormats() }
    }

    private var parts: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            Text(L10n.SourceTypes.copyPartsHeading)
                .pvMicroCaps()
                .foregroundStyle(PVColor.textFaint)
            PVFormLoadArea(
                state: model.loadState,
                loadingText: L10n.SourceTypes.copyLoading,
                errorTitle: L10n.SourceTypes.copyLoadErrorTitle,
                errorMessage: { $0 },
                onReadAgain: { model.reload() },
                accessibilityIdentifierPrefix: "sourceTypes.copy"
            ) {
                ticks
            }
        }
    }

    private var ticks: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space5) {
            PVCopyPartTick(
                label: L10n.SourceTypes.copyIcon,
                hint: model.iconHint,
                absentHint: absentHint,
                isChecked: $model.choices.includeIcon,
                isAvailable: true,
                isDisabled: model.isSaving
            )
            .accessibilityIdentifier("sourceTypes.copy.icon")
            PVCopyPartTick(
                label: L10n.SourceTypes.copyDescription,
                hint: L10n.string(L10n.SourceTypes.copyDescriptionHint),
                absentHint: absentHint,
                isChecked: $model.choices.includeDescription,
                isAvailable: model.descriptionAvailable,
                isDisabled: model.isSaving
            )
            .accessibilityIdentifier("sourceTypes.copy.description")
            PVCopyPartTick(
                label: L10n.SourceTypes.copyFormats,
                hint: model.formatsHint,
                absentHint: absentHint,
                isChecked: $model.choices.includeFormats,
                isAvailable: model.formatsAvailable,
                isDisabled: model.isSaving
            )
            .accessibilityIdentifier("sourceTypes.copy.formats")
            PVCopyPartTick(
                label: L10n.SourceTypes.copySuggestions,
                hint: model.suggestionsHint,
                absentHint: absentHint,
                isChecked: $model.choices.includeSuggestions,
                isAvailable: model.suggestionsAvailable,
                isDisabled: model.isSaving
            )
            .accessibilityIdentifier("sourceTypes.copy.suggestions")
        }
    }

    private var absentHint: String { L10n.string(L10n.SourceTypes.copyPartAbsent) }
}
