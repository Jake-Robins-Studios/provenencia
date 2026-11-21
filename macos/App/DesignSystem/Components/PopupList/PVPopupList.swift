import AppKit
import SwiftUI

extension View {
    /// The kit popup list: `content` in its own borderless window under this
    /// view (or, with `anchorRect`, at a rect on screen: a text caret), placed
    /// by `PVPopupListPlacement` and closed through `.pvPopup`. `isMeasured`
    /// holds the window down until the caller has measured its rows. The field
    /// keeps focus and its keys (`keysStayInField`) and stays open on a click in
    /// its own area (`staysOpenOnFieldClick`); it holds one `PVPopupListHighlight`.
    /// `PVComboBox` and `PVTextArea`'s completion list both present through it.
    func pvPopupList<Content: View>(
        isPresented: Binding<Bool>,
        isMeasured: Bool = true,
        maxHeight: CGFloat,
        contentHeight: CGFloat,
        optionCount: Int,
        width: CGFloat? = nil,
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
    /// `PVComboBox.measuringRows`).
    let contentHeight: CGFloat
    /// How many rows the list is showing. Together with `contentHeight` this
    /// is what decides whether the window needs re-framing — SwiftUI hands us
    /// a fresh `content` on every update, so the values are compared instead.
    let optionCount: Int
    /// A width of its own, in points; nil is the anchor's width (a field).
    var width: CGFloat?
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
        var anchorRect: (() -> CGRect?)?
        /// The single source of truth for whether the panel should be up,
        /// written synchronously by every `updateNSView`. `applyPresentation`
        /// mirrors it into AppKit, so a deferred show can never re-open a list
        /// the presenter closed.
        var wantsPresented = false

        private let host = PVPopupWindowHost(hasShadow: true)
        /// Kept unwidened so `frame()` can re-wrap it at the field's width.
        private var content: AnyView = AnyView(EmptyView())
        /// The width the panel was last framed at.
        private var shownWidth: CGFloat = 0
        /// The content metrics the panel was last framed for; `nil` while it
        /// is down. Comparing against these is what keeps re-framing (which
        /// is disruptive mid-interaction) to actual size changes.
        private var shownHeight: CGFloat?
        private var shownCount: Int?

        init() {
            host.onFollow = { [weak self] in self?.position() }
        }

        func setContent(_ content: some View) {
            self.content = AnyView(content)
            if host.isShown {
                host.rootView = widened(to: shownWidth)
            }
        }

        /// The popup is exactly as wide as the field, and measuring it at that
        /// width is what makes `fittingSize` trustworthy — an unconstrained
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
            if !host.isShown {
                show()
                shownHeight = contentHeight
                shownCount = optionCount
            } else if shownHeight != contentHeight || shownCount != optionCount {
                // Re-frame when the rows changed, not on every SwiftUI update.
                shownHeight = contentHeight
                shownCount = optionCount
                position()
            }
        }

        // MARK: Show / hide

        private func show() {
            guard let frame = frame() else { return }
            host.show(at: frame)
        }

        private func hide() {
            shownHeight = nil
            shownCount = nil
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
            if let width { anchorOnScreen.size.width = width }

            host.rootView = widened(to: anchorOnScreen.width)
            let wanted = min(contentHeight, maxHeight)

            let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? anchorOnScreen
            let frame = PVPopupListPlacement.popupFrame(
                anchor: anchorOnScreen,
                contentHeight: wanted,
                visibleFrame: visible
            )
            shownWidth = frame.width
            return frame
        }

        private func position() {
            guard host.isShown, let frame = frame() else { return }
            host.setFrame(frame)
        }
    }
}

// MARK: - The list inside the window

/// The list both callers of `.pvPopupList` draw in the window: the card (fill,
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
    var verticalPadding: CGFloat = PVSpacing.space2
    @ViewBuilder let stack: Stack

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
