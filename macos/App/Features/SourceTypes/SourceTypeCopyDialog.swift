import SwiftUI

extension View {
    /// The Copy type sheet, presented while `model` is non-nil. A successful copy clears `model`
    /// and opens the new type's page, with no toast, as Add type does.
    func sourceTypeCopyDialog(_ model: Binding<SourceTypeCopyModel?>) -> some View {
        modifier(SourceTypeCopyDialogModifier(model: model))
    }
}

private struct SourceTypeCopyDialogModifier: ViewModifier {
    @Environment(WorkspaceNavigation.self) private var navigation
    @Binding var model: SourceTypeCopyModel?

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
                navigation.go(to: .sourceTypePage(typeId: created.id, title: created.label))
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
                PVCallout(tone: .danger, title: L10n.SourceTypes.copyErrorTitle, message: copyError)
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
            .disabled(model.isSaving)
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
            tick(
                label: L10n.SourceTypes.copyIcon,
                hint: model.iconHint,
                isChecked: $model.choices.includeIcon,
                available: true,
                id: "sourceTypes.copy.icon"
            )
            tick(
                label: L10n.SourceTypes.copyDescription,
                hint: L10n.string(L10n.SourceTypes.copyDescriptionHint),
                isChecked: $model.choices.includeDescription,
                available: model.descriptionAvailable,
                id: "sourceTypes.copy.description"
            )
            tick(
                label: L10n.SourceTypes.copyFormats,
                hint: model.formatsHint,
                isChecked: $model.choices.includeFormats,
                available: model.formatsAvailable,
                id: "sourceTypes.copy.formats"
            )
            ForEach(Level.metadataLevels, id: \.self) { level in
                tick(
                    label: L10n.SourceTypes.level(level).copyTick,
                    hint: model.levelHint(level),
                    isChecked: levelBinding(level),
                    available: model.levelAvailable(level),
                    id: "sourceTypes.copy.\(level.rawValue)"
                )
            }
        }
    }

    private func tick(
        label: LocalizedStringResource,
        hint: String,
        isChecked: Binding<Bool>,
        available: Bool,
        id: String
    ) -> some View {
        PVCopyPartTick(
            label: L10n.string(label),
            hint: hint,
            absentHint: L10n.string(L10n.SourceTypes.copyPartAbsent),
            isChecked: isChecked,
            isAvailable: available,
            isDisabled: model.isSaving
        )
        .accessibilityIdentifier(id)
    }

    private func levelBinding(_ level: Level) -> Binding<Bool> {
        Binding(
            get: { model.choices.includedLevels.contains(level) },
            set: { isOn in
                if isOn {
                    model.choices.includedLevels.insert(level)
                } else {
                    model.choices.includedLevels.remove(level)
                }
            }
        )
    }
}
