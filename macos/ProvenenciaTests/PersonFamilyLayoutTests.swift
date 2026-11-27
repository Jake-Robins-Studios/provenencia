import CoreGraphics
import Foundation
import Testing
@testable import Provenencia

struct PersonFamilyLayoutTests {
    private let en = Locale(identifier: "en_US")
    private typealias Data = PersonFamilyPreviewData

    private func layout(
        _ family: CatalogPersonFamily,
        revealed: [PersonFamilyContent.Fold] = [],
        width: CGFloat = 1038,
        _ widthClass: PVWidthClass = .regular
    ) -> (PersonFamilyContent, PersonFamilyLayout) {
        var folds = PagedFoldState<PersonFamilyContent.Fold>()
        for fold in revealed { folds.revealPage(fold) }
        let content = PersonFamilyContent(family: family, folds: folds, locale: en)
        return (content, PersonFamilyLayout(content: content, width: width, widthClass: widthClass))
    }

    /// The frame of the first tile titled `name`.
    private func frame(_ layout: PersonFamilyLayout, _ content: PersonFamilyContent, _ name: String) -> CGRect? {
        guard let tile = content.allTiles.first(where: { $0.content.title.text == name }) else { return nil }
        return layout.frame(of: tile.id)
    }

    private func verticals(_ layout: PersonFamilyLayout, at x: CGFloat) -> [CGRect] {
        layout.segments.filter { $0.minX == x && $0.width == 1 && $0.height > 1 }
    }

    private func horizontals(_ layout: PersonFamilyLayout, at y: CGFloat) -> [CGRect] {
        layout.segments.filter { $0.minY == y && $0.height == 1 && $0.width > 1 }
    }

    /// T-8 (AC-1.1, D-10)
    @Test func regularAndWideMeasures() throws {
        let (content, l) = layout(Data.full)
        #expect(l.columnWidth == 485 && l.rightX == 553 && l.busX == 521)
        let heinrich = try #require(l.frame(of: "l-g0-heinrich"))
        #expect(heinrich.origin == CGPoint(x: 20, y: 26) && heinrich.width == 485)
        #expect(try #require(l.frame(of: "l-g0-anna")).minY == 130)
        let margarethe = try #require(frame(l, content, "Margarethe Weber"))
        #expect(margarethe.minX == 52 && margarethe.width == 453 && margarethe.minY == 234)
        #expect(try #require(frame(l, content, "Wilhelm Weber")).minY == 546)
        // Group 1 sits 20 below group 0, under its own caption.
        #expect(l.captions.map(\.text) == ["Parents", "Shared parent", "Partners and children"])
        #expect(l.captions.map(\.origin) == [CGPoint(x: 20, y: 0), CGPoint(x: 20, y: 658), CGPoint(x: 553, y: 0)])
        #expect(try #require(l.frame(of: "l-g1-anna")).minY == 684)
        #expect(try #require(l.frame(of: "l-g1-christian")).minY == 788)
        // One line per group at x 10, from its first tile's centre to its last child's.
        let lines = verticals(l, at: 10).sorted { $0.minY < $1.minY }
        #expect(lines.map(\.minY) == [72, 730] && lines.map(\.maxY) == [593, 835])
        #expect(horizontals(l, at: 72).contains { $0.minX == 10 && $0.maxX == 20 })
        #expect(horizontals(l, at: margarethe.midY).contains { $0.minX == 10 && $0.maxX == 52 })

        let maria = try #require(frame(l, content, "Maria Schulz"))
        #expect(maria.minX == 553 && maria.minY == 26 && maria.midY == 72 && maria.width == 485)
        let paul = try #require(frame(l, content, "Paul Weber"))
        #expect(paul.minX == 585 && paul.midY == 728)
        let johann = try #require(frame(l, content, "Johann Weber"))
        // The focus's horizontal ends at the bus; the bus spans Maria's centre to Paul's.
        #expect(horizontals(l, at: johann.midY).contains { $0.minX == johann.maxX && $0.maxX == 521 })
        let bus = try #require(verticals(l, at: 521).first)
        #expect(bus.minY == 72 && bus.maxY == 729)
        // Tiles are listed left column, then right column.
        #expect(l.groups.map(\.label) == [
            "This person, siblings and parents", "Children of Anna Weber",
            "Partner Maria Schulz and children", "Partner Sophie Brandt and children", "Children",
        ])

        let (_, regular) = layout(Data.full, width: 1180, .regular)
        #expect(regular.columnWidth == 556 && PersonFamilyLayout.gutter(.regular) == 48)
        let (_, wide) = layout(Data.full, width: 1180, .wide)
        #expect(wide.columnWidth == 532 && PersonFamilyLayout.gutter(.wide) == 96 && wide.rightX == 20 + 532 + 96)
        // Nothing moves down between widths.
        for id in content.allTiles.map(\.id) {
            #expect(regular.frame(of: id)?.minY == wide.frame(of: id)?.minY)
        }
    }

    /// T-9 (AC-1.4, D-10)
    @Test func noLineLeavesItsGroup() throws {
        for family in [Data.conflicting, Data.oneParentGroups, Data.unrelatedSets, Data.full] {
            let (content, l) = layout(family)
            let left = l.groups.prefix(content.siblingGroups.count)
            for (a, b) in zip(left, left.dropFirst()) { #expect(!a.frame.intersects(b.frame)) }
            let lines = verticals(l, at: 10)
            for line in lines {
                #expect(left.filter { $0.frame.minY <= line.minY && line.maxY <= $0.frame.maxY }.count == 1)
            }
            let drawn = content.siblingGroups.filter { !$0.parents.isEmpty || $0.children.count > 1 }
            #expect(lines.count == drawn.count)
        }
        // Elisabeth stands alone at the margin: no line, no bracket.
        let (content, l) = layout(Data.unrelatedSets)
        let elisabeth = try #require(frame(l, content, "Elisabeth Weber"))
        #expect(elisabeth.minX == 20 && elisabeth.width == 485)
        #expect(!l.segments.contains { $0.minY <= elisabeth.midY && $0.maxY > elisabeth.midY })
    }

    @Test func siblingsOnlyAndTheFocusAlone() throws {
        let (content, l) = layout(Data.siblingsOnly)
        let clara = try #require(frame(l, content, "Clara Weber"))
        #expect(clara.origin == CGPoint(x: 20, y: 26))
        let line = try #require(verticals(l, at: 10).first)
        let karl = try #require(frame(l, content, "Karl Weber"))
        #expect(line.minY == clara.midY && line.maxY == karl.midY + 1)
        #expect(horizontals(l, at: clara.midY).contains { $0.minX == 10 && $0.maxX == 20 })
        #expect(l.captions.map(\.text) == ["Siblings"])

        let (annaContent, anna) = layout(Data.annaOnly)
        let focus = try #require(frame(anna, annaContent, "Anna Weber"))
        #expect(focus.origin == CGPoint(x: 20, y: 26))
        #expect(anna.captions.map(\.text) == ["Partner and children"])
        #expect(verticals(anna, at: 10).isEmpty)
    }

    /// A group of two parents, 49 siblings and the person last.
    private var crowd: CatalogPersonFamily {
        var family = Data.alone
        let kids = (0..<49).map { Data.member("kid\($0)", "Kid \($0)") }
        family.siblingGroups = [Data.group([Data.member("a", "A"), Data.member("b", "B")], kids + [Data.johannMember])]
        return family
    }

    @Test func fiftySiblingsStack() {
        let (content, l) = layout(crowd, revealed: [.siblings])
        let frames = content.allTiles.compactMap { l.frame(of: $0.id) }
        #expect(frames.count == 52)
        let expected: CGFloat = 26 + 52 * 104 - 12
        #expect(l.height == expected)
        for (a, b) in zip(frames, frames.dropFirst()) { #expect(!a.intersects(b)) }
    }

    @Test func fiftySiblingsFolded() throws {
        let (content, l) = layout(crowd)
        #expect(content.siblingGroups[0].children.count == 31 && content.siblingsHidden == 19)
        let group = try #require(l.groups.first)
        #expect(group.tiles.count == 33 && group.more.count == 1)
        // Parents, then children, then the row: the order VoiceOver reads.
        #expect(group.items.prefix(2).map(\.id) == ["l-g0-a", "l-g0-b"] && group.items.last?.id == "more.siblings")
        let more = try #require(group.more.first)
        #expect(more.fold == .siblings && more.count == 19 && more.frame.height == PersonFamilyLayout.moreRowHeight)
        let frames = group.tiles.map { $0.frame } + [more.frame]
        for (a, b) in zip(frames, frames.dropFirst()) { #expect(!a.intersects(b)) }
        // The group's frame holds the row, and so does the page.
        let absolute = more.frame.offsetBy(dx: group.frame.minX, dy: group.frame.minY)
        #expect(group.frame.contains(absolute) && l.height == absolute.maxY)
        // No line reaches the row.
        #expect(!l.segments.contains { $0.intersects(absolute) })
    }

    @Test func theMoreRowSitsInsideTheLastShownGroup() throws {
        var family = Data.alone
        family.siblingGroups = [
            Data.group([Data.heinrich, Data.anna], [Data.johannMember] + (0..<20).map { Data.member("a\($0)", "A \($0)") }),
            Data.group([Data.anna], (0..<20).map { Data.member("b\($0)", "B \($0)") }),
        ]
        let (_, l) = layout(family)
        #expect(l.groups.count == 2)
        #expect(l.groups[0].more.isEmpty)
        let more = try #require(l.groups[1].more.first)
        #expect(more.count == 10 && l.groups[1].items.last?.id == "more.siblings")
    }

    /// T-10 (AC-2.1, AC-2.4, AC-2.5, D-10, D-11)
    @Test func marriageLinesSitBetweenTheCouple() throws {
        let (_, married) = layout(Data.married)
        #expect(married.frame(of: "l-g0-m0-m-ha") == CGRect(x: 20, y: 124, width: 485, height: 21))
        #expect(try #require(married.frame(of: "l-g0-anna")).minY == 151)
        #expect(try #require(married.frame(of: "l-g0-margarethe")).minY == 255)
        #expect(married.frame(of: "r-0-m1-m-jm") == CGRect(x: 553, y: 26, width: 485, height: 21))
        #expect(try #require(married.frame(of: "r-0-maria")).minY == 51)
        // Sophie has no line.
        #expect(try #require(married.frame(of: "r-1-sophie")).minY == married.groups[3].frame.minY)

        let (_, two) = layout(Data.twoMarriages)
        #expect(two.frame(of: "r-0-m0-m-jm1") == CGRect(x: 553, y: 26, width: 485, height: 21))
        #expect(two.frame(of: "r-0-m0-m-jm2") == CGRect(x: 553, y: 47, width: 485, height: 21))
        #expect(try #require(two.frame(of: "r-0-maria")).minY == 72)

        let (three, l) = layout(Data.threeParentMarriages)
        #expect(l.frame(of: "l-g0-m0-m-ha") == CGRect(x: 20, y: 124, width: 485, height: 21))
        #expect(try #require(l.frame(of: "l-g0-anna")).minY == 151)
        #expect(try #require(l.frame(of: "l-g0-katharina")).minY == 255)
        #expect(l.frame(of: "l-g0-m1-m-hk") == CGRect(x: 20, y: 353, width: 485, height: 21))
        // The children start under the line that follows the last parent.
        #expect(try #require(frame(l, three, "Friedrich Weber")).minY == 380 + 104)
        // Each line is read just after its second parent.
        #expect(l.groups[0].items.prefix(5).map(\.id) == ["l-g0-heinrich", "l-g0-anna", "l-g0-m0-m-ha", "l-g0-katharina", "l-g0-m1-m-hk"])
        // The other two groups draw the same marriages with no name.
        #expect(l.frame(of: "l-g1-m0-m-ha")?.minY == (l.frame(of: "l-g1-heinrich")?.maxY ?? 0) + 6)
        #expect(l.frame(of: "l-g2-m1-m-hk")?.minY == (l.frame(of: "l-g2-heinrich")?.maxY ?? 0) + 6)

        // At a wide pane nothing moves down.
        let (_, wide) = layout(Data.threeParentMarriages, width: 1180, .wide)
        let (_, regular) = layout(Data.threeParentMarriages, width: 1180, .regular)
        for id in ["l-g0-m0-m-ha", "l-g0-m1-m-hk", "l-g1-m0-m-ha", "l-g2-m1-m-hk"] {
            #expect(wide.frame(of: id)?.minY == regular.frame(of: id)?.minY)
        }
    }
}
