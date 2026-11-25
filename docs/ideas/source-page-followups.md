# Source page follow-ups

**Status:** idea only — not roadmapped. Split out of the retired `structural-debt.md` on 2026-11-17 (checked against the code that day). No user-visible change unless a section says so; pull one in when a feature next changes that code. How the Source page learns that its Source is gone.

## Missing-Source errors outside the page context

A Source deleted elsewhere reaches the Source page as `sources.not_found` through `SourcePageContext.fail` from the sections that write through the page context. The note, metadata, credibility and Artifact packages, and `SourceCopyModel` and `SourceGraphFormModel`, still map a missing Source in their own Go package or Swift model; give each the same `sources.ErrNotFound` and route the two form models through `fail` when those files are next touched. S15-32 left `SourceCopyModel` as it was: it has two hosts and the Sources list has no `SourcePageContext`. (S15-03 plan)

## Delete after the Source was deleted elsewhere

Delete from the Source page after the Source was deleted in another window: `DeleteImpactFlow` reports `sources.not_found` as its own error, not through `SourcePageContext.fail`, so the page does not leave with the "was deleted" notice. Route it through `fail` when `DeleteImpactFlow` is next touched. (S15-03 plan)

## The fake answers a missing Source with a blank one

`FakeStore.getSourceWorkspace` returns a blank `SRC-XXXXX` Source for an unknown id where the engine answers `sources.not_found`. `CatalogSessionStoreTests.getSourceWorkspaceMarksSessionHeld` reads the missing id `"missing"` and relies on the blank read; seed a Source in that test, then throw `sourceNotFound` from the fake. (S15-03 review MNT-6)

## Exact Sources row heights

The Sources table's platform estimates a row it has not drawn at 34 pt, and a Source row is 66, so a far scroll position can land on other rows than were left, and Back to one the estimated document is too short to show opens at the top (S16-72, D-13, accepted by the user, 2026-11-25). Give the table its row heights (the outline knows each row's kind, so each row's height is a function of it) so a far y lands on the same rows. Pull it in when the Sources table next changes.
