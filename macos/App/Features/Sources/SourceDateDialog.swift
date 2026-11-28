import SwiftUI

extension View {
    /// The Source date dialog, presented while `model` is non-nil. The Source page sets `model`
    /// (Add or Edit date) and adds this one line. A successful save clears `model`.
    func sourceDateDialog(_ model: Binding<SourceDateFormModel?>) -> some View {
        modifier(SourceDateDialogModifier(model: model))
    }
}

private struct SourceDateDialogModifier: ViewModifier {
    @Binding var model: SourceDateFormModel?

    func body(content: Content) -> some View {
        content.pvFormDialog(
            item: $model,
            copy: PVFormDialogCopy(
                title: L10n.Sources.sourceDateDialogTitle,
                subtitle: L10n.Sources.sourceDateDialogSubtitle,
                confirm: L10n.Sources.sourceDateSave,
                cancel: L10n.Sources.cancelAction
            ),
            width: SourceFields.dialogWidth,
            isRunning: model?.isSaving ?? false,
            isDirty: model?.isDirty ?? false,
            confirmDisabled: !(model?.canSave ?? false),
            accessibilityIdentifierPrefix: "sources.page.sourceDate",
            onConfirm: { await $0.save() },
            form: { SourceDateForm(model: $0) }
        )
    }
}

/// The dialog body: the refused-date Callout, the shared date form, what the date reads as,
/// and Clear date (only for a Source that has a date).
private struct SourceDateForm: View {
    @Bindable var model: SourceDateFormModel
    private enum Field: Hashable { case year }
    @FocusState private var focus: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if let saveError = model.saveError {
                PVCallout(tone: .danger, message: saveError, announces: true)
                    .accessibilityIdentifier("sources.page.sourceDate.error")
            }
            SourceDateEditor(
                draft: $model.draft,
                accessibilityIdentifierPrefix: "sources.page.sourceDate",
                yearFocus: PVFieldFocus($focus, equals: .year)
            )
            if model.initial != nil {
                clearControls
            }
        }
        .onAppear { FocusClaim.claim($focus, .year) }
    }

    private var clearControls: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space3) {
            PVButton(L10n.Sources.sourceDateClear, variant: .ghost, size: .sm, icon: .trash) {
                model.clear()
            }
            .accessibilityIdentifier("sources.page.sourceDate.clear")
            if model.clears {
                // Announced: Clear date changes the form without moving focus.
                PVCallout(
                    message: L10n.string(L10n.Sources.sourceDateClearsCaption),
                    compact: true,
                    announces: true
                )
                .accessibilityIdentifier("sources.page.sourceDate.clearsCaption")
            }
        }
    }
}
