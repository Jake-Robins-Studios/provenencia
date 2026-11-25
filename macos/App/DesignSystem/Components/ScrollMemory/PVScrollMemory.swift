import AppKit
import SwiftUI

/// The name of one scroll view on a page. A page with one scroll view uses `.page`; a page with a
/// second names its own. The raw value is written to navigation history files, so it is frozen once
/// a page ships it.
struct PVScrollSlot: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }

    init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The page's own scroll view.
    static let page = PVScrollSlot(rawValue: "page")
}

/// What a page's scroll views are asked to remember: the y each was left at, and where to report the
/// y as the researcher scrolls. The workspace hands it to the kit through `\.pvScrollMemory`; the kit
/// knows nothing of navigation. `arrival` names one visit: a new value re-arms every probe.
struct PVScrollMemory: Equatable, Sendable {
    /// Names one visit to a page. A change re-arms the restore of every scroll view under it.
    let arrival: Int
    /// The y each slot was left at on the last visit, 0 at the top.
    let offsets: [PVScrollSlot: Double]
    /// Reports a slot's live y. Stores one number: no observation, no file write.
    let note: @MainActor @Sendable (PVScrollSlot, Double) -> Void
    /// Slots a container above already remembers, so a nested scroll view never claims them.
    private(set) var claimed: Set<PVScrollSlot> = []

    init(arrival: Int, offsets: [PVScrollSlot: Double], note: @escaping @MainActor @Sendable (PVScrollSlot, Double) -> Void) {
        self.arrival = arrival
        self.offsets = offsets
        self.note = note
    }

    static func == (lhs: PVScrollMemory, rhs: PVScrollMemory) -> Bool {
        lhs.arrival == rhs.arrival && lhs.offsets == rhs.offsets
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

/// When to scroll a restored view, as a value (D-6). One per probe and arrival.
///
/// Armed with the y the slot was left at: a nil or 0 y scrolls to the top once if the view is not
/// there, and is done; any other y waits until the content is tall enough to show it, scrolls once,
/// and is done. While armed, a bounds change at the top is not the researcher's; one away from it is,
/// and disarms the restore. Once done, every bounds change is noted. There is no time limit: content
/// that never grows tall enough leaves the page at its top.
struct PVScrollRestore: Equatable {
    private let offset: Double?
    private(set) var isDone = false

    init(offset: Double?) {
        if let offset, offset.isFinite, offset > 0 {
            self.offset = offset
        } else {
            self.offset = nil
        }
    }

    /// Starts the restore at the view's current y. Returns the y to scroll to now (0), or nil.
    mutating func arm(currentY: Double) -> Double? {
        guard offset == nil else { return nil }
        isDone = true
        return currentY == 0 ? nil : 0
    }

    /// The y to scroll to once the content is tall enough to show the offset, then done.
    mutating func layout(currentY: Double, documentHeight: Double, visibleHeight: Double, topInset: Double) -> Double? {
        guard !isDone, let offset else { return nil }
        guard offset <= documentHeight - (visibleHeight - topInset) + 0.5 else { return nil }
        isDone = true
        return offset
    }

    /// The y to note for a bounds change, or nil. While armed, the top is not noted and any other y
    /// is the researcher's: it disarms the restore.
    mutating func bounds(_ y: Double) -> Double? {
        if isDone { return y }
        if y < 0.5 { return nil }
        isDone = true
        return y
    }
}

extension View {
    /// Makes the scroll view this content is in (or, for a `List` or `Table`, is the background of)
    /// open where it was left: on arrival it scrolls to the slot's remembered y once the content is
    /// tall enough, else stays at the top; it reports the y as the researcher scrolls. The kit's
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

    init(memory: PVScrollMemory, slot: PVScrollSlot) {
        self.memory = memory
        self.slot = slot
        self.restore = PVScrollRestore(offset: memory.offsets[slot])
        self.armedArrival = memory.arrival
    }

    // MARK: Following

    func update(memory: PVScrollMemory) {
        self.memory = memory
        if memory.arrival != armedArrival {
            armedArrival = memory.arrival
            restore = PVScrollRestore(offset: memory.offsets[slot])
            if scrollView != nil { arm() }
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
            MainActor.assumeIsolated { self?.layoutChanged() }
        })
        if let document = scrollView.documentView {
            document.postsFrameChangedNotifications = true
            observers.append(center.addObserver(forName: NSView.frameDidChangeNotification, object: document, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.layoutChanged() }
            })
        }
        arm()
    }

    // MARK: Restoring

    private func arm() {
        guard let scrollView else { return }
        if let top = restore.arm(currentY: Self.y(of: scrollView)) {
            Task { @MainActor [weak self] in self?.scroll(to: top) }
        } else if !restore.isDone {
            Task { @MainActor [weak self] in self?.layoutChanged() }
        }
    }

    private func layoutChanged() {
        guard !restore.isDone, let scrollView else { return }
        let clip = scrollView.contentView
        let top = clip.contentInsets.top
        if let y = restore.layout(
            currentY: Self.y(of: scrollView),
            documentHeight: Double(scrollView.documentView?.frame.height ?? 0),
            visibleHeight: Double(clip.bounds.height),
            topInset: Double(top)
        ) {
            scroll(to: y)
        }
    }

    private func boundsChanged() {
        guard let scrollView else { return }
        if let y = restore.bounds(Self.y(of: scrollView)) {
            memory.note(slot, y)
        }
    }

    private func scroll(to y: Double) {
        guard let scrollView else { return }
        let clip = scrollView.contentView
        clip.scroll(to: NSPoint(x: clip.bounds.minX, y: y - clip.contentInsets.top))
        scrollView.reflectScrolledClipView(clip)
    }

    /// 0 at the top, content-agnostic (D-1).
    private static func y(of scrollView: NSScrollView) -> Double {
        Double(scrollView.contentView.bounds.minY + scrollView.contentView.contentInsets.top)
    }

    // MARK: Finding the scroll view (D-3)

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
