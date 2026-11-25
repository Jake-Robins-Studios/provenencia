import SwiftUI
import Testing
@testable import Provenencia

@MainActor
struct PVBadgeTests {
    private func fittingWidth(_ view: some View) -> CGFloat {
        NSHostingView(rootView: view).fittingSize.width
    }

    /// The Sources table's Evidence badges share a right edge down their column: every status is one
    /// width, the widest label's (Not started).
    @Test func everyStatusBadgeIsOneWidth() {
        PVFontRegistration.registerBundledFontsIfNeeded()
        let widths = SourcesModel.EvidenceStatus.allCases.map { fittingWidth($0.badge) }
        #expect(Set(widths) == [SourcesModel.EvidenceStatus.badgeWidth])
        #expect(SourcesModel.EvidenceStatus.badgeWidth == 128)
    }

    /// `PVListTests.onSelectionInkIsTheSystemsOnlyWhenProminent` resolves the on-selection ink.
    @Test func anOutlinedBadgeTakesTheOnSelectionInkAndAFilledOneKeepsItsOwn() {
        let outlined = PVBadge(L10n.Sources.statusEmpty, tone: .neutral, subtle: true)
        #expect((outlined.ink(.red) as? PVOnSelectionStyle)?.base == .red)
        let filled = PVBadge(L10n.Sources.statusPromoted, tone: .success)
        #expect(filled.ink(.red) as? Color == .red)
    }
}
