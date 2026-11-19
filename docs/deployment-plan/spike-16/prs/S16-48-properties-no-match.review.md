# Review — S16-48 A Properties search with no match shows the kit's empty state

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet). Plan and brief S16-D8 reviewed together.

No round 2: round 1's only blockers were M-1 (fixed by deleting a trim, no reshape) and X-1 / X-2 (the board, which is the user's).

## To user

- **X-2 · Which board holds the Properties page frames?** Answered (user, 2026-11-19): the "Properties View" board, page `S7-D2 Subject Fields`; the S16-D8 turn is drawn there. Linked on the brief's and the plan's **Board** lines.
- **How the agreed board reaches the implementer.** The artifact link and section on the **Board** line, as S16-D6 did.

## Board check (2026-11-19)

The "S16-D8 · No match" section draws N1a, N1b, N2, N3a, N3b and N4. Against the brief: all four strings exactly; icons `text-search` (`PVSymbol.searchEmpty`) and `list-tree` (`WorkspaceSection.properties.glyph`); each state top-aligned with a `space6` inset (D-4); identifiers `properties.noMatch`, `properties.emptyType`, `properties.clearSearch` (D-7); the body order rows → no match → empty type → nothing (D-1); the 120-character title wraps; Wide spans the card beside the 340 pt inspector. One difference: Clear search is drawn `sm`, the toolbar's size, where the Sources precedent uses the default `md`. Taken into D-3. Plan → Planned.

## Writer's own calls

- D-1: the body is decided in the model (`PropertiesTablePresentation`), with "no Properties loaded" (`.nothing`) checked before the search, so a query typed during the first load shows nothing rather than a no-match state.
- D-2: Clear search moves focus to the search field.
- D-4: inset `space6`, top-aligned inside the card (board can change it).
- D-6: `openCreate`'s never-used `prefillLabel` goes, since there is no Create button.
- D-9 (from M-3): `PVEmptyState` gains its missing `glyph:verbatimTitle:` init so the empty-type state reads `WorkspaceSection.properties.glyph`.
- Copy: "Try another word, or clear the search.", "Clear search", "No properties on %@", "Add one with the field above."

## Round 1

### M-1 · blocker · The query is trimmed twice: in the body decision and in `emptySearchTitle(query:)`
`L10n.Properties.emptySearchTitle(query:)` trims beside D-1's trim; elsewhere the model trims and L10n only formats (`CatalogSearchModel.trimmedQuery` → `L10n.Workspace.omnibarNoMatchesTitle(query:)`).
**Answer:** Fixed — D-5, Strings and STEP-2: the accessor becomes a plain `L10n.format` with no trim; D-1 is the one trim.

### M-2 · major · `.nothing` re-derives "first load" beside a dead `isLoading`
`PropertiesModel.isLoading` has no caller (`rg`, confirmed).
**Answer:** Fixed — `isLoading` is in **Deletes** and STEP-1; a Stop condition if it has gained a caller. The case keeps the name `.nothing`: it also covers an empty catalog, which is not loading.

### M-3 · major · The empty-type icon hard-codes `.listTree` instead of the section's glyph
`MetadataListPane`, `SourceTypesListPane` read `WorkspaceSection.<section>.glyph`; `PVEmptyState` lacks only `glyph:verbatimTitle:`.
**Answer:** Fixed — D-3, D-9 (new), Codebase fit, STEP-3, Out row narrowed to the kit's look and other inits; brief inventory rows Empty state (Extend) and Icons.

### M-4 · minor · Next adds misses the reorderable bound-Properties idea
**Answer:** Fixed — **Next adds** names `docs/ideas/properties-and-terms.md` as a future case of the presentation enum.

### M-5 · minor · Names: one family for the no-match state; "Presentation" for the enum
**Answer:** Fixed — `PropertiesTablePresentation` / `tablePresentation`; `emptySearchTitle(query:)` → `noMatchTitle(query:)` (key unchanged); old names in the DoD sweep.

### X-1 · blocker · Blocked on a board that does not exist
**Answer:** Declined as a plan defect — it is the gate itself: status stays `Blocked — on board S16-D8` until the user agrees the board.

### X-2 · blocker (brief) · The brief never names the board holding the Properties frames
**Answer:** To user (above).

### X-3 · major · Checks need Xcode, absent on a Linux host
**Answer:** Declined — `scripts/check-pr.sh` and every Swift plan in this spike (S16-46 STEP checks) run `xcodebuild test` on the macOS machine the ship loop uses; the manual check is the reviewer's, as the template says.

### X-4 · major · Where the accessibility identifiers go
**Answer:** Fixed — D-7 places them as the Sources precedent, and forbids an `.accessibilityElement` modifier.

### X-5 · major · The L10n declarations are not typed
**Answer:** Fixed — Strings gives each kind and the xcstrings entry shape.

### X-6 · minor · Which `MARKETING_VERSION` lines
**Answer:** Fixed — STEP-4: all four lines, both targets.

### X-7 · minor · First-load and stale type key edges
**Answer:** Fixed — D-1 checks "no Properties loaded" before the search; T-5 now expects `.nothing` for `zzz`; a stale type key is `.rows`.

### X-8 · minor · Test fixture, commit order, sweep hits
**Answer:** Fixed — STEP-1 gives the `sourceType()` fixture, tests first, D-6 in its own commit; the DoD notes the expected `prefillLabel` hits in this plan and the map.

### X-9 · minor (brief) · The box is the kit's
**Answer:** Fixed — PN-5 says the EmptyState box is drawn as the kit draws it.
