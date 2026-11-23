import SwiftUI

/// What a Conclusion list shows for its query handle. Persons, Events, and
/// Places share this; the count wording stays with the kind.
enum ConclusionListPresentation<Row: Equatable>: Equatable {
    /// First load: skeleton, no count, rows inert.
    case loading
    /// Loaded with nothing to list, even while a merge or refetch runs: no
    /// count, Promote explanation.
    case empty
    /// Rows, never empty, with the header meta; stale rows stay live while
    /// refreshing.
    case rows([Row], refreshing: Bool)
    /// The read failed with nothing to show.
    case failed(String)

    init(_ read: QueryRead<[Row]>, isFetching: Bool) {
        switch read {
        case .loaded(let value):
            self = value.isEmpty ? .empty : .rows(value, refreshing: isFetching)
        case .failed(let error):
            self = .failed(L10n.Errors.message(for: error))
        case .loading:
            self = .loading
        }
    }

    /// Header meta from count copy, or none when there are no rows.
    /// Takes formatters (not MainActor kind methods) so tests and callers can
    /// pass L10n without crossing isolation.
    func meta(count: (Int) -> String, refreshing: (Int) -> String) -> String? {
        guard case .rows(let rows, let isRefreshing) = self, !rows.isEmpty else { return nil }
        return isRefreshing ? refreshing(rows.count) : count(rows.count)
    }
}

/// One Conclude list: what `ConclusionListPage` needs to know about a kind.
/// Persons, Events, and Places each conform once; the page owns the chrome,
/// the query handle, and navigation. Each kind stays its own place: its
/// query key and the location a row opens.
protocol ConclusionListKind {
    associatedtype Row: CatalogListRow & Equatable
    associatedtype Secondary: View

    static func key(project: ProjectKey) -> CatalogQueryKey
    static var title: LocalizedStringResource { get }
    /// Stable identifier root: `<root>.list`, `<root>.empty`, `<root>.row.<ref>`.
    static var identifierRoot: String { get }
    static var emptyTitle: LocalizedStringResource { get }
    static var emptyMessage: LocalizedStringResource { get }
    static func countMeta(_ count: Int) -> String
    static func refreshingMeta(_ count: Int) -> String
    static var mark: PVMarkKey { get }

    static func ref(_ row: Row) -> String
    /// RFC3339 UTC time of the row's last revision; empty when unknown.
    static func updatedAt(_ row: Row) -> String
    /// The `objects/…` path of the row's thumbnail image; "" shows the kind's mark.
    static func thumbnailRelPath(_ row: Row) -> String
    static func titleSource(_ row: Row) -> PVTitleSource
    static func titleSource(_ row: Row, orders: NameFormatOrders) -> PVTitleSource
    /// Names beyond the one shown. Zero omits the +N badge.
    static func extraCount(_ row: Row) -> Int
    static func accessibilityLabel(_ row: Row) -> String
    static func accessibilityLabel(_ row: Row, orders: NameFormatOrders) -> String
    static func location(_ row: Row) -> WorkspaceLocation
    static func location(_ row: Row, orders: NameFormatOrders) -> WorkspaceLocation
    @MainActor static func secondary(_ row: Row) -> Secondary
}

extension ConclusionListKind {
    static func extraCount(_: Row) -> Int { 0 }

    static func titleSource(_ row: Row, orders: NameFormatOrders) -> PVTitleSource {
        titleSource(row)
    }

    static func accessibilityLabel(_ row: Row, orders: NameFormatOrders) -> String {
        accessibilityLabel(row)
    }

    static func location(_ row: Row, orders: NameFormatOrders) -> WorkspaceLocation {
        location(row)
    }
}

/// The shared Conclude list page for one kind. This view does not choose a
/// section or push history.
struct ConclusionListPage<Kind: ConclusionListKind>: View {
    let session: WorkspaceSession

    private var key: CatalogQueryKey { Kind.key(project: session.projectKey) }

    var body: some View {
        Group {
            if let handle: QueryHandle<CatalogListRows<Kind.Row>> = session.queryHandle(key) {
                ConclusionListBody<Kind>(handle: handle)
            } else {
                ConclusionListFrame(title: Kind.title, meta: nil, identifierRoot: Kind.identifierRoot) { gutter in
                    Self.loadingArea(gutter: gutter)
                }
            }
        }
        .task {
            let _: QueryHandle<CatalogListRows<Kind.Row>> = session.query(key)
        }
    }

    /// First-load placeholder with the last-updated column bar, so rows do not
    /// shift when the times arrive: 30 rows fill the list area.
    static func loadingArea(gutter: CGFloat) -> some View {
        PVListSkeleton(rows: 30, detailWidth: PVLastUpdated.columnWidth, horizontalInset: gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
    }

    /// No records of this kind: the empty state, centered in the list area.
    static func emptyArea() -> some View {
        PVEmptyState(
            glyph: .mark(Kind.mark),
            title: Kind.emptyTitle,
            message: L10n.string(Kind.emptyMessage)
        )
        .accessibilityIdentifier("\(Kind.identifierRoot).empty")
    }

    /// The read failed with nothing to show: the danger Callout at the top of the list area.
    static func failureArea(_ message: String, gutter: CGFloat) -> some View {
        PVCallout(tone: .danger, message: message)
            .pvListPageMessage(gutter: gutter, maxWidth: PVSpacing.measureForm)
    }
}

/// Page chrome shared by every state: the list page header across the pane on the page surface, a
/// full-width hairline, then the list area filling the rest of the pane on the card surface. The
/// gutter is chosen once, here, from the width class, and handed to the area.
private struct ConclusionListFrame<Content: View>: View {
    let title: LocalizedStringResource
    let meta: String?
    let identifierRoot: String
    @ViewBuilder let content: (CGFloat) -> Content

    @Environment(\.pvWidthClass) private var widthClass

    var body: some View {
        let gutter = widthClass.fullPaneGutter
        VStack(spacing: 0) {
            PVListPageHeader(title: title, countLine: meta, identifierPrefix: identifierRoot, gutter: gutter)
                .background(PVColor.surfacePage)
            PVDivider()
            content(gutter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PVColor.surfaceCard)
        }
        .background(PVColor.surfacePage)
        .accessibilityIdentifier("\(identifierRoot).list")
    }
}

private struct ConclusionListBody<Kind: ConclusionListKind>: View {
    @Bindable var handle: QueryHandle<CatalogListRows<Kind.Row>>
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(WorkspaceSession.self) private var session

    private var presentation: ConclusionListPresentation<Kind.Row> {
        ConclusionListPresentation(handle.read.map(\.rows), isFetching: handle.isFetching)
    }

    private var headerMeta: String? {
        guard case .rows(let rows, let isRefreshing) = presentation, !rows.isEmpty else { return nil }
        return isRefreshing
            ? Kind.refreshingMeta(rows.count)
            : Kind.countMeta(rows.count)
    }

    var body: some View {
        ConclusionListFrame(title: Kind.title, meta: headerMeta, identifierRoot: Kind.identifierRoot) { gutter in
            switch presentation {
            case .loading:
                ConclusionListPage<Kind>.loadingArea(gutter: gutter)
            case .empty:
                ConclusionListPage<Kind>.emptyArea()
            case .failed(let message):
                ConclusionListPage<Kind>.failureArea(message, gutter: gutter)
            case .rows(let rows, _):
                PVList(
                    // Go owns list order (conclusionsummaries.SortByTitle); rows show as given.
                    items: rows,
                    // Navigation owns the selected row: it is the row history stamps on leaving.
                    selection: Binding(
                        get: { navigation.listAnchor },
                        set: { navigation.noteListAnchor($0) }
                    ),
                    thumbnail: {
                        CachedThumbnail(
                            projectDir: session.projectKey.projectDir,
                            relPath: Kind.thumbnailRelPath($0),
                            fallbackMark: Kind.mark
                        )
                    },
                    meta: { Kind.ref($0) },
                    detail: ConclusionListRow.updatedColumn(Kind.self),
                    horizontalInset: gutter,
                    label: Kind.title,
                    itemAccessibilityLabel: {
                        PVLastUpdated.label(
                            Kind.accessibilityLabel($0, orders: session.nameFormat),
                            updatedAt: Kind.updatedAt($0),
                            in: .current
                        )
                    },
                    itemAccessibilityIdentifier: { "\(Kind.identifierRoot).row.\(Kind.ref($0))" },
                    onActivate: { navigation.go(to: Kind.location($0, orders: session.nameFormat)) },
                    primary: { PVTitleText(Kind.titleSource($0, orders: session.nameFormat), extraCount: Kind.extraCount($0)) },
                    secondary: { Kind.secondary($0) }
                )
            }
        }
        .modifier(ListSelectionAnchorModifier(rowIDs: rowIDs, isSettled: handle.isSettled))
    }

    private var rowIDs: [String] {
        guard case .rows(let rows, _) = presentation else { return [] }
        return rows.map(\.id)
    }
}

#if DEBUG
/// One state of the list page at a pane width, on the width class that width measures.
@MainActor
private func conclusionListStatePreview<Area: View>(
    width: CGFloat, @ViewBuilder area: @escaping (CGFloat) -> Area
) -> some View {
    ConclusionListFrame(title: PersonsList.title, meta: nil, identifierRoot: PersonsList.identifierRoot, content: area)
        .environment(\.pvWidthClass, PVWidthClass(paneWidth: width))
        .frame(width: width, height: 480)
}

#Preview("Empty") {
    VStack(spacing: PVSpacing.space8) {
        conclusionListStatePreview(width: 1102) { _ in ConclusionListPage<PersonsList>.emptyArea() }
        conclusionListStatePreview(width: 2296) { _ in ConclusionListPage<PersonsList>.emptyArea() }
    }
}

#Preview("Failed") {
    VStack(spacing: PVSpacing.space8) {
        conclusionListStatePreview(width: 1102) { gutter in
            ConclusionListPage<PersonsList>.failureArea("The catalog could not be read.", gutter: gutter)
        }
        conclusionListStatePreview(width: 2296) { gutter in
            ConclusionListPage<PersonsList>.failureArea("The catalog could not be read.", gutter: gutter)
        }
    }
}
#endif
