import SwiftUI

/// The frame of a list page that fills the pane: the list page header across the pane on the page
/// surface, a full-width hairline, the toolbar when the page has one (on the card surface, with its own
/// hairline), then the list area filling the rest of the pane on the card surface. The gutter is chosen
/// once, here, from the width class (`fullPaneGutter`), and handed to the toolbar and the area, so every
/// list page insets alike. Mints `<root>.list`, and the header's `<root>.countLine` and `<root>.add`.
/// The Conclusion lists and the Sources list wear it; `PVListPageArea` draws the states of the area.
struct PVListPage<Toolbar: View, Content: View>: View {
    let title: LocalizedStringResource
    var description: LocalizedStringResource?
    let countLine: String?
    var add: PVListPageHeader.Add?
    let identifierRoot: String
    var showsToolbar = false
    @ViewBuilder let toolbar: (CGFloat) -> Toolbar
    @ViewBuilder let content: (CGFloat) -> Content

    @Environment(\.pvWidthClass) private var widthClass

    var body: some View {
        let gutter = widthClass.fullPaneGutter
        VStack(spacing: 0) {
            PVListPageHeader(
                title: title, description: description, countLine: countLine, add: add,
                identifierPrefix: identifierRoot, gutter: gutter
            )
            .background(PVColor.surfacePage)
            PVDivider()
            if showsToolbar {
                toolbar(gutter)
                    .background(PVColor.surfaceCard)
                    .overlay(alignment: .bottom) { PVDivider() }
                    .zIndex(1)
            }
            content(gutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PVColor.surfaceCard)
        }
        .background(PVColor.surfacePage)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(identifierRoot).list")
    }
}

extension PVListPage where Toolbar == EmptyView {
    /// A page with no toolbar.
    init(
        title: LocalizedStringResource,
        description: LocalizedStringResource? = nil,
        countLine: String?,
        add: PVListPageHeader.Add? = nil,
        identifierRoot: String,
        @ViewBuilder content: @escaping (CGFloat) -> Content
    ) {
        self.init(
            title: title, description: description, countLine: countLine, add: add,
            identifierRoot: identifierRoot, showsToolbar: false,
            toolbar: { _ in EmptyView() }, content: content
        )
    }
}

/// The states of a list page's area that every list draws the same way.
@MainActor
enum PVListPageArea {
    /// First-load placeholder in row geometry, with a bar for each detail column so rows do not shift
    /// when the cells arrive: 30 rows fill the list area.
    static func loadingArea(gutter: CGFloat, detailWidths: [CGFloat]) -> some View {
        PVListSkeleton(rows: 30, detailWidths: detailWidths, horizontalInset: gutter)
            .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
            .clipped()
    }

    /// The read failed with nothing to show: the danger Callout at the top of the list area.
    static func failureArea(_ message: String, gutter: CGFloat) -> some View {
        PVCallout(tone: .danger, message: message)
            .pvListPageMessage(gutter: gutter, maxWidth: PVSpacing.measureForm)
    }
}
