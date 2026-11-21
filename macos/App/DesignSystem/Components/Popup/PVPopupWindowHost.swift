import AppKit
import SwiftUI

/// The one child-panel host of a floating popup: a borderless, non-activating
/// panel at `.popUpMenu` level that never becomes key or main, shown as a child
/// above its anchor's window, and kept in step when that window moves or
/// resizes or the pane the anchor sits in scrolls. It decides nothing about
/// where the panel goes or when it closes: its owner frames it (the context
/// menu at a point, the popup list against a rect) and `.pvPopup` closes it.
@MainActor
final class PVPopupWindowHost {
    /// The view the popup hangs from; its window is the panel's parent.
    weak var anchor: NSView?
    /// The parent moved or resized, or the anchor's enclosing scroll view
    /// scrolled: the owner frames the panel again.
    var onFollow: () -> Void = {}

    private let hasShadow: Bool
    private let hosting: PVPopupWindowHostingView
    private var panel: PVPopupWindowPanel?
    private var observers: [NSObjectProtocol] = []

    /// `hasShadow`: AppKit derives the panel's shadow from its alpha, so rounded
    /// content gets a correctly shaped native shadow; a menu whose chrome draws
    /// its own turns it off.
    init(hasShadow: Bool) {
        self.hasShadow = hasShadow
        hosting = PVPopupWindowHostingView(rootView: AnyView(EmptyView()))
    }

    var isShown: Bool { panel?.parent != nil }

    var rootView: AnyView {
        get { hosting.rootView }
        set { hosting.rootView = newValue }
    }

    var fittingSize: CGSize { hosting.fittingSize }

    /// Frames the panel and adds it as a child above the anchor's window. A
    /// no-op when it is already shown or the anchor has no window.
    func show(at frame: CGRect) {
        guard let parent = anchor?.window else { return }
        let panel = self.panel ?? makePanel()
        self.panel = panel
        guard panel.parent == nil else { return }
        panel.setFrame(frame, display: true)
        if hasShadow { panel.invalidateShadow() }
        parent.addChildWindow(panel, ordered: .above)
        startFollowing(parent: parent)
    }

    /// A no-op when the panel already has this frame.
    func setFrame(_ frame: CGRect) {
        guard let panel, panel.frame != frame else { return }
        panel.setFrame(frame, display: true)
        if hasShadow { panel.invalidateShadow() }
    }

    func hide() {
        guard let panel, panel.parent != nil else { return }
        stopFollowing()
        panel.parent?.removeChildWindow(panel)
        panel.orderOut(nil)
    }

    func tearDown() {
        stopFollowing()
        if let panel {
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }
        panel = nil
    }

    private func makePanel() -> PVPopupWindowPanel {
        let created = PVPopupWindowPanel(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        created.isOpaque = false
        created.backgroundColor = .clear
        created.hasShadow = hasShadow
        created.level = .popUpMenu
        created.animationBehavior = .none
        created.contentView = hosting
        return created
    }

    // MARK: Following

    private func startFollowing(parent: NSWindow) {
        stopFollowing()
        let center = NotificationCenter.default
        // Follow the anchor when the window moves or resizes, and when the pane
        // it lives in scrolls: a detached popup is worse than none.
        for name in [NSWindow.didMoveNotification, NSWindow.didResizeNotification] {
            observers.append(center.addObserver(forName: name, object: parent, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.onFollow() }
            })
        }
        if let clip = anchor?.enclosingScrollView?.contentView {
            clip.postsBoundsChangedNotifications = true
            observers.append(
                center.addObserver(forName: NSView.boundsDidChangeNotification, object: clip, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.onFollow() }
                }
            )
        }
    }

    private func stopFollowing() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }
}

/// Borderless popup that never takes key focus, so the field behind it keeps
/// handling arrows, Return and Escape while the popup is open.
private final class PVPopupWindowPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Hosting view for the popup's content. Rows commit on the first click, so a
/// click arriving while the app is inactive still lands on the row instead of
/// being swallowed to activate the app.
private final class PVPopupWindowHostingView: NSHostingView<AnyView> {
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
