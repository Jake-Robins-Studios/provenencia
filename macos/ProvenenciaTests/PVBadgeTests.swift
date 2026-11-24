import SwiftUI
import Testing
@testable import Provenencia

@MainActor
struct PVBadgeTests {
    private func fittingWidth(_ view: some View) -> CGFloat {
        NSHostingView(rootView: view).fittingSize.width
    }

    private func png(_ badge: PVBadge, _ prominence: BackgroundProminence) throws -> Data {
        let view = badge.padding(4).background(Color.blue).environment(\.backgroundProminence, prominence)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return try #require(renderer.nsImage?.tiffRepresentation)
    }

    @Test func aMinimumWidthHoldsTheBadge() {
        PVFontRegistration.registerBundledFontsIfNeeded()
        // The two badges that fit in 126 pt are held at exactly 126; Not started's own width is wider
        // (128 pt in this build), and a minimum never shrinks a badge.
        let held = [
            PVBadge(L10n.Sources.statusInProgress, tone: .warning, icon: .circleDot, minWidth: 126),
            PVBadge(L10n.Sources.statusPromoted, tone: .success, icon: .circleCheck, minWidth: 126),
        ]
        for badge in held { #expect(fittingWidth(badge) == 126) }
        let natural = fittingWidth(PVBadge(L10n.Sources.statusEmpty, tone: .neutral, icon: .circleDashed, subtle: true))
        let floored = fittingWidth(
            PVBadge(L10n.Sources.statusEmpty, tone: .neutral, icon: .circleDashed, subtle: true, minWidth: 126)
        )
        #expect(floored == max(natural, 126))
        #expect(fittingWidth(PVBadge(L10n.Sources.statusPromoted, tone: .success)) < 126)
    }

    /// The Sources table's Evidence badges share a right edge down their column: every status is one
    /// width, the widest label's (Not started).
    @Test func everyStatusBadgeIsOneWidth() {
        PVFontRegistration.registerBundledFontsIfNeeded()
        let widths = SourcesModel.EvidenceStatus.allCases.map { fittingWidth($0.badge) }
        #expect(Set(widths) == [SourcesModel.EvidenceStatus.badgeWidth])
        #expect(SourcesModel.EvidenceStatus.badgeWidth == 128)
    }

    @Test func anOutlinedBadgeTakesTheOnSelectionInkAndAFilledOneKeepsItsOwn() throws {
        let outlined = PVBadge(L10n.Sources.statusEmpty, tone: .neutral, icon: .circleDashed, subtle: true)
        #expect(try png(outlined, .increased) != png(outlined, .standard))
        let filled = PVBadge(L10n.Sources.statusPromoted, tone: .success, icon: .circleCheck)
        #expect(try png(filled, .increased) == png(filled, .standard))
        let overridden = PVBadge(text: "+2", tone: .neutral, subtle: true, foreground: .red)
        #expect(try png(overridden, .increased) != png(overridden, .standard))
    }

    @Test func relativeDetailHasNoIconAndTakesTheCallersHelp() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
        let context = TimestampFormat.Context(
            locale: Locale(identifier: "en_US"), calendar: calendar, now: TimestampFormat.parse("2026-10-15T00:00:00Z")!
        )
        let known = PVListDetail.relative("2026-10-14T21:15:00Z", in: context, help: { "Added \($0)" })
        #expect(known.icon == nil)
        #expect(known.help?.hasPrefix("Added ") == true)
        #expect(!known.faint)
        let unknown = PVListDetail.relative("", in: context, help: { "Added \($0)" })
        #expect(unknown.text == "—")
        #expect(unknown.help == nil)
        #expect(unknown.faint)
        #expect(PVLastUpdated.detail("2026-10-14T21:15:00Z", in: context).icon == .history)
    }
}
