import SwiftUI

/// Constants the owner forms share.
enum SourceOwnerForm {
    /// The width of the dialog holding owner-form columns.
    static let dialogWidth: CGFloat = 880
}

/// The body both owner forms share (the Artifact sheet and the Evidence graph form): the save
/// error across the top, then two equal columns at every width, with no fallback (user,
/// 2026-11-14). The left column is disabled while the form saves; a caller disables its right
/// column's controls itself.
struct SourceOwnerFormColumns<Left: View, Right: View>: View {
    let saveError: String?
    let saveErrorTitle: LocalizedStringResource
    let saveErrorIdentifier: String
    let isSaving: Bool
    @ViewBuilder let left: Left
    @ViewBuilder let right: Right

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            if let saveError {
                PVCallout(
                    tone: .danger,
                    title: saveErrorTitle,
                    message: saveError,
                    announces: true
                )
                .accessibilityIdentifier(saveErrorIdentifier)
            }
            HStack(alignment: .top, spacing: PVSpacing.space8) {
                VStack(alignment: .leading, spacing: PVSpacing.space6) {
                    left
                }
                .disabled(isSaving)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                VStack(alignment: .leading, spacing: PVSpacing.space6) {
                    right
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

/// A draft metadata board in a labelled field, as an owner form draws it.
struct DraftMetadataBoardField: View {
    let label: LocalizedStringResource
    let board: MetadataBoardModel
    let accessibilityIdentifierPrefix: String

    var body: some View {
        PVField(label: label) {
            MetadataBoardView(
                board: board,
                placement: .form,
                accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                onClear: { id in
                    // A draft board clears with no confirm.
                    Task { _ = await board.requestClear(fieldID: id) }
                }
            )
        }
    }
}
