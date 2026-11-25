import AppKit
import SwiftUI

/// The name of one scroll view on a page. A page with one scroll view uses `.page`; a page with a
/// second names its own. The raw value is written to navigation history files, so it is frozen once
/// a page ships it.
struct PVScrollSlot: RawRepresentable, Hashable, Sendable {
    let rawValue: String

    /// The page's own scroll view.
    static let page = PVScrollSlot(rawValue: "page")
}

/// What a page's scroll views are asked to remember: the y each was left at, and where to report the
/// y as the researcher scrolls. The workspace hands it to the kit through `\.pvScrollMemory`; the kit
/// knows nothing of navigation.
struct PVScrollMemory: Equatable, Sendable {
    /// Names one visit to a page. A change re-arms the restore of every scroll view under it.
    let arrival: Int
    /// The y to restore in a slot. Nil once the slot has been noted in this visit: a scroll view mounted
    /// again starts at its top.
    let offset: @MainActor @Sendable (PVScrollSlot) -> Double?
    /// Reports a slot's live y, once its restore is over. Stores one number: no observation, no file write.
    let note: @MainActor @Sendable (PVScrollSlot, Double) -> Void
    /// Slots a container above already remembers, so a nested scroll view never claims them.
    private(set) var claimed: Set<PVScrollSlot> = []

    init(
        arrival: Int,
        offset: @escaping @MainActor @Sendable (PVScrollSlot) -> Double?,
        note: @escaping @MainActor @Sendable (PVScrollSlot, Double) -> Void
    ) {
        self.arrival = arrival
        self.offset = offset
        self.note = note
    }

    static func == (lhs: PVScrollMemory, rhs: PVScrollMemory) -> Bool {
        lhs.arrival == rhs.arrival && lhs.claimed == rhs.claimed
    }

    fileprivate func claiming(_ slot: PVScrollSlot) -> PVScrollMemory {
        var copy = self
        copy.claimed.insert(slot)
        return copy
    }
}

private struct PVScrollMemoryKey: EnvironmentKey {
    static let defaultValue: PVScrollMemory? = nil
}

extension EnvironmentValues {
    /// The scroll memory of the page, nil outside the workspace (a preview, a test).
    var pvScrollMemory: PVScrollMemory? {
        get { self[PVScrollMemoryKey.self] }
        set { self[PVScrollMemoryKey.self] = newValue }
    }
}

/// When a scroll view moves to its remembered y, as a value. One per probe and arrival.
///
/// On arrival the view goes to its top. With a y, it asks for the y as far as the view can reach, again
/// each time the reach grows, and is done at the y; short of it, it stays armed at the top. While armed
/// nothing is noted. The researcher's first scroll, key or press ends it; once done, every y is noted.
struct PVScrollRestore: Equatable {
    private let offset: Double
    private(set) var isDone = false
    /// The farthest y the view has been able to show.
    private var reach = 0.0

    init(offset: Double?) {
        self.offset = offset ?? 0
    }

    /// Starts the restore at the view's current y. Returns the y to scroll to now (the top), nil when there.
    mutating func arm(currentY: Double) -> Double? {
        isDone = offset == 0
        return currentY == 0 ? nil : 0
    }

    /// The y to ask for now that the view reaches `reach`; nil when it has reached that far before.
    mutating func layout(reach: Double) -> Double? {
        guard !isDone, reach > self.reach else { return nil }
        self.reach = reach
        return min(offset, reach)
    }

    /// Where the view went. Done when it is the remembered y, within a point of the display's rounding.
    mutating func landed(_ y: Double) {
        if abs(y - offset) < 1 { isDone = true }
    }

    /// The researcher acted: the view stays where it is.
    mutating func input() {
        isDone = true
    }

    /// The y to note for a bounds change; nil while armed.
    func bounds(_ y: Double) -> Double? {
        isDone ? y : nil
    }
}

extension View {
    /// Makes the scroll view this content is in (or, for a `List` or `Table`, is the background of)
    /// open where it was left: on arrival it scrolls to the slot's remembered y as soon as it reaches
    /// that far, unless the researcher acts first, and waits at the top; it reports the y as the
    /// researcher scrolls. The kit's
    /// scroll containers (`PVPageColumns`, `PVTable`, `pvNativeListBehavior`) apply it; a plain
    /// `ScrollView` on a main page applies it to its content, naming its slot when it is not the
    /// page's only one. A slot a container above already remembers is not claimed again, and nothing
    /// happens outside the workspace.
    func pvRemembersScroll(_ slot: PVScrollSlot = .page) -> some View {
        modifier(PVRemembersScroll(slot: slot))
    }
}

private struct PVRemembersScroll: ViewModifier {
    let slot: PVScrollSlot
    @Environment(\.pvScrollMemory) private var memory

    func body(content: Content) -> some View {
        if let memory, !memory.claimed.contains(slot) {
            content
                .environment(\.pvScrollMemory, memory.claiming(slot))
                .background(PVScrollMemoryProbe(memory: memory, slot: slot))
        } else {
            content
        }
    }
}

/// Finds the scroll view and follows its clip view, the way `PVPopupWindowHost` follows a window.
private struct PVScrollMemoryProbe: NSViewRepresentable {
    let memory: PVScrollMemory
    let slot: PVScrollSlot

    func makeCoordinator() -> PVScrollMemoryCoordinator {
        PVScrollMemoryCoordinator(memory: memory, slot: slot)
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
    private let slot: PVScrollSlot
    private var restore: PVScrollRestore
    private var armedArrival: Int
    private weak var scrollView: NSScrollView?
    private var observers: [NSObjectProtocol] = []
    /// Watches for the researcher's first act; held only while armed.
    private var inputMonitor: Any?

    init(memory: PVScrollMemory, slot: PVScrollSlot) {
        self.memory = memory
        self.slot = slot
        self.restore = PVScrollRestore(offset: memory.offset(slot))
        self.armedArrival = memory.arrival
    }

    // MARK: Following

    func update(memory: PVScrollMemory) {
        self.memory = memory
        if memory.arrival != armedArrival {
            armedArrival = memory.arrival
            restore = PVScrollRestore(offset: memory.offset(slot))
            if let scrollView { arm(at: Self.y(of: scrollView)) }
        }
        if scrollView == nil {
            Task { @MainActor [weak self] in self?.attachIfNeeded() }
        }
    }

    func attachIfNeeded() {
        guard scrollView == nil, let probe, probe.window != nil, let found = Self.scrollView(for: probe) else { return }
        attach(found)
    }

    func detach() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
        endWatchingInput()
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
            MainActor.assumeIsolated { self?.note() }
        })
        observers.append(center.addObserver(forName: NSView.frameDidChangeNotification, object: clip, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.layoutChanged() }
        })
        if let document = scrollView.documentView {
            document.postsFrameChangedNotifications = true
            observers.append(center.addObserver(forName: NSView.frameDidChangeNotification, object: document, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.layoutChanged() }
            })
        }
        // A view just mounted is at its top; one the researcher already scrolled keeps its place.
        arm(at: 0)
    }

    // MARK: Restoring

    private func arm(at y: Double) {
        let top = restore.arm(currentY: y)
        watchInput()
        // Next turn: the arriving content is not laid out yet.
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let top { scroll(to: top) }
            if restore.isDone { note() } else { ask() }
        }
    }

    private func layoutChanged() {
        guard !restore.isDone else { return }
        // Next turn: this is inside the layout that changed.
        Task { @MainActor [weak self] in self?.ask() }
    }

    /// Goes to the y as far as the view reaches, again while that makes it reach farther, and back to the
    /// top when it falls short: all in one turn, so no step is drawn. A document that is an estimate of
    /// what it has not drawn (a lazy stack, a table) grows as it is laid out, so short of the y the view
    /// goes there a screen at a time.
    private func ask() {
        guard !restore.isDone, let scrollView else { return }
        while true {
            let reach = Self.reach(of: scrollView)
            guard let y = restore.layout(reach: reach) else { break }
            if y == reach {
                let screen = max(1, Double(scrollView.contentView.bounds.height))
                for step in stride(from: screen, to: y, by: screen) { show(step) }
            }
            show(y)
            restore.landed(Self.y(of: scrollView))
        }
        if restore.isDone {
            endWatchingInput()
            note()
        } else if Self.y(of: scrollView) != 0 {
            scroll(to: 0)
        }
    }

    private func show(_ y: Double) {
        scroll(to: y)
        scrollView?.window?.contentView?.layoutSubtreeIfNeeded()
    }

    /// The researcher scrolled, or pressed a key or the mouse: the view is theirs from here.
    func input() {
        guard !restore.isDone else { return }
        restore.input()
        endWatchingInput()
        note()
    }

    private func watchInput() {
        endWatchingInput()
        guard !restore.isDone else { return }
        inputMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.scrollWheel, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            MainActor.assumeIsolated {
                if let window = self?.scrollView?.window, event.window === window { self?.input() }
            }
            return event
        }
    }

    private func endWatchingInput() {
        inputMonitor.map(NSEvent.removeMonitor)
        inputMonitor = nil
    }

    private func note() {
        guard let scrollView, let y = restore.bounds(Self.y(of: scrollView)) else { return }
        memory.note(slot, y)
    }

    private func scroll(to y: Double) {
        guard let scrollView else { return }
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
