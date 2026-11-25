import Foundation
import Observation
import SwiftUI

enum PendingNavigation: Equatable, Sendable {
    case location(WorkspaceLocation)
    case back
    case forward
    case index(Int)
}

/// How a commit came.
enum WorkspaceArrivalKind: Equatable, Sendable {
    /// `go(to:)`, the project attaching, a place replaced.
    case push
    /// Back, Forward or a jump in the history menu.
    case history
}

@MainActor
protocol WorkspaceLeaveGuard: AnyObject {
    /// The navigation the guard holds and resumes; `workspaceLeaveGuard(_:)` sets it while the
    /// guard's page is on screen.
    var navigation: WorkspaceNavigation? { get set }

    /// Return true to hold this navigation. The guard must later call
    /// `resumeHeldNavigation()` or `cancelHeldNavigation()`.
    func shouldHoldNavigation(_ pending: PendingNavigation) -> Bool
}

/// First-class workspace navigation history (`go(to:)` / Back / Forward).
/// Owned by `WorkspaceView` and injected via `.environment` so any destination
/// can commit or apply places without talking to sidebar chrome.
/// See `docs/deployment-plan/archive/spike-3/navigation-history.md`.
@MainActor
@Observable
final class WorkspaceNavigation {
    /// Derived from history; updated by `go` / Back / Forward / apply.
    private(set) var selectedSection: WorkspaceSection
    /// Current history leaf (section + deep ids). Views apply deep state from this.
    private(set) var currentLocation: WorkspaceLocation
    /// Stored (not computed) so `@Observable` publishes when the stack index moves.
    private(set) var canGoBack = false
    private(set) var canGoForward = false
    /// Latest load/persist failure for chrome toast; cleared via `acknowledgeHistoryIssue()`.
    private(set) var lastHistoryIssue: NavigationHistoryIssue?
    /// Fired synchronously whenever a location is committed (including history restore), with how it came.
    var onLocationCommit: ((WorkspaceLocation, WorkspaceArrivalKind) -> Void)?
    /// Views never observe this; it only intercepts committed moves.
    @ObservationIgnored
    weak var leaveGuard: (any WorkspaceLeaveGuard)?
    private(set) var heldNavigation: PendingNavigation?

    private var history: NavigationHistoryStore?
    private(set) var projectUuid: String = ""
    /// The visit being shown. Changes when a visit to a page begins: another page, or any history move;
    /// a coalesced `go(to:)` and another row selected on the page (`WorkspaceLocation.isSamePage(as:)`)
    /// keep it. Observed: the page's scroll view restores once per arrival, and a note of another is stale.
    private(set) var arrival = 0
    /// What the visit has noted so far: the list's selection, the scroll view's y, the section
    /// anchor; the open Source is read as it is stamped. Stamped onto the entry on the next Back, Forward, jump or `go(to:)`, and by `flush()`;
    /// on a new arrival it starts as the entry's own. Scrolling does not write the history file or
    /// notify observers; only `listSelection` does.
    @ObservationIgnored private var revisit = WorkspaceRevisit()
    /// Whether a y was noted in this visit: the restore is over.
    @ObservationIgnored private var scrollIsNoted = false
    /// The Source open in the Sources list, read when the Sources list root is left. `WorkspaceView` sets it.
    @ObservationIgnored var openSourceProvider: (() -> String?)?
    /// The visible list's selected row (the list draws it selected). Its view readers are the lists
    /// and `ListSelectionModifier`.
    private(set) var listSelection: String? {
        get {
            _$observationRegistrar.access(self, keyPath: \.listSelection)
            return revisit.listSelection
        }
        set {
            _$observationRegistrar.withMutation(of: self, keyPath: \.listSelection) {
                revisit.listSelection = newValue
            }
        }
    }

    init(selectedSection: WorkspaceSection = .sources) {
        self.selectedSection = selectedSection
        self.currentLocation = .sectionRoot(selectedSection)
    }

    /// Load or create persisted history for this catalog project UUID.
    func attachProject(
        uuid: String,
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let trimmed = uuid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if trimmed == projectUuid, history != nil { return }
        projectUuid = trimmed
        let url: URL
        if let fileURL {
            url = fileURL
        } else {
            do {
                url = try InstallPaths.navigationFile(projectUuid: trimmed, fileManager: fileManager)
            } catch {
                lastHistoryIssue = .persistFailed
                return
            }
        }
        let store = NavigationHistoryStore(
            projectUuid: trimmed,
            fileURL: url,
            fileManager: fileManager,
            seed: .sectionRoot(.sources)
        )
        history = store
        apply(store.current, kind: .push, beginsVisit: true)
        refreshHistoryIssue()
    }

    /// Wires the session to the navigation: a commit applies the location to the session, and a history
    /// move also puts the Sources list's open Source back as it was left. The
    /// open Source is read from the session when the Sources list root is left.
    func connect(to session: WorkspaceSession) {
        openSourceProvider = { [weak session] in session?.openSourceID }
        onLocationCommit = { location, kind in
            session.apply(location: location)
            session.applyHistoryState(location, kind: kind)
        }
    }

    /// Clears a surfaced history issue so it is not shown again until a new failure.
    func acknowledgeHistoryIssue() {
        history?.clearLastIssue()
        lastHistoryIssue = nil
    }

    /// The visible list reports its selected row (Persons, Events, Places, Sources).
    /// This does not push a history entry and does not write the history file.
    func noteListSelection(_ selection: String?) {
        guard currentLocation.isListRoot else { return }
        listSelection = Self.normalizedSelection(selection)
    }

    /// A scroll view reports its y. A note of another visit (a closing page's last scroll) is dropped.
    /// This does not push a history entry and does not write the history file.
    func noteScrollOffset(_ y: Double, arrival: Int) {
        guard arrival == self.arrival, revisit.note(y) else { return }
        scrollIsNoted = true
    }

    /// What the page's scroll view is asked to remember: this visit's id, the y it was left
    /// at (until a y is noted in this visit), and where to report a new one.
    var scrollMemory: PVScrollMemory {
        let arrival = arrival
        return PVScrollMemory(arrival: arrival) { [weak self] in
            guard let self, arrival == self.arrival, !scrollIsNoted else { return nil }
            return revisit.scrollOffset
        } note: { [weak self] y in
            self?.noteScrollOffset(y, arrival: arrival)
        }
    }

    /// Writes the visit's y onto the current entry and the file, so a quit keeps where the
    /// researcher was.
    func flush() {
        stampLeaving()
        history?.persist()
    }

    /// Committed navigation. Coalesces identical locations; truncates forward.
    func go(to location: WorkspaceLocation) {
        if location == currentLocation {
            performGo(to: location)
            return
        }
        if hold(.location(location)) { return }
        performGo(to: location)
    }

    /// Committed navigation from a row of a record page's section. Writes the row onto the
    /// entry being left so Back can return to it; a visit to the place already open writes
    /// nothing, and a nil anchor (a row id that cannot be kept) navigates all the same.
    func go(to location: WorkspaceLocation, from anchor: ConclusionSectionAnchor?) {
        if let anchor, location != currentLocation {
            revisit.sectionAnchor = anchor
        }
        go(to: location)
    }

    func goBack() {
        guard history != nil, canGoBack else { return }
        if hold(.back) { return }
        performBack()
    }

    func goForward() {
        guard history != nil, canGoForward else { return }
        if hold(.forward) { return }
        performForward()
    }

    func go(toIndex index: Int) {
        guard history != nil else { return }
        if hold(.index(index)) { return }
        performIndex(index)
    }

    func resumeHeldNavigation() {
        guard let pending = heldNavigation else { return }
        heldNavigation = nil
        switch pending {
        case .location(let location):
            performGo(to: location)
        case .back:
            performBack()
        case .forward:
            performForward()
        case .index(let index):
            performIndex(index)
        }
    }

    func cancelHeldNavigation() {
        heldNavigation = nil
    }

    /// Nearest history entries before current (nearest first) for the Back jump menu.
    func backJumpItems(limit: Int = 15) -> [(index: Int, location: WorkspaceLocation)] {
        history?.backJumpItems(limit: limit) ?? []
    }

    /// History entries after current (stack order) for the Forward jump menu.
    func forwardJumpItems(limit: Int = 15) -> [(index: Int, location: WorkspaceLocation)] {
        history?.forwardJumpItems(limit: limit) ?? []
    }

    /// When a deep id is missing after catalog load, land on the section list
    /// and rewrite the current stack entry so persistence stays honest.
    func fallbackToSectionRoot() {
        replaceCurrent(with: .sectionRoot(currentLocation.section))
    }

    /// Updates the current entry in place, without a push. A place whose
    /// visible keys change within one mount (the composer's Artifact) uses it
    /// so the session and the persisted entry follow.
    func replaceCurrent(with location: WorkspaceLocation) {
        guard let history else {
            apply(location, kind: .push)
            return
        }
        apply(history.replaceCurrent(with: location), kind: .push)
        refreshHistoryIssue()
    }

    private func hold(_ pending: PendingNavigation) -> Bool {
        guard let leaveGuard, leaveGuard.shouldHoldNavigation(pending) else { return false }
        heldNavigation = pending
        return true
    }

    private func performGo(to location: WorkspaceLocation) {
        guard let history else {
            apply(location, kind: .push)
            return
        }
        // Leaving a place stamps how it was left. Staying on it (a coalesced visit)
        // lets the incoming selection replace the held one, including nil.
        if location != currentLocation {
            stampLeaving()
        }
        apply(history.go(to: location), kind: .push)
        refreshHistoryIssue()
    }

    private func performBack() {
        guard let history, history.canGoBack else { return }
        stampLeaving()
        guard let location = history.goBack() else { return }
        apply(location, kind: .history)
        refreshHistoryIssue()
    }

    private func performForward() {
        guard let history, history.canGoForward else { return }
        stampLeaving()
        guard let location = history.goForward() else { return }
        apply(location, kind: .history)
        refreshHistoryIssue()
    }

    private func performIndex(_ index: Int) {
        guard let history, history.contains(index: index) else { return }
        stampLeaving()
        guard let location = history.go(toIndex: index) else { return }
        apply(location, kind: .history)
        refreshHistoryIssue()
    }

    private func stampLeaving() {
        revisit.openSourceId = openSourceProvider?()
        history?.stampLeaving(revisit)
    }

    /// The one commit. A visit begins on any history move, on another page, or when asked; then the held
    /// revisit becomes the entry's. Otherwise (a coalesced `go(to:)`, another row selected on the page)
    /// only the selection is taken from the committed entry: the live y and section anchor stay,
    /// and the entry takes them when it is left.
    private func apply(_ location: WorkspaceLocation, kind: WorkspaceArrivalKind, beginsVisit: Bool = false) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["PROVENENCIA_DEBUG_NAV_TIMING"] == "1" {
            print(
                "WorkspaceNavigation.apply section=\(location.section.rawValue) " +
                    "sourceId=\(location.sourceId ?? "nil") fieldId=\(location.fieldId ?? "nil") " +
                    "typeId=\(location.typeId ?? "nil") t=\(CFAbsoluteTimeGetCurrent())"
            )
        }
        #endif
        let begins = beginsVisit || kind == .history || !location.isSamePage(as: currentLocation)
        currentLocation = location
        selectedSection = location.section
        canGoBack = history?.canGoBack ?? false
        canGoForward = history?.canGoForward ?? false
        if begins {
            arrival += 1
            scrollIsNoted = false
            revisit = location.revisit
            if !location.isListRoot { revisit.listSelection = nil }
            // Observers of the selection hear it change.
            listSelection = revisit.listSelection
        } else {
            listSelection = location.isListRoot ? location.revisit.listSelection : nil
        }
        onLocationCommit?(location, kind)
    }

    private func refreshHistoryIssue() {
        if let issue = history?.lastIssue {
            lastHistoryIssue = issue
        }
    }

    private static func normalizedSelection(_ selection: String?) -> String? {
        guard let selection, !selection.isEmpty else { return nil }
        return selection
    }
}

/// Clears a selected row that a list no longer shows. Once the list's read settles, a
/// `navigation.listSelection` with no row of that id (a record deleted since, a reload that
/// removed it) becomes nil; a listed one stays. The list itself binds `listSelection` as its selection.
struct ListSelectionModifier: ViewModifier {
    var rowIDs: [String]
    var isSettled: Bool

    @Environment(WorkspaceNavigation.self) private var navigation

    func body(content: Content) -> some View {
        content
            .onChange(of: isSettled, initial: true) { _, _ in clearIfGone() }
            .onChange(of: rowIDs) { _, _ in clearIfGone() }
            .onChange(of: navigation.listSelection) { _, _ in clearIfGone() }
    }

    private func clearIfGone() {
        guard isSettled, let selection = navigation.listSelection, !rowIDs.contains(selection) else { return }
        navigation.noteListSelection(nil)
    }
}

/// Leaves the page for its section's list once its entity is gone: it replaces the current
/// entry (`fallbackToSectionRoot`). Also fires on mount, so a page opened on a gone entity leaves.
/// A non-nil `notice` is added to the window's toasts first, so the list says why.
struct LeavesForSectionRoot: ViewModifier {
    let gone: Bool
    let notice: String?
    @Environment(WorkspaceNavigation.self) private var navigation
    @Environment(WorkspaceSession.self) private var session

    func body(content: Content) -> some View {
        content.onChange(of: gone, initial: true) { _, gone in
            guard gone else { return }
            Self.leave(notice: notice, navigation: navigation, session: session)
        }
    }

    /// Adds `notice` to the window's toasts when it is non-nil, then replaces the
    /// current entry with its section's list.
    static func leave(notice: String?, navigation: WorkspaceNavigation, session: WorkspaceSession) {
        if let notice {
            session.toasts.add(tone: .info, title: notice, message: nil)
        }
        navigation.fallbackToSectionRoot()
    }
}

/// The ask a guarded page raises when a move away is held and the page has nothing to say about
/// it beyond "discard or keep editing". A page whose ask carries a payload uses its own item type.
struct WorkspaceLeaveAsk: Identifiable, Equatable {
    let id = UUID()
}

/// The binding under a guarded page's discard confirm: it reads the page's ask, and clearing it
/// (Cancel, Escape, a click outside) is the page's keep-editing answer.
enum WorkspaceLeaveConfirm {
    static func binding<Item>(
        pending: @escaping @MainActor @Sendable () -> Item?,
        keepEditing: @escaping @MainActor @Sendable () -> Void
    ) -> Binding<Item?> {
        Binding(
            get: pending,
            set: { newValue in
                if newValue == nil { MainActor.assumeIsolated { keepEditing() } }
            }
        )
    }
}

/// Installs a page's leave guard while the page is on screen: sets the guard's `navigation` and the
/// navigation's `leaveGuard`, and clears `leaveGuard` on disappear when it is still this guard's.
struct WorkspaceLeaveGuardInstall<Guard: WorkspaceLeaveGuard>: ViewModifier {
    let leaveGuard: Guard
    @Environment(WorkspaceNavigation.self) private var navigation

    func body(content: Content) -> some View {
        content
            .onAppear {
                leaveGuard.navigation = navigation
                navigation.leaveGuard = leaveGuard
            }
            .onDisappear {
                if navigation.leaveGuard === leaveGuard {
                    navigation.leaveGuard = nil
                }
            }
    }
}

extension View {
    /// Makes `leaveGuard` the navigation's guard while this page is on screen, so a move away
    /// asks it first (`go(to:)`, Back, Forward and the history menu; `fallbackToSectionRoot` does
    /// not ask). One install for every page that holds unsaved work.
    func workspaceLeaveGuard(_ leaveGuard: some WorkspaceLeaveGuard) -> some View {
        modifier(WorkspaceLeaveGuardInstall(leaveGuard: leaveGuard))
    }

    /// The discard confirm of a guarded page: shown while `pending` is non-nil, Discard runs
    /// `onDiscard`, and every other way out of it runs `onKeepEditing`. One confirm for every page
    /// that installs `workspaceLeaveGuard(_:)`.
    func workspaceLeaveConfirm<Item: Identifiable>(
        pending: @escaping @MainActor @Sendable () -> Item?,
        copy: @escaping (Item) -> PVConfirmCopy,
        accessibilityIdentifierPrefix: String,
        onDiscard: @escaping () -> Void,
        onKeepEditing: @escaping @MainActor @Sendable () -> Void
    ) -> some View {
        pvConfirm(
            item: WorkspaceLeaveConfirm.binding(pending: pending, keepEditing: onKeepEditing),
            copy: copy,
            tone: .danger,
            accessibilityIdentifierPrefix: accessibilityIdentifierPrefix,
            onConfirm: onDiscard,
            detail: { _ in EmptyView() }
        )
    }

    /// Leaves for the section's list when `gone` is true (the entity the page shows no longer exists),
    /// first adding `notice` to the window's toasts when it is non-nil.
    func leavesForSectionRoot(when gone: Bool, notice: String? = nil) -> some View {
        modifier(LeavesForSectionRoot(gone: gone, notice: notice))
    }
}
