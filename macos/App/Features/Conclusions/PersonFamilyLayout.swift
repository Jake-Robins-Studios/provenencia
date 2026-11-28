import CoreGraphics

/// Where the Family section puts everything (S13-12, board S13-D3 `layTree3`, S16-D18):
/// the tiles of both columns, the marriage lines between them, their captions, and the
/// one-point lines that join them. A pure function of the content, the width of the primary
/// column and the width class, so the geometry is tested without a view.
///
/// The left column is the origin: each sibling group under its caption, its parents then its
/// children indented beneath, one line per group in the margin that stays inside the group. The
/// right column is the family the person formed: each partner with their children indented
/// beneath. A couple's marriages are lines between the two tiles, or under a partner's tile,
/// starting where the tile's text starts. A bus joins the person's tile to every partner. A
/// folded list ends in one "more" row; no line goes to it.
struct PersonFamilyLayout: Equatable {
    struct PlacedTile: Equatable {
        var id: String
        /// Relative to its group.
        var frame: CGRect
    }

    /// A marriage line between two tiles or over a partner's.
    struct PlacedLine: Equatable {
        var id: String
        /// Relative to its group.
        var frame: CGRect
    }

    /// The "Show N more" row that ends a folded list. The view words it.
    struct PlacedMore: Equatable {
        var fold: PersonFamilyContent.Fold
        var count: Int
        /// Relative to its group.
        var frame: CGRect
    }

    /// One thing in a group, in the order VoiceOver reads it. Its frame is relative to its group
    /// once the group is built, and absolute while the layout places it.
    enum Placed: Equatable, Identifiable {
        case tile(PlacedTile)
        case line(PlacedLine)
        case more(PlacedMore)

        var id: String {
            switch self {
            case .tile(let tile): tile.id
            case .line(let line): line.id
            case .more(let more): PersonFamilyContent.moreID(more.fold)
            }
        }

        var frame: CGRect {
            switch self {
            case .tile(let tile): tile.frame
            case .line(let line): line.frame
            case .more(let more): more.frame
            }
        }

        func offsetBy(dx: CGFloat, dy: CGFloat) -> Placed {
            switch self {
            case .tile(var tile):
                tile.frame = tile.frame.offsetBy(dx: dx, dy: dy)
                return .tile(tile)
            case .line(var line):
                line.frame = line.frame.offsetBy(dx: dx, dy: dy)
                return .line(line)
            case .more(var more):
                more.frame = more.frame.offsetBy(dx: dx, dy: dy)
                return .more(more)
            }
        }
    }

    /// One VoiceOver container, in reading order.
    struct Group: Equatable {
        var label: String
        var frame: CGRect
        /// Tiles, marriage lines and the Show more row, in reading order.
        var items: [Placed]

        var tiles: [PlacedTile] { items.compactMap { if case .tile(let tile) = $0 { tile } else { nil } } }
        var lines: [PlacedLine] { items.compactMap { if case .line(let line) = $0 { line } else { nil } } }
        var more: [PlacedMore] { items.compactMap { if case .more(let more) = $0 { more } else { nil } } }
    }

    struct Caption: Equatable {
        var text: String
        var origin: CGPoint
    }

    static let margin: CGFloat = 20
    static let moreRowHeight: CGFloat = 28
    static let moreGap: CGFloat = 4
    static let tileGap: CGFloat = 12
    static let captionBand: CGFloat = 26
    static let indent: CGFloat = 32
    /// Between two sibling groups.
    static let siblingGroupGap: CGFloat = 20
    /// Between two partner groups in the right column.
    static let partnerGroupGap: CGFloat = 28
    /// The x of every sibling group's line.
    static let lineX: CGFloat = 10
    /// One marriage line's height, and how far below a tile the first one starts.
    static let marriageLineHeight: CGFloat = 21
    static let marriageLineInset: CGFloat = 6
    /// The space between a partner's last marriage line and their first child: three times
    /// `marriageLineInset`, so the line reads as the partner's and not the child's.
    static let partnerMarriageChildGap: CGFloat = 18

    static func gutter(_ widthClass: PVWidthClass) -> CGFloat {
        widthClass == .wide ? 96 : 48
    }

    var groups: [Group] = []
    var captions: [Caption] = []
    /// Horizontal and vertical lines, one point thick.
    var segments: [CGRect] = []
    var height: CGFloat = 0
    /// The column width, the right column's x, and the bus's x, as laid out.
    var columnWidth: CGFloat = 0
    var rightX: CGFloat = 0
    var busX: CGFloat = 0

    /// The absolute frame of the tile, marriage line or Show more row with `id`.
    func frame(of id: String) -> CGRect? {
        for group in groups {
            if let item = group.items.first(where: { $0.id == id }) {
                return item.frame.offsetBy(dx: group.frame.minX, dy: group.frame.minY)
            }
        }
        return nil
    }

    init(content: PersonFamilyContent, width: CGFloat, widthClass: PVWidthClass) {
        let m = Self.margin
        let th = PVTileCardSize.regular.height
        let step = th + Self.tileGap
        let lineHeight = Self.marriageLineHeight
        let textLeading = PVTileCardSize.regular.textLeading
        let gutter = Self.gutter(widthClass)
        let tp = max((width - m - gutter) / 2, PVTileCardSize.regular.minimumWidth).rounded(.down)
        let c2 = m + tp + gutter
        columnWidth = tp
        rightX = c2
        busX = c2 - Self.indent

        // Absolute frames collected per container, then made relative.
        func container(_ label: String, _ items: [Placed]) -> Group {
            let union = items.dropFirst().reduce(items[0].frame) { $0.union($1.frame) }
            return Group(label: label, frame: union, items: items.map { $0.offsetBy(dx: -union.minX, dy: -union.minY) })
        }
        /// The row under a list that ends at `bottom`.
        func moreRow(x: CGFloat, width: CGFloat, below bottom: CGFloat) -> CGRect {
            CGRect(x: x, y: bottom + Self.moreGap, width: width, height: Self.moreRowHeight)
        }
        let moreBand = Self.moreGap + Self.moreRowHeight
        func horizontal(_ x1: CGFloat, _ x2: CGFloat, y: CGFloat) {
            segments.append(CGRect(x: min(x1, x2), y: y, width: abs(x2 - x1), height: 1))
        }
        func vertical(x: CGFloat, _ y1: CGFloat, _ y2: CGFloat) {
            segments.append(CGRect(x: x, y: min(y1, y2), width: 1, height: abs(y2 - y1) + 1))
        }

        var leftBottom: CGFloat = 0
        var focusCenter: CGFloat?
        var focusRight: CGFloat?

        // Left: the sibling groups, each its parents (with their marriages), then its children.
        var y: CGFloat = 0
        for (k, group) in content.siblingGroups.enumerated() {
            if let caption = group.caption {
                captions.append(Caption(text: caption, origin: CGPoint(x: m, y: y)))
            }
            let hasParents = !group.parents.isEmpty
            var parentRects: [CGRect] = []
            var lineRectOf: [Int: CGRect] = [:]
            var top = y + Self.captionBand
            for i in group.parents.indices {
                let rect = CGRect(x: m, y: top, width: tp, height: th)
                parentRects.append(rect)
                // The lines drawn in the gap after this parent stack in order.
                var inGap: CGFloat = 0
                for (index, marriage) in group.marriages.enumerated() where marriage.drawnAfter == i {
                    lineRectOf[index] = CGRect(
                        x: m + textLeading, y: rect.maxY + Self.marriageLineInset + inGap * lineHeight,
                        width: tp - textLeading, height: lineHeight
                    )
                    inGap += 1
                }
                top = rect.maxY + Self.tileGap + inGap * lineHeight
            }
            var items: [Placed] = []
            for (i, parent) in group.parents.enumerated() {
                items.append(.tile(PlacedTile(id: parent.id, frame: parentRects[i])))
                for (index, marriage) in group.marriages.enumerated() where marriage.spokenAfter == i {
                    if let rect = lineRectOf[index] { items.append(.line(PlacedLine(id: marriage.marriage.id, frame: rect))) }
                }
            }
            let childX = hasParents ? m + Self.indent : m
            let childWidth = hasParents ? tp - Self.indent : tp
            var childCenters: [CGFloat] = []
            var lastChild: CGRect?
            for child in group.children {
                let rect = CGRect(x: childX, y: top, width: childWidth, height: th)
                items.append(.tile(PlacedTile(id: child.id, frame: rect)))
                childCenters.append(rect.midY)
                if child.content.isFocus {
                    focusCenter = rect.midY
                    focusRight = rect.maxX
                }
                lastChild = rect
                top += step
            }
            var bottom = items.map { $0.frame.maxY }.max() ?? top
            if content.siblingsHidden > 0, k == content.siblingGroups.count - 1, let lastChild {
                let row = moreRow(x: childX, width: childWidth, below: lastChild.maxY)
                items.append(.more(PlacedMore(fold: .siblings, count: content.siblingsHidden, frame: row)))
                bottom = row.maxY
            }
            // One line per group, inside it: a lone child with no parents has none.
            let parentCenters = parentRects.map(\.midY)
            if hasParents || childCenters.count > 1,
               let first = parentCenters.first ?? childCenters.first,
               let last = childCenters.last ?? parentCenters.last {
                vertical(x: Self.lineX, first, last)
                for center in parentCenters { horizontal(Self.lineX, m, y: center) }
                for center in childCenters { horizontal(Self.lineX, childX, y: center) }
            }
            if !items.isEmpty { groups.append(container(group.label, items)) }
            leftBottom = max(leftBottom, bottom)
            y = bottom + Self.siblingGroupGap
        }

        // Right: the groups.
        var rightBottom: CGFloat = 0
        var joins: [CGFloat] = []
        var gy = Self.captionBand
        if let caption = content.rightCaption {
            captions.append(Caption(text: caption, origin: CGPoint(x: c2, y: 0)))
        }
        let childX = c2 + Self.indent
        let childRail = c2 - 12
        for (index, group) in content.groups.enumerated() {
            var items: [Placed] = []
            var top = gy
            var partnerCenter: CGFloat?
            // The partner, then their marriages under them, as the left column does.
            if let partner = group.partner {
                items.append(.tile(PlacedTile(id: partner.id, frame: CGRect(x: c2, y: top, width: tp, height: th))))
                partnerCenter = top + th / 2
                top += th
            }
            var lastLineMaxY: CGFloat?
            for line in group.marriages {
                let frame = CGRect(
                    x: c2 + textLeading, y: top + Self.marriageLineInset, width: tp - textLeading, height: lineHeight
                )
                items.append(.line(PlacedLine(id: line.id, frame: frame)))
                lastLineMaxY = frame.maxY
                top += lineHeight
            }
            if let lastLineMaxY {
                top = lastLineMaxY + Self.partnerMarriageChildGap
            } else if group.partner != nil {
                top += Self.tileGap
            }
            var childCenters: [CGFloat] = []
            for child in group.children {
                items.append(.tile(PlacedTile(id: child.id, frame: CGRect(x: childX, y: top, width: tp - Self.indent, height: th))))
                childCenters.append(top + th / 2)
                top += step
            }
            let join = partnerCenter ?? childCenters.first ?? gy
            joins.append(join)
            if let partnerCenter {
                horizontal(busX, c2, y: partnerCenter)
                if let last = childCenters.last {
                    vertical(x: childRail, partnerCenter, last)
                    for center in childCenters { horizontal(childRail, childX, y: center) }
                }
            } else if childCenters.count == 1 {
                horizontal(busX, childX, y: childCenters[0])
            } else if let first = childCenters.first, let last = childCenters.last {
                horizontal(busX, childRail, y: first)
                vertical(x: childRail, first, last)
                for center in childCenters { horizontal(childRail, childX, y: center) }
            }
            var bottom = items.map { $0.frame.maxY }.max() ?? top - Self.tileGap
            if group.childrenHidden > 0 {
                items.append(.more(PlacedMore(
                    fold: .children(index), count: group.childrenHidden,
                    frame: moreRow(x: childX, width: tp - Self.indent, below: bottom)
                )))
                bottom += moreBand
            }
            if index == content.groups.count - 1, content.groupsHidden > 0 {
                items.append(.more(PlacedMore(
                    fold: .partners, count: content.groupsHidden, frame: moreRow(x: c2, width: tp, below: bottom)
                )))
                bottom += moreBand
            }
            if !items.isEmpty {
                groups.append(container(group.label, items))
                rightBottom = max(rightBottom, bottom)
                gy = bottom + Self.partnerGroupGap
            }
        }
        if !joins.isEmpty {
            var spans = joins
            if let focusCenter, let focusRight {
                spans.append(focusCenter)
                horizontal(focusRight, busX, y: focusCenter)
            }
            vertical(x: busX, spans.min() ?? 0, spans.max() ?? 0)
        }
        height = max(leftBottom, rightBottom)
    }
}
