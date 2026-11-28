import SwiftUI

/// The Source date block: the shared date form. The Source date dialog and the Add Source sheet
/// draw it, so a change to the date's control lands in both; S15-42's marks control (No date,
/// Supplied) is the next thing it holds. The form shows its own field errors; the host shows any
/// other line.
struct SourceDateEditor: View {
    @Binding var draft: DateValueDraft
    var accessibilityIdentifierPrefix: String
    var yearFocus: PVFieldFocus? = nil

    var body: some View {
        DateValueEditorForm(
            draft: $draft,
            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
            yearFocus: yearFocus
        )
    }
}
