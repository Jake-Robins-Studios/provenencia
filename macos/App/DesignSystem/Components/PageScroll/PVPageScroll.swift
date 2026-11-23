import AppKit
import ObjectiveC
import SwiftUI

/// The scroll view a workspace page scrolls in. Page Up, Page Down, Home and
/// End scroll it whenever no focused view, text field or menu takes them
/// (`PVPageKeyResponder`), and a change of `startsAtTopWhen` sends it to its
/// top (a page's reset; `pvScrollsRowIntoView`'s `startsAtTopWhenRowsChange:`
/// is a list's first row); the content needs no key code and no ids.
///
/// `yieldsPageKeys`: when another page scroll view in the window can scroll and
/// the pointer is over neither, the page keys go to that one. A focused view
/// that handles the keys (a focused `PVTable`) keeps them.
struct PVPageScrollView<Content: View>: View {
    private let resetKey: AnyHashable?
    private let yieldsPageKeys: Bool
    private let content: Content
    @State private var handle = PVPageScrollHandle()

    init(
        startsAtTopWhen resetKey: AnyHashable? = nil,
        yieldsPageKeys: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.resetKey = resetKey
        self.yieldsPageKeys = yieldsPageKeys
        self.content = content()
    }

    var body: some View {
        ScrollView(.vertical) {
            content.background(
                PVPageScrollProbe(handle: handle, yieldsPageKeys: yieldsPageKeys).frame(width: 0, height: 0)
            )
        }
        .onChange(of: resetKey) { handle.scrollToTop() }
    }
}

/// Reaches the page's `NSScrollView` from SwiftUI.
@MainActor
final class PVPageScrollHandle {
    weak var probe: NSView?

    func scrollToTop() {
        PVPageKeys.scrollToEdge(probe?.enclosingScrollView, top: true)
    }
}

private struct PVPageScrollProbe: NSViewRepresentable {
    let handle: PVPageScrollHandle
    let yieldsPageKeys: Bool

    final class Probe: NSView {
        weak var responder: PVPageKeyResponder?
        var yieldsPageKeys = false

        override func viewWillMove(toWindow newWindow: NSWindow?) {
            if newWindow !== window { responder?.unregister(self) }
            super.viewWillMove(toWindow: newWindow)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            let responder = PVPageKeyResponder.install(in: window)
            self.responder = responder
            responder.register(self)
        }
    }

    func makeNSView(context: Context) -> Probe {
        let probe = Probe()
        probe.yieldsPageKeys = yieldsPageKeys
        handle.probe = probe
        return probe
    }

    func updateNSView(_ probe: Probe, context: Context) {
        probe.yieldsPageKeys = yieldsPageKeys
        handle.probe = probe
    }
}

enum PVPageKeyCommand: Equatable { case pageUp, pageDown, top, bottom }

enum PVPageKeys {
    /// The page command a key press names, or nil. Plain keys only: ⌘↓ and
    /// ⇧Page Down keep their meanings elsewhere. `.function` (fn + arrow on a
    /// laptop) and `.numericPad` do not matter.
    static func command(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> PVPageKeyCommand? {
        guard modifiers.intersection([.command, .option, .control, .shift]).isEmpty else { return nil }
        switch keyCode {
        case PVKeyCode.pageUp: return .pageUp
        case PVKeyCode.pageDown: return .pageDown
        case PVKeyCode.home: return .top
        case PVKeyCode.end: return .bottom
        default: return nil
        }
    }

    /// Whether `visible` (the clip view's bounds) shows the document's top or
    /// bottom edge, within half a point.
    static func edgeReached(visible: CGRect, document: CGRect, flipped: Bool, top: Bool) -> Bool {
        let atMin = flipped == top
        return atMin ? visible.minY <= document.minY + 0.5 : visible.maxY >= document.maxY - 0.5
    }

    /// Scrolls to the edge, then pins the scroll view there: a lazy page's
    /// height is an estimate until its rows are built, so the first scroll can
    /// stop short (`PVPageEdgePin`).
    @MainActor static func scrollToEdge(_ scrollView: NSScrollView?, top: Bool) {
        PVPageEdgePin.start(scrollView, top: top)
    }

    /// One scroll to the document's top or bottom, at its current height.
    @MainActor fileprivate static func scrollOnce(_ scrollView: NSScrollView, top: Bool) {
        guard let doc = scrollView.documentView else { return }
        scrollView.layoutSubtreeIfNeeded()
        let y: CGFloat = doc.isFlipped == top ? 0 : doc.bounds.height - 1
        doc.scrollToVisible(NSRect(x: 0, y: y, width: 1, height: 1))
    }
}

/// When a pin to the page's edge holds and when it lets go.
struct PVPageEdgePinState {
    private(set) var isPinned = true

    /// True: scroll to the edge again.
    mutating func documentChanged() -> Bool { isPinned }

    /// A move the pin did not make, away from the edge, is the user's.
    mutating func clipMoved(bySelf: Bool, atEdge: Bool) {
        if !bySelf && !atEdge { isPinned = false }
    }

    /// `seconds` since the document last changed height.
    mutating func quiet(for seconds: TimeInterval) {
        if seconds >= 0.6 { isPinned = false }
    }

    /// `seconds` since the pin began.
    mutating func elapsed(_ seconds: TimeInterval) {
        if seconds >= 3 { isPinned = false }
    }
}

/// Keeps a page scrolled to its top or bottom while a lazy page's height
/// settles: rescrolls on each document change until the height has been still
/// for 0.6 s (3 s at most) or the user scrolls away. At most one is alive.
@MainActor
final class PVPageEdgePin {
    private static var current: PVPageEdgePin?

    private weak var scrollView: NSScrollView?
    private let top: Bool
    private var state = PVPageEdgePinState()
    private let began = Date()
    private var lastChange = Date()
    private var scrolling = false
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    static func start(_ scrollView: NSScrollView?, top: Bool) {
        current?.end()
        guard let scrollView else { return }
        PVPageKeys.scrollOnce(scrollView, top: top)
        guard let doc = scrollView.documentView else { return }
        let pin = PVPageEdgePin(scrollView: scrollView, document: doc, top: top)
        current = pin
    }

    private init(scrollView: NSScrollView, document: NSView, top: Bool) {
        self.scrollView = scrollView
        self.top = top
        document.postsFrameChangedNotifications = true
        scrollView.contentView.postsBoundsChangedNotifications = true
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: NSView.frameDidChangeNotification, object: document, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.documentChanged() }
            })
        observers.append(
            center.addObserver(
                forName: NSView.boundsDidChangeNotification, object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.clipMoved() }
            })
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func documentChanged() {
        lastChange = Date()
        guard state.documentChanged(), let scrollView else { return end() }
        scrolling = true
        PVPageKeys.scrollOnce(scrollView, top: top)
        scrolling = false
    }

    private func clipMoved() {
        guard let scrollView, let doc = scrollView.documentView else { return end() }
        let atEdge = PVPageKeys.edgeReached(
            visible: scrollView.contentView.bounds, document: doc.bounds,
            flipped: doc.isFlipped, top: top)
        state.clipMoved(bySelf: scrolling, atEdge: atEdge)
        if !state.isPinned { end() }
    }

    private func tick() {
        let now = Date()
        state.quiet(for: now.timeIntervalSince(lastChange))
        state.elapsed(now.timeIntervalSince(began))
        if !state.isPinned { end() }
    }

    private func end() {
        timer?.invalidate()
        timer = nil
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        if PVPageEdgePin.current === self { PVPageEdgePin.current = nil }
    }
}

/// One per window, after the window in the responder chain: it sees only the
/// keys no focused view, text field or menu used.
@MainActor
final class PVPageKeyResponder: NSResponder {
    private struct WeakProbe { weak var view: NSView? }

    nonisolated(unsafe) private static var associationKey: UInt8 = 0
    weak var window: NSWindow?
    private var probes: [WeakProbe] = []

    /// The window's responder, inserted directly after the window when it has
    /// none. The window owns it (`nextResponder` does not retain).
    static func install(in window: NSWindow) -> PVPageKeyResponder {
        var next = window.nextResponder
        while let current = next {
            if let found = current as? PVPageKeyResponder { return found }
            next = current.nextResponder
        }
        let responder = PVPageKeyResponder()
        responder.window = window
        responder.nextResponder = window.nextResponder
        window.nextResponder = responder
        objc_setAssociatedObject(
            window, &associationKey, responder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return responder
    }

    func register(_ probe: NSView) {
        probes.removeAll { $0.view == nil || $0.view === probe }
        probes.append(WeakProbe(view: probe))
    }

    func unregister(_ probe: NSView) {
        probes.removeAll { $0.view === probe }
    }

    override func keyDown(with event: NSEvent) {
        guard let command = PVPageKeys.command(keyCode: event.keyCode, modifiers: event.modifierFlags),
              let scrollView = pageProbe()?.enclosingScrollView
        else { return super.keyDown(with: event) }
        switch command {
        case .pageDown: scrollView.pageDown(nil)
        case .pageUp: scrollView.pageUp(nil)
        case .top: PVPageKeys.scrollToEdge(scrollView, top: true)
        case .bottom: PVPageKeys.scrollToEdge(scrollView, top: false)
        }
    }

    /// The window's page: the scrollable one under the pointer, else the last
    /// registered that is not a side list, else the last registered.
    private func pageProbe() -> NSView? {
        guard let window else { return nil }
        let candidates = probes.compactMap(\.view).filter { view in
            guard view.window === window, let scroll = view.enclosingScrollView,
                  let doc = scroll.documentView else { return false }
            return doc.frame.height > scroll.contentView.bounds.height
        }
        let mouse = window.mouseLocationOutsideOfEventStream
        if let hovered = candidates.last(where: { view in
            guard let scroll = view.enclosingScrollView else { return false }
            return scroll.bounds.contains(scroll.convert(mouse, from: nil))
        }) {
            return hovered
        }
        return candidates.last(where: { ($0 as? PVPageScrollProbe.Probe)?.yieldsPageKeys == false })
            ?? candidates.last
    }
}

private struct PVPageScrollPreview: View {
    var body: some View {
        PVPageScrollView {
            VStack(alignment: .leading) {
                ForEach(0..<120, id: \.self) { i in
                    Text(verbatim: "Line \(i)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview { PVPageScrollPreview().frame(width: 320, height: 360) }
