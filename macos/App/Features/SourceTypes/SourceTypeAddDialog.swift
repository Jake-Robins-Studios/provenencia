import SwiftUI

extension View {
    /// The Add type dialog, presented while `model` is non-nil. A successful create clears `model`
    /// and opens the new type's page.
    func sourceTypeAddDialog(_ model: Binding<SourceTypeAddModel?>) -> some View {
        modifier(SourceTypeAddDialogModifier(model: model))
    }
}

private struct SourceTypeAddDialogModifier: ViewModifier {
    @Environment(WorkspaceNavigation.self) private var navigation
    @Binding var model: SourceTypeAddModel?

    func body(content: Content) -> some View {
        content.pvFormDialog(
            item: $model,
            copy: PVFormDialogCopy(
                title: L10n.SourceTypes.addDialogTitle,
                subtitle: L10n.SourceTypes.addDialogSubtitle,
                confirm: L10n.SourceTypes.addType,
                cancel: L10n.SourceTypes.cancel
            ),
            width: SourceTypeAddForm.dialogWidth,
            isRunning: model?.isSaving ?? false,
            isDirty: model?.isDirty ?? false,
            confirmDisabled: !(model?.canAdd ?? false),
            accessibilityIdentifierPrefix: "sourceTypes.add",
            onConfirm: { current in
                guard let created = await current.create() else { return false }
                navigation.go(to: .sourceTypePage(typeId: created.id, title: created.label))
                return true
            },
            form: { SourceTypeAddForm(model: $0) }
        )
    }
}

/// The form body, in `PVFormColumns`: Label, Key and Description on the left, the icon grid on
/// the right. The grid picks live; the dialog's Add type or Cancel keeps or drops the pick.
private struct SourceTypeAddForm: View {
    static let dialogWidth: CGFloat = 840
    static let iconColumnWidth: CGFloat = 432

    @Bindable var model: SourceTypeAddModel
    @FocusState private var focus: Field?

    private enum Field: Hashable { case label, description }

    var body: some View {
        let order: [Field] = [.label, .description]
        PVFormColumns(
            saveError: model.createError,
            saveErrorTitle: L10n.SourceTypes.addErrorTitle,
            saveErrorIdentifier: "sourceTypes.add.error",
            isSaving: model.isSaving,
            rightWidth: Self.iconColumnWidth
        ) {
            SourceTypeLabelKeyFields(
                label: Binding(get: { model.draft.label }, set: { model.editLabel($0) }),
                check: model.labelCheck,
                key: model.key,
                placeholder: L10n.SourceTypes.formLabelPlaceholder,
                focus: PVFieldFocus($focus, equals: .label, in: order),
                accessibilityIdentifierPrefix: "sourceTypes.add"
            )
            PVField(label: L10n.SourceTypes.formDescription, hint: L10n.SourceTypes.formDescriptionHint) {
                PVTextArea(
                    text: $model.draft.description,
                    lineLimit: 4...8,
                    prompt: L10n.SourceTypes.formDescriptionPlaceholder,
                    focus: PVFieldFocus($focus, equals: .description, in: order)
                )
                .accessibilityIdentifier("sourceTypes.add.description")
            }
        } right: {
            PVField(label: L10n.SourceTypes.formIcon, hint: L10n.SourceTypes.formIconHint) {
                SourceTypeIconGrid(
                    selection: $model.draft.iconKey,
                    columns: 5,
                    groupLabel: L10n.SourceTypes.addIconGroupLabel
                )
            }
            .disabled(model.isSaving)
        }
    }
}
