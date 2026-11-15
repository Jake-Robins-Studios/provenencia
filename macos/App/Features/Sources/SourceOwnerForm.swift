import SwiftUI

/// Constants the owner forms share.
enum SourceOwnerForm {
    /// The width of the dialog holding owner-form columns.
    static let dialogWidth: CGFloat = 880
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
