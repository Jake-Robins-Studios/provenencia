import AppKit
import SwiftUI

/// Hosts `content` in a borderless child window anchored to the view this is
/// a background of (or, with `anchorRect`, to a rect on screen: a text caret).
/// It sits in the view tree only to get hold of an `NSView` to measure
/// against — it draws nothing itself. `PVComboBox` and `PVTextArea`'s
/// completion list both present through it.
struct PVPopupList<Content: View>: NSViewRepresentable {
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
    let onDismiss: () -> Void
    let content: Content

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.anchor = view
        return view
    }

    func updateNSView(_: NSView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onDismiss = onDismiss
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
        weak var anchor: NSView?
        var onDismiss: () -> Void = {}
        var maxHeight: CGFloat = 288
        var contentHeight: CGFloat = 0
        var optionCount = 0
        var width: CGFloat?
        var anchorRect: (() -> CGRect?)?
        /// The single source of truth for whether the panel should be up,
        /// written synchronously by every `updateNSView` and by `dismiss()`.
        /// `applyPresentation` mirrors it into AppKit.
        var wantsPresented = false

        private var panel: PVPopupPanel?
        private var hosting: PVPopupHostingView?
        /// Kept unwidened so `position` can re-wrap it at the field's width.
        private var content: AnyView = AnyView(EmptyView())
        private var clickMonitor: Any?
        private var observers: [NSObjectProtocol] = []
        /// The content metrics the panel was last framed for; `nil` while it
        /// is down. Comparing against these is what keeps re-framing (which
        /// is disruptive mid-interaction) to actual size changes.
        private var shownHeight: CGFloat?
        private var shownCount: Int?

        func setContent(_ content: some View) {
            self.content = AnyView(content)
            if let hosting, let panel, panel.parent != nil {
                hosting.rootView = widened(to: panel.frame.width)
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
            if panel?.parent == nil {
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
            guard let anchor, let parent = anchor.window else { return }
            if hosting == nil {
                hosting = PVPopupHostingView(rootView: widened(to: width ?? anchor.bounds.width))
            }
            guard let hosting else { return }
            if panel == nil {
                let created = PVPopupPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                created.isOpaque = false
                created.backgroundColor = .clear
                // AppKit derives the shadow from the window's alpha, so the
                // rounded content gets a correctly-shaped native popup shadow.
                created.hasShadow = true
                created.level = .popUpMenu
                created.animationBehavior = .none
                created.contentView = hosting
                panel = created
            }
            guard let panel, panel.parent == nil else { return }
            position()
            parent.addChildWindow(panel, ordered: .above)
            startWatching(parent: parent)
        }

        private func hide() {
            shownHeight = nil
            shownCount = nil
            guard let panel, panel.parent != nil else { return }
            stopWatching()
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }

        func tearDown() {
            stopWatching()
            if let panel {
                panel.parent?.removeChildWindow(panel)
                panel.orderOut(nil)
            }
            panel = nil
            hosting = nil
        }

        // MARK: Geometry

        /// Sizes the panel to its content (clamped by `maxHeight` and by the
        /// room on screen) and puts it just outside the field.
        private func position() {
            guard let panel, let anchor, let window = anchor.window, let hosting else { return }
            var anchorOnScreen = anchorRect?() ?? window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
            if let width { anchorOnScreen.size.width = width }

            hosting.rootView = widened(to: anchorOnScreen.width)
            let wanted = min(contentHeight, maxHeight)

            let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? anchorOnScreen
            panel.setFrame(
                PVComboBoxPlacement.popupFrame(
                    anchor: anchorOnScreen,
                    contentHeight: wanted,
                    visibleFrame: visible
                ),
                display: true
            )
            panel.invalidateShadow()
        }

        // MARK: Dismissal

        /// SwiftUI does not resign a `TextField`'s focus when you click inert
        /// content, so "clicked away" has to be observed at the event level —
        /// the same job the web component's `mousedown` listener does.
        private func startWatching(parent: NSWindow) {
            clickMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] event in
                self?.handleMouseDown(event)
                return event
            }
            // No global monitor: a click in another app deactivates this one,
            // and the `didResignKeyNotification` observer below already
            // dismisses on that.

            let center = NotificationCenter.default
            // Follow the field when the window moves or resizes, and when the
            // pane it lives in scrolls — a detached popup is worse than none.
            for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification] {
                observers.append(center.addObserver(forName: name, object: parent, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.position() }
                })
            }
            observers.append(
                center.addObserver(forName: NSWindow.didResignKeyNotification, object: parent, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.dismiss() }
                }
            )
            if let clip = anchor?.enclosingScrollView?.contentView {
                clip.postsBoundsChangedNotifications = true
                observers.append(
                    center.addObserver(forName: NSView.boundsDidChangeNotification, object: clip, queue: .main) { [weak self] _ in
                        MainActor.assumeIsolated { self?.position() }
                    }
                )
            }
        }

        private func stopWatching() {
            if let clickMonitor {
                NSEvent.removeMonitor(clickMonitor)
            }
            clickMonitor = nil
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
        }

        /// Every mouse-down in the app while the popup is open lands here.
        /// There are exactly two things it can be: a click on a row — which
        /// the monitor passes through untouched, the row's own tap gesture
        /// commits it — or a click away. Anything that is not in the popup
        /// and not on the field itself dismisses — no exceptions, whether or
        /// not the thing clicked takes focus.
        private func handleMouseDown(_ event: NSEvent) {
            if let panel, event.window === panel { return }
            if let anchor, event.window === anchor.window {
                let point = anchor.convert(event.locationInWindow, from: nil)
                // Clicking the field it belongs to leaves the list up — the
                // caret moves, the list stays.
                if anchor.bounds.contains(point) { return }
            }
            dismiss()
        }

        /// A dismissal decided on the AppKit side (click away, window resigns
        /// key). Writing `wantsPresented` first means any queued
        /// `applyPresentation` agrees with the hide instead of undoing it;
        /// `onDismiss` then brings the SwiftUI state along.
        private func dismiss() {
            wantsPresented = false
            hide()
            onDismiss()
        }
    }
}

/// Borderless popup that never takes key focus, so the text field behind it
/// keeps handling arrows, Return and Escape while the list is open.
private final class PVPopupPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Hosting view for the popup's content. Rows commit on the first click, so a
/// click arriving while the app is inactive still lands on the row instead of
/// being swallowed to activate the app.
private final class PVPopupHostingView: NSHostingView<AnyView> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used — the popup is built in code")
    }

    @MainActor
    required init(rootView: AnyView) {
        super.init(rootView: rootView)
    }
}

// MARK: - The list inside the window

/// The list both callers of `PVPopupList` draw in the window: the card (fill,
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
