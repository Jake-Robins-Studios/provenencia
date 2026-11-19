import Foundation

/// The row a record page's section opened another place from, so Back can put the
/// scroll and the keyboard on it. Written on the history entry being left
/// (`WorkspaceLocation.sectionAnchor`); not part of a place's identity. A value
/// this build cannot read decodes as nil and the page opens at its top.
struct ConclusionSectionAnchor: Codable, Equatable, Sendable {
    /// Which section, and which kind of stop in it, the anchor names. The raw
    /// values are written to navigation history files, so they are frozen.
    enum Part: String, Codable, CaseIterable, Sendable {
        case family
        case timeline
        case sourceTitle
        case sourceLine
        case recordLinks
        case detailRow
        case picture
        case related
    }

    let part: Part
    /// The stop's id within the section: a tile, an event or card, a Source, a claim, a graph, a row.
    let id: String
    /// The row that holds `id` where the stop is inside a row: a Timeline card's event id, a
    /// Sources line's Source id. Nil elsewhere.
    let row: String?

    /// Nil for an empty `id`; an empty `row` is nil.
    init?(part: Part, id: String, row: String? = nil) {
        guard !id.isEmpty else { return nil }
        self.part = part
        self.id = id
        self.row = (row?.isEmpty == false) ? row : nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let part = try container.decode(Part.self, forKey: .part)
        let id = try container.decode(String.self, forKey: .id)
        let row = try container.decodeIfPresent(String.self, forKey: .row)
        guard let anchor = ConclusionSectionAnchor(part: part, id: id, row: row) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Empty anchor id.")
        }
        self = anchor
    }

    enum CodingKeys: String, CodingKey {
        case part, id, row
    }
}
