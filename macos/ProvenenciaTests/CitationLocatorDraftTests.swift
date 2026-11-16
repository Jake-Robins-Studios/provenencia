import CoreGraphics
import Testing
@testable import Provenencia

@Suite
struct CitationLocatorDraftTests {
    @Test func decodeDropsRegionOverPointCap() {
        #expect(CitationLocatorDraft.decode(RegionFixtures.locatorJSON(ringCount: 257)).region == nil)
        #expect(CitationLocatorDraft.decode(RegionFixtures.locatorJSON(ringCount: 256)).region != nil)
    }

    @Test func freeformKindsSurviveAReload() {
        for points in [RegionFixtures.bumpyRing, RegionFixtures.hexagon] {
            let region = CitationLocatorDraft.decode(RegionFixtures.locatorJSON(points: points)).region
            #expect(region?.kind == .freeform)
        }
    }

    @Test func pdfRegionStampsPageWhenMissing() {
        var draft = CitationLocatorDraft.artifactOnly()
        let stamped = draft.setRegion(Self.rectangle, capabilities: Self.pdf, viewerPage: 3)
        #expect(stamped)
        #expect(draft.page == 3)
        #expect(draft.hasRegion)
    }

    @Test func pdfRegionRestampsPageAfterClearingRegion() {
        var draft = CitationLocatorDraft.artifactOnly()
        let first = draft.setRegion(Self.rectangle, capabilities: Self.pdf, viewerPage: 3)
        #expect(first)
        draft.clearRegion()
        #expect(draft.page == 3)
        #expect(!draft.hasRegion)

        let restamped = draft.setRegion(Self.rectangle, capabilities: Self.pdf, viewerPage: 5)
        #expect(restamped)
        #expect(draft.page == 5)
        #expect(draft.hasRegion)
    }

    @Test func imageRegionDoesNotWritePage() {
        var draft = CitationLocatorDraft.artifactOnly()
        let ok = draft.setRegion(Self.rectangle, capabilities: Self.image, viewerPage: 2)
        #expect(ok)
        #expect(draft.page == nil)
        #expect(draft.hasRegion)
    }

    @Test func overlayHidesCommittedRegionOffLocatorPage() {
        #expect(
            ArtifactRegionOverlayInput.committedOnCurrentPage(
                Self.rectangle,
                locatorPage: 3,
                viewerPage: 3,
                supportsPageLocator: true
            ) == Self.rectangle
        )
        #expect(
            ArtifactRegionOverlayInput.committedOnCurrentPage(
                Self.rectangle,
                locatorPage: 3,
                viewerPage: 4,
                supportsPageLocator: true
            ) == nil
        )
        #expect(
            ArtifactRegionOverlayInput.committedOnCurrentPage(
                Self.rectangle,
                locatorPage: nil,
                viewerPage: 1,
                supportsPageLocator: false
            ) == Self.rectangle
        )
    }

    @Test func printedPageRoundTrips() {
        let json = #"{"version":1,"selectors":[{"type":"artifact"},{"type":"page","artifact_page":37,"page_label":" 23 "}]}"#
        let draft = CitationLocatorDraft.decode(json)
        #expect(draft.page == 37)
        #expect(draft.pageLabel == "23")
        let again = CitationLocatorDraft.decode(draft.encodeJSON())
        #expect(again == draft)
        #expect(draft.encodeJSON().contains(#""page_label":"23""#))
        #expect(draft.encodeJSON().contains(#""artifact_page":37"#))
    }

    @Test func printedPageAloneEncodesALabelOnlySelector() {
        var draft = CitationLocatorDraft.artifactOnly()
        draft.pageLabel = "iv"
        let json = draft.encodeJSON()
        #expect(json.contains(#""page_label":"iv""#))
        #expect(!json.contains("artifact_page"))
        #expect(CitationLocatorDraft.decode(json).pageLabel == "iv")
        #expect(CitationLocatorDraft.decode(json).page == nil)

        draft.pageLabel = "  14 "
        #expect(draft.encodeJSON().contains(#""page_label":"14""#))
    }

    @Test func blankPrintedPageWritesNoSelector() {
        var draft = CitationLocatorDraft.artifactOnly()
        draft.pageLabel = "   "
        #expect(draft.encodeJSON() == #"{"version":1,"selectors":[{"type":"artifact"}]}"#)

        draft.page = 37
        let json = draft.encodeJSON()
        #expect(json.contains(#""artifact_page":37"#))
        #expect(!json.contains("page_label"))
    }

    @Test func printedPageSurvivesLocatorResets() {
        var draft = CitationLocatorDraft.artifactOnly()
        _ = draft.setRegion(Self.rectangle, capabilities: Self.pdf, viewerPage: 3)
        draft.pageLabel = "23"
        draft.resetToEntireArtifact()
        #expect(draft.pageLabel == "23")
        _ = draft.setRegion(Self.rectangle, capabilities: Self.pdf, viewerPage: 3)
        draft.clearRegion()
        #expect(draft.pageLabel == "23")
        draft.removePage()
        #expect(draft.pageLabel == "23")
        draft.peelIllegalLayers(capabilities: ArtifactViewerKind.audio.locatorCapabilities)
        #expect(draft.pageLabel == "23")
    }

    @Test func nonStringPageLabelIsIgnored() {
        let json = #"{"version":1,"selectors":[{"type":"page","artifact_page":3,"page_label":14}]}"#
        let draft = CitationLocatorDraft.decode(json)
        #expect(draft.pageLabel == "")
        #expect(draft.page == 3)
    }

    private static let pdf = ArtifactViewerKind.pdf.locatorCapabilities
    private static let image = ArtifactViewerKind.image.locatorCapabilities
    private static let rectangle = ArtifactRegionDraft(
        kind: .rectangle,
        points: [
            CGPoint(x: 0.1, y: 0.1),
            CGPoint(x: 0.4, y: 0.1),
            CGPoint(x: 0.4, y: 0.4),
            CGPoint(x: 0.1, y: 0.4),
        ]
    )
}
