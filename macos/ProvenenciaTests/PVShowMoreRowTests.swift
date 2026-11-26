import AppKit
import SwiftUI
import Testing
@testable import Provenencia

struct PVShowMoreRowTests {
    @Test func pressMovesOnlyFromTheRow() {
        let key = PVShowMorePress<Int>(startedOnRow: true, revealed: 6, revealedRow: 6)
        #expect(key.focus == 6 && key.scroll == AnyHashable(6))
        let click = PVShowMorePress<Int>(startedOnRow: false, revealed: 6, revealedRow: 6)
        #expect(click.focus == nil && click.scroll == nil)
        let rowOnly = PVShowMorePress<Int>(startedOnRow: true, revealed: nil, revealedRow: 6)
        #expect(rowOnly.focus == nil && rowOnly.scroll == AnyHashable(6))
    }

    @Test func labelWordsThePage() {
        #expect(L10n.DesignSystem.showMoreRowLabel(1) == "Show 1 more")
        #expect(L10n.DesignSystem.showMoreRowLabel(50) == "Show 50 more")
    }
}

/// The reveal scroll in a real (never shown) window: a caller that asks for a scroll and leaves
/// the tree in the same action still gets it, because the provider holds the request.
@Suite(.serialized, .hostedWindows)
@MainActor
struct PVShowMoreRowHostedTests {
    private struct Probe: View {
        @Environment(\.pvShowMoreReveal) private var reveal
        let leave: () -> Void

        var body: some View {
            Color.clear.frame(height: 1).onAppear {
                // Asks and leaves in one action, as a Show more does on the last page.
                reveal(AnyHashable(11))
                leave()
            }
        }
    }

    /// Holds the ask back until the test has seen the list laid out, so the request never
    /// precedes the rows it scrolls to.
    @MainActor @Observable final class Trigger {
        var asking = false
    }

    private struct Harness: View {
        let trigger: Trigger
        @State private var probing = true

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0 ..< 12, id: \.self) { index in
                        Text(verbatim: "Row \(index)").frame(height: 60).id(index)
                    }
                    if trigger.asking && probing { Probe { probing = false } }
                }
            }
            // An unshown window, and a CI runner with no display, steps no animation, so
            // an animated scroll may never land. Unanimated, it lands on the next layout.
            .pvScrollsShowMoreReveals(animated: false)
            .frame(width: 300, height: 200)
        }
    }

    @Test func revealScrollsAfterTheCallerLeaves() async throws {
        let trigger = Trigger()
        let (_, host) = hostInBorderlessWindow(Harness(trigger: trigger), windowSize: CGSize(width: 300, height: 200))
        // Wait for the list to lay out, so the scroll has rows to find.
        let laidOut = await eventually(host) {
            descendant(NSScrollView.self, in: host).map { ($0.documentView?.frame.height ?? 0) >= 720 } ?? false
        }
        #expect(laidOut)
        trigger.asking = true
        let scrollView = try #require(descendant(NSScrollView.self, in: host))
        let visible = await eventually(host) {
            let rect = scrollView.documentVisibleRect
            return rect.minY <= 660 && rect.maxY >= 720
        }
        #expect(visible)
    }
}
