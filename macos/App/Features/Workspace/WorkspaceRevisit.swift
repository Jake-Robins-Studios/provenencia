import Foundation

/// What a history entry keeps of how it was left, so a move back to it (Back, Forward, a jump, a
/// relaunch) finds the page as it was. A push never carries one: a new visit starts clean. Not part
/// of a place's identity (`WorkspaceLocation.==` ignores it).
///
/// Encoded flat at the location's top level: `listScrollAnchor`, `sectionAnchor` and `scrollOffsets`
/// (a JSON object keyed by each slot's raw value). `openSourceId` is never encoded: a relaunch opens
/// every Source closed.
struct WorkspaceRevisit: Equatable, Sendable {
    /// The row selected in the list (Persons, Events, Places, Sources). Source types never notes one.
    var listSelection: String?
    /// The Source open in the Sources list, kept only on the Sources list root and never written to the file.
    var openSourceId: String?
    /// The y each of the page's scroll views was left at, 0 at the top.
    var scrollOffsets: [PVScrollSlot: Double] = [:]
    /// The row of a record page's section the researcher opened another place from; Back puts the keyboard there.
    var sectionAnchor: ConclusionSectionAnchor?

    init(
        listSelection: String? = nil,
        openSourceId: String? = nil,
        scrollOffsets: [PVScrollSlot: Double] = [:],
        sectionAnchor: ConclusionSectionAnchor? = nil
    ) {
        self.listSelection = listSelection?.isEmpty == false ? listSelection : nil
        self.openSourceId = openSourceId?.isEmpty == false ? openSourceId : nil
        self.scrollOffsets = scrollOffsets.filter { $0.value.isFinite && $0.value >= 0 }
        self.sectionAnchor = sectionAnchor
    }
}
