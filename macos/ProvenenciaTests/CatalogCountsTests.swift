import Foundation
import Testing
@testable import Provenencia

@Suite
@MainActor
struct CatalogCountsTests {
    private let projectDir = "/tmp/counts.provenencia"

    /// The list's sleep never returns, so no entry expires during a test.
    private func makeToasts() -> PVToastList {
        PVToastList(sleep: ManualSleep().sleep)
    }

    private func makeCounts(
        store: FakeStore = FakeStore(),
        toasts: PVToastList? = nil
    ) -> CatalogCounts {
        CatalogCounts(projectDir: projectDir, store: store, toasts: toasts ?? makeToasts())
    }

    @Test func refreshAllPopulatesEveryDestination() async {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "1", ref: "SRC-1", sourceTypeID: "", title: "A", description: ""),
            CatalogSource(id: "2", ref: "SRC-2", sourceTypeID: "", title: "B", description: ""),
        ]
        let counts = makeCounts(store: store)
        await counts.refreshAll()

        #expect(counts.sources == 2)
        #expect(counts.persons == 0)
        #expect(counts.events == 0)
        #expect(counts.places == 0)
        #expect(counts.badge(for: .sources) == 2)
        #expect(counts.badge(for: .persons) == 0)
        #expect(counts.badge(for: .events) == 0)
        #expect(counts.badge(for: .places) == 0)
        // Configure rows draw no badge.
        #expect(counts.badge(for: .sourceTypes) == nil)
        #expect(counts.badge(for: .metadata) == nil)
        #expect(counts.badge(for: .properties) == nil)
    }

    @Test func refreshAllCountsPromotedPersons() async throws {
        let store = FakeStore()
        store.subjectTypesByProject[projectDir] = [
            CatalogSubjectType(
                id: "type-person", key: "person", origin: "provenencia", label: "Person",
                description: "", refPrefix: "PER", candidateRefPrefix: "CPR"
            ),
        ]
        store.subjectsByGraph["g1"] = [
            CatalogSubject(id: "sub-1", ref: "CPR-1", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
            CatalogSubject(id: "sub-2", ref: "CPR-2", sourceID: "s1", subjectTypeID: "type-person", label: "", description: ""),
        ]
        _ = store.seedPromotion(projectDir: projectDir, subjectID: "sub-1")
        _ = store.seedPromotion(projectDir: projectDir, subjectID: "sub-2")
        let counts = makeCounts(store: store)
        await counts.refreshAll()
        #expect(counts.persons == 2)
        #expect(counts.badge(for: .persons) == 2)
    }

    @Test func refreshAllOnEmptyProjectYieldsZero() async {
        let toasts = makeToasts()
        let counts = makeCounts(toasts: toasts)
        await counts.refreshAll()
        #expect(counts.sources == 0)
        #expect(counts.persons == 0)
        #expect(counts.events == 0)
        #expect(counts.places == 0)
        #expect(toasts.entries.isEmpty)
    }

    @Test func refreshAllFailureAddsToastAndLeavesBadgesUnset() async {
        let store = FakeStore()
        enum Boom: Error { case boom }
        store.workspaceNavCountsError = Boom.boom

        let toasts = makeToasts()
        let counts = makeCounts(store: store, toasts: toasts)
        await counts.refreshAll()

        #expect(toasts.cards == [ToastCard(
            .danger,
            L10n.string(L10n.Workspace.countsRefreshFailedTitle),
            L10n.string(L10n.Errors.unknown)
        )])
        #expect(counts.sources == nil)
        #expect(counts.badge(for: .sources) == nil)
    }

    @Test func refreshAllSuccessAddsNoToast() async {
        let store = FakeStore()
        let toasts = makeToasts()
        let counts = makeCounts(store: store, toasts: toasts)
        await counts.refreshAll()
        #expect(toasts.entries.isEmpty, "a success adds no toast")
        #expect(counts.sources == 0)
    }

    /// A write's recount that fails after a good launch count adds the danger toast and keeps
    /// the last badges. The same failure again refreshes that card; once it is dismissed, the
    /// next failure adds it again.
    @Test func writeRecountFailureAddsToastEachTime() async {
        let store = FakeStore()
        store.sourcesByProject[projectDir] = [
            CatalogSource(id: "1", ref: "SRC-1", sourceTypeID: "", title: "A", description: ""),
        ]
        let toasts = makeToasts()
        let counts = makeCounts(store: store, toasts: toasts)
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: projectDir), store: store)
        session.onNavCountsMoved = { await counts.refreshAll() }
        await counts.refreshAll()
        #expect(toasts.entries.isEmpty)

        enum Boom: Error { case boom }
        store.workspaceNavCountsError = Boom.boom
        session.apply(CatalogWriteEffects(lists: [.counts]))
        await session.settleWrites()
        #expect(toasts.cards == [ToastCard(
            .danger,
            L10n.string(L10n.Workspace.countsRefreshFailedTitle),
            L10n.string(L10n.Errors.unknown)
        )])
        #expect(counts.sources == 1)
        let first = toasts.entries[0].id

        session.apply(CatalogWriteEffects(lists: [.counts]))
        await session.settleWrites()
        #expect(toasts.entries.count == 1, "the same failure refreshes the card")
        #expect(toasts.entries[0].id == first)

        store.workspaceNavCountsError = CoreInvokeError.coded(status: 1, code: "catalog.closed", kind: .user, params: [])
        session.apply(CatalogWriteEffects(lists: [.counts]))
        await session.settleWrites()
        #expect(toasts.entries.count == 1, "a different failure keeps the one card")
        #expect(toasts.entries[0].id == first)
        #expect(toasts.cards.first?.message == L10n.Errors.message(code: "catalog.closed"))
        #expect(toasts.cards.first?.message != L10n.string(L10n.Errors.unknown))

        toasts.dismiss(first)
        #expect(toasts.entries.isEmpty)
        session.apply(CatalogWriteEffects(lists: [.counts]))
        await session.settleWrites()
        #expect(toasts.entries.count == 1, "a failure after a dismiss adds the card again")
        #expect(toasts.entries[0].id != first)
    }

    /// Two recounts overlap: the one started last reads the newest catalog, so the earlier,
    /// slower one finishing after it must not overwrite its counts.
    @Test func newestRecountWins() async throws {
        let store = FakeStore()
        store.workspaceNavCountsHold.isOn = true
        let counts = makeCounts(store: store)

        let first = Task { await counts.refreshAll() }
        // The first recount has read zero Sources and is held before returning them.
        await store.workspaceNavCountsHold.untilSuspended(1)
        store.workspaceNavCountsHold.isOn = false
        _ = try await store.createSource(
            projectDir: projectDir, userID: "u", sourceTypeID: "t1", title: "New", description: "",
            date: nil, isPrivate: false
        )

        await counts.refreshAll()
        #expect(counts.sources == 1)
        store.workspaceNavCountsHold.release()
        await first.value
        #expect(counts.sources == 1)
    }
}
