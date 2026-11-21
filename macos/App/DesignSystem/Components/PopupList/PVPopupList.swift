import AppKit
import SwiftUI

extension View {
    /// The kit popup list: `content` in its own borderless window under this
    /// view (or, with `anchorRect`, at a rect on screen: a text caret), placed
    /// by `PVPopupListPlacement` and closed through `.pvPopup`. `isMeasured`
    /// holds the window down until the caller has measured its rows. The field
    /// keeps focus and its keys (`keysStayInField`) and stays open on a click in
    /// its own area (`staysOpenOnFieldClick`); it holds one `PVPopupListHighlight`.
    /// `PVComboBox`, `PVTextArea`'s completion list and the omnibar's results all
    /// present through it. A list wider than its field passes `width`, and
    /// `alignment` says which of the field's edges it keeps (`.trailing`: the
    /// list's trailing edge is the field's, and it grows leftward).
    func pvPopupList<Content: View>(
        isPresented: Binding<Bool>,
        isMeasured: Bool = true,
        maxHeight: CGFloat,
        contentHeight: CGFloat,
        optionCount: Int,
        width: CGFloat? = nil,
        alignment: HorizontalEdge = .leading,
        anchorRect: (() -> CGRect?)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        background(
            PVPopupListWindow(
                isPresented: isPresented.wrappedValue && isMeasured,
                maxHeight: maxHeight,
                contentHeight: contentHeight,
                optionCount: optionCount,
                width: width,
                alignment: alignment,
                anchorRect: anchorRect,
                content: content()
            )
        )
        .pvPopup(
            isPresented: isPresented,
            options: PVPopupOptions(keysStayInField: true, staysOpenOnFieldClick: true)
        )
    }
}

/// Hosts `content` in a borderless child window anchored to the view this is
/// a background of (or, with `anchorRect`, to a rect on screen: a text caret).
/// It sits in the view tree only to get hold of an `NSView` to measure
/// against — it draws nothing itself, and it never closes: `.pvPopup` does.
private struct PVPopupListWindow<Content: View>: NSViewRepresentable {
    let isPresented: Bool
    let maxHeight: CGFloat
    /// The height the content wants, measured by the caller (see
    /// `PVPopupListMeasure`).
    let contentHeight: CGFloat
    /// How many rows the list is showing. Together with `contentHeight` this
    /// is what decides whether the window needs re-framing — SwiftUI hands us
    /// a fresh `content` on every update, so the values are compared instead.
    let optionCount: Int
    /// A width of its own, in points; nil is the anchor's width (a field).
    var width: CGFloat?
    /// The anchor edge a list with its own `width` keeps.
    var alignment: HorizontalEdge = .leading
    /// The anchor in AppKit screen coordinates, read each time the popup is
    /// framed; nil is the frame of the view this is a background of.
    var anchorRect: (() -> CGRect?)?
    let content: Content

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.anchor = view
        return view
    }

    func updateNSView(_: NSView, context: Context) {
        let coordinator = context.coordinator
        coordinator.maxHeight = maxHeight
        coordinator.contentHeight = contentHeight
        coordinator.optionCount = optionCount
        coordinator.width = width
        coordinator.alignment = alignment
        coordinator.anchorRect = anchorRect
        coordinator.wantsPresented = isPresented
        // Rows in the popup see what the field sees: the host's environment
        // (a session, `isEnabled`) does not cross into a child window by itself.
        coordinator.setContent(content.environment(\.self, context.environment))
        // Showing or moving a window mutates AppKit state, which must not
        // happen inside SwiftUI's layout pass — hence the hop. The closure
        // deliberately captures no values: `applyPresentation` reads the
        // coordinator's *current* fields, so a closure queued before a
        // dismissal cannot re-show the panel with stale state.
        DispatchQueue.main.async {
            coordinator.applyPresentation()
        }
    }

    static func dismantleNSView(_: NSView, coordinator: Coordinator) {
        coordinator.tearDown()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        weak var anchor: NSView? {
            didSet { host.anchor = anchor }
        }
        var maxHeight: CGFloat = 288
        var contentHeight: CGFloat = 0
        var optionCount = 0
        var width: CGFloat?
        var alignment: HorizontalEdge = .leading
        var anchorRect: (() -> CGRect?)?
        /// The single source of truth for whether the panel should be up,
        /// written synchronously by every `updateNSView`. `applyPresentation`
        /// mirrors it into AppKit, so a deferred show can never re-open a list
        /// the presenter closed.
        var wantsPresented = false

        private let host = PVPopupWindowHost(hasShadow: true)
        /// Kept unwidened so `frame()` can re-wrap it at the field's width.
        private var content: AnyView = AnyView(EmptyView())
        /// The size metrics the panel was last framed for; `nil` while it is
        /// down. Comparing against this is what keeps re-framing (which is
        /// disruptive mid-interaction) to actual size changes.
        private var framed: Framed?

        private struct Framed: Equatable {
            let height: CGFloat
            let count: Int
            let width: CGFloat?
        }

        init() {
            host.onFollow = { [weak self] in self?.position() }
        }

        func setContent(_ content: some View) {
            self.content = AnyView(content)
            if let width = host.frame?.width {
                host.rootView = widened(to: width)
            }
        }

        /// The popup is exactly as wide as the field (or its own `width`), and
        /// measuring it at that width is what makes `fittingSize` trustworthy — an unconstrained
        /// `NSHostingView` reports the height its content would take at its
        /// *ideal* width, which is not the width we are about to give it.
        private func widened(to width: CGFloat) -> AnyView {
            AnyView(content.frame(width: width))
        }

        /// Brings the panel in line with `wantsPresented` and the current
        /// content metrics. Idempotent, and always reads current state — it
        /// is safe to call from a stale queued closure.
        func applyPresentation() {
            guard wantsPresented else {
                hide()
                return
            }
            let current = Framed(height: contentHeight, count: optionCount, width: width)
            if !host.isShown {
                show()
                framed = current
            } else if framed != current {
                // Re-frame when the rows or the width changed, not on every
                // SwiftUI update.
                framed = current
                position()
            }
        }

        // MARK: Show / hide

        private func show() {
            guard let frame = frame() else { return }
            host.show(at: frame)
        }

        private func hide() {
            framed = nil
            host.hide()
        }

        func tearDown() {
            host.tearDown()
        }

        // MARK: Geometry

        /// Sizes the panel to its content (clamped by `maxHeight` and by the
        /// room on screen) and puts it just outside the field. Nil without an
        /// anchor window.
        private func frame() -> CGRect? {
            guard let anchor, let window = anchor.window else { return nil }
            var anchorOnScreen = anchorRect?() ?? window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
            anchorOnScreen = PVPopupListPlacement.anchorFrame(anchorOnScreen, width: width, alignment: alignment)

            host.rootView = widened(to: anchorOnScreen.width)
            let wanted = min(contentHeight, maxHeight)

            let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? anchorOnScreen
            let frame = PVPopupListPlacement.popupFrame(
                anchor: anchorOnScreen,
                contentHeight: wanted,
                visibleFrame: visible
            )
            return frame
        }

        private func position() {
            guard host.isShown, let frame = frame() else { return }
            host.setFrame(frame)
        }
    }
}

// MARK: - The list inside the window

/// The list every caller of `.pvPopupList` draws in the window: the card (fill,
/// stroke, radius), the scroller that keeps the highlighted row in view, and the
/// caller's row stack. The caller builds the stack from `PVPopupListRow` and
/// `PVPopupListLine`, and picks `VStack` (rows of unequal height, measured before
/// the window shows: `PVComboBox`) or `LazyVStack` (a fixed row height sizes the
/// window: `PVTextArea`'s completion list).
struct PVPopupListCard<Stack: View>: View {
    /// The `id` of each row, in order; a new list goes back to its first row.
    let rowIDs: [String]
    /// The highlighted row's id, or nil.
    let activeID: String?
    var verticalPadding: CGFloat = defaultVerticalPadding
    @ViewBuilder let stack: Stack

    /// Air above and below the rows, inside the card's border.
    static var defaultVerticalPadding: CGFloat { PVSpacing.space2 }

    /// How tall a card wants to be around `rows` points of rows: the rows plus
    /// the padding above and below.
    static func height(rows: CGFloat, verticalPadding: CGFloat = defaultVerticalPadding) -> CGFloat {
        rows + verticalPadding * 2
    }

    var body: some View {
        ScrollView {
            stack
        }
        .pvScrollsRowIntoView(activeID, startsAtTopWhenRowsChange: rowIDs)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: PVRadius.md, style: .continuous)
                .fill(PVColor.surfaceCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PVRadius.md, style: .continuous)
                .strokeBorder(PVColor.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: PVRadius.md, style: .continuous))
        // No `.pvShadow`: the popup is its own window, so AppKit casts the
        // shadow from the window's alpha (README "Platform deviations").
    }
}

/// One row's shell: the highlight fill, the hit area, and the pointer and
/// keyboard sharing one highlight (hovering a row makes it the active one). The
/// caller draws the row inside it, padding and all.
struct PVPopupListRow<Content: View>: View {
    let isActive: Bool
    /// The committed or selected row, for VoiceOver.
    var isSelected = false
    var isDisabled = false
    /// The pointer moved onto this row.
    let onHighlight: () -> Void
    /// A click, or VoiceOver's default action.
    let onCommit: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isActive ? PVColor.surfaceSelected : .clear)
            .opacity(isDisabled ? 0.42 : 1)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside, !isDisabled { onHighlight() }
            }
            // The sole commit path for a click. The popup window never becomes
            // key, but mouse events still reach the window under the pointer.
            .onTapGesture(perform: onCommit)
            .accessibilityAction(.default, onCommit)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// The line a list shows in place of rows: the empty line, or the searching
/// line. Its text starts at the column `gutter` points in, where a row's label does.
struct PVPopupListLine<Content: View>: View {
    var gutter: CGFloat = 0
    var minHeight: CGFloat?
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .padding(.leading, gutter + PVSpacing.space5)
            .padding(.trailing, PVSpacing.space5)
            .padding(.vertical, minHeight == nil ? PVSpacing.space4 : 0)
    }
}

/// A hidden, non-interactive copy of a list's rows, laid out behind the field
/// purely to measure them. The caller mounts it only while the list is open.
///
/// The popup window has to know how tall to be *before* it is shown, and a
/// `ScrollView` inside that window cannot tell it, nor can
/// `NSHostingView.fittingSize`, reliably. Laying the rows out once more here is
/// the honest way to get the number: a background never influences its parent's
/// size, so this costs a layout pass and nothing else. Give it the `width` the
/// window will be when that is not the field's, so a wrapping line measures as
/// it will draw. The caller holds the height and the window waits for it.
struct PVPopupListMeasure<Rows: View>: View {
    let isActive: Bool
    var width: CGFloat?
    let onHeight: (CGFloat) -> Void
    @ViewBuilder let rows: Rows

    var body: some View {
        rows
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.height, initial: true) { _, height in
                            guard isActive, height > 0 else { return }
                            onHeight(height)
                        }
                }
            )
    }
}

/// The rows' height a caller measured through `PVPopupListMeasure`, and
/// whether one has come in yet. The window stays down until it has.
struct PVPopupListMeasurement: Equatable {
    var height: CGFloat = 0
    var isMeasured = false

    mutating func record(_ height: CGFloat) {
        self.height = height
        isMeasured = true
    }

    mutating func reset() {
        self = PVPopupListMeasurement()
    }
}

/// What a list draws: its rows, the searching line, or the caller's empty
/// line. Rows already in stay on screen while a new search runs; the searching
/// line shows only when there is nothing else to show. A failed search is the
/// caller's empty line.
enum PVPopupListLineKind: Equatable {
    /// The rows alone.
    case rows
    /// The searching line: results are loading and none are in yet.
    case loading
    /// The caller's empty line.
    case empty

    static func of(rowCount: Int, isLoading: Bool) -> PVPopupListLineKind {
        if rowCount > 0 { return .rows }
        return isLoading ? .loading : .empty
    }
}

/// The line a list shows while a remote search runs and no results are in yet.
/// Its text starts at the column `gutter` points in, where a row's label does.
struct PVPopupListSearchingLine: View {
    var gutter: CGFloat = 0

    var body: some View {
        PVPopupListLine(gutter: gutter) {
            HStack(spacing: PVSpacing.space3) {
                ProgressView()
                    .controlSize(.small)
                Text(L10n.DesignSystem.popupListSearching)
                    .font(PVFont.body(size: PVTypeScale.bodySmall))
                    .foregroundStyle(PVColor.textMuted)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The highlight

/// The one highlight of a popup list: which row is active, and how a key, a
/// landing and the pointer move it. The pointer and the keyboard drive the same
/// value. Return is the field's, not the list's. Each field holds one.
struct PVPopupListHighlight: Equatable {
    /// Rows a Page Up or Page Down moves.
    static let pageStep = 8

    /// The active row, or -1 for none.
    private(set) var index: Int

    init(index: Int = -1) {
        self.index = index
    }

    /// Return and keypad Enter: the keys that commit the active row.
    static func isCommitKey(_ key: KeyEquivalent) -> Bool {
        key == .return || key == KeyEquivalent("\u{3}")
    }

    /// The keys `move` takes: ↑, ↓, Home, End, Page Up and Page Down.
    static func isMovementKey(_ key: KeyEquivalent) -> Bool {
        PVListKeyboard.moveIndex(for: key, option: false, index: -1, count: 1) != nil
    }

    /// Clamped, no wrap, steps over disabled rows; ⌘ with ↑/↓ jumps to an end.
    /// Any other key leaves the index.
    mutating func move(_ key: KeyEquivalent, command: Bool, count: Int, isDisabled: (Int) -> Bool) {
        guard let next = PVListKeyboard.moveIndex(
            for: key, option: command, index: index, count: count,
            isDisabled: isDisabled, pageStep: Self.pageStep
        ) else { return }
        index = next
    }

    /// The Spotlight landing: the first enabled row, or -1 when there is none.
    mutating func land(count: Int, isDisabled: (Int) -> Bool) {
        index = PVFloatingMenuSelection.moveIndex(from: -1, delta: 1, count: count, isDisabled: isDisabled)
    }

    /// The pointer is over `row`: an enabled row in range becomes the active one.
    mutating func hover(at row: Int, count: Int, isDisabled: (Int) -> Bool) {
        guard (0..<count).contains(row), !isDisabled(row) else { return }
        index = row
    }

    mutating func clear() {
        index = -1
    }

    /// The active row when it is one of `count` rows.
    func current(count: Int) -> Int? {
        (0..<count).contains(index) ? index : nil
    }
}

/// Where a popup list's window sits relative to its anchor.
enum PVPopupListPlacement {
    /// Air between the field and its list.
    static let gap: CGFloat = 4

    /// The anchor a list with its own `width` hangs from: nil `width` is the
    /// anchor itself; `.leading` keeps its `minX`, `.trailing` its `maxX`.
    static func anchorFrame(_ anchor: CGRect, width: CGFloat?, alignment: HorizontalEdge) -> CGRect {
        guard let width else { return anchor }
        var frame = anchor
        frame.size.width = width
        if alignment == .trailing { frame.origin.x = anchor.maxX - width }
        return frame
    }

    /// The width of a list that hangs from `edgeX` inside a column `columnWidth`
    /// wide, both measured from the column's left edge. It keeps `inset` clear
    /// of the column's edge on the side it grows toward (`.trailing`: leftward,
    /// `.leading`: rightward), never goes under `minimum`, and is `preferred`
    /// while the column's width is not yet known (0).
    static func fittedWidth(
        preferred: CGFloat,
        hangsFrom edgeX: CGFloat,
        alignment: HorizontalEdge,
        columnWidth: CGFloat,
        minimum: CGFloat = 0,
        inset: CGFloat = PVSpacing.space6
    ) -> CGFloat {
        guard columnWidth > 0 else { return preferred }
        let room = alignment == .trailing ? edgeX - inset : columnWidth - edgeX - inset
        return max(minimum, min(preferred, room))
    }

    /// Screen frame for the popup window. All rects are AppKit **screen**
    /// coordinates, so y grows upward and "below the field" means a smaller
    /// y than the field's `minY`.
    ///
    /// The popup is placed strictly outside the anchor — it can never cover
    /// the text you are typing into — and always inside `visibleFrame`, so it
    /// cannot run off the display. It prefers to open downward and flips
    /// above the field only when it does not fit below *and* there is more
    /// room up there; whichever side it lands on, the height is trimmed to
    /// the space actually available, leaving the list to scroll inside it.
    static func popupFrame(
        anchor: CGRect,
        contentHeight: CGFloat,
        visibleFrame: CGRect,
        gap: CGFloat = gap
    ) -> CGRect {
        let spaceBelow = max(0, anchor.minY - visibleFrame.minY - gap)
        let spaceAbove = max(0, visibleFrame.maxY - anchor.maxY - gap)
        let opensUp = contentHeight > spaceBelow && spaceAbove > spaceBelow
        let height = min(contentHeight, opensUp ? spaceAbove : spaceBelow)
        let y = opensUp ? anchor.maxY + gap : anchor.minY - gap - height
        let width = min(anchor.width, visibleFrame.width)
        let x = min(max(anchor.minX, visibleFrame.minX), visibleFrame.maxX - width)
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
