import AppKit
import SwiftUI

/// What differs between popups. A difference a popup really has is a field
/// here, never a second watcher.
struct PVPopupOptions: Equatable {
    /// The popup's keys belong to a field that stays focused (a `PVSelect`),
    /// so the watcher does not watch keys at all, Escape included.
    var keysStayInField = false
}

enum PVPopupMouseButton: Equatable {
    case left, right, other
}

/// One event the watcher sees, reduced to what the rule reads.
enum PVPopupInput: Equatable {
    case key(KeyEquivalent)
    case mouseDown(PVPopupMouseButton, inside: Bool)
    case mouseUp(PVPopupMouseButton, inside: Bool)
    case windowResignedKey

    /// Nil for an event type, or a key, the watcher does not take.
    @MainActor
    init?(_ event: NSEvent) {
        let inside = Self.isPopupWindow(level: event.window?.level)
        switch event.type {
        case .keyDown:
            guard let key = Self.keyEquivalent(
                keyCode: event.keyCode,
                characters: event.charactersIgnoringModifiers,
                modifiers: event.modifierFlags
            ) else { return nil }
            self = .key(key)
        case .leftMouseDown: self = .mouseDown(.left, inside: inside)
        case .rightMouseDown: self = .mouseDown(.right, inside: inside)
        case .otherMouseDown: self = .mouseDown(.other, inside: inside)
        case .leftMouseUp: self = .mouseUp(.left, inside: inside)
        case .rightMouseUp: self = .mouseUp(.right, inside: inside)
        case .otherMouseUp: self = .mouseUp(.other, inside: inside)
        default: return nil
        }
    }

    /// The keys a popup takes, as the SwiftUI vocabulary the kit's lists,
    /// tables and selects already speak. A letter or digit with neither ⌘ nor
    /// ⌃ type-selects; anything else is not taken and the event passes.
    static func keyEquivalent(
        keyCode: UInt16,
        characters: String?,
        modifiers: NSEvent.ModifierFlags
    ) -> KeyEquivalent? {
        switch keyCode {
        case 53: return .escape
        case 126: return .upArrow
        case 125: return .downArrow
        case 115: return .home
        case 119: return .end
        case 36, 76: return .return
        default:
            guard let characters, characters.count == 1,
                  let character = characters.first,
                  PVTypeSelectMatcher.isTypeSelectCharacter(character),
                  !modifiers.contains(.command),
                  !modifiers.contains(.control)
            else { return nil }
            return KeyEquivalent(character)
        }
    }

    /// Every kit popup is a child panel at `.popUpMenu` level, so a window at
    /// or above that level is the popup (or a system menu over it), not the
    /// page. Sheets use the same test (`PVOutsideClick.isInsideSheet`).
    static func isPopupWindow(level: NSWindow.Level?) -> Bool {
        guard let level else { return false }
        return level.rawValue >= NSWindow.Level.popUpMenu.rawValue
    }
}

/// What the watcher does with one event. The whole closing rule, decided
/// without a window, in the shape of `PVSheetDismiss.action`.
enum PVPopupDecision: Equatable {
    /// The event goes on, untouched.
    case pass
    /// Close the popup; `consumesEvent` also swallows the event.
    case close(consumesEvent: Bool)
    /// The press that opened the popup is being released: the flag clears and
    /// the event goes on.
    case endOpeningPress
    /// Hand the key to the popup; it is swallowed when the popup handles it.
    case toPopup(KeyEquivalent)

    static func decide(
        _ input: PVPopupInput,
        openingPressPending: Bool,
        options: PVPopupOptions
    ) -> PVPopupDecision {
        switch input {
        case .key(let key):
            if options.keysStayInField { return .pass }
            return key == .escape ? .close(consumesEvent: true) : .toPopup(key)
        case .mouseUp(let button, let inside):
            if openingPressPending { return .endOpeningPress }
            guard button == .left, !inside else { return .pass }
            return .close(consumesEvent: false)
        case .mouseDown(let button, let inside):
            guard button != .left, !inside else { return .pass }
            return .close(consumesEvent: false)
        case .windowResignedKey:
            return .close(consumesEvent: false)
        }
    }
}

private struct PVPopupRepresentable: NSViewRepresentable {
    var isPresented: Bool
    var options: PVPopupOptions
    var onKey: (KeyEquivalent) -> KeyPress.Result
    var close: () -> Void

    func makeNSView(context: Context) -> PVPopupWatcherView {
        let view = PVPopupWatcherView()
        apply(to: view)
        return view
    }

    func updateNSView(_ nsView: PVPopupWatcherView, context: Context) {
        apply(to: nsView)
    }

    private func apply(to view: PVPopupWatcherView) {
        view.options = options
        view.onKey = onKey
        view.close = close
        view.isPresented = isPresented
    }
}

/// The one event watcher of a floating popup, attached to its anchor. It owns
/// no window: the popup keeps its own, and this only decides when it closes.
@MainActor
private final class PVPopupWatcherView: NSView {
    var options = PVPopupOptions()
    var onKey: (KeyEquivalent) -> KeyPress.Result = { _ in .ignored }
    var close: () -> Void = {}
    var isPresented = false {
        didSet { if isPresented != oldValue { sync() } }
    }

    /// Touched from `deinit`, which is not isolated to the main actor.
    nonisolated(unsafe) private var monitor: Any?
    nonisolated(unsafe) private var resignObserver: Any?
    private var isArming = false
    /// True while the press that opened the popup has not been released.
    private var openingPressPending = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        sync()
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
    }

    private func sync() {
        if isPresented, window != nil {
            guard monitor == nil, !isArming else { return }
            // One main-queue turn after it opens, so the event that opened it
            // is already delivered.
            isArming = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                isArming = false
                if isPresented, window != nil { arm() }
            }
        } else {
            disarm()
        }
    }

    private func arm() {
        guard monitor == nil, let window else { return }
        openingPressPending = NSEvent.pressedMouseButtons != 0
        var mask: NSEvent.EventTypeMask = [
            .leftMouseUp, .rightMouseUp, .otherMouseUp, .rightMouseDown, .otherMouseDown,
        ]
        if !options.keysStayInField { mask.insert(.keyDown) }
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            let consumed = MainActor.assumeIsolated { self?.handle(event) ?? false }
            return consumed ? nil : event
        }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: window, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                _ = self?.apply(.windowResignedKey)
            }
        }
    }

    private func disarm() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let resignObserver { NotificationCenter.default.removeObserver(resignObserver) }
        monitor = nil
        resignObserver = nil
        openingPressPending = false
    }

    /// True when the event is swallowed.
    private func handle(_ event: NSEvent) -> Bool {
        guard let input = PVPopupInput(event) else { return false }
        return apply(input)
    }

    /// Applies the decision. True when the event is swallowed.
    private func apply(_ input: PVPopupInput) -> Bool {
        switch PVPopupDecision.decide(input, openingPressPending: openingPressPending, options: options) {
        case .pass:
            return false
        case .endOpeningPress:
            openingPressPending = false
            return false
        case .close(let consumesEvent):
            // After the event is delivered: a button that opened the popup
            // toggles on this same release and would reopen it.
            DispatchQueue.main.async { [weak self] in self?.close() }
            return consumesEvent
        case .toPopup(let key):
            return onKey(key) == .handled
        }
    }
}

extension View {
    /// The one presenter of a floating popup. Attach it to the popup's anchor.
    /// Escape, a left click outside (on release), a right-click outside and an
    /// app switch close it; the press that opened it never does; a click
    /// inside never does. Keys other than Escape go to `onKey`. See
    /// `PVPopupDecision.decide`.
    func pvPopup(
        isPresented: Binding<Bool>,
        options: PVPopupOptions = PVPopupOptions(),
        onKey: @escaping (KeyEquivalent) -> KeyPress.Result = { _ in .ignored }
    ) -> some View {
        background {
            PVPopupRepresentable(
                isPresented: isPresented.wrappedValue,
                options: options,
                onKey: onKey,
                close: { isPresented.wrappedValue = false }
            )
        }
    }
}
