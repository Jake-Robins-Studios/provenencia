import Foundation
import Testing
@testable import Provenencia

struct PersonFamilyContentTests {
    private let en = Locale(identifier: "en_US")
    private typealias Data = PersonFamilyPreviewData

    private func content(_ family: CatalogPersonFamily, folds: PagedFoldState<PersonFamilyContent.Fold> = PagedFoldState()) -> PersonFamilyContent {
        PersonFamilyContent(family: family, folds: folds, locale: en)
    }
    private func pages(_ revealed: [PersonFamilyContent.Fold], _ count: Int = 1) -> PagedFoldState<PersonFamilyContent.Fold> {
        var state = PagedFoldState<PersonFamilyContent.Fold>()
        for fold in revealed { state.reveal(fold, pages: count) }
        return state
    }
    private func names(_ tiles: [PersonCardLink]) -> [String] { tiles.map(\.content.title.text) }
    private func parents(_ content: PersonFamilyContent) -> [[String]] { content.siblingGroups.map { names($0.parents) } }
    private func children(_ content: PersonFamilyContent) -> [[String]] { content.siblingGroups.map { names($0.children) } }
    private func ids(_ content: PersonFamilyContent) -> [String] { content.allTiles.map(\.id) }

    /// The person alone with `units`: a family that needs only the right column.
    private func rightOnly(_ units: [CatalogFamilyUnit]) -> CatalogPersonFamily {
        var family = Data.alone
        family.units = units
        return family
    }

    /// A sibling group of `count` children named `"\(prefix) 0"…`, ids `"\(prefix)0"…`.
    private func members(_ prefix: String, _ count: Int) -> [CatalogFamilyMember] {
        (0..<count).map { Data.member("\(prefix)\($0)", "\(prefix.uppercased()) \($0)") }
    }

    // MARK: Groups

    /// T-4 (AC-1.1 – AC-1.6, AC-1.7, D-6)
    @Test func siblingGroupsFromFamily() {
        let full = content(Data.full)
        #expect(parents(full) == [["Heinrich Weber", "Anna Weber"], ["Anna Weber"]])
        #expect(children(full) == [
            ["Margarethe Weber", "Johann Weber", "Friedrich Weber", "Wilhelm Weber"], ["Christian Weber"],
        ])
        #expect(full.siblingGroups[0].children.map(\.content.isFocus) == [false, true, false, false])
        #expect(full.siblingGroups[0].children[1].location == nil && full.siblingGroups[0].children[1].content.role == nil)
        #expect(full.groups.map { $0.partner?.content.title.text } == ["Maria Schulz", "Sophie Brandt", nil])
        #expect(full.groups.map { names($0.children) } == [["Karl Weber", "Luise Weber", "Emma Weber"], ["Otto Weber"], ["Paul Weber"]])
        #expect(!full.isEmpty)
        // Anna is a parent in two groups: a tile in each, with different ids.
        #expect(full.siblingGroups[0].parents[1].id == "l-g0-anna" && full.siblingGroups[1].parents[0].id == "l-g1-anna")
        #expect(Set(ids(full)).count == ids(full).count)
        // Tab visits the tiles that open something, in reading order (AC-1.7).
        #expect(full.allTiles.filter { $0.location != nil }.map(\.content.title.text).prefix(8) == [
            "Heinrich Weber", "Anna Weber", "Margarethe Weber", "Friedrich Weber", "Wilhelm Weber", "Anna Weber", "Christian Weber",
            "Maria Schulz",
        ])

        let conflicting = content(Data.conflicting)
        #expect(parents(conflicting) == [
            ["Heinrich Weber", "Anna Weber", "Katharina Weber"], ["Heinrich Weber", "Anna Weber"], ["Heinrich Weber", "Katharina Weber"],
        ])
        #expect(children(conflicting) == [["Johann Weber", "Friedrich Weber"], ["Margarethe Weber", "Wilhelm Weber"], ["Christian Weber"]])
        #expect(Set(ids(conflicting)).count == ids(conflicting).count)

        let oneParent = content(Data.oneParentGroups)
        #expect(parents(oneParent) == [["Heinrich Weber", "Anna Weber"], ["Heinrich Weber"], ["Anna Weber"]])

        let unrelated = content(Data.unrelatedSets)
        #expect(parents(unrelated).map(\.count) == [4, 2, 2, 0])
        #expect(children(unrelated).last == ["Elisabeth Weber"])

        let only = content(Data.siblingsOnly)
        #expect(parents(only) == [[]] && children(only) == [["Clara Weber", "Johann Weber", "Karl Weber"]] && only.groups.isEmpty)

        let anna = content(Data.annaOnly)
        #expect(children(anna) == [["Anna Weber"]] && anna.siblingGroups[0].children[0].content.isFocus)
        #expect(anna.groups.count == 1 && anna.groups[0].children.count == 4)
    }

    @Test func aCoParentIsAPartnerAndNoPersonMeansNoFocus() {
        var family = Data.full
        family.units[0].partners[0].link = nil
        #expect(content(family).groups[0].partner?.content.title.text == "Maria Schulz")
        family.person = nil
        #expect(!content(family).allTiles.contains { $0.content.isFocus })
    }

    @Test func tilesOpenTheRelativeOnFamily() throws {
        let anna = try #require(content(Data.full).siblingGroups[0].parents.last)
        let summary = Data.summary("anna", "Anna Weber")
        #expect(anna.location == PersonsList.location(summary, orders: NameFormatOrders()).withPageSection(.family))
        #expect(anna.location?.pageSection == .family)
        #expect(anna.content.role == "Parent")
    }

    /// T-6 (AC-1.2 – AC-1.6, D-8)
    @Test func captionsAndGroupLabels() {
        func captions(_ family: CatalogPersonFamily) -> [String?] { content(family).siblingGroups.map(\.caption) }
        func labels(_ family: CatalogPersonFamily) -> [String] { content(family).siblingGroups.map(\.label) }
        let full = content(Data.full)
        #expect(captions(Data.full) == ["Parents", "Shared parent"])
        #expect(labels(Data.full) == ["This person, siblings and parents", "Children of Anna Weber"])
        #expect(full.rightCaption == "Partners and children")
        #expect(full.groups.map(\.label) == ["Partner Maria Schulz and children", "Partner Sophie Brandt and children", "Children"])

        #expect(captions(Data.conflicting) == ["Parents", "Shared parents", "Shared parents"])
        #expect(labels(Data.conflicting) == [
            "This person, siblings and parents", "Children of Heinrich Weber and Anna Weber", "Children of Heinrich Weber and Katharina Weber",
        ])
        #expect(captions(Data.oneParentGroups) == ["Parents", "Shared parent", "Shared parent"])
        #expect(labels(Data.oneParentGroups) == ["This person, siblings and parents", "Children of Heinrich Weber", "Children of Anna Weber"])
        #expect(captions(Data.unrelatedSets) == ["Parents", "Shared parents", "Shared parents", "Other siblings"])
        #expect(labels(Data.unrelatedSets).first == "This person and parents")
        #expect(labels(Data.unrelatedSets).last == "Other siblings")
        #expect(captions(Data.siblingsOnly) == ["Siblings"])
        #expect(labels(Data.siblingsOnly) == ["This person and siblings"])
        #expect(captions(Data.annaOnly) == [nil])
        #expect(labels(Data.annaOnly) == ["This person"])
        #expect(content(Data.annaOnly).rightCaption == "Partner and children")

        var oneParent = Data.alone
        oneParent.siblingGroups = [Data.group([Data.member("dorothea", "Dorothea Weber")], [Data.member("heinrich", "Heinrich Weber"), Data.johannMember])]
        #expect(captions(oneParent) == ["Parent"])
        #expect(labels(oneParent) == ["This person, siblings and parent"])
        oneParent.siblingGroups[0].children = [Data.johannMember]
        #expect(labels(oneParent) == ["This person and parent"])

        var partnerAlone = Data.annaOnly
        partnerAlone.units[0].children = []
        let alone = content(partnerAlone)
        #expect(alone.rightCaption == "Partner" && alone.groups[0].label == "Partner Heinrich Weber")

        #expect(content(rightOnly([Data.unit(.oneParent, children: [Data.member("kid", "Kid Weber")])])).rightCaption == "Children")

        var twoPartners = Data.full
        twoPartners.units = [twoPartners.units[0], twoPartners.units[1]]
        twoPartners.units[0].children = []
        twoPartners.units[1].children = []
        #expect(content(twoPartners).rightCaption == "Partners")
    }

    @Test func fiftyMembersKeepOrder() {
        let kids = (0..<50).map { Data.member("kid\($0)", "Kid \($0)") }
        let family = rightOnly([Data.unit(.partner, partners: [Data.member("sam", "Sam Weber")], children: kids)])
        let tiles = content(family, folds: pages([.children(0)])).groups[0].children
        #expect(tiles.count == 50 && names(tiles) == (0..<50).map { "Kid \($0)" })
        #expect(Set(tiles.map(\.id)).count == 50)
    }

    // MARK: Folds

    /// T-7 (AC-1.8, AC-1.9, D-7)
    @Test func foldsEachListAtThirty() {
        #expect(PersonFamilyContent.fold.limit == 30)
        let kids = (0..<50).map { Data.member("kid\($0)", "Kid \($0)") }
        let children = content(rightOnly([Data.unit(.partner, partners: [Data.member("sam", "Sam Weber")], children: kids)]))
        #expect(children.groups[0].children.count == 30 && children.groups[0].childrenHidden == 20)
        #expect(names(children.groups[0].children) == (0..<30).map { "Kid \($0)" })

        // 20 siblings in the person's group and 20 in a group under Anna: the first 30 show.
        var twoGroups = Data.alone
        twoGroups.siblingGroups = [
            Data.group([Data.heinrich, Data.anna], [Data.johannMember] + members("a", 20)),
            Data.group([Data.anna], members("b", 20)),
        ]
        let split = content(twoGroups)
        #expect(split.siblingGroups.count == 2 && split.siblingGroups[0].children.count == 21)
        #expect(split.siblingGroups[1].children.count == 10 && split.siblingGroups[1].parents.map(\.id) == ["l-g1-anna"])
        #expect(split.siblingsHidden == 10)
        #expect(split.firstRevealed(by: .siblings) == "l-g1-b10")
        let more = content(twoGroups, folds: pages([.siblings]))
        #expect(more.siblingGroups[1].children.count == 20 && more.siblingsHidden == 0 && more.firstRevealed(by: .siblings) == nil)

        let partners = (0..<40).map { Data.unit(.partner, partners: [Data.member("mate\($0)", "Mate \($0)")]) }
        let groups = content(rightOnly(partners))
        #expect(groups.groups.count == 30 && groups.groupsHidden == 10)

        #expect(content(Data.full).siblingsHidden == 0)
        #expect(content(Data.full).groupsHidden == 0 && content(Data.full).groups.allSatisfy { $0.childrenHidden == 0 })
    }

    @Test func aGroupShowsWhenItsFirstChildDoes() {
        var family = Data.alone
        family.siblingGroups = [
            Data.group([Data.heinrich, Data.anna], [Data.johannMember] + members("a", 30)),
            Data.group([Data.anna], members("b", 5)),
        ]
        let closed = content(family)
        #expect(closed.siblingGroups.count == 1 && closed.siblingsHidden == 5)
        #expect(closed.firstRevealed(by: .siblings) == "l-g1-anna")
        let open = content(family, folds: pages([.siblings]))
        #expect(open.siblingGroups.count == 2 && open.siblingGroups[1].children.count == 5)
        #expect(open.siblingsHidden == 0)
    }

    @Test func expandedShowsAll() {
        let kids = (0..<50).map { Data.member("kid\($0)", "Kid \($0)") }
        let mates = (0..<40).map { Data.unit(.partner, partners: [Data.member("mate\($0)", "Mate \($0)")], children: kids) }
        var family = rightOnly(mates)
        family.siblingGroups = [Data.group([Data.heinrich], [Data.johannMember] + members("sib", 40))]
        let folded = content(family)
        #expect(folded.siblingsHidden == 10 && folded.groupsHidden == 10)
        #expect(folded.groups[0].childrenHidden == 20)

        var everything: [PersonFamilyContent.Fold] = [.siblings, .partners]
        for index in 0..<40 { everything.append(.children(index)) }
        let open = content(family, folds: pages(everything))
        #expect(open.siblingGroups[0].children.count == 41 && open.groups.count == 40)
        #expect(open.siblingsHidden == 0 && open.groupsHidden == 0)
        #expect(open.groups.allSatisfy { $0.children.count == 50 && $0.childrenHidden == 0 })
        #expect(open.allTiles.count == 1 + 41 + 40 + 40 * 50)
    }

    @Test func foldKeepsTheFocus() {
        let siblings = members("sib", 49)
        var family = Data.alone
        family.siblingGroups = [Data.group([], Array(siblings[..<45]) + [Data.johannMember] + Array(siblings[45...]))]
        let folded = content(family)
        #expect(folded.siblingGroups[0].children.count == 31 && folded.siblingsHidden == 19)
        #expect(names(folded.siblingGroups[0].children) == (0..<30).map { "SIB \($0)" } + ["Johann Weber"])
        #expect(folded.siblingGroups[0].children.last?.content.isFocus == true)
    }

    @Test func childrenAndSiblingsPage() {
        let kids = (0..<100).map { Data.member("kid\($0)", "Kid \($0)") }
        let hundred = rightOnly([Data.unit(.partner, partners: [Data.member("sam", "Sam Weber")], children: kids)])
        let counts = (0...2).map { content(hundred, folds: pages([.children(0)], $0)).groups[0].children.count }
        #expect(counts == [30, 80, 100])
        let folded = content(hundred)
        #expect(folded.firstRevealed(by: .children(0)) == "r-0-kid30")
        #expect(PersonFamilyContent.fold.nextPageCount(hidden: folded.groups[0].childrenHidden) == 50)
        #expect(content(hundred, folds: pages([.children(0)], 1)).firstRevealed(by: .children(0)) == "r-0-kid80")
        #expect(content(hundred, folds: pages([.children(0)], 2)).firstRevealed(by: .children(0)) == nil)

        // 130 siblings with the person 40th in Go's order: the fold counts the others only.
        let others = members("sib", 129)
        var family = Data.alone
        family.siblingGroups = [Data.group([], Array(others[..<39]) + [Data.johannMember] + Array(others[39...]))]
        let closed = content(family)
        #expect(closed.siblingGroups[0].children.count == 31 && closed.siblingGroups[0].children.last?.content.isFocus == true)
        #expect(closed.siblingsHidden == 99)
        #expect(PersonFamilyContent.fold.nextPageCount(hidden: closed.siblingsHidden) == 50)
        #expect(closed.firstRevealed(by: .siblings) == "l-g0-sib30")
        let paged = content(family, folds: pages([.siblings]))
        #expect(paged.siblingGroups[0].children.count == 81 && paged.siblingsHidden == 49)
        #expect(paged.siblingGroups[0].children[39].content.isFocus)
        #expect(paged.firstRevealed(by: .siblings) == "l-g0-sib80")
        #expect(paged.firstRevealed(by: .siblings) != paged.siblingGroups[0].children[39].id)
    }

    @Test func partnersFoldNamesTheFirstRevealedUnit() {
        let tileID = PersonFamilyContent.tileID
        let partners = (0..<31).map { Data.unit(.partner, partners: [Data.member("sp\($0)", "Spouse \($0)")]) }
        let partnered = content(rightOnly(partners))
        #expect(partnered.groups.count == 30)
        #expect(partnered.firstRevealed(by: .partners) == tileID("r", "30", "sp30"))

        // A unit with no other parent has no partner tile: its first child takes the keyboard.
        let lone = (0..<30).map { Data.unit(.partner, partners: [Data.member("sp\($0)", "Spouse \($0)")]) }
            + [Data.unit(.oneParent, children: [Data.member("only", "Only Weber"), Data.member("second", "Second Weber")])]
        #expect(content(rightOnly(lone)).firstRevealed(by: .partners) == tileID("r", "30", "only"))
    }

    /// T-7 (AC-1.10): an anchor resolves to the tile, else to its fold's Show more.
    @Test func anchorResolvesToTheTileOrItsFold() throws {
        let tileID = PersonFamilyContent.tileID
        func target(_ content: PersonFamilyContent, _ id: String) -> String? {
            content.anchorStop(for: ConclusionSectionAnchor(part: .family, id: id)!)
        }

        let kids = (0..<35).map { Data.member("kid\($0)", "Kid \($0)") }
        let children = content(rightOnly([Data.unit(.partner, partners: [Data.member("sam", "Sam Weber")], children: kids)]))
        #expect(target(children, tileID("r", "0", "kid2")) == tileID("r", "0", "kid2"))
        #expect(target(children, tileID("r", "0", "kid32")) == PersonFamilyContent.moreID(.children(0)))
        #expect(PersonFamilyContent.moreID(.children(0)) == "more.children.0")
        #expect(target(children, tileID("l", "g0", "unknown")) == nil)
        // The focus person's tile opens nothing, so it is never an anchor.
        #expect(target(children, tileID("l", "g0", "johann")) == nil)

        // 32 units: the 31st and 32nd are behind the partners fold, partner and children alike.
        let units = (0..<32).map {
            Data.unit(.partner, partners: [Data.member("mate\($0)", "Mate \($0)")], children: [Data.member("child\($0)", "Child \($0)")])
        }
        let partnered = content(rightOnly(units))
        let partnersMore = PersonFamilyContent.moreID(.partners)
        #expect(target(partnered, tileID("r", "31", "mate31")) == partnersMore)
        #expect(target(partnered, tileID("r", "31", "child31")) == partnersMore)
        #expect(target(partnered, tileID("r", "29", "mate29")) == tileID("r", "29", "mate29"))

        // A one-parent unit's hidden child belongs to that unit's children fold.
        let lone = content(rightOnly([Data.unit(.oneParent, children: (0..<35).map { Data.member("only\($0)", "Only \($0)") })]))
        #expect(target(lone, tileID("r", "0", "only33")) == PersonFamilyContent.moreID(.children(0)))

        // Sibling groups: a hidden child, and a hidden group's parent, are behind the siblings fold.
        var family = Data.alone
        family.siblingGroups = [
            Data.group([Data.heinrich, Data.anna], [Data.johannMember] + members("a", 30)),
            Data.group([Data.anna], members("b", 5)),
        ]
        let origin = content(family)
        #expect(target(origin, tileID("l", "g0", "anna")) == tileID("l", "g0", "anna"))
        #expect(target(origin, tileID("l", "g0", "a3")) == tileID("l", "g0", "a3"))
        #expect(target(origin, tileID("l", "g1", "anna")) == PersonFamilyContent.moreID(.siblings))
        #expect(target(origin, tileID("l", "g1", "b2")) == PersonFamilyContent.moreID(.siblings))
        // An id from the old drawing, or another part, resolves to nothing.
        #expect(target(origin, "l-p0-anna") == nil && target(origin, "l-s-margarethe") == nil)
        #expect(origin.anchorStop(for: ConclusionSectionAnchor(part: .timeline, id: tileID("l", "g0", "a3"))!) == nil)
    }

    @Test func emptyFamilyIsEmpty() {
        #expect(content(Data.alone).isEmpty)
        #expect(content(CatalogPersonFamily(units: [])).isEmpty)
        #expect(!content(Data.full).isEmpty)
        #expect(!content(Data.annaOnly).isEmpty)
        // A group with no parents and a sibling is a family; so is a lone partner.
        #expect(!content(Data.siblingsOnly).isEmpty)
        #expect(!content(rightOnly([Data.unit(.partner, partners: [Data.member("sam", "Sam Weber")])])).isEmpty)
    }

    // MARK: Marriages

    /// T-5 (D-9): a bad index or end draws nothing, and does not crash.
    @Test func badCoupleIndexesDrawNothing() {
        var family = Data.married
        family.siblingGroups[0].coupleIndexes = [7]
        #expect(content(family).siblingGroups[0].marriages.isEmpty)
        // A couple whose B is not among the group's parents.
        family.couples = [Data.couple("heinrich", "nobody", Data.marriage("m-x", Data.day(1812, 5, 3), place: "Altona"))]
        family.siblingGroups[0].coupleIndexes = [0]
        #expect(content(family).siblingGroups[0].marriages.isEmpty)
        // A couple of one person with themselves.
        family.couples = [Data.couple("anna", "anna", Data.marriage("m-y", nil, place: nil))]
        #expect(content(family).siblingGroups[0].marriages.isEmpty)
        // A partner's bad index.
        family.units[0].coupleIndexes = [9]
        #expect(content(family).groups[0].marriages.isEmpty)
    }

    /// T-11 (AC-2.1 – AC-2.6, D-5, D-9)
    @Test func marriagesOfEachCouple() throws {
        let married = content(Data.married)
        let first = try #require(married.siblingGroups[0].marriages.first)
        #expect(married.siblingGroups[0].marriages.count == 1)
        #expect(first.marriage.line.accessibilityLabel == "Heinrich Weber and Anna Weber, married 3 May 1812, Altona")
        #expect(first.marriage.line.text == "m. 3 May 1812 · Altona")
        #expect(first.drawnAfter == 0 && first.spokenAfter == 1)
        #expect(married.siblingGroups[1].marriages.isEmpty)
        #expect(married.groups[0].marriages.map(\.line.accessibilityLabel) == ["Johann Weber and Maria Schulz, married 12 Jun 1841, Hamburg"])
        #expect(married.groups[0].marriages.map(\.line.text) == ["m. 12 Jun 1841 · Hamburg"])
        #expect(married.groups[1].marriages.isEmpty && married.groups[2].marriages.isEmpty)
        #expect(married.allMarriageLines.count == 2)
        #expect(Set(married.allMarriageLines.map(\.id)).count == 2)

        let halves = content(Data.marriageHalves)
        #expect(halves.siblingGroups[0].marriages.map(\.marriage.line.accessibilityLabel) == ["Heinrich Weber and Anna Weber, married in Altona"])
        #expect(halves.groups[0].marriages.map(\.line.accessibilityLabel) == ["Johann Weber and Maria Schulz, married 12 Jun 1841"])
        #expect(halves.groups[1].marriages.map(\.line.accessibilityLabel) == ["Johann Weber and Sophie Brandt, married"])
        #expect(halves.groups.prefix(2).flatMap { $0.marriages.map(\.line.text) } == ["m. 12 Jun 1841", "m."])
        #expect(halves.siblingGroups[0].marriages.map(\.marriage.line.text) == ["m. Altona"])

        let two = content(Data.twoMarriages)
        #expect(two.groups[0].marriages.map(\.line.text) == ["m. 12 Jun 1841 · Hamburg", "m. Lübeck"])

        let three = content(Data.threeParentMarriages)
        let lines = three.siblingGroups[0].marriages
        #expect(lines.map(\.marriage.line.accessibilityLabel) == [
            "married 3 May 1812, Altona, with Heinrich Weber", "married abt 1816, Kiel, with Heinrich Weber",
        ])
        #expect(lines.map(\.marriage.line.text) == [
            "m. 3 May 1812 · Altona, with Heinrich Weber", "m. abt 1816 · Kiel, with Heinrich Weber",
        ])
        #expect(lines.map(\.drawnAfter) == [0, 2] && lines.map(\.spokenAfter) == [1, 2])
        #expect(three.siblingGroups[1].marriages.map(\.marriage.line.accessibilityLabel)
            == ["Heinrich Weber and Anna Weber, married 3 May 1812, Altona"])
        #expect(three.siblingGroups[2].marriages.map(\.marriage.line.accessibilityLabel)
            == ["Heinrich Weber and Katharina Weber, married abt 1816, Kiel"])
        #expect(three.siblingGroups[2].marriages.map(\.marriage.line.text) == ["m. abt 1816 · Kiel"])

        // Without the person, a partner's line is spoken by its own label.
        var nobody = Data.married
        nobody.person = nil
        #expect(content(nobody).groups[0].marriages.map(\.line.accessibilityLabel) == ["married 12 Jun 1841, Hamburg"])
    }

    /// F-1: one marriage Event shared by three couples of a group's parents has one id per line, each
    /// naming its own partner.
    @Test func aMarriageOfThreeParentsHasOneIDPerLine() {
        var family = Data.threeParentMarriages
        let shared = Data.marriage("m-all", Data.day(1812, 5, 3), place: "Altona")
        family.couples = [
            Data.couple("heinrich", "anna", shared),
            Data.couple("heinrich", "katharina", shared),
            Data.couple("anna", "katharina", shared),
        ]
        family.siblingGroups[0].coupleIndexes = [0, 1, 2]
        let lines = content(family).siblingGroups[0].marriages.map(\.marriage)
        #expect(lines.count == 3)
        #expect(Set(lines.map(\.id)).count == 3)
        #expect(lines.map(\.line.accessibilityLabel) == [
            "married 3 May 1812, Altona, with Heinrich Weber",
            "married 3 May 1812, Altona, with Heinrich Weber",
            "married 3 May 1812, Altona, with Anna Weber",
        ])
        #expect(lines.map(\.id) == ["l-g0-m0-m-all", "l-g0-m1-m-all", "l-g0-m2-m-all"])
    }

    /// T-11 (AC-2.6, AC-2.7): a line hides with its group, and a type with no copy draws none.
    @Test func marriageLinesHideWithTheirTiles() {
        var family = Data.alone
        family.units = (0..<31).map { index in
            Data.unit(.partner, partners: [Data.member("sp\(index)", "Spouse \(index)")], couples: index == 0 ? [0] : index == 30 ? [1] : [])
        }
        family.couples = [
            Data.couple("johann", "sp0", Data.marriage("m-0", Data.day(1841, 6, 12), place: "Hamburg")),
            Data.couple("johann", "sp30", Data.marriage("m-30", nil, place: nil)),
        ]
        let folded = content(family)
        #expect(folded.groups.count == 30 && folded.allMarriageLines.count == 1)
        #expect(content(family, folds: pages([.partners])).allMarriageLines.count == 2)

        // A burial is not a marriage the spouse patterns draw.
        var burial = Data.married
        burial.couples[1].marriages = [PersonTimelinePreviewData.eventSummary("b1", type: SeededEventTypeTerm.burial)]
        #expect(content(burial).groups[0].marriages.isEmpty)
        var user = Data.married
        user.couples[1].marriages[0].eventTypeOrigin = "user"
        #expect(content(user).groups[0].marriages.isEmpty)
    }
}
