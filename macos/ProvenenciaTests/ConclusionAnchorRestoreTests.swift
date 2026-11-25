import AppKit
import SwiftUI
import Testing
@testable import Provenencia

@Suite(.serialized, .hostedWindows)
@MainActor
struct ConclusionAnchorRestoreTests {
    /// T-9 (D-1): the part names are written to history files, so they are frozen.
    @Test func anchorPartsAreFrozen() {
        #expect(ConclusionSectionAnchor.Part.allCases.map(\.rawValue) == [
            "family", "timeline", "sourceTitle", "sourceLine", "recordLinks", "detailRow", "picture", "related",
        ])
    }

    /// T-10 (AC-4.1, AC-4.2, D-12): only a row that leads somewhere is an anchor.
    @Test func detailRowAnchorNeedsAnOpensRow() {
        var birth = ReconciledValueRowModel.empty(id: "birth", label: "Birth", face: .date, emptyText: "")
        birth.opens = ReconciledValueRowModel.Opens(
            location: .eventDetail(entityId: "e1", ref: "EVT-1", title: nil), label: "Open event"
        )
        let name = ReconciledValueRowModel.empty(id: "name", label: "Name", face: .text, emptyText: "")
        let rows = [birth, name]
        func target(_ part: ConclusionSectionAnchor.Part, _ id: String) -> String? {
            ConclusionDetailRowsSection.anchorStop(rows: rows, anchor: ConclusionSectionAnchor(part: part, id: id)!)
        }
        #expect(target(.detailRow, "birth") == "birth")
        #expect(target(.detailRow, "name") == nil)
        #expect(target(.detailRow, "unknown") == nil)
        #expect(target(.family, "birth") == nil)
    }

    enum Section: CaseIterable { case details, timeline }

    /// AC-1.3: Back puts the page at its y and the keyboard on the row it opened from, and the keyboard's
    /// move does not scroll. Return on the focused row opens it, which is how the stop is read.
    @Test(arguments: Section.allCases)
    func backRestoresTheYAndTheKeyboard(section: Section) async throws {
        let navigation = WorkspaceNavigation()
        navigation.attachProject(
            uuid: UUID().uuidString,
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).json")
        )
        let anchor = section == .details
            ? ConclusionSectionAnchor(part: .detailRow, id: "row29")
            : ConclusionSectionAnchor(part: .timeline, id: "9")
        let person = WorkspaceLocation.personDetail(entityId: "p1", ref: "PER-1", title: nil)
        navigation.go(to: person)
        navigation.noteScrollOffset(120, slot: .page, arrival: navigation.arrival.id)
        navigation.go(to: .sectionRoot(.places), from: anchor)
        navigation.goBack()

        let (window, host) = hostInBorderlessWindow(
            AnchoredSection(section: section).environment(navigation), windowSize: CGSize(width: 1100, height: 500)
        )
        let y = {
            descendant(NSScrollView.self, in: host).map { Double($0.contentView.bounds.minY + $0.contentView.contentInsets.top) }
        }
        #expect(await eventually(host) { y() == 120 })
        // The platform gives a button the keyboard only with Keyboard navigation on (System Settings).
        guard NSApplication.shared.isFullKeyboardAccessEnabled else { return }
        #expect(await eventually(host) {
            window.sendEvent(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
                context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36
            )!)
            return navigation.currentLocation != person
        })
        #expect(navigation.currentLocation.entityId == anchor?.id)
        #expect(y() == 120)
    }

    private struct AnchoredSection: View {
        let section: Section
        @Environment(WorkspaceNavigation.self) private var navigation

        var body: some View {
            PVPageColumns(primary: {
                switch section {
                case .details:
                    ConclusionDetailRowsSection(rows: (0 ..< 30).map { index in
                        var row = ReconciledValueRowModel.empty(id: "row\(index)", label: "Row \(index)", face: .date, emptyText: "")
                        row.opens = ReconciledValueRowModel.Opens(
                            location: .eventDetail(entityId: "row\(index)", ref: "EVT-1", title: nil), label: "Open event"
                        )
                        return row
                    }, refreshing: false)
                case .timeline:
                    PersonTimelineList(
                        content: PersonTimelineContent(timeline: PersonTimelinePreviewData.johann),
                        projectDir: "", accessibilityIdentifierRoot: "timeline",
                        open: { navigation.go(to: .eventDetail(entityId: $1?.id ?? "", ref: $0.ref ?? "", title: nil)) },
                        expand: { _ in }, expandThrough: { _, _ in }
                    )
                }
            })
            .environment(\.pvScrollMemory, navigation.scrollMemory)
        }
    }
}
