import AppKit
import Foundation
import Observation
import SwiftUI
import Testing
@testable import Provenencia

@Suite
@MainActor
struct WorkspaceNavigationTests {
    private let projectUuid = "00000000-0000-7000-8000-0000000000aa"

    private func tempNavigationFile() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nav-history-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("history.json", isDirectory: false)
    }

    private func entryCount(_ navigation: WorkspaceNavigation) -> Int {
        navigation.backJumpItems(limit: 100).count + navigation.forwardJumpItems(limit: 100).count + 1
    }

    private func attachedNavigation(fileURL: URL? = nil) throws -> (WorkspaceNavigation, URL) {
        let url = try fileURL ?? tempNavigationFile()
        let navigation = WorkspaceNavigation()
        navigation.attachProject(uuid: projectUuid, fileURL: url)
        return (navigation, url)
    }

    /// A graph, composer or Promote entry follows its graph to the Source it moved to (D-17):
    /// the entry is corrected only against a cached row of the same graph on another Source,
    /// and the place's identity then differs, so it remounts once.
    @Test func correctingGraphSource() {
        func graph(_ id: String, on sourceID: String) -> CatalogEvidenceGraph {
            CatalogEvidenceGraph(id: id, ref: "GPH-\(id)", sourceID: sourceID, name: id, description: "", artifactIDs: [])
        }
        let canvas = WorkspaceLocation.evidenceGraph(sourceId: "s1", graphId: "g1", title: "Hale", sourceTitle: "Census")
        let composer = WorkspaceLocation.citationComposer(
            sourceId: "s1", graphId: "g1", subjectId: "sub-1", sourceTitle: "Census"
        )
        let promote = WorkspaceLocation.promote(
            sourceId: "s1", graphId: "g1", subjectId: "sub-1", kind: .person, ref: "CPR-1", title: nil, sourceTitle: "Census"
        )

        for location in [canvas, composer, promote] {
            let corrected = location.correctingGraphSource(graph("g1", on: "s2"))
            #expect(corrected?.sourceId == "s2")
            #expect(corrected?.sourceTitle == nil)
            #expect(corrected?.graphId == "g1")
            #expect(corrected?.sourceSurface == location.sourceSurface)
            // Unchanged: the same Source, no cached row, another graph's row.
            #expect(location.correctingGraphSource(graph("g1", on: "s1")) == nil)
            #expect(location.correctingGraphSource(nil) == nil)
            #expect(location.correctingGraphSource(graph("g9", on: "s2")) == nil)
        }
        #expect(WorkspaceLocation.sourcePage(sourceId: "s1").correctingGraphSource(graph("g1", on: "s2")) == nil)

        // The host observes the pending correction, not the graph's Source: two entries for G1 that
        // both name S1 (canvas, then composer) after G1 moved to S2 each get their own correction,
        // though the graph's Source is S2 for both. Only places that follow their graph's Source
        // have one.
        let registry = PlaceRegistry.standard
        let projectKey = ProjectKey(projectDir: "/tmp/pending-graph-source.provenencia")
        let moved = graph("g1", on: "s2")
        for location in [canvas, composer, promote] {
            let place = registry.resolve(location, project: projectKey)
            #expect(place?.pendingGraphSourceCorrection(for: location, graph: moved)?.sourceId == "s2")
            #expect(place?.pendingGraphSourceCorrection(for: location, graph: graph("g1", on: "s1")) == nil)
        }
        let page = WorkspaceLocation.sourcePage(sourceId: "s1")
        #expect(registry.resolve(page, project: projectKey)?.pendingGraphSourceCorrection(for: page, graph: moved) == nil)

        // The two Sources' locations of one graph mount as different places.
        let project = ProjectKey(projectDir: "/tmp/correct-graph-source.provenencia")
        func identity(_ location: WorkspaceLocation) -> String? {
            PlaceRegistry.standard.resolve(location, project: project)?.viewIdentity
        }
        for location in [canvas, composer, promote] {
            var moved = location
            moved.sourceId = "s2"
            #expect(identity(location) != nil)
            #expect(identity(location) != identity(moved))
        }
    }

    @Test func leavingAGonePageShowsTheNoticeAndRewritesTheEntry() throws {
        for notice in ["Gone", nil] as [String?] {
            let (navigation, _) = try attachedNavigation()
            navigation.go(to: .sectionRoot(.sources))
            navigation.go(to: .evidenceGraph(sourceId: "src-1", graphId: "g-x", title: "Graph"))
            let session = WorkspaceSession(
                projectKey: ProjectKey(projectDir: "/tmp/leave-gone-page.provenencia"), store: FakeStore()
            )

            LeavesForSectionRoot.leave(notice: notice, navigation: navigation, session: session)

            #expect(navigation.currentLocation == .sectionRoot(.sources))
            let remembered = navigation.backJumpItems(limit: 100) + navigation.forwardJumpItems(limit: 100)
            #expect(!remembered.contains { $0.location.graphId == "g-x" })
            if let notice {
                #expect(session.toasts.cards == [ToastCard(.info, notice)])
            } else {
                #expect(session.toasts.cards.isEmpty)
            }
        }
    }

    @Test func eventsListAndDetailStayOffThePersonsPlace() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.events))
        navigation.go(to: .eventDetail(entityId: "evt-1", ref: "EVT-1", title: "Fire at York"))
        #expect(navigation.currentLocation.section == .events)
        #expect(navigation.currentLocation.entityId == "evt-1")
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.events))
        #expect(navigation.currentLocation.section != .persons)
        navigation.goForward()
        #expect(navigation.currentLocation.entityId == "evt-1")
        #expect(navigation.currentLocation.section == .events)
        navigation.goBack()
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.sources))
    }

    @Test func replaceCurrentUpdatesTheEntryWithoutAPush() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.events))
        let before = entryCount(navigation)
        var recorded: [WorkspaceLocation] = []
        navigation.onLocationCommit = { recorded.append($0) }

        var next = WorkspaceLocation(section: .sources, sourceId: "s1", graphId: "g-1", sourceSurface: .citationComposer)
        next.artifactId = "art-1"
        navigation.replaceCurrent(with: next)

        #expect(navigation.currentLocation == next)
        #expect(entryCount(navigation) == before)
        #expect(recorded == [next])
        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation == next)
    }

    @Test func attachProjectSetsUuidAndCommitsSynchronously() throws {
        let (seed, url) = try attachedNavigation()
        seed.go(to: WorkspaceLocation.sectionRoot(.sources).withListSelection("s3"))

        let navigation = WorkspaceNavigation()
        var recorded: [WorkspaceLocation] = []
        navigation.onLocationCommit = { recorded.append($0) }
        navigation.attachProject(uuid: projectUuid, fileURL: url)

        #expect(navigation.projectUuid == projectUuid)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(navigation.currentLocation.revisit.listSelection == "s3")
        #expect(recorded.count == 1)
        #expect(recorded[0].revisit.listSelection == "s3")

        navigation.attachProject(uuid: projectUuid, fileURL: url)
        #expect(recorded.count == 1)
    }

    @Test func defaultsToSources() {
        let navigation = WorkspaceNavigation()
        #expect(navigation.selectedSection == .sources)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
    }

    @Test func selectingEachSectionUpdatesLocation() {
        let navigation = WorkspaceNavigation()
        for section in WorkspaceSection.allCases {
            navigation.go(to: .sectionRoot(section))
            #expect(navigation.selectedSection == section)
            #expect(navigation.currentLocation == .sectionRoot(section))
        }
    }

    @Test func goPushesAndCoalescesIdentical() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.metadata))
        #expect(navigation.canGoBack)
        navigation.go(to: .sectionRoot(.metadata))
        // Identical to current — no second push; still one step back to Sources.
        #expect(navigation.canGoBack)
        #expect(!navigation.canGoForward)

        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", title: "A"))
        #expect(navigation.currentLocation.sourceId == "src-1")

        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", title: "Renamed"))
        // Title fluff must not push a second identical place.
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
    }

    @Test func goTruncatesForwardFromMiddle() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.metadata))
        navigation.go(to: .sectionRoot(.sourceTypes))
        navigation.go(to: .sectionRoot(.sources))
        navigation.goBack()
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
        #expect(navigation.canGoForward)

        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-9"))
        #expect(!navigation.canGoForward)
        #expect(navigation.currentLocation.sourceId == "src-9")
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
    }

    @Test func backForwardAndJumpIndex() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.metadata))
        navigation.go(to: WorkspaceLocation(section: .metadata, fieldId: "fld-1", title: "Author"))
        navigation.go(to: .sectionRoot(.sourceTypes))

        #expect(navigation.canGoBack)
        navigation.goBack()
        #expect(navigation.currentLocation.fieldId == "fld-1")
        navigation.goForward()
        #expect(navigation.currentLocation == .sectionRoot(.sourceTypes))

        navigation.go(toIndex: 0)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(navigation.canGoForward)
        navigation.go(toIndex: 2)
        #expect(navigation.currentLocation.fieldId == "fld-1")
    }

    @Test func persistRoundTripRestoresIndex() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", ref: "SRC-AAAA", title: "Deed"))
        navigation.go(to: WorkspaceLocation(section: .sourceTypes, typeId: "typ-1", title: "Deed book"))
        navigation.goBack()
        #expect(navigation.currentLocation.sourceId == "src-1")

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation.sourceId == "src-1")
        #expect(reloaded.canGoBack)
        #expect(reloaded.canGoForward)
        reloaded.goForward()
        #expect(reloaded.currentLocation.typeId == "typ-1")
    }

    @Test func sourcesListAndPageRoundTrip() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-42", ref: "SRC-4242", title: "Census"))
        #expect(navigation.selectedSection == .sources)
        #expect(navigation.currentLocation.sourceId == "src-42")

        navigation.go(to: .sectionRoot(.sources))
        #expect(navigation.currentLocation.sourceId == nil)
        navigation.goBack()
        #expect(navigation.currentLocation.sourceId == "src-42")
    }

    @Test func vocabularySelectionPushAndRestore() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.metadata))
        navigation.go(to: WorkspaceLocation(section: .metadata, fieldId: "fld-9", title: "Place"))
        navigation.go(to: .sectionRoot(.sourceTypes))
        navigation.go(to: WorkspaceLocation(section: .sourceTypes, typeId: "typ-9", title: "Will"))

        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.sourceTypes))
        navigation.goBack()
        #expect(navigation.currentLocation.fieldId == "fld-9")
        navigation.goForward()
        navigation.goForward()
        #expect(navigation.currentLocation.typeId == "typ-9")
    }

    @Test func propertiesTwoLevelSelectionPushAndRestore() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.properties))
        navigation.go(to: WorkspaceLocation(section: .properties, subjectTypeKey: "person", title: "Person"))
        navigation.go(
            to: WorkspaceLocation(
                section: .properties,
                subjectTypeKey: "person",
                propertyId: "prop-name",
                title: "Name"
            )
        )
        navigation.go(to: .sectionRoot(.sources))

        navigation.goBack()
        #expect(navigation.selectedSection == .properties)
        #expect(navigation.currentLocation.subjectTypeKey == "person")
        #expect(navigation.currentLocation.propertyId == "prop-name")
        navigation.goBack()
        #expect(navigation.currentLocation.subjectTypeKey == "person")
        #expect(navigation.currentLocation.propertyId == nil)
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.properties))
        navigation.goForward()
        navigation.goForward()
        #expect(navigation.currentLocation.propertyId == "prop-name")

        // Category and property are both identity, so a strip change is its own entry
        // and title fluff still coalesces.
        #expect(
            WorkspaceLocation(section: .properties, subjectTypeKey: "person", propertyId: "prop-name")
                != WorkspaceLocation(section: .properties, propertyId: "prop-name")
        )
        #expect(
            WorkspaceLocation(section: .properties, subjectTypeKey: "person", propertyId: "prop-name", title: "A")
                == WorkspaceLocation(section: .properties, subjectTypeKey: "person", propertyId: "prop-name", title: "B")
        )

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation.subjectTypeKey == "person")
        #expect(reloaded.currentLocation.propertyId == "prop-name")
    }

    @Test(arguments: [
        ("files", WorkspaceSection.sources),
        ("source-fields", WorkspaceSection.metadata),
        ("subject-fields", WorkspaceSection.properties),
    ])
    func retiredSectionIdsDecodeToTheirSection(id: String, section: WorkspaceSection) throws {
        let json = Data("""
        {"section":"\(id)"}
        """.utf8)
        let location = try JSONDecoder().decode(WorkspaceLocation.self, from: json)
        #expect(location == .sectionRoot(section))
        #expect(location.subjectTypeKey == nil)
        #expect(location.propertyId == nil)
        #expect(WorkspaceSection(id: id) == section)
    }

    @Test func currentSectionIdsRoundTrip() throws {
        for section in WorkspaceSection.allCases {
            #expect(WorkspaceSection(id: section.rawValue) == section)
            let data = try JSONEncoder().encode(WorkspaceLocation.sectionRoot(section))
            #expect(try JSONDecoder().decode(WorkspaceLocation.self, from: data) == .sectionRoot(section))
        }
        #expect(WorkspaceSection(id: "nope") == nil)
    }

    /// A history file saved before S9-07b keeps its entries and raises no
    /// "history couldn't load" reset.
    @Test func historyWithRetiredSectionIdsLoadsIntact() throws {
        let url = try tempNavigationFile()
        let json = """
        {"v":1,"projectUuid":"\(projectUuid)","index":1,"entries":[{"section":"source-fields"},{"section":"subject-fields"}]}
        """
        try Data(json.utf8).write(to: url)
        let (navigation, _) = try attachedNavigation(fileURL: url)
        #expect(navigation.lastHistoryIssue == nil)
        #expect(navigation.currentLocation == .sectionRoot(.properties))
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
    }

    @Test func engineLocationWithRetiredSectionIdResolves() {
        var proto = Provenencia_Engine_V1_WorkspaceLocation()
        proto.section = "source-fields"
        proto.fieldID = "fld-1"
        let location = GoStore.mapWorkspaceLocationFromProto(proto)
        #expect(location.section == .metadata)
        #expect(location.fieldId == "fld-1")
        proto.section = "metadata"
        #expect(GoStore.mapWorkspaceLocationFromProto(proto).section == .metadata)
    }

    @Test func missingEntityPruneRewritesCurrentEntry() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "gone", title: "Deleted"))
        navigation.fallbackToSectionRoot()
        #expect(navigation.currentLocation == .sectionRoot(.sources))

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation == .sectionRoot(.sources))
        #expect(reloaded.currentLocation.sourceId == nil)
    }

    @Test func locationEqualityIgnoresTitleAndRef() {
        let a = WorkspaceLocation(section: .sources, sourceId: "1", ref: "SRC-1", title: "Old")
        let b = WorkspaceLocation(section: .sources, sourceId: "1", ref: "SRC-2", title: "New")
        #expect(a == b)
        var scrolled = WorkspaceLocation.sectionRoot(.persons)
        scrolled.revisit.listSelection = "person-1"
        #expect(scrolled == .sectionRoot(.persons))
        #expect(a != WorkspaceLocation(section: .sources, sourceId: "2"))
        #expect(
            WorkspaceLocation.sourcePage(sourceId: "1")
                != WorkspaceLocation(section: .sources, sourceId: "1", graphId: "g-1", sourceSurface: .graph)
        )
    }

    @Test func legacyHistoryMissingSourceSurfaceDecodesAsPage() throws {
        let json = Data("""
        {"section":"sources","sourceId":"src-legacy","title":"Deed"}
        """.utf8)
        let location = try JSONDecoder().decode(WorkspaceLocation.self, from: json)
        #expect(location.sourceId == "src-legacy")
        #expect(location.sourceSurface == .page)
        #expect(location.title == "Deed")
        #expect(location.revisit.listSelection == nil)
    }

    /// T-12 (AC-1.5): canvas, composer and Promote locations keep their graph
    /// through the history file.
    @Test func graphLocationsRoundTripTheGraph() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .evidenceGraph(sourceId: "src-1", graphId: "g-1", title: "Deed"))
        navigation.go(to: .citationComposer(sourceId: "src-1", graphId: "g-1", subjectId: "sub-1"))
        navigation.go(to: .promote(
            sourceId: "src-1", graphId: "g-1", subjectId: "sub-1", kind: .person,
            ref: "CPR-1", title: "James", sourceTitle: "Deed"
        ))
        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        for surface in [SourceSurface.promote, .citationComposer, .graph] {
            #expect(reloaded.currentLocation.sourceSurface == surface)
            #expect(reloaded.currentLocation.graphId == "g-1")
            #expect(reloaded.currentLocation.sourceId == "src-1")
            reloaded.goBack()
        }
    }

    /// T-12 (AC-1.6): history written before graph ids named a Source with a
    /// graph surface and no graph; it decodes as that Source's page.
    @Test func legacyGraphSurfaceWithoutGraphDecodesAsPage() throws {
        for surface in ["graph", "citationComposer", "promote"] {
            let json = Data("""
            {"section":"sources","sourceId":"src-legacy","subjectId":"sub-1","sourceSurface":"\(surface)"}
            """.utf8)
            let location = try JSONDecoder().decode(WorkspaceLocation.self, from: json)
            #expect(location.sourceSurface == .page, "\(surface)")
            #expect(location.sourceId == "src-legacy")
            #expect(location.graphId == nil)
        }
        let withGraph = try JSONDecoder().decode(WorkspaceLocation.self, from: Data("""
        {"section":"sources","sourceId":"src-1","graphId":"g-1","sourceSurface":"graph"}
        """.utf8))
        #expect(withGraph.sourceSurface == .graph)
    }

    /// T-23 (AC-1.6, D-11): every way a location is built applies the same rule.
    @Test func graphSurfaceWithoutGraphBecomesThePage() {
        for surface in [SourceSurface.graph, .citationComposer, .promote] {
            for graphId in [nil, ""] as [String?] {
                let location = WorkspaceLocation(
                    section: .sources, sourceId: "src-1", graphId: graphId, sourceSurface: surface
                )
                #expect(location.sourceSurface == .page)
                #expect(location.sourceId == "src-1")
            }
            #expect(
                WorkspaceLocation(section: .sources, sourceId: "src-1", graphId: "g-1", sourceSurface: surface)
                    .sourceSurface == surface
            )
        }
        var proto = Provenencia_Engine_V1_WorkspaceLocation()
        proto.section = "sources"
        proto.sourceID = "src-1"
        proto.sourceSurface = "graph"
        let withoutGraph = GoStore.mapWorkspaceLocationFromProto(proto)
        #expect(withoutGraph.sourceSurface == .page)
        #expect(withoutGraph.sourceId == "src-1")
        proto.graphID = "g-1"
        let withGraph = GoStore.mapWorkspaceLocationFromProto(proto)
        #expect(withGraph.sourceSurface == .graph)
        #expect(withGraph.graphId == "g-1")
    }

    @Test func legacyHistoryMissingListSelectionDecodesAsNil() throws {
        let json = Data("""
        {"v":1,"projectUuid":"\(projectUuid)","index":0,"entries":[{"section":"persons"}]}
        """.utf8)
        let document = try JSONDecoder().decode(NavigationHistoryDocument.self, from: json)
        #expect(document.entries.count == 1)
        #expect(document.entries[0].revisit.listSelection == nil)
        #expect(document.entries[0] == .sectionRoot(.persons))
    }

    @Test func listSelectionRoundTrips() throws {
        var location = WorkspaceLocation.sectionRoot(.sources)
        location.revisit.listSelection = "src-1"
        let decoded = try JSONDecoder().decode(
            WorkspaceLocation.self,
            from: JSONEncoder().encode(location)
        )
        #expect(decoded.revisit.listSelection == "src-1")
        #expect(decoded == location)
    }

    /// T-1 (AC-2.5, AC-6.1, D-2): an open from a row writes the row onto the entry being left.
    @Test func sectionAnchorStampsTheEntryBeingLeft() throws {
        let (navigation, url) = try attachedNavigation()
        let anchor = try #require(ConclusionSectionAnchor(part: .family, id: "r-0-p2"))
        navigation.go(to: .personDetail(entityId: "p1", ref: "PER-1", title: "Ada"))
        navigation.go(
            to: .personDetail(entityId: "p2", ref: "PER-2", title: "Bo"), from: anchor
        )
        #expect(navigation.currentLocation.entityId == "p2")
        #expect(navigation.currentLocation.revisit.sectionAnchor == nil)

        navigation.goBack()
        #expect(navigation.currentLocation.entityId == "p1")
        #expect(navigation.currentLocation.revisit.sectionAnchor == anchor)

        navigation.goForward()
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.sectionAnchor == anchor)

        navigation.go(to: .sectionRoot(.places))
        navigation.goBack()
        #expect(navigation.currentLocation.entityId == "p1")
        #expect(navigation.currentLocation.revisit.sectionAnchor == anchor)

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation.revisit.sectionAnchor == anchor)

        // A row whose anchor cannot be built still opens its place and writes nothing.
        let (plain, _) = try attachedNavigation()
        plain.go(to: .personDetail(entityId: "p1", ref: "PER-1", title: "Ada"))
        plain.go(to: .personDetail(entityId: "p2", ref: "PER-2", title: "Bo"), from: nil)
        #expect(plain.currentLocation.entityId == "p2")
        plain.goBack()
        #expect(plain.currentLocation.entityId == "p1")
        #expect(plain.currentLocation.revisit.sectionAnchor == nil)
    }

    /// T-2 (AC-6.2, D-1): the anchor is not identity and decodes leniently.
    @Test func sectionAnchorIsNotIdentityAndDecodesLeniently() throws {
        let plain = WorkspaceLocation.personDetail(entityId: "p1", ref: "PER-1", title: nil)
        var anchored = plain
        anchored.revisit.sectionAnchor = ConclusionSectionAnchor(part: .family, id: "x")
        #expect(plain == anchored)

        for anchor in [
            ConclusionSectionAnchor(part: .family, id: "x"),
            ConclusionSectionAnchor(part: .timeline, id: "e-p", row: "e"),
        ] {
            var location = plain
            location.revisit.sectionAnchor = anchor
            let decoded = try JSONDecoder().decode(
                WorkspaceLocation.self, from: JSONEncoder().encode(location)
            )
            #expect(decoded.revisit.sectionAnchor == anchor)
        }

        for extra in [
            "",
            ",\"sectionAnchor\":{\"part\":\"zzz\",\"id\":\"x\"}",
            ",\"sectionAnchor\":{\"part\":\"family\",\"id\":\"\"}",
            ",\"sectionAnchor\":\"family:x\"",
        ] {
            let json = Data("{\"section\":\"persons\",\"entityId\":\"p1\"\(extra)}".utf8)
            let decoded = try JSONDecoder().decode(WorkspaceLocation.self, from: json)
            #expect(decoded.revisit.sectionAnchor == nil)
            #expect(decoded.entityId == "p1")
        }

        #expect(ConclusionSectionAnchor(part: .family, id: "") == nil)
        #expect(ConclusionSectionAnchor(part: .timeline, id: "c", row: "")?.row == nil)
    }

    /// T-4 (D-2): a visit to the place already open pushes nothing and writes no anchor.
    @Test func sectionAnchorSkipsACoalescedVisit() throws {
        let (navigation, _) = try attachedNavigation()
        let p1 = WorkspaceLocation.personDetail(entityId: "p1", ref: "PER-1", title: "Ada")
        navigation.go(to: p1)
        let count = entryCount(navigation)
        navigation.go(to: p1, from: ConclusionSectionAnchor(part: .family, id: "r-0-p1"))
        #expect(entryCount(navigation) == count)
        #expect(navigation.currentLocation.revisit.sectionAnchor == nil)
    }

    // MARK: Revisit (S16-72)

    private func decoded(_ json: String) throws -> WorkspaceLocation {
        try JSONDecoder().decode(WorkspaceLocation.self, from: Data(json.utf8))
    }

    /// D-8, AC-1.1, AC-1.2: the y the page was left at is written on the entry being left, and Back reads it.
    @Test func theRevisitIsStampedOnTheEntryBeingLeft() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .sourcePage(sourceId: "s1"))
        navigation.noteScrollOffset(600, slot: .page, arrival: navigation.arrival.id)
        navigation.go(to: .evidenceGraph(sourceId: "s1", graphId: "g1"))
        #expect(navigation.currentLocation.revisit.scrollOffsets.isEmpty)

        navigation.goBack()
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 600)
        navigation.goForward()
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 600)

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation.revisit.scrollOffsets[.page] == 600)
    }

    /// D-8, AC-1.10: a section switch on one record page starts the new section clean and keeps the old
    /// section's y.
    @Test func aSectionSwitchKeepsTheOldYAndStartsTheNewOneClean() throws {
        let (navigation, _) = try attachedNavigation()
        let vitals = WorkspaceLocation.personDetail(entityId: "p1", ref: "PER-1", title: "Ada")
        navigation.go(to: vitals)
        navigation.noteScrollOffset(900, slot: .page, arrival: navigation.arrival.id)
        navigation.go(to: navigation.currentLocation.withPageSection(.family))
        #expect(navigation.currentLocation.revisit.scrollOffsets.isEmpty)
        navigation.noteScrollOffset(40, slot: .page, arrival: navigation.arrival.id)

        navigation.goBack()
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 900)
        navigation.goForward()
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 40)
    }

    /// Selecting another row of a page whose selected row is a place keeps the visit and its y; each
    /// entry keeps its own for Back.
    @Test(arguments: [WorkspaceSection.metadata, .properties])
    func selectingOnThePageKeepsItsScroll(section: WorkspaceSection) throws {
        func row(_ id: String) -> WorkspaceLocation {
            section == .metadata
                ? WorkspaceLocation(section: section, fieldId: id)
                : WorkspaceLocation(section: section, subjectTypeKey: "person", propertyId: id)
        }
        let (first, second) = (row("a"), row("b"))
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: first)
        navigation.noteScrollOffset(300, slot: .page, arrival: navigation.arrival.id)
        let arrival = navigation.arrival
        navigation.go(to: second)
        #expect(navigation.arrival == arrival)
        navigation.go(to: .sectionRoot(.persons))
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 300)
        navigation.noteScrollOffset(700, slot: .page, arrival: navigation.arrival.id)
        navigation.goBack()
        #expect(navigation.currentLocation == first)
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 300)
        navigation.goForward()
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 700)
    }

    /// A category of the Properties strip is another page: it opens at its top.
    @Test func aPropertiesCategoryStartsClean() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .properties, subjectTypeKey: "person", propertyId: "a"))
        navigation.noteScrollOffset(300, slot: .page, arrival: navigation.arrival.id)
        let arrival = navigation.arrival.id
        navigation.go(to: WorkspaceLocation(section: .properties, subjectTypeKey: "event"))
        #expect(navigation.arrival.id == arrival + 1)
        navigation.go(to: .sectionRoot(.persons))
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.scrollOffsets.isEmpty)
    }

    /// D-8: a pushed location starts clean, whatever the copy it was built from held.
    @Test func aPushStartsClean() throws {
        let (navigation, _) = try attachedNavigation()
        var carrying = WorkspaceLocation.personDetail(entityId: "p1", ref: "PER-1", title: "Ada")
        carrying.revisit = WorkspaceRevisit(
            listSelection: "x", openSourceId: "s1", scrollOffsets: [.page: 5],
            sectionAnchor: ConclusionSectionAnchor(part: .family, id: "r-0-p2")
        )
        navigation.go(to: carrying)
        #expect(navigation.currentLocation.revisit == WorkspaceRevisit())

        let anchored = WorkspaceLocation.personDetail(entityId: "p2", ref: "PER-2", title: nil)
            .withPageSection(.family)
        var held = anchored
        held.revisit.sectionAnchor = ConclusionSectionAnchor(part: .family, id: "r-0-p2")
        navigation.go(to: held)
        #expect(navigation.currentLocation.revisit.sectionAnchor == nil)
    }

    /// D-7, D-8: a closing page's last note must not land on the next entry.
    @Test func aNoteOfAnotherArrivalIsDropped() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        let stale = navigation.arrival.id
        navigation.go(to: .sectionRoot(.places))
        navigation.noteScrollOffset(300, slot: .page, arrival: stale)
        navigation.noteScrollOffset(-5, slot: .page, arrival: navigation.arrival.id)
        navigation.noteScrollOffset(.infinity, slot: .page, arrival: navigation.arrival.id)
        navigation.go(to: .sectionRoot(.events))
        navigation.goBack()
        #expect(navigation.currentLocation.section == .places)
        #expect(navigation.currentLocation.revisit.scrollOffsets.isEmpty)
    }

    /// D-7: a visit begins on an identity change and on any history move, not on a coalesced visit.
    @Test func arrivalCountsIdentityChangesAndHistoryMoves() throws {
        let (navigation, _) = try attachedNavigation()
        let start = navigation.arrival.id
        navigation.go(to: .sectionRoot(.persons))
        #expect(navigation.arrival == WorkspaceArrival(id: start + 1, kind: .push))
        navigation.go(to: .sectionRoot(.persons))
        navigation.replaceCurrent(with: .sectionRoot(.persons).withListSelection("p1"))
        #expect(navigation.arrival.id == start + 1)

        navigation.go(to: .sectionRoot(.places))
        navigation.goBack()
        #expect(navigation.arrival == WorkspaceArrival(id: start + 3, kind: .history))
        navigation.goForward()
        #expect(navigation.arrival == WorkspaceArrival(id: start + 4, kind: .history))
        navigation.go(toIndex: 0)
        #expect(navigation.arrival == WorkspaceArrival(id: start + 5, kind: .history))
        navigation.go(to: .sectionRoot(.events))
        #expect(navigation.arrival == WorkspaceArrival(id: start + 6, kind: .push))
        navigation.fallbackToSectionRoot()
        #expect(navigation.arrival.id == start + 6)
    }

    /// D-9: `scrollOffsets` is a JSON object keyed by slot; an entry that is not a finite, non-negative
    /// number is dropped and the rest kept.
    @Test func scrollOffsetsRoundTripAndDecodeLeniently() throws {
        var location = WorkspaceLocation.sectionRoot(.persons)
        location.revisit.scrollOffsets = [.page: 1800, PVScrollSlot(rawValue: "second"): 12.5]
        let data = try JSONEncoder().encode(location)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["scrollOffsets"] as? [String: Double] == ["page": 1800, "second": 12.5])
        #expect(try JSONDecoder().decode(WorkspaceLocation.self, from: data).revisit.scrollOffsets == location.revisit.scrollOffsets)

        #expect(try decoded(#"{"section":"persons","scrollOffsets":{"page":-1}}"#).revisit.scrollOffsets.isEmpty)
        #expect(try decoded(#"{"section":"persons","scrollOffsets":{"page":"far","second":7,"third":null}}"#)
            .revisit.scrollOffsets == [PVScrollSlot(rawValue: "second"): 7])
        #expect(try decoded(#"{"section":"persons","scrollOffsets":[1,2]}"#).revisit.scrollOffsets.isEmpty)
        #expect(try decoded(#"{"section":"persons","scrollOffsets":{"page":4},"listScrollAnchor":9}"#).revisit.scrollOffsets == [.page: 4])
    }

    /// D-8, D-9, AC-2.2, AC-2.4, AC-2.5: the open Source is stamped on the Sources list root only, and
    /// never written to the file.
    @Test func theOpenSourceIsStampedOnTheSourcesListAndNeverWritten() throws {
        let (navigation, url) = try attachedNavigation()
        var open: String? = "s2"
        navigation.openSourceProvider = { open }
        navigation.go(to: .sourcePage(sourceId: "s1"))
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(navigation.currentLocation.revisit.openSourceId == "s2")

        // Leaving with none open stamps none; leaving another place stamps no open Source.
        open = nil
        navigation.go(to: .sectionRoot(.persons))
        open = "s9"
        navigation.go(to: .sectionRoot(.places))
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.persons))
        #expect(navigation.currentLocation.revisit.openSourceId == nil)
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(navigation.currentLocation.revisit.openSourceId == nil)

        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(!text.contains("openSourceId"))
    }

    /// D-9: a file written before the revisit keeps its selection and its section anchor.
    @Test func oldFilesKeepTheirSelectionAndSectionAnchor() throws {
        let location = try decoded(
            #"{"section":"persons","listScrollAnchor":"person-1","sectionAnchor":{"part":"family","id":"x"}}"#
        )
        #expect(location.revisit.listSelection == "person-1")
        #expect(location.revisit.sectionAnchor == ConclusionSectionAnchor(part: .family, id: "x"))
        #expect(location.revisit.scrollOffsets.isEmpty)

        var written = WorkspaceLocation.sectionRoot(.persons)
        written.revisit = location.revisit
        written.revisit.openSourceId = "s1"
        let object = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(written)) as? [String: Any]
        )
        #expect(object["listScrollAnchor"] as? String == "person-1")
        #expect(object["sectionAnchor"] is [String: Any])
        #expect(object["openSourceId"] == nil)
        #expect(object["revisit"] == nil)
    }

    /// D-8: a sort or filter change clears the selection, and the live y and open state stay.
    @Test func aCoalescedVisitClearsTheHeldSelection() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        navigation.noteListSelection("p1")
        navigation.noteScrollOffset(70, slot: .page, arrival: navigation.arrival.id)
        let arrival = navigation.arrival
        navigation.go(to: navigation.currentLocation.withListSelection(nil))
        #expect(navigation.listSelection == nil)
        #expect(navigation.arrival == arrival)

        navigation.go(to: .sectionRoot(.places))
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.listSelection == nil)
        #expect(navigation.currentLocation.revisit.scrollOffsets[.page] == 70)
    }

    /// D-8, AC-1.9: a quit writes the current page's y.
    @Test func flushWritesTheCurrentY() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.places))
        navigation.noteScrollOffset(700, slot: .page, arrival: navigation.arrival.id)
        navigation.flush()

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation == .sectionRoot(.places))
        #expect(reloaded.currentLocation.revisit.scrollOffsets[.page] == 700)
    }

    /// T-4 (AC-1.4, D-10): the Source types list is a list root, its page is not,
    /// and a noted scroll survives the page and Back.
    @Test func sourceTypesListIsAListRoot() throws {
        #expect(WorkspaceLocation.sectionRoot(.sourceTypes).isListRoot)
        #expect(!WorkspaceLocation.sourceTypePage(typeId: "typ-1", title: "Census").isListRoot)
        #expect(!WorkspaceLocation.sectionRoot(.metadata).isListRoot)

        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.sourceTypes))
        navigation.noteListSelection("typ-7")
        navigation.go(to: .sourceTypePage(typeId: "typ-1", title: "Census"))
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.sourceTypes))
        #expect(navigation.currentLocation.revisit.listSelection == "typ-7")
    }

    @Test func notingListScrollDoesNotPushHistory() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        let count = entryCount(navigation)
        navigation.noteListSelection("person-1")
        navigation.noteListSelection("person-2")
        #expect(entryCount(navigation) == count)
        #expect(!navigation.canGoForward)
        #expect(navigation.currentLocation.revisit.listSelection == nil)
    }

    @Test func theListSelectionFollowsHistory() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        #expect(navigation.listSelection == nil)

        navigation.noteListSelection("person-1")
        #expect(navigation.listSelection == "person-1")

        // A coalesced visit (the sidebar's Persons again) clears the selection with no Back.
        navigation.go(to: .sectionRoot(.persons))
        #expect(navigation.listSelection == nil)

        navigation.noteListSelection("person-2")
        navigation.go(to: .sectionRoot(.events))
        #expect(navigation.listSelection == nil)
        navigation.goBack()
        #expect(navigation.listSelection == "person-2")
    }

    @Test func leavingAListStampsTheOutgoingEntry() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        navigation.noteListSelection("person-1")
        navigation.go(to: .personDetail(entityId: "p1", ref: "PER-1", title: "Ada"))
        #expect(navigation.currentLocation.revisit.listSelection == nil)

        navigation.goBack()
        #expect(navigation.currentLocation.section == .persons)
        #expect(navigation.currentLocation.revisit.listSelection == "person-1")

        navigation.goForward()
        #expect(navigation.currentLocation.entityId == "p1")
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.listSelection == "person-1")

        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation.revisit.listSelection == "person-1")
    }

    @Test func forwardAndJumpRestoreTheStampedAnchor() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        navigation.noteListSelection("person-1")
        navigation.goBack()
        navigation.goForward()
        #expect(navigation.currentLocation == .sectionRoot(.persons))
        #expect(navigation.currentLocation.revisit.listSelection == "person-1")

        navigation.noteListSelection("person-4")
        navigation.go(to: .sectionRoot(.places))
        let persons = try #require(
            navigation.backJumpItems(limit: 15).first { $0.location.section == .persons }
        )
        navigation.go(toIndex: persons.index)
        #expect(navigation.currentLocation == .sectionRoot(.persons))
        #expect(navigation.currentLocation.revisit.listSelection == "person-4")
    }

    @Test func revisitingAListWithoutASelectionClearsItAndDoesNotPush() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        navigation.noteListSelection("person-1")
        navigation.go(to: .personDetail(entityId: "p1", ref: "PER-1", title: "Ada"))
        navigation.goBack()
        #expect(navigation.currentLocation.revisit.listSelection == "person-1")
        let count = entryCount(navigation)

        navigation.go(to: .sectionRoot(.persons))
        #expect(navigation.currentLocation.revisit.listSelection == nil)
        #expect(entryCount(navigation) == count)
        #expect(navigation.canGoForward)

        navigation.goBack()
        navigation.goForward()
        #expect(navigation.currentLocation == .sectionRoot(.persons))
        #expect(navigation.currentLocation.revisit.listSelection == nil)
    }

    @Test func goToGraphIsDistinctPlaceFromPage() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation.sourcePage(sourceId: "src-1"))
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", graphId: "g-1", sourceSurface: .graph))
        #expect(navigation.currentLocation.sourceSurface == .graph)
        #expect(navigation.selectedSection == .sources)
        #expect(navigation.canGoBack)
        navigation.goBack()
        #expect(navigation.currentLocation.sourceSurface == .page)
        #expect(navigation.currentLocation.sourceId == "src-1")
    }

    @Test func goToCitationComposerRestoresSubjectId() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", graphId: "g-1", sourceSurface: .graph))
        navigation.go(
            to: WorkspaceLocation(
                section: .sources,
                sourceId: "src-1",
                graphId: "g-1",
                subjectId: "sub-9",
                citationId: "cit-1",
                sourceSurface: .citationComposer,
                title: "Margt."
            )
        )
        #expect(navigation.currentLocation.sourceSurface == .citationComposer)
        #expect(navigation.currentLocation.subjectId == "sub-9")
        #expect(navigation.currentLocation.citationId == "cit-1")
        navigation.goBack()
        #expect(navigation.currentLocation.sourceSurface == .graph)
        #expect(navigation.currentLocation.subjectId == nil)
        #expect(
            WorkspaceLocation(
                section: .sources,
                sourceId: "src-1",
                graphId: "g-1",
                subjectId: "sub-9",
                sourceSurface: .citationComposer
            ) != WorkspaceLocation(
                section: .sources,
                sourceId: "src-1",
                graphId: "g-1",
                subjectId: "sub-9",
                citationId: "cit-1",
                sourceSurface: .citationComposer
            )
        )
    }

    @Test func goToCitationComposerRestoresObservationId() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", graphId: "g-1", sourceSurface: .graph))
        navigation.go(
            to: WorkspaceLocation(
                section: .sources,
                sourceId: "src-1",
                graphId: "g-1",
                subjectId: "sub-9",
                citationId: "cit-1",
                artifactId: "art-0",
                observationId: "obs-row",
                sourceSurface: .citationComposer
            )
        )
        #expect(navigation.currentLocation.observationId == "obs-row")
        #expect(navigation.currentLocation.artifactId == "art-0")
        navigation.goBack()
        #expect(navigation.currentLocation.observationId == nil)
        #expect(
            WorkspaceLocation(
                section: .sources,
                sourceId: "src-1",
                graphId: "g-1",
                subjectId: "sub-9",
                citationId: "cit-1",
                observationId: "obs-a",
                sourceSurface: .citationComposer
            ) != WorkspaceLocation(
                section: .sources,
                sourceId: "src-1",
                graphId: "g-1",
                subjectId: "sub-9",
                citationId: "cit-1",
                observationId: "obs-b",
                sourceSurface: .citationComposer
            )
        )
    }

    @Test func navigationFileNameStripsDashesAndBraces() {
        #expect(
            InstallPaths.navigationFileName(projectUuid: "{00000000-0000-7000-8000-0000000000AA}")
                == "000000000000700080000000000000aa.json"
        )
    }

    @Test func backJumpItemsNearestFirstAndCapped() throws {
        let (navigation, _) = try attachedNavigation()
        // indices: 0 sources, 1 fields, 2 types, 3 source detail, 4 deep source — current at 4
        navigation.go(to: .sectionRoot(.metadata))
        navigation.go(to: .sectionRoot(.sourceTypes))
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-0"))
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", title: "Deep"))

        let back = navigation.backJumpItems(limit: 2)
        #expect(back.map(\.index) == [3, 2])
        #expect(back[0].location.sourceId == "src-0")
        #expect(back[1].location == .sectionRoot(.sourceTypes))

        let allBack = navigation.backJumpItems(limit: 15)
        #expect(allBack.map(\.index) == [3, 2, 1, 0])
    }

    @Test func forwardJumpItemsStackOrderAndCapped() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.metadata))
        navigation.go(to: .sectionRoot(.sourceTypes))
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-0"))
        navigation.goBack()
        navigation.goBack()
        // current at metadata (index 1); forward: types (2), source detail (3)
        #expect(navigation.currentLocation == .sectionRoot(.metadata))

        let forward = navigation.forwardJumpItems(limit: 1)
        #expect(forward.map(\.index) == [2])
        #expect(forward[0].location == .sectionRoot(.sourceTypes))

        let allForward = navigation.forwardJumpItems(limit: 15)
        #expect(allForward.map(\.index) == [2, 3])
        #expect(allForward[1].location.sourceId == "src-0")
    }

    @Test func jumpItemsEmptyAtStackEnds() throws {
        let (navigation, _) = try attachedNavigation()
        #expect(navigation.backJumpItems().isEmpty)
        #expect(navigation.forwardJumpItems().isEmpty)

        navigation.go(to: .sectionRoot(.metadata))
        #expect(navigation.forwardJumpItems().isEmpty)
        #expect(navigation.backJumpItems().map(\.index) == [0])
    }

    @Test func corruptJSONFallsBackAndReportsLoadIssue() throws {
        let url = try tempNavigationFile()
        try Data("{not-json".utf8).write(to: url)

        let (navigation, _) = try attachedNavigation(fileURL: url)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(!navigation.canGoBack)
        #expect(navigation.lastHistoryIssue == .loadFailed)

        navigation.acknowledgeHistoryIssue()
        #expect(navigation.lastHistoryIssue == nil)
    }

    @Test func unwritablePathReportsPersistIssue() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nav-history-ro-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o555],
            ofItemAtPath: dir.path
        )
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: dir.path
            )
            try? FileManager.default.removeItem(at: dir)
        }

        let url = dir.appendingPathComponent("history.json", isDirectory: false)
        let navigation = WorkspaceNavigation()
        navigation.attachProject(uuid: projectUuid, fileURL: url)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(navigation.lastHistoryIssue == .persistFailed)

        navigation.acknowledgeHistoryIssue()
        #expect(navigation.lastHistoryIssue == nil)

        // In-memory navigation still works; further writes keep reporting.
        navigation.go(to: .sectionRoot(.metadata))
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
        #expect(navigation.lastHistoryIssue == .persistFailed)
    }

    @Test func missingHistoryFileDoesNotReportLoadIssue() throws {
        let (navigation, _) = try attachedNavigation()
        #expect(navigation.lastHistoryIssue == nil)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
    }

    @Test func locationCommitOnGo() {
        let navigation = WorkspaceNavigation()
        var committed: [WorkspaceLocation] = []
        navigation.onLocationCommit = { committed.append($0) }

        navigation.go(to: .sectionRoot(.metadata))
        #expect(committed == [.sectionRoot(.metadata)])
    }

    @Test func locationCommitOnAttachProjectRestore() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: WorkspaceLocation(section: .sources, sourceId: "src-1", title: "Deed"))
        navigation.go(to: WorkspaceLocation(section: .sourceTypes, typeId: "typ-1", title: "Book"))
        navigation.goBack()

        var committed: [WorkspaceLocation] = []
        let reloaded = WorkspaceNavigation()
        reloaded.onLocationCommit = { committed.append($0) }
        reloaded.attachProject(uuid: projectUuid, fileURL: url)

        #expect(committed.count == 1)
        #expect(committed[0].sourceId == "src-1")
    }

    @Test func locationCommitOnBackForward() throws {
        let (navigation, _) = try attachedNavigation()
        var committed: [WorkspaceLocation] = []
        navigation.onLocationCommit = { committed.append($0) }

        navigation.go(to: .sectionRoot(.metadata))
        navigation.go(to: .sectionRoot(.sourceTypes))
        committed.removeAll()

        navigation.goBack()
        #expect(committed.last == .sectionRoot(.metadata))

        navigation.goForward()
        #expect(committed.last == .sectionRoot(.sourceTypes))

        committed.removeAll()
        navigation.go(toIndex: 0)
        #expect(committed.last == .sectionRoot(.sources))
    }

    @Test func leaveGuardHoldsAndResumes() throws {
        let (navigation, _) = try attachedNavigation()
        let guardBox = HoldGuard()
        navigation.leaveGuard = guardBox
        navigation.go(to: .sectionRoot(.metadata))
        #expect(navigation.currentLocation == .sectionRoot(.sources))
        #expect(navigation.heldNavigation == .location(.sectionRoot(.metadata)))
        navigation.resumeHeldNavigation()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
        #expect(navigation.heldNavigation == nil)
    }

    @Test func leaveGuardCancelKeepsPlace() throws {
        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.metadata))
        let guardBox = HoldGuard()
        navigation.leaveGuard = guardBox
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
        #expect(navigation.heldNavigation == .back)
        navigation.cancelHeldNavigation()
        #expect(navigation.currentLocation == .sectionRoot(.metadata))
        #expect(navigation.heldNavigation == nil)
    }

    @Test func leaveGuardDoesNotHoldIdenticalLocation() throws {
        let (navigation, _) = try attachedNavigation()
        let guardBox = HoldGuard()
        navigation.leaveGuard = guardBox
        navigation.go(to: .sectionRoot(.sources))
        #expect(navigation.heldNavigation == nil)
        #expect(navigation.currentLocation == .sectionRoot(.sources))
    }

    // MARK: - Page sections

    private func person(_ section: ConclusionPageSection? = nil) -> WorkspaceLocation {
        .personDetail(entityId: "per-1", ref: "PER-1", title: "Jane Doe", pageSection: section)
    }

    @Test func pageSectionPushAndRestore() throws {
        let (navigation, url) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        navigation.go(to: person())
        navigation.go(to: navigation.currentLocation.withPageSection(.family))
        navigation.go(to: navigation.currentLocation.withPageSection(.gallery))
        #expect(navigation.currentLocation.pageSection == .gallery)

        navigation.goBack()
        #expect(navigation.currentLocation.pageSection == .family)
        navigation.goBack()
        #expect(navigation.currentLocation.pageSection == nil)
        #expect(navigation.currentLocation.entityId == "per-1")
        navigation.goBack()
        #expect(navigation.currentLocation == .sectionRoot(.persons))

        navigation.goForward()
        navigation.goForward()
        navigation.go(to: navigation.currentLocation.withPageSection(.timeline))
        let reloaded = WorkspaceNavigation()
        reloaded.attachProject(uuid: projectUuid, fileURL: url)
        #expect(reloaded.currentLocation.pageSection == .timeline)
        #expect(reloaded.currentLocation.entityId == "per-1")
        #expect(reloaded.currentLocation.title == "Jane Doe")
    }

    @Test func firstSectionIsStoredAsNil() throws {
        let linked = person()
        #expect(person(.vitals) == linked)
        #expect(person(.vitals).pageSection == nil)
        #expect(person(.gallery).withPageSection(.vitals) == linked)
        #expect(person(.gallery).withPageSection(.vitals).pageSection == nil)

        let (navigation, _) = try attachedNavigation()
        navigation.go(to: .sectionRoot(.persons))
        navigation.go(to: linked)
        let before = entryCount(navigation)
        navigation.go(to: person(.vitals))
        #expect(entryCount(navigation) == before)
        navigation.go(to: person(.gallery))
        let after = entryCount(navigation)
        navigation.go(to: person(.gallery))
        #expect(entryCount(navigation) == after)
    }

    @Test func pageSectionIsIdentity() {
        #expect(person(.family) != person(.gallery))
        #expect(person(.family) != person())
        #expect(person(.family) == person(.family))
    }

    @Test func pageSectionOnlyWhereOffered() throws {
        let locations: [WorkspaceLocation] = [
            .eventDetail(entityId: "evt-1", ref: "EVT-1", title: nil),
            .placeDetail(entityId: "plc-1", ref: "PLC-1", title: nil),
            .sectionRoot(.persons),
        ]
        for location in locations {
            let changed = location.withPageSection(.family)
            #expect(changed.pageSection == nil)
            #expect(changed == location)
            let json = Data("""
            {"section":"\(location.section.rawValue)","entityId":"\(location.entityId ?? "")","pageSection":"family"}
            """.utf8)
            let decoded = try JSONDecoder().decode(WorkspaceLocation.self, from: json)
            #expect(decoded.pageSection == nil)
        }
        let built = WorkspaceLocation(section: .events, entityId: "evt-1", pageSection: .family)
        #expect(built.pageSection == nil)
    }

    @Test func legacyAndUnknownPageSectionDecodeAsTheFirst() throws {
        let legacy = Data("""
        {"section":"persons","entityId":"per-1","ref":"PER-1"}
        """.utf8)
        #expect(try JSONDecoder().decode(WorkspaceLocation.self, from: legacy).pageSection == nil)
        let unknown = Data("""
        {"section":"persons","entityId":"per-1","pageSection":"lineage"}
        """.utf8)
        let decoded = try JSONDecoder().decode(WorkspaceLocation.self, from: unknown)
        #expect(decoded.pageSection == nil)
        #expect(decoded.entityId == "per-1")
        let known = Data("""
        {"section":"persons","entityId":"per-1","pageSection":"gallery"}
        """.utf8)
        #expect(try JSONDecoder().decode(WorkspaceLocation.self, from: known).pageSection == .gallery)
    }

    @Test func openPageSectionIsTheStoredOrFirst() throws {
        #expect(person().openPageSection == .vitals)
        for section in ConclusionPageSection.allCases {
            #expect(person(section).openPageSection == section)
        }
        let unknown = Data("""
        {"section":"persons","entityId":"per-1","pageSection":"lineage"}
        """.utf8)
        #expect(try JSONDecoder().decode(WorkspaceLocation.self, from: unknown).openPageSection == .vitals)
        let none: [WorkspaceLocation] = [
            .eventDetail(entityId: "evt-1", ref: "EVT-1", title: nil),
            .placeDetail(entityId: "plc-1", ref: "PLC-1", title: nil),
            .sectionRoot(.persons),
        ]
        for location in none {
            #expect(location.openPageSection == nil)
        }
    }

    @Test func sectionsOfferedPerKind() {
        #expect(ConclusionPageSection.offered(by: .persons) == [.vitals, .family, .timeline, .gallery, .sources])
        for section in [WorkspaceSection.events, .places, .sources, .sourceTypes, .metadata, .properties] {
            #expect(ConclusionPageSection.offered(by: section).isEmpty)
        }
    }
}

@MainActor
fileprivate final class HoldGuard: WorkspaceLeaveGuard {
    weak var navigation: WorkspaceNavigation?

    func shouldHoldNavigation(_ pending: PendingNavigation) -> Bool {
        true
    }
}

@MainActor
@Observable
private final class PageShown {
    var isShown = true
    var disappeared = false
}

private struct GuardedPage<Guard: WorkspaceLeaveGuard>: View {
    let shown: PageShown
    let leaveGuard: Guard

    var body: some View {
        if shown.isShown {
            Text(verbatim: "page").workspaceLeaveGuard(leaveGuard)
                .onDisappear { shown.disappeared = true }
        }
    }
}

/// T-9 (D-8): the one install modifier every guarded page uses.
@Suite(.hostedWindows)
@MainActor
struct WorkspaceLeaveGuardInstallTests {
    private func host(
        _ leaveGuard: HoldGuard, shown: PageShown, navigation: WorkspaceNavigation
    ) -> NSHostingView<some View> {
        let view = GuardedPage(shown: shown, leaveGuard: leaveGuard).environment(navigation)
        let (_, host) = hostInBorderlessWindow(view, windowSize: CGSize(width: 200, height: 100))
        host.layoutSubtreeIfNeeded()
        return host
    }

    /// Lays out until the hidden page's `onDisappear` has run; a hosted window delivers it
    /// on a later run-loop turn on a slow runner.
    private func hidePage(_ shown: PageShown, in host: NSHostingView<some View>) async {
        shown.isShown = false
        _ = await waitUntil(timeout: .seconds(10)) {
            host.layoutSubtreeIfNeeded()
            return shown.disappeared
        }
        await Task.yield()
    }

    @Test func leaveGuardModifierInstallsAndClears() async {
        let navigation = WorkspaceNavigation()
        let leaveGuard = HoldGuard()
        let shown = PageShown()
        let host = host(leaveGuard, shown: shown, navigation: navigation)
        #expect(navigation.leaveGuard === leaveGuard)
        #expect(leaveGuard.navigation === navigation)

        await hidePage(shown, in: host)
        #expect(shown.disappeared)
        #expect(navigation.leaveGuard == nil)
    }

    @Test func leaveGuardModifierLeavesAnotherGuardInPlace() async {
        let navigation = WorkspaceNavigation()
        let leaveGuard = HoldGuard()
        let other = HoldGuard()
        let shown = PageShown()
        let host = host(leaveGuard, shown: shown, navigation: navigation)
        #expect(navigation.leaveGuard === leaveGuard)

        navigation.leaveGuard = other
        await hidePage(shown, in: host)
        #expect(shown.disappeared)
        #expect(navigation.leaveGuard === other)
    }

    @Test func confirmCancelKeepsEditing() {
        var kept = 0
        let ask: WorkspaceLeaveAsk? = WorkspaceLeaveAsk()
        let binding = WorkspaceLeaveConfirm.binding(pending: { ask }, keepEditing: { kept += 1 })
        #expect(binding.wrappedValue == ask)

        binding.wrappedValue = nil
        #expect(kept == 1)

        binding.wrappedValue = WorkspaceLeaveAsk()
        #expect(kept == 1)
    }
}
