import AppKit
import Observation
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
/// the tree in the same update still gets it, because the provider holds the request.
@Suite(.serialized, .hostedWindows)
@MainActor
struct PVShowMoreRowHostedTests {
    private struct Probe: View {
        @Environment(\.pvShowMoreReveal) private var reveal

        var body: some View {
            Color.clear.frame(height: 1).onAppear { reveal(AnyHashable(11)) }
        }
    }

    private struct Harness: View {
        @State private var probing = false
        let trigger: Trigger

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0 ..< 12, id: \.self) { index in
                        Text(verbatim: "Row \(index)").frame(height: 60).id(index)
                    }
                    if probing { Probe() }
                }
            }
            .pvScrollsShowMoreReveals()
            .frame(width: 300, height: 200)
            .onChange(of: trigger.fired) {
                probing = true
                // The caller leaves in the next update, as a Show more does on the last page.
                DispatchQueue.main.async { probing = false }
            }
        }
    }

    @Observable
    final class Trigger {
        var fired = 0
    }

    @Test func revealScrollsAfterTheCallerLeaves() async throws {
        let trigger = Trigger()
        let (_, host) = hostInBorderlessWindow(Harness(trigger: trigger), windowSize: CGSize(width: 300, height: 200))
        // The list is laid out before the caller asks, so the scroll has rows to find.
        let laidOut = await eventually(host) {
            descendant(NSScrollView.self, in: host).map { ($0.documentView?.frame.height ?? 0) >= 720 } ?? false
        }
        #expect(laidOut)
        let scrollView = try #require(descendant(NSScrollView.self, in: host))
        trigger.fired += 1
        let visible = await eventually(host) {
            let rect = scrollView.documentVisibleRect
            return rect.minY <= 660 && rect.maxY >= 720
        }
        #expect(visible)
    }
}
