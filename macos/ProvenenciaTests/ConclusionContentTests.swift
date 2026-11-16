import Foundation
import Testing
@testable import Provenencia

/// `WorkspaceSession.conclusionContent`: a page's or section's content built once per
/// change of the reads it draws and of its plain inputs.
@Suite(.serialized)
@MainActor
struct ConclusionContentTests {
    private let projectDir = "/tmp/conclusion-content.provenencia"

    private func makeSession(store: FakeStore = FakeStore()) -> WorkspaceSession {
        WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
    }

    /// AC-2.7: the Timeline section's content is built once per read, fold and reload of
    /// the person's events, and a write to another person's page builds nothing.
    @Test func sectionContentBuildsOncePerReadAndFold() async throws {
        let store = FakeStore()
        store.seededConclusionDetails = ["e1": catalogConclusionDetail("e1"), "e2": catalogConclusionDetail("e2")]
        store.seededPersonEvents = ["e1": CatalogPersonTimeline(), "e2": CatalogPersonTimeline()]
        let session = makeSession(store: store)
        let section = ConclusionPageSection.timeline
        let location = WorkspaceLocation.personDetail(entityId: "e1", ref: "PER-e1", title: nil)
        session.apply(location: location.withPageSection(section))
        await session.settleWrites()
        session.apply(location: WorkspaceLocation.personDetail(entityId: "e2", ref: "PER-e2", title: nil).withPageSection(section))
        await session.settleWrites()
        session.apply(location: location.withPageSection(section))
        await session.settleWrites()

        let key = try #require(section.read(.own, project: session.projectKey, entityId: "e1"))
        let inputs = section.reads(project: session.projectKey, entityId: "e1").map(\.key)
        let value = try #require((session.queryHandle(key) as QueryHandle<CatalogPersonTimeline>?)?.value)
        var folds = ConclusionFoldState<PersonTimelineContent.Fold>()
        var builds = 0
        func read() {
            let extra = PersonTimelineContent.Inputs(
                folds: folds, orders: session.nameFormat, widthClass: .regular, locale: .autoupdatingCurrent
            )
            _ = session.conclusionContent(key, inputs: inputs, extra: extra, value: value) {
                builds += 1
                return PersonTimelineContent(
                    timeline: $0, folds: $1.folds, locale: $1.locale, orders: $1.orders, widthClass: $1.widthClass
                )
            }
        }
        read()
        read()
        read()
        #expect(builds == 1)

        folds.revealPage(.dated)
        read()
        read()
        #expect(builds == 2)

        session.apply(CatalogWriteEffects(handles: ["e1"]))
        await session.settleWrites()
        read()
        #expect(builds == 3)

        let otherKey = CatalogQueryKey.personEvents(project: session.projectKey, entityId: "e2")
        let otherRevision = session.inputRevision(otherKey)
        session.setQueryValue(otherKey, value: CatalogPersonTimeline())
        #expect(session.inputRevision(otherKey) != otherRevision)
        read()
        #expect(builds == 3)
    }

    /// AC-2.8: a detail page's content is built once per read and name format.
    @Test func detailContentFollowsTheNameFormat() {
        let session = makeSession()
        let key = CatalogQueryKey.conclusionDetail(project: session.projectKey, entityId: "e1")
        session.setQueryValue(key, value: catalogConclusionDetail("e1"))
        var builds = 0
        func read(_ orders: NameFormatOrders) {
            _ = session.conclusionContent(key, inputs: [key], extra: orders, value: catalogConclusionDetail("e1")) {
                builds += 1
                return PersonDetailContent(detail: $0, orders: $1)
            }
        }
        let first = NameFormatOrders()
        read(first)
        read(first)
        read(first)
        #expect(builds == 1)

        var other = NameFormatOrders()
        other.sorted = [NameFormatPart(partType: "surname", trailingSeparator: "")]
        read(other)
        #expect(builds == 2)
    }
}
