# Swift test fixtures

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. Test helpers and fakes copied across the macOS test suite ([`add-swift-test`](../../.agents/skills/add-swift-test/SKILL.md)).

## Artifact file fixtures

Fold leftover test PNG / PDF writers and `seedArtifact` into `ArtifactFileFixtures`. `waitUntil` already lives in `QueryHandleWaiting`. Still private: `ArtifactViewerModelTests` (`minimalPNGData` / `minimalPDFData` / `textPDFData`), `CitationComposerModelTests.seedArtifact`. Touch with the next artifact or composer test edit. (S10-34 / dogfood 2026-10-17)

## Person key tests and fake reads

Each person key repeats near-identical tests and fake reads: three hand-kept key lists and four RevalidateOnTouchedHandle and four LoadThroughTheStore tests in `CatalogQueryRegistryTests`, four seeded-read stubs in `FakeStore` (around lines 1865–1915), and the raw `"conclusiondetails.not_found"` thirteen times (FakeStore, `CatalogQueryRegistryTests`, `PersonDetailTests`) beside `EngineErrorCode.conclusionNotFound`. One `@Test(arguments:)` over (key, value), one `FakeStore.seededRead(_:entityID:)`, and the typed code. (P-27, Person page audit)

## The fake's saved observations near-copy

`FakeStore.appendFakeObservations` near-copies `fakeObservation` and synthesizes an engine-like `displayText` (text, term, date, subject) for the saved row; build it on `fakeObservation` and drop the synthesis once the composer reads every saved line from `ObservationValueDisplay`. (S14-37 review M-7)
