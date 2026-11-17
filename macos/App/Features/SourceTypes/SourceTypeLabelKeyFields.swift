import SwiftUI

/// The Label field and the read-only Key it mints, the pair the Add type dialog and the Copy type
/// sheet open with. The check carries the Label's error (`SourceTypeLabelCheck`); ids are
/// `<prefix>.label` and `<prefix>.key`.
struct SourceTypeLabelKeyFields: View {
    @Binding var label: String
    let check: SourceTypeLabelCheck
    /// The key the engine will mint from the label.
    let key: String
    let placeholder: LocalizedStringResource
    var focus: PVFieldFocus?
    let accessibilityIdentifierPrefix: String

    var body: some View {
        PVField(
            label: L10n.SourceTypes.formLabel,
            error: check.error,
            marker: .required,
            announcesError: check.announces
        ) {
            PVInput(
                text: $label,
                prompt: placeholder,
                isInvalid: check.error != nil,
                focus: focus,
                activateOnAppear: true
            )
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).label")
        }
        PVField(label: L10n.SourceTypes.addKey, hint: L10n.SourceTypes.keyHintAdd) {
            PVInput(
                text: .constant(key),
                mono: true,
                isReadOnly: true,
                prompt: L10n.SourceTypes.addKeyPlaceholder
            )
            .accessibilityIdentifier("\(accessibilityIdentifierPrefix).key")
        }
    }
}
