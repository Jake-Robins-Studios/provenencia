import SwiftUI

/// The two-column body of a form dialog: the save error across the top, then two columns. The
/// form dialog disables its whole body while it runs, so the columns disable nothing themselves.
/// Content-agnostic: the Artifact sheet, the Evidence graph form and the Add source type
/// dialog all fill it.
///
/// `rightWidth` nil draws two equal columns. A value fixes the right column at that width
/// (padding and rule included), the left takes the rest, and a rule runs the columns' full
/// height between them.
struct PVFormColumns<Left: View, Right: View>: View {
    let saveError: String?
    let saveErrorTitle: LocalizedStringResource
    let saveErrorIdentifier: String
    var rightWidth: CGFloat? = nil
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
            if let rightWidth {
                columns(rightWidth: rightWidth)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                columns(rightWidth: nil)
            }
        }
    }

    private func columns(rightWidth: CGFloat?) -> some View {
        HStack(alignment: .top, spacing: PVSpacing.space8) {
            VStack(alignment: .leading, spacing: PVSpacing.space6) {
                left
            }
            .frame(maxWidth: .infinity, maxHeight: rightWidth == nil ? nil : .infinity, alignment: .topLeading)
            if let rightWidth {
                VStack(alignment: .leading, spacing: PVSpacing.space6) {
                    right
                }
                .padding(.leading, PVSpacing.space8)
                .frame(width: rightWidth, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .top)
                .overlay(alignment: .leading) {
                    PVDivider(axis: .vertical)
                }
            } else {
                VStack(alignment: .leading, spacing: PVSpacing.space6) {
                    right
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }
}

#Preview("Equal columns, save error") {
    PVFormColumns(
        saveError: "The type was not added.",
        saveErrorTitle: "Could not add",
        saveErrorIdentifier: "preview.error"
    ) {
        Text(verbatim: "Left column")
    } right: {
        Text(verbatim: "Right column")
    }
    .padding(PVSpacing.space9)
    .frame(width: 640)
    .background(PVColor.surfacePage)
}

#Preview("Fixed right column") {
    PVFormColumns(
        saveError: nil,
        saveErrorTitle: "Could not add",
        saveErrorIdentifier: "preview.error",
        rightWidth: 432
    ) {
        Text(verbatim: "Left column")
    } right: {
        Text(verbatim: "Right column")
    }
    .padding(PVSpacing.space9)
    .frame(width: 840)
    .background(PVColor.surfacePage)
}
