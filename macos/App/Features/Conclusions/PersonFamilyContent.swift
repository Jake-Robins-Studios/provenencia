import Foundation

/// What a relative is to the person on the Family section (spoken before the
/// tile). Family's own; the tile takes the label.
enum PersonFamilyRole: Equatable {
    case parent, sibling, partner, child

    var label: String {
        switch self {
        case .parent: L10n.string(L10n.Conclusions.familyRoleParent)
        case .sibling: L10n.string(L10n.Conclusions.familyRoleSibling)
        case .partner: L10n.string(L10n.Conclusions.familyRolePartner)
        case .child: L10n.string(L10n.Conclusions.familyRoleChild)
        }
    }
}

/// The Family section's two columns (S13-12, board S13-D3, S16-D18): the origin on the
/// left (the person's siblings, the person among them, in groups by the parents each shares with
/// the person: each group its parents, then its children) and the family the person formed on
/// the right (each partner with their children). Each couple the page shows carries a line for
/// each marriage both are subjects of. Laid out from what Go gives, in Go's order, with no
/// regrouping. The siblings and each list of children are folded at `fold.limit` behind a
/// "Show N more" row, then unfolded a page at a time as `folds` records; Go returns at most
/// `kinship.Rules.MaxKinPerRole` relatives per role (`kinship.KinOf`); here only the first paint
/// is bounded.
/// Pure; the layout places it and the view draws it.
struct PersonFamilyContent: Equatable {
    /// How many tiles a list shows before it folds, and the fewest it hides.
    static let fold = PagedFold(limit: 30, minimumHidden: 1)

    /// A list that can be folded. `children` takes the group's index in Go's
    /// order (before the partner fold).
    enum Fold: Hashable {
        case siblings, partners
        case children(Int)
    }

    /// One marriage a couple on the page has, as a life line: drawn "m. 3 May 1812 · Altona",
    /// spoken as `line.accessibilityLabel`: the couple's names, then the line; a line that names the
    /// other spouse is read as it is drawn.
    struct MarriageLine: Equatable {
        var id: String
        var line: PersonLifeDisplay.LifeLine
    }

    /// A marriage of two of a sibling group's parents (indexes into its `parents`): drawn in
    /// the gap after parent `drawnAfter`, read after parent `spokenAfter`.
    struct ParentMarriage: Equatable {
        var marriage: MarriageLine
        var drawnAfter: Int
        var spokenAfter: Int
    }

    /// The person's siblings who share exactly the same of the person's parents, the person among
    /// them in the first group.
    struct SiblingGroup: Equatable {
        /// Over the group; nil for none.
        var caption: String?
        var parents: [PersonCardLink]
        /// The shown ones, in Go's order, the person among them in the first group.
        var children: [PersonCardLink]
        var marriages: [ParentMarriage]
        /// What VoiceOver calls the group.
        var label: String
    }

    /// One partner and the children with them, or the children with no other
    /// known parent (`partner` nil).
    struct Group: Equatable {
        var partner: PersonCardLink?
        var children: [PersonCardLink]
        /// How many children the fold hides.
        var childrenHidden: Int
        /// What VoiceOver calls the group.
        var label: String
        /// The person's and the partner's marriages, drawn under the partner.
        var marriages: [MarriageLine] = []
    }

    /// The groups the fold shows, in Go's order: the first always, another when its first child shows.
    var siblingGroups: [SiblingGroup]
    /// How many siblings the fold hides, over every group.
    var siblingsHidden: Int
    var groups: [Group]
    /// How many partner groups the fold hides.
    var groupsHidden: Int
    /// The right column's one caption, over its first group; nil with no groups.
    var rightCaption: String?
    /// The focus id of the first tile each fold's next page adds; absent when it hides nothing.
    private var revealed: [Fold: String] = [:]
    /// Each tile the folds hide, by the id it would have, and the fold that hides it.
    private var hiddenTiles: [String: Fold] = [:]

    /// The id of the tile that the next "Show more" of `fold` adds first, for the keyboard to
    /// land on; nil when the list hides nothing.
    func firstRevealed(by fold: Fold) -> String? { revealed[fold] }

    /// A tile's focus and scroll id: the column (`l` or `r`), the group in it and the person.
    static func tileID(column: String, group: String, personID: String) -> String {
        "\(column)-\(group)-\(personID)"
    }

    /// A marriage line's id: the column, the group in it, the couple (its index in
    /// `CatalogPersonFamily.couples`) and the marriage Event, which several couples can share.
    static func marriageID(column: String, group: String, couple: Int, eventID: String) -> String {
        "\(column)-\(group)-m\(couple)-\(eventID)"
    }

    /// The id of a fold's "Show more" row: the stop and scroll target Back restores when the
    /// opened tile is hidden. Tile ids start `l-` or `r-`, so they cannot collide.
    static func moreID(_ fold: Fold) -> String {
        switch fold {
        case .siblings: "more.siblings"
        case .partners: "more.partners"
        case .children(let index): "more.children.\(index)"
        }
    }

    /// Where Back puts the keyboard for `anchor`: the tile it opened, or its fold's Show more
    /// when the fold hides it. Nil when no tile has that id (the focus person's tile opens nothing).
    func anchorStop(for anchor: ConclusionSectionAnchor) -> String? {
        guard anchor.part == .family else { return nil }
        if allTiles.contains(where: { $0.id == anchor.id && $0.location != nil }) {
            return anchor.id
        }
        guard let fold = hiddenTiles[anchor.id] else { return nil }
        return Self.moreID(fold)
    }

    /// Every tile on the page, in reading order.
    var allTiles: [PersonCardLink] {
        siblingGroups.flatMap { $0.parents + $0.children }
            + groups.flatMap { ($0.partner.map { [$0] } ?? []) + $0.children }
    }

    /// Every marriage line on the page.
    var allMarriageLines: [MarriageLine] {
        siblingGroups.flatMap { $0.marriages.map(\.marriage) } + groups.flatMap(\.marriages)
    }

    /// Nothing to draw but the person: one sibling group with no parents and no sibling
    /// besides the person, and no groups.
    var isEmpty: Bool {
        groups.isEmpty && siblingGroups.count <= 1
            && siblingGroups.allSatisfy { $0.parents.isEmpty && !$0.children.contains { !$0.content.isFocus } }
    }

    init(
        family: CatalogPersonFamily,
        folds: PagedFoldState<Fold> = PagedFoldState(),
        locale: Locale = .autoupdatingCurrent,
        orders: NameFormatOrders = NameFormatOrders()
    ) {
        let rule = Self.fold
        /// The list as far as the pages revealed for `fold` show it.
        func folded<T>(_ list: [T], _ fold: Fold) -> [T] {
            rule.shown(list, pages: folds.pages(fold)).shown
        }
        func revealedAt<T>(_ list: [T], _ fold: Fold) -> T? {
            rule.firstRevealed(list, pages: folds.pages(fold))
        }
        var revealed: [Fold: String] = [:]
        var hiddenTiles: [String: Fold] = [:]
        let focusID = family.person?.entity.id
        func tile(_ member: CatalogFamilyMember, role: PersonFamilyRole, column: String, group: String) -> PersonCardLink {
            let summary = member.person
            return PersonCardLink.link(
                id: Self.tileID(column: column, group: group, personID: summary.entity.id),
                summary: summary,
                role: role.label,
                opensOn: .family,
                locale: locale,
                orders: orders
            )
        }
        func focusTile(_ member: CatalogFamilyMember, group: String) -> PersonCardLink {
            PersonCardLink(
                id: Self.tileID(column: "l", group: group, personID: member.person.entity.id),
                content: PVPersonCardContent(summary: member.person, role: nil, isFocus: true, locale: locale, orders: orders),
                location: nil
            )
        }
        /// A marriage line of `couple`, nil for a marriage whose event type draws no line.
        func marriageLines(
            _ coupleIndex: Int, column: String, group: String, partner: PVTitleSource?, names: [String]?
        ) -> [MarriageLine] {
            family.couples[coupleIndex].marriages.compactMap { event in
                guard var line = PersonLifeDisplay.eventLine(event, partner: partner, locale: locale) else { return nil }
                if let spoken = names.flatMap({ L10n.DesignSystem.spokenJoin([L10n.list($0, locale: locale), line.accessibilityLabel]) }) {
                    line.accessibilityLabel = spoken
                }
                return MarriageLine(
                    id: Self.marriageID(column: column, group: group, couple: coupleIndex, eventID: event.entity.id),
                    line: line
                )
            }
        }
        let focusTitle = family.person.map { PersonTitleDisplay.titleSource($0, orders: orders) }

        // Left: the sibling groups, as Go grouped them. The fold runs over the children other than
        // the person, in group order, so a page adds exactly its count of tiles; the person always
        // shows, in Go's place when the sibling before them shows, else last in the first group.
        let sourceGroups = family.siblingGroups
        var others: [(group: Int, member: CatalogFamilyMember)] = []
        for (g, group) in sourceGroups.enumerated() {
            for member in group.children where member.person.entity.id != focusID { others.append((g, member)) }
        }
        let shownOthers = folded(others, .siblings)
        siblingsHidden = others.count - shownOthers.count
        let shownIDs = Set(shownOthers.map(\.member.person.entity.id))
        let shownGroups = sourceGroups.indices.filter { g in
            g == 0 || shownOthers.contains { $0.group == g }
        }
        for hidden in others.dropFirst(shownOthers.count) {
            hiddenTiles[Self.tileID(column: "l", group: "g\(hidden.group)", personID: hidden.member.person.entity.id)] = .siblings
        }
        for g in sourceGroups.indices where !shownGroups.contains(g) {
            for parent in sourceGroups[g].parents {
                hiddenTiles[Self.tileID(column: "l", group: "g\(g)", personID: parent.person.entity.id)] = .siblings
            }
        }
        if let next = revealedAt(others, .siblings) {
            let group = sourceGroups[next.group]
            let first = group.children.first?.person.entity.id == next.member.person.entity.id
            let stop = next.group > 0 && first ? group.parents.first ?? next.member : next.member
            revealed[.siblings] = Self.tileID(column: "l", group: "g\(next.group)", personID: stop.person.entity.id)
        }
        siblingGroups = shownGroups.map { g in
            let source = sourceGroups[g]
            let name = "g\(g)"
            let parents = source.parents.map { tile($0, role: .parent, column: "l", group: name) }
            // The shown children other than the person, then the person at their place.
            var shown = source.children.filter { $0.person.entity.id != focusID && shownIDs.contains($0.person.entity.id) }
            let personAt = source.children.firstIndex { $0.person.entity.id == focusID }
            if let personAt {
                shown.insert(source.children[personAt], at: min(personAt, shown.count))
            }
            let children = shown.map { member in
                member.person.entity.id == focusID
                    ? focusTile(member, group: name)
                    : tile(member, role: .sibling, column: "l", group: name)
            }
            let hasOthers = source.children.contains { $0.person.entity.id != focusID }
            let caption: String?
            let label: String
            if g == 0 {
                switch (parents.count, hasOthers) {
                case (0, true):
                    caption = L10n.string(L10n.Conclusions.familyCaptionSiblings)
                    label = L10n.string(L10n.Conclusions.familyGroupThisPersonAndSiblings)
                case (0, false):
                    caption = nil
                    label = L10n.string(L10n.Conclusions.familyThisPerson)
                case (1, _):
                    caption = L10n.string(L10n.Conclusions.familyCaptionParent)
                    label = L10n.string(hasOthers
                        ? L10n.Conclusions.familyGroupThisPersonSiblingsAndParent
                        : L10n.Conclusions.familyGroupThisPersonAndParent)
                default:
                    caption = L10n.string(L10n.Conclusions.familyCaptionParents)
                    label = L10n.string(hasOthers
                        ? L10n.Conclusions.familyGroupThisPersonSiblingsAndParents
                        : L10n.Conclusions.familyGroupThisPersonAndParents)
                }
            } else {
                switch parents.count {
                case 0:
                    caption = L10n.string(L10n.Conclusions.familyCaptionOtherSiblings)
                    label = caption ?? ""
                case 1:
                    caption = L10n.string(L10n.Conclusions.familyCaptionSharedParent)
                    label = L10n.Conclusions.familyGroupChildrenOf(L10n.list(parents.map(\.content.title.spokenText), locale: locale))
                default:
                    caption = L10n.string(L10n.Conclusions.familyCaptionSharedParents)
                    label = L10n.Conclusions.familyGroupChildrenOf(L10n.list(parents.map(\.content.title.spokenText), locale: locale))
                }
            }

            // A couple whose two ends are among the group's parents draws its marriages beside them.
            var marriages: [ParentMarriage] = []
            for index in source.coupleIndexes where family.couples.indices.contains(index) {
                let couple = family.couples[index]
                guard let a = source.parents.firstIndex(where: { $0.person.entity.id == couple.aEntityId }),
                      let b = source.parents.firstIndex(where: { $0.person.entity.id == couple.bEntityId }),
                      a != b else { continue }
                let (i, j) = (min(a, b), max(a, b))
                let named = parents.count > 2
                let lines = marriageLines(
                    index, column: "l", group: name,
                    partner: named ? parents[i].content.title : nil,
                    names: named ? nil : [parents[i].content.title.spokenText, parents[j].content.title.spokenText]
                )
                marriages += lines.map { ParentMarriage(marriage: $0, drawnAfter: j == i + 1 ? i : j, spokenAfter: j) }
            }
            return SiblingGroup(caption: caption, parents: parents, children: children, marriages: marriages, label: label)
        }

        // Right: each partner with their children, then the children with no other parent.
        let partnerUnits = family.units.filter { $0.kind == .partner && !$0.partners.isEmpty }
        let oneParentUnits = family.units.filter { $0.kind == .oneParent }
        let allUnits = partnerUnits + oneParentUnits
        let shownUnits = folded(allUnits, .partners)
        if let unit = revealedAt(allUnits, .partners) {
            let index = shownUnits.count
            let first = unit.kind == .partner ? unit.partners.first : unit.children.first
            if let first { revealed[.partners] = Self.tileID(column: "r", group: "\(index)", personID: first.person.entity.id) }
        }
        for (index, unit) in allUnits.enumerated() where index >= shownUnits.count {
            for member in (unit.kind == .partner ? [unit.partners[0]] : []) + unit.children {
                hiddenTiles[Self.tileID(column: "r", group: "\(index)", personID: member.person.entity.id)] = .partners
            }
        }
        func children(_ unit: CatalogFamilyUnit, group index: Int) -> (tiles: [PersonCardLink], hidden: Int) {
            let shown = folded(unit.children, .children(index))
            if let first = revealedAt(unit.children, .children(index)) {
                revealed[.children(index)] = Self.tileID(column: "r", group: "\(index)", personID: first.person.entity.id)
            }
            for member in unit.children.dropFirst(shown.count) {
                hiddenTiles[Self.tileID(column: "r", group: "\(index)", personID: member.person.entity.id)] = .children(index)
            }
            return (shown.map { tile($0, role: .child, column: "r", group: "\(index)") }, unit.children.count - shown.count)
        }
        var groups: [Group] = []
        for (index, unit) in shownUnits.enumerated() {
            let kids = children(unit, group: index)
            if unit.kind == .partner {
                let partner = tile(unit.partners[0], role: .partner, column: "r", group: "\(index)")
                let name = partner.content.title.spokenText
                // The person's marriages with this partner, spoken with both names when the person is known.
                var marriages: [MarriageLine] = []
                for coupleIndex in unit.coupleIndexes where family.couples.indices.contains(coupleIndex) {
                    marriages += marriageLines(
                        coupleIndex, column: "r", group: "\(index)", partner: nil,
                        names: focusTitle.map { [$0.spokenText, name] }
                    )
                }
                groups.append(Group(
                    partner: partner,
                    children: kids.tiles,
                    childrenHidden: kids.hidden,
                    label: unit.children.isEmpty
                        ? L10n.Conclusions.familyGroupPartner(name)
                        : L10n.Conclusions.familyGroupPartnerAndChildren(name),
                    marriages: marriages
                ))
            } else {
                groups.append(Group(
                    partner: nil,
                    children: kids.tiles,
                    childrenHidden: kids.hidden,
                    label: L10n.string(L10n.Conclusions.familyCaptionChildren)
                ))
            }
        }
        self.groups = groups
        self.revealed = revealed
        self.hiddenTiles = hiddenTiles
        groupsHidden = allUnits.count - groups.count
        let anyChildren = allUnits.contains { !$0.children.isEmpty }
        if allUnits.isEmpty {
            rightCaption = nil
        } else {
            switch (partnerUnits.count, anyChildren) {
            case (0, _): rightCaption = L10n.string(L10n.Conclusions.familyCaptionChildren)
            case (1, true): rightCaption = L10n.string(L10n.Conclusions.familyCaptionPartnerAndChildren)
            case (1, false): rightCaption = L10n.string(L10n.Conclusions.familyCaptionPartner)
            case (_, true): rightCaption = L10n.string(L10n.Conclusions.familyCaptionPartnersAndChildren)
            case (_, false): rightCaption = L10n.string(L10n.Conclusions.familyCaptionPartners)
            }
        }
    }
}

extension PersonFamilyContent {
    /// What the content is built from beside its read; it is built again when any of them changes.
    struct Inputs: Equatable {
        var folds: PagedFoldState<Fold>
        var orders: NameFormatOrders
        var locale: Locale
    }
}
