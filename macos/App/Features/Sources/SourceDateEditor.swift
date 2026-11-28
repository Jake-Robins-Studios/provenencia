import SwiftUI

/// The Source date block: the shared date form, then, when the date parses, what it reads as.
/// The Source date dialog and the Add Source sheet draw it, so a change to the date's control
/// lands in both. The form shows its own field errors; the host shows any other line.
struct SourceDateEditor: View {
    @Binding var draft: DateValueDraft
    var accessibilityIdentifierPrefix: String
    var yearFocus: PVFieldFocus? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: PVSpacing.space6) {
            DateValueEditorForm(
                draft: $draft,
                accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
                yearFocus: yearFocus
            )
            if draft.isValid, let line = SourceDateText.line(draft.value) {
                readsAs(line)
            }
        }
    }

    private func readsAs(_ line: String) -> some View {
        PVCard(tone: .sunken, cornerRadius: PVRadius.sm, padding: PVSpacing.space5) {
            HStack(spacing: PVSpacing.space5) {
                Text(L10n.Sources.sourceDateReadsAs)
                    .pvMicroCaps()
                Text(verbatim: line)
                    .font(PVFont.mono(size: PVTypeScale.caption))
                    .foregroundStyle(PVColor.textPrimary)
                    .accessibilityIdentifier("\(accessibilityIdentifierPrefix).readsAs")
                Spacer(minLength: 0)
            }
        }
    }
}
