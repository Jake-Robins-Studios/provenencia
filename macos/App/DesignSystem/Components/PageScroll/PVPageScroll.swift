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

    @MainActor static func scrollToEdge(_ scrollView: NSScrollView?, top: Bool) {
        guard let doc = scrollView?.documentView else { return }
        let y: CGFloat = doc.isFlipped == top ? 0 : doc.bounds.height - 1
        doc.scrollToVisible(NSRect(x: 0, y: y, width: 1, height: 1))
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
