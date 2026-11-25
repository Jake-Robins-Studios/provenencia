import AppKit

/// A left click the researcher just made, read from the event being dispatched: nil for any other event
/// and for one a second old or more (a selection nobody clicked: AppKit's current event stays the last one).
struct SourcesClick: Equatable {
    var count: Int
    /// No modifier: the click opens what it lands on.
    var isPlain: Bool
}

extension SourcesClick {
    init?(_ event: NSEvent?, now: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let event, event.type == .leftMouseDown || event.type == .leftMouseUp,
              now - event.timestamp < 1 else { return nil }
        count = event.clickCount
        isPlain = event.modifierFlags.isDisjoint(with: [.command, .shift, .option, .control])
    }
}

/// What a selection write means.
enum SourcesPress: Equatable {
    /// The second press of a double-click: the selection stays, and `opens` opens.
    case second(opens: String?)
    case select(SourcesOutlineAction)
}

/// What the pointer did on the Sources list: the Source whose triangle it is on, and the row of the last
/// plain click's first press. A plain class, not observable: only the selection write and the open action
/// read it, so the rows never redraw for it.
final class SourcesPointer {
    private(set) var sourceID: String?
    /// Set by a plain first press that moves the selection; cleared by any other press and once a second press opens its row.
    private(set) var pressed: String?

    func note(_ id: String, inside: Bool) {
        if inside { sourceID = id } else if sourceID == id { sourceID = nil }
    }

    /// The row `click` is the second press of a double-click on: the row first pressed, while it is still
    /// `selected`. The first press may have moved rows (opening a Source closes the one above), so the
    /// second lands on another row and the double-click is still the first row's.
    private func second(_ click: SourcesClick?, selected: String?) -> String? {
        guard let click, click.count >= 2, pressed == selected else { return nil }
        return pressed
    }

    /// The row the double action opens, when it is the second press's: it forgets the first press, so the
    /// row opens once.
    func secondPress(_ click: SourcesClick?, selected: String?, outline: SourcesOutline) -> SourcesOutlineRow? {
        guard let first = second(click, selected: selected), let row = outline.row(id: first) else { return nil }
        pressed = nil
        return row
    }

    /// What the selection's write of `id` over `old` means, and the first press it notes. A second press that
    /// lands on no row is followed by no double action, so it opens the first row itself; on a row, the double
    /// action does.
    func press(
        selecting id: String?, from old: String?, click: SourcesClick?, outline: SourcesOutline
    ) -> SourcesPress {
        if let first = second(click, selected: old) {
            guard id == nil, let row = outline.row(id: first) else { return .second(opens: nil) }
            pressed = nil
            return .second(opens: row.id)
        }
        if let click, click.count == 1 { pressed = click.isPlain && id != old ? id : nil }
        return .select(outline.clickAction(
            selecting: id, from: old, isPlainClick: click?.isPlain == true, onTriangle: id != nil && sourceID == id
        ))
    }
}
