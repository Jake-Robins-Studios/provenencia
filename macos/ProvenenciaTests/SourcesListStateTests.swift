import Foundation
import Testing
@testable import Provenencia

/// The Sources page's list area as one decision (AC-6.1, 6.2, 6.6 – 6.10): the state, and whether its
/// toolbar shows.
@Suite
@MainActor
struct SourcesListStateTests {
    private enum Boom: Error { case boom }

    /// A page with rows and nothing wrong; each test changes what it needs.
    private func inputs(_ change: (inout SourcesListState.Inputs) -> Void = { _ in }) -> SourcesListState.Inputs {
        var inputs = SourcesListState.Inputs(
            loadError: nil, sourcesAreRead: true, isCatalogEmpty: false, statusError: nil,
            isAwaitingGraphList: false, isAwaitingFilterData: false, hasRows: true, graphListError: nil
        )
        change(&inputs)
        return inputs
    }

    private func name(_ state: SourcesListState) -> String {
        switch state {
        case .failed: "failed"
        case .firstLoad: "firstLoad"
        case .empty: "empty"
        case .statusFailed: "statusFailed"
        case .waitingForFilter: "waitingForFilter"
        case .noMatch: "noMatch"
        case .rows(let error): error == nil ? "rows" : "rows+graphsError"
        }
    }

    @Test func eachStateAndItsToolbar() {
        let table: [(String, SourcesListState.Inputs, String, Bool)] = [
            ("AC-6.1 Sources list not read", inputs { $0.sourcesAreRead = false }, "firstLoad", false),
            ("AC-6.1 graph list not read", inputs { $0.isAwaitingGraphList = true }, "firstLoad", false),
            ("AC-6.2 status counts loading", inputs { $0.isAwaitingFilterData = true }, "waitingForFilter", true),
            ("AC-6.6 graph list failed, no status filter", inputs { $0.graphListError = Boom.boom }, "rows+graphsError", true),
            ("AC-6.7 status data failed", inputs { $0.statusError = Boom.boom }, "statusFailed", true),
            ("AC-6.8 whole list failed", inputs { $0.loadError = Boom.boom; $0.sourcesAreRead = false }, "failed", false),
            ("AC-6.9 empty catalog", inputs { $0.isCatalogEmpty = true }, "empty", false),
            ("AC-6.10 no match", inputs { $0.hasRows = false }, "noMatch", true),
            ("rows", inputs(), "rows", true),
            // The status failure shows with its toolbar even while the graph list is still loading.
            ("AC-6.7 beside a graph list still loading",
             inputs { $0.statusError = Boom.boom; $0.isAwaitingGraphList = true }, "statusFailed", true),
        ]
        for (label, input, expected, toolbar) in table {
            let state = SourcesListState.make(input)
            #expect(name(state) == expected, Comment(rawValue: label))
            #expect(state.showsToolbar == toolbar, Comment(rawValue: label))
        }
    }

    @Test func statusFailureKeepsTheToolbar() async {
        let store = FakeStore()
        store.listEvidenceGraphsHold.isOn = true
        store.listEvidenceGraphProgressError = Boom.boom
        store.sourcesByProject["/tmp/state.provenencia"] = [
            CatalogSource(
                id: "s1", ref: "SRC-AAAAA", sourceTypeID: "t1", title: "A", description: "",
                updated: CatalogActivity(revision: 0)
            )
        ]
        let session = WorkspaceSession(projectKey: ProjectKey(projectDir: "/tmp/state.provenencia"), store: store)
        let model = SourcesModel(
            session: session, userID: "00000000-0000-7000-8000-000000000001", store: store
        )
        model.warmListQueries()
        if let handle: QueryHandle<[CatalogSource]> = session.queryHandle(SourcesModel.sourcesListKey(for: session)) {
            await waitForQuery(handle)
        }
        if let handle: QueryHandle<[String: EvidenceGraphProgress]> = session.queryHandle(
            session.evidenceGraphProgressKey
        ) {
            await waitForQuery(handle)
        }
        model.settings.status = .promoted
        #expect(model.isAwaitingGraphList)
        #expect(model.statusCountsError != nil)
        guard case .statusFailed = model.listState else {
            Issue.record("expected statusFailed, got \(model.listState)")
            return
        }
        #expect(model.listState.showsToolbar)
        store.listEvidenceGraphsHold.isOn = false
        store.listEvidenceGraphsHold.release()
    }
}
