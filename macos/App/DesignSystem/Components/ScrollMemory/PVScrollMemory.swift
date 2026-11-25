import AppKit
import SwiftUI

/// What a page's scroll view is asked to remember: the y it was left at, and where to report the y as
/// the researcher scrolls. The workspace hands it to the kit through `\.pvScrollMemory`; the kit
/// knows nothing of navigation.
struct PVScrollMemory: Equatable, Sendable {
    /// Names one visit to a page. A change restores the scroll view again.
    let arrival: Int
    /// The y to restore. Nil once one has been noted in this visit: a scroll view mounted again starts
    /// at its top.
    let offset: @MainActor @Sendable () -> Double?
    /// Reports the live y, once the restore is over. Stores one number: no observation, no file write.
    let note: @MainActor @Sendable (Double) -> Void

    static func == (lhs: PVScrollMemory, rhs: PVScrollMemory) -> Bool {
        lhs.arrival == rhs.arrival
    }
}

private struct PVScrollMemoryKey: EnvironmentKey {
    static let defaultValue: PVScrollMemory? = nil
}

extension EnvironmentValues {
    /// The scroll memory of the page. Nil outside the workspace (a preview, a test) and inside the
    /// container that remembers the page's scroll.
    var pvScrollMemory: PVScrollMemory? {
        get { self[PVScrollMemoryKey.self] }
        set { self[PVScrollMemoryKey.self] = newValue }
    }
}

extension View {
    /// Makes the scroll view this content is in (or, for a `List` or `Table`, is the background of)
    /// open at the y it was left at, or at its top when it cannot show that y yet, checked again when
    /// its size changes until the researcher acts; it reports the y as the researcher scrolls. The
    /// kit's scroll containers (`PVPageColumns`, `PVTable`, `pvNativeListBehavior`) apply it; a plain
    /// `ScrollView` on a main page applies it to its content. One scroll view per page: a container
    /// inside one that remembers does not, and nothing happens outside the workspace.
    func pvRemembersScroll() -> some View {
        modifier(PVRemembersScroll())
    }
}

private struct PVRemembersScroll: ViewModifier {
    @Environment(\.pvScrollMemory) private var memory

    func body(content: Content) -> some View {
        if let memory {
            content
                .environment(\.pvScrollMemory, nil)
                .background(PVScrollMemoryProbe(memory: memory))
        } else {
            content
        }
    }
}

/// Finds the scroll view and follows its clip view, the way `PVPopupWindowHost` follows a window.
private struct PVScrollMemoryProbe: NSViewRepresentable {
    let memory: PVScrollMemory

    func makeCoordinator() -> PVScrollMemoryCoordinator {
        PVScrollMemoryCoordinator(memory: memory)
    }

    func makeNSView(context: Context) -> PVScrollMemoryProbeView {
        let view = PVScrollMemoryProbeView()
        view.coordinator = context.coordinator
        context.coordinator.probe = view
        return view
    }

    func updateNSView(_ view: PVScrollMemoryProbeView, context: Context) {
        context.coordinator.update(memory: memory)
    }

    static func dismantleNSView(_ view: PVScrollMemoryProbeView, coordinator: PVScrollMemoryCoordinator) {
        coordinator.detach()
    }
}

final class PVScrollMemoryProbeView: NSView {
    weak var coordinator: PVScrollMemoryCoordinator?

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        MainActor.assumeIsolated { coordinator?.attachIfNeeded() }
    }

    override func layout() {
        super.layout()
        MainActor.assumeIsolated { coordinator?.attachIfNeeded() }
    }
}

@MainActor
final class PVScrollMemoryCoordinator {
    weak var probe: PVScrollMemoryProbeView?
    private var memory: PVScrollMemory
    /// The y still to restore; nil once it is there or the researcher acted. While set, nothing is noted.
    private var pending: Double?
    private weak var scrollView: NSScrollView?
    private var observers: [NSObjectProtocol] = []
    /// Watches for the researcher's first act; held only while a y is pending.
    private var inputMonitor: Any?

    init(memory: PVScrollMemory) {
        self.memory = memory
    }

    // MARK: Following

    func update(memory: PVScrollMemory) {
        let arrived = memory.arrival != self.memory.arrival
        self.memory = memory
        if scrollView == nil {
            Task { @MainActor [weak self] in self?.attachIfNeeded() }
        } else if arrived {
            arm(memory.offset() ?? 0)
        }
    }

    func attachIfNeeded() {
        guard scrollView == nil, let probe, probe.window != nil, let found = Self.scrollView(for: probe) else { return }
        attach(found)
    }

    func detach() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        end()
        scrollView = nil
    }

    private func attach(_ scrollView: NSScrollView) {
        detach()
        self.scrollView = scrollView
        let center = NotificationCenter.default
        let clip = scrollView.contentView
        clip.postsBoundsChangedNotifications = true
        clip.postsFrameChangedNotifications = true
        observers.append(center.addObserver(forName: NSView.boundsDidChangeNotification, object: clip, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.boundsChanged() }
        })
        observers.append(center.addObserver(forName: NSView.frameDidChangeNotification, object: clip, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.restore() }
        })
        if let document = scrollView.documentView {
            document.postsFrameChangedNotifications = true
            observers.append(center.addObserver(forName: NSView.frameDidChangeNotification, object: document, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.restore() }
            })
        }
        // A view just mounted is at its top.
        if let y = memory.offset() { arm(y) }
    }

    // MARK: Restoring

    private func arm(_ y: Double) {
        end()
        pending = y
        inputMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.scrollWheel, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            MainActor.assumeIsolated {
                if let window = self?.scrollView?.window, event.window === window { self?.end() }
            }
            return event
        }
        restore()
    }

    /// Goes to the pending y when the view can show it now, else to the top. Next turn: the content is
    /// not laid out yet.
    private func restore() {
        guard pending != nil else { return }
        Task { @MainActor [weak self] in
            guard let self, let pending, let scrollView else { return }
            let fits = pending <= Self.reach(of: scrollView)
            if fits { end() }
            scroll(scrollView, to: fits ? pending : 0)
        }
    }

    /// The y is there, or the researcher scrolled or pressed a key or the mouse: the view is theirs.
    func end() {
        pending = nil
        inputMonitor.map(NSEvent.removeMonitor)
        inputMonitor = nil
    }

    private func boundsChanged() {
        guard pending == nil, let scrollView else { return }
        memory.note(Self.y(of: scrollView))
    }

    private func scroll(_ scrollView: NSScrollView, to y: Double) {
        guard Self.y(of: scrollView) != y else { return }
        let clip = scrollView.contentView
        clip.scroll(to: NSPoint(x: clip.bounds.minX, y: y - clip.contentInsets.top))
        scrollView.reflectScrolledClipView(clip)
    }

    /// 0 at the top, whatever the content.
    private static func y(of scrollView: NSScrollView) -> Double {
        Double(scrollView.contentView.bounds.minY + scrollView.contentView.contentInsets.top)
    }

    /// The farthest y the platform lets the view go to now.
    private static func reach(of scrollView: NSScrollView) -> Double {
        let clip = scrollView.contentView
        var far = clip.bounds
        far.origin.y = scrollView.documentView?.frame.maxY ?? 0
        return Double(clip.constrainBoundsRect(far).minY + clip.contentInsets.top)
    }

    // MARK: Finding the scroll view

    /// The scroll view the probe is inside (a `ScrollView`'s content), else the first one in an
    /// ancestor's subtree, up to six levels, whose window rect is the probe's (a `List` or `Table` the
    /// probe is the background of).
    private static func scrollView(for probe: NSView) -> NSScrollView? {
        if let enclosing = probe.enclosingScrollView { return enclosing }
        let rect = probe.convert(probe.bounds, to: nil)
        var ancestor = probe.superview
        var hops = 0
        while let current = ancestor, hops < 6 {
            if let found = firstScrollView(in: current, matching: rect, skipping: probe) { return found }
            ancestor = current.superview
            hops += 1
        }
        return nil
    }

    private static func firstScrollView(in view: NSView, matching rect: NSRect, skipping probe: NSView) -> NSScrollView? {
        if view === probe { return nil }
        if let scroll = view as? NSScrollView, scroll.convert(scroll.bounds, to: nil).isClose(to: rect) {
            return scroll
        }
        for child in view.subviews {
            if let found = firstScrollView(in: child, matching: rect, skipping: probe) { return found }
        }
        return nil
    }
}

private extension NSRect {
    func isClose(to other: NSRect, tolerance: CGFloat = 1) -> Bool {
        abs(minX - other.minX) <= tolerance && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance && abs(height - other.height) <= tolerance
    }
}
