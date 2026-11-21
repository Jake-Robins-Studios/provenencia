import SwiftUI

// MARK: - Omnibar results (kit popup list on the omnibar field)

/// Gives the omnibar field its results: the kit popup list under the field, its
/// highlight and keys from `OmnibarResultsModel`, and its width kept inside the
/// content column. Apply it to the field itself — the popup anchors to, and the
/// presenter's "a click on the field keeps it open" reads, the view it modifies.
struct OmnibarResultsHost: ViewModifier {
    var results: OmnibarResultsModel
    let projectDir: String
    /// The content column's width.
    let contentWidth: CGFloat
    let onActivate: (CatalogSearchHit) -> Void

    @State private var measurement = PVPopupListMeasurement()

    /// The list's width: preferred, narrowed to stay inside the content column,
    /// never narrower than the field.
    private var listWidth: CGFloat {
        PVPopupListPlacement.fittedWidth(
            preferred: OmnibarResultsModel.listWidth,
            hangsFrom: results.fieldFrame.maxX,
            alignment: .trailing,
            columnWidth: contentWidth,
            minimum: results.fieldFrame.width
        )
    }

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .named(WorkspaceContent.coordinateSpace))
            } action: {
                results.fieldFrame = $0
            }
            .background {
                if results.isPresented {
                    PVPopupListMeasure(isActive: results.isPresented, width: listWidth, onHeight: { measurement.record($0) }) {
                        rowsStack
                    }
                }
            }
            .pvPopupList(
                isPresented: Binding(
                    get: { results.isPresented },
                    set: { if !$0 { results.closePanel() } }
                ),
                isMeasured: measurement.isMeasured,
                maxHeight: OmnibarResultsModel.maxListHeight,
                contentHeight: PVPopupListCard<EmptyView>.height(rows: measurement.height),
                optionCount: results.search.hits.count,
                width: listWidth,
                alignment: .trailing
            ) {
                card
            }
            .onKeyPress { press in
                results.handleKey(press.key, command: press.modifiers.contains(.command), activate: onActivate)
            }
            .onChange(of: results.isPresented) { _, presented in
                if !presented { measurement.reset() }
            }
            .onDisappear { results.dismiss() }
    }

    private var card: some View {
        PVPopupListCard(
            rowIDs: results.search.hits.map(\.id),
            activeID: results.highlightedHit?.id
        ) {
            rowsStack
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(L10n.Workspace.omnibarResultsAccessibilityLabel))
        .accessibilityIdentifier("workspace.toolbar.omnibar.results")
    }

    /// What the list shows. Shared by the card and the hidden measuring copy,
    /// so the two never disagree.
    private var rowsStack: some View {
        VStack(spacing: 0) {
            switch results.search.line {
            case .rows:
                ForEach(Array(results.search.hits.enumerated()), id: \.element.id) { index, hit in
                    PVPopupListRow(
                        isActive: index == results.highlight.index,
                        onHighlight: { results.hover(at: index) },
                        onCommit: { onActivate(hit) }
                    ) {
                        CatalogSearchHitRow(hit: hit, projectDir: projectDir)
                    }
                    .id(hit.id)
                    .accessibilityIdentifier("workspace.toolbar.omnibar.hit.\(hit.id)")
                }
            case .searching:
                PVPopupListSearchingLine()
                    .accessibilityIdentifier("workspace.toolbar.omnibar.loading")
            case .noMatches:
                PVPopupListLine {
                    VStack(alignment: .leading, spacing: PVSpacing.space3) {
                        Text(L10n.Workspace.omnibarNoMatchesTitle(query: results.search.trimmedQuery))
                            .font(PVFont.body(size: PVTypeScale.bodySmall, weight: PVFontWeight.medium))
                            .foregroundStyle(PVColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(L10n.Workspace.omnibarNoMatchesHint)
                            .font(PVFont.body(size: PVTypeScale.caption))
                            .foregroundStyle(PVColor.textMuted)
                    }
                }
                .accessibilityIdentifier("workspace.toolbar.omnibar.noMatches")
            case .failed(let message):
                PVPopupListLine {
                    PVCallout(tone: .danger, message: message)
                }
                .accessibilityIdentifier("workspace.toolbar.omnibar.error")
            }
        }
    }
}
