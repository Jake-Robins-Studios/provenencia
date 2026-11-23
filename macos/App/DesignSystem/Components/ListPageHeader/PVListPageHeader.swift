import SwiftUI

/// The list pages' header: display title (and an optional description) on the
/// left, the count line and an optional add button on the right. Source types,
/// Metadata, Properties, Sources and the Conclusion lists wear it. Mints
/// `<prefix>.countLine` and `<prefix>.add`.
struct PVListPageHeader: View {
    /// The header's add button.
    struct Add {
        var label: LocalizedStringResource
        var isDisabled = false
        var size: PVControlSize = .md
        var action: () -> Void
    }

    let title: LocalizedStringResource
    var description: LocalizedStringResource?
    var countLine: String?
    var add: Add?
    let identifierPrefix: String
    var descriptionItalic = false
    /// Horizontal inset. A page that fills the pane at Wide passes its own.
    var gutter: CGFloat = PVSpacing.gutterPage

    var body: some View {
        HStack(alignment: .bottom, spacing: PVSpacing.space8) {
            VStack(alignment: .leading, spacing: PVSpacing.space2) {
                Text(title)
                    .font(PVFont.display(size: PVTypeScale.h1))
                    .foregroundStyle(PVColor.textDisplay)
                if let description {
                    Text(description)
                        .font(PVFont.body(size: PVTypeScale.bodySmall, italic: descriptionItalic))
                        .foregroundStyle(PVColor.textMuted)
                        .frame(maxWidth: PVSpacing.measureProse, alignment: .leading)
                }
            }
            Spacer(minLength: PVSpacing.space6)
            HStack(spacing: PVSpacing.space6) {
                if let countLine {
                    Text(countLine)
                        .font(PVFont.mono(size: PVTypeScale.micro))
                        .foregroundStyle(PVColor.textMuted)
                        .accessibilityIdentifier("\(identifierPrefix).countLine")
                }
                if let add {
                    PVButton(add.label, variant: .primary, size: add.size, icon: .plus) {
                        add.action()
                    }
                    .disabled(add.isDisabled)
                    .accessibilityIdentifier("\(identifierPrefix).add")
                }
            }
        }
        .padding(.horizontal, gutter)
        .padding(.top, PVSpacing.space8)
        .padding(.bottom, PVSpacing.space6)
    }
}

extension View {
    /// Places a list page's failure message: at the top of the list area, its
    /// leading edge on the gutter, at most `maxWidth` wide (the area's width
    /// when nil).
    func pvListPageMessage(gutter: CGFloat = PVSpacing.gutterPage, maxWidth: CGFloat? = nil) -> some View {
        frame(maxWidth: maxWidth ?? .infinity, alignment: .leading)
            .padding(.horizontal, gutter)
            .padding(.top, PVSpacing.space8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview("Header") {
    VStack(spacing: 0) {
        PVListPageHeader(title: "Persons", countLine: "1,204 persons", identifierPrefix: "persons")
        PVDivider()
        PVListPageHeader(
            title: "Sources", description: "Every document you cite.", countLine: "12 sources",
            add: .init(label: "Add source") {}, identifierPrefix: "sources"
        )
    }
    .frame(width: 800)
    .background(PVColor.surfacePage)
}
