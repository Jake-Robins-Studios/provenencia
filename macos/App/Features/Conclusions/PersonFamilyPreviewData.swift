#if DEBUG
import Foundation
import SwiftUI

/// Families for the Family section's `#Preview`s and tests: the S13-D3 sample
/// (Johann Weber) as Go returns it.
enum PersonFamilyPreviewData {
    static func summary(_ id: String, _ name: String?, born: Int32? = nil) -> CatalogPersonSummary {
        var h = CatalogPersonSummary(
            entity: CatalogCanonicalEntity(id: id, ref: "PER-\(id.uppercased())", subjectTypeID: "t", label: ""),
            name: name.map { CatalogNameValue(form: $0) },
            nameValueCount: name == nil ? 0 : 1
        )
        if let born { h.birth = CatalogLifeFacts(date: CatalogDateValueInput(kind: "point", startYear: born), dateCount: 1) }
        return h
    }

    static func member(_ id: String, _ name: String?, born: Int32? = nil, link: Bool = true) -> CatalogFamilyMember {
        CatalogFamilyMember(
            person: summary(id, name, born: born),
            link: link ? CatalogFamilyLink(recorded: true, associationIDs: [], implied: []) : nil
        )
    }

    static func unit(
        _ kind: CatalogFamilyUnit.Kind,
        partners: [CatalogFamilyMember] = [],
        children: [CatalogFamilyMember] = [],
        couples: [Int] = []
    ) -> CatalogFamilyUnit {
        CatalogFamilyUnit(kind: kind, partners: partners, children: children, coupleIndexes: couples)
    }

    /// A sibling group: the parents it shares with the person, its children, and the couples among its parents.
    static func group(
        _ parents: [CatalogFamilyMember],
        _ children: [CatalogFamilyMember],
        couples: [Int] = []
    ) -> CatalogSiblingGroup {
        CatalogSiblingGroup(parents: parents, children: children, coupleIndexes: couples)
    }

    /// The marriages of two people, by entity id, earliest first.
    static func couple(_ a: String, _ b: String, _ marriages: CatalogEventSummary...) -> CatalogFamilyCouple {
        CatalogFamilyCouple(aEntityId: a, bEntityId: b, marriages: marriages)
    }

    /// A marriage Event of a couple: dated by `date` as an occurrence, at `place`.
    static func marriage(_ id: String, _ date: CatalogDateValueInput?, place: String?) -> CatalogEventSummary {
        PersonTimelinePreviewData.eventSummary(
            id,
            type: SeededEventTypeTerm.marriage,
            dating: date.map { CatalogEventDating(kind: .occurrence, low: $0) },
            place: place
        )
    }

    static func day(_ year: Int32, _ month: Int32, _ day: Int32) -> CatalogDateValueInput {
        CatalogDateValueInput(kind: "point", startYear: year, startMonth: month, startDay: day)
    }

    static let johann = summary("johann", "Johann Weber", born: 1817)

    /// The person's own member: no link.
    static var johannMember: CatalogFamilyMember { CatalogFamilyMember(person: johann, link: nil) }

    static var heinrich: CatalogFamilyMember { member("heinrich", "Heinrich Weber") }
    static var anna: CatalogFamilyMember { member("anna", "Anna Weber") }
    static var katharina: CatalogFamilyMember { member("katharina", "Katharina Weber") }
    static var margarethe: CatalogFamilyMember { member("margarethe", "Margarethe Weber", born: 1815) }
    static var friedrich: CatalogFamilyMember { member("friedrich", "Friedrich Weber", born: 1820) }
    static var christian: CatalogFamilyMember { member("christian", "Christian Weber", born: 1823) }
    static var wilhelm: CatalogFamilyMember { member("wilhelm", "Wilhelm Weber") }

    /// The right column of the sample: Maria and her children, Sophie and Otto, and Paul with no other parent.
    private static func partnerUnits(maria: [Int] = [], sophie: [Int] = []) -> [CatalogFamilyUnit] {
        [
            unit(.partner, partners: [member("maria", "Maria Schulz")],
                 children: [member("karl", "Karl Weber"), member("luise", "Luise Weber"), member("emma", "Emma Weber")],
                 couples: maria),
            unit(.partner, partners: [member("sophie", "Sophie Brandt")], children: [member("otto", "Otto Weber")], couples: sophie),
            unit(.oneParent, children: [member("paul", "Paul Weber")]),
        ]
    }

    /// Frame F1: Margarethe, the person, Friedrich and Wilhelm share both parents; Christian only Anna.
    static var full: CatalogPersonFamily {
        CatalogPersonFamily(
            units: partnerUnits(),
            person: johann,
            siblingGroups: [
                group([heinrich, anna], [margarethe, johannMember, friedrich, wilhelm]),
                group([anna], [christian]),
            ]
        )
    }

    /// Frame F2 (11c): a third parent; Christian shares Heinrich and Katharina with no one but the person.
    static var conflicting: CatalogPersonFamily {
        CatalogPersonFamily(
            units: [],
            person: johann,
            siblingGroups: [
                group([heinrich, anna, katharina], [johannMember, friedrich]),
                group([heinrich, anna], [margarethe, wilhelm]),
                group([heinrich, katharina], [christian]),
            ]
        )
    }

    /// Frame F3: one-parent groups under a shared two-parent group.
    static var oneParentGroups: CatalogPersonFamily {
        CatalogPersonFamily(
            units: [],
            person: johann,
            siblingGroups: [
                group([heinrich, anna], [margarethe, johannMember, friedrich]),
                group([heinrich], [wilhelm]),
                group([anna], [christian]),
            ]
        )
    }

    /// Frame F4: the person's four parents, and siblings of two of them, and Elisabeth with no parent in common.
    static var unrelatedSets: CatalogPersonFamily {
        let georg = member("georg", "Georg Becker")
        let beckerKatharina = member("katharina-b", "Katharina Becker")
        return CatalogPersonFamily(
            units: [],
            person: johann,
            siblingGroups: [
                group([heinrich, anna, georg, beckerKatharina], [johannMember]),
                group([heinrich, anna], [margarethe, friedrich]),
                group([georg, beckerKatharina], [christian]),
                group([], [member("elisabeth", "Elisabeth Weber")]),
            ]
        )
    }

    /// Frame F6 (11d): the person and their siblings with no parent recorded.
    static var siblingsOnly: CatalogPersonFamily {
        CatalogPersonFamily(
            units: [],
            person: johann,
            siblingGroups: [
                group([], [member("clara", "Clara Weber", born: 1815), johannMember, member("karl", "Karl Weber", born: 1820)]),
            ]
        )
    }

    /// Frame M1: Heinrich and Anna married in 1812 at Altona, Johann and Maria in 1841 at Hamburg, Johann and
    /// Sophie are partners with no marriage.
    static var married: CatalogPersonFamily {
        var family = full
        family.siblingGroups[0].coupleIndexes = [0]
        family.units = partnerUnits(maria: [1])
        family.couples = [
            couple("heinrich", "anna", marriage("m-ha", day(1812, 5, 3), place: "Altona")),
            couple("johann", "maria", marriage("m-jm", day(1841, 6, 12), place: "Hamburg")),
        ]
        return family
    }

    /// Frame M2: a place only, a date only, neither.
    static var marriageHalves: CatalogPersonFamily {
        var family = full
        family.siblingGroups[0].coupleIndexes = [0]
        family.units = partnerUnits(maria: [1], sophie: [2])
        family.couples = [
            couple("heinrich", "anna", marriage("m-ha", nil, place: "Altona")),
            couple("johann", "maria", marriage("m-jm", day(1841, 6, 12), place: nil)),
            couple("johann", "sophie", marriage("m-js", nil, place: nil)),
        ]
        return family
    }

    /// Frame M3: Johann and Maria married twice, the second undated, at Lübeck.
    static var twoMarriages: CatalogPersonFamily {
        var family = full
        family.units = partnerUnits(maria: [0])
        family.couples = [
            couple(
                "johann", "maria",
                marriage("m-jm1", day(1841, 6, 12), place: "Hamburg"),
                marriage("m-jm2", nil, place: "Lübeck")
            ),
        ]
        return family
    }

    /// Frame M4: three parents, Heinrich married to Anna and to Katharina.
    static var threeParentMarriages: CatalogPersonFamily {
        var family = conflicting
        family.siblingGroups[0].coupleIndexes = [0, 1]
        family.siblingGroups[1].coupleIndexes = [0]
        family.siblingGroups[2].coupleIndexes = [1]
        family.couples = [
            couple("heinrich", "anna", marriage("m-ha", day(1812, 5, 3), place: "Altona")),
            couple(
                "heinrich", "katharina",
                marriage("m-hk", CatalogDateValueInput(kind: "point", qualifier: "ABT", startYear: 1816), place: "Kiel")
            ),
        ]
        return family
    }

    /// Frame 11h: Anna, with Heinrich as partner.
    static var annaOnly: CatalogPersonFamily {
        let anna = summary("anna", "Anna Weber", born: 1790)
        return CatalogPersonFamily(
            units: [unit(.partner, partners: [heinrich], children: [margarethe, member("johann", "Johann Weber", born: 1817), friedrich, wilhelm])],
            person: anna,
            siblingGroups: [group([], [CatalogFamilyMember(person: anna, link: nil)])]
        )
    }

    /// The person alone: one group, no parents and no sibling.
    static var alone: CatalogPersonFamily {
        CatalogPersonFamily(units: [], person: johann, siblingGroups: [group([], [johannMember])])
    }

    @MainActor
    static func diagram(_ family: CatalogPersonFamily, width: CGFloat = 1038) -> some View {
        ScrollView {
            PersonFamilyDiagram(
                content: PersonFamilyContent(family: family),
                projectDir: "/tmp/preview.provenencia",
                widthClass: .regular,
                accessibilityIdentifierRoot: "preview",
                open: { _, _ in }
            )
        }
        .frame(width: width, height: 900)
        .background(PVColor.surfacePage)
    }
}
#endif
