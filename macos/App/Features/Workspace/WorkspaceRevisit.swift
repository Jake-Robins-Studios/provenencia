import Foundation

/// What a history entry keeps of how it was left, so a move back to it (Back, Forward, a jump, a
/// relaunch) finds the page as it was. A push never carries one: a new visit starts clean. Not part
/// of a place's identity (`WorkspaceLocation.==` ignores it).
///
/// Encoded flat at the location's top level (`scrollOffsets` is a JSON object keyed by each slot's raw
/// value); each key decodes on its own, one this build cannot read as empty. `openSourceId` is never
/// encoded: a relaunch opens every Source closed.
struct WorkspaceRevisit: Codable, Equatable, Sendable {
    /// The row selected in the list (Persons, Events, Places, Sources). Source types never notes one.
    var listSelection: String?
    /// The Source open in the Sources list, kept only on the Sources list root and never written to the file.
    var openSourceId: String?
    /// The y each of the page's scroll views was left at, 0 at the top.
    private(set) var scrollOffsets: [PVScrollSlot: Double] = [:]
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
        self.sectionAnchor = sectionAnchor
        for (slot, y) in scrollOffsets { note(y, slot: slot) }
    }

    /// Keeps a scroll view's y. One that is not finite or is negative is no position: false.
    @discardableResult
    mutating func note(_ y: Double, slot: PVScrollSlot) -> Bool {
        guard y.isFinite, y >= 0 else { return false }
        scrollOffsets[slot] = y
        return true
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case listSelection = "listScrollAnchor"
        case scrollOffsets, sectionAnchor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let offsets = (try? container.decode([String: LenientOffset].self, forKey: .scrollOffsets)) ?? [:]
        self.init(
            listSelection: try? container.decode(String.self, forKey: .listSelection),
            scrollOffsets: Dictionary(uniqueKeysWithValues: offsets.compactMap { key, value in
                value.y.map { (PVScrollSlot(rawValue: key), $0) }
            }),
            sectionAnchor: try? container.decode(ConclusionSectionAnchor.self, forKey: .sectionAnchor)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(listSelection, forKey: .listSelection)
        try container.encodeIfPresent(sectionAnchor, forKey: .sectionAnchor)
        guard !scrollOffsets.isEmpty else { return }
        // A dictionary keyed by a struct would encode as an array.
        let offsets = Dictionary(uniqueKeysWithValues: scrollOffsets.map { ($0.key.rawValue, $0.value) })
        try container.encode(offsets, forKey: .scrollOffsets)
    }

    /// One entry of `scrollOffsets`, nil when it is not a number.
    private struct LenientOffset: Decodable {
        let y: Double?

        init(from decoder: Decoder) throws {
            y = try? decoder.singleValueContainer().decode(Double.self)
        }
    }
}
