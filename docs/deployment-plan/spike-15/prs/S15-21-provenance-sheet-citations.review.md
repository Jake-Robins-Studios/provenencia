# Review — S15-21 The provenance sheet shows formatted citations

**Verdict:** round 1: Fits with changes — Not ready (X-1: the board is not agreed; X-2, X-3: tests not writable as specified). Round 2: pending
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet). Reviewed with the brief [S15-D9](../design/S15-D9-provenance-sheet-citations.md)

## To user

- **M-3: the rule's wording.** "Citations render on demand" names `whenHidden: .evict`, which cannot hold a key no place shows. Recommended: reword to "released when the sheet closes (`WorkspaceSession.release`)". **Answered (user, 2026-11-21): reword.** Done in `deployment-plan.md` (the rule and S15-21's scope entry); the plan's **Rules this plan bends** names it.
- **M-2: the load area.** Recommended: the kit's `PVFormLoadArea` as it is (skeleton bars, Read again) instead of the spinner and Try again the user first picked. **Answered (user, 2026-11-21): use the kit area.**

## Writer's own calls

- Copy full and Copy short are two `PVClipboardButton`s in a 58pt track on every row; a fallback row keeps one Copy citation (D-9). The user chose two buttons; the track width and the slot order are the writer's.
- A same-citation run is ordered by first appearance inside each value run, never across value runs or owner groups (D-7).
- The sheet's key is keyed by the sorted distinct citation ids; no chunking past 2,000 ids (D-2, D-5).
- The empty-Source-title fallback is deleted with no replacement; the denier phrase test drops its untitled case (D-10, STEP-8).
- The store method returns reply order; the sheet's value holds a dictionary (D-1, D-2).
- The version bump is minor (0.31.0).

## Round 1

### M-1 · blocker · Two ways to style the same citation runs, beside the app's styled-text convention
`CitationRunsText` moved to Platform plus a separate `pasteboardText`; the app already marks emphasis `.emphasized` in an `AttributedString` (`NameDisplay.styled`) and draws it with `PVTitleText.italicizingEmphasis`.
**Answer:** Fixed — D-11: one `CatalogCitationRender.styled` (`.emphasized`) in `Platform/CitationLineDisplay.swift`; the row and the format preview draw it through `italicizingEmphasis`; the kit's `rtfData` turns emphasis into the italic trait. D-12: `CitationRunsText` is deleted. Brief inventory row rewritten.

### M-2 · blocker · A third read-to-state mapping beside the kit's load area
`PVProvenanceSheet.Citations` and `ProvenanceSheetHost.citations(for:)` beside `PVFormLoadState` / `QueryRead.formLoadState` and `ConclusionDetailPresentation`; grouping inside the recipe's body.
**Answer:** Fixed (with the user's answer above) — D-6: the recipe takes `PVFormLoadState` and draws `PVFormLoadArea` unchanged; D-4: the host maps with `QueryRead.formLoadState` and groups once per value in `@State`. No recipe enum, no new mapping. Brief PC-6, PC-7, frames 4–5 and inventory rewritten.

### M-3 · blocker · D-2/D-3 bend a working rule; `release` could drop a key another view holds
**Answer:** Fixed and To user (answered) — the rule is reworded with the user's answer and listed under **Rules this plan bends**; `release` does nothing for a key in `visibleKeys`, its doc names one holder per released kind, and the kind is the sheet's alone (M-5). T-3 covers the guard.

### M-4 · blocker · Swift repeats and contradicts the engine's no-format grouping rule
**Answer:** Fixed — D-7 groups only by the engine's `groupKey`, falling back to the record's id only when the reply has no render. AC-3.4, Edges, T-5 and the brief's § 2 "Same citation" now say two records of one no-format Citation share a run; different no-format Citations never do.

### M-5 · major · The key and value are named for citations, but S15-29 grows this read
**Answer:** Fixed — D-2: `Kind.provenanceSheet`, `CatalogProvenanceSheetRead { citations; inputs }`; the store method stays `renderCitations` with `CatalogRenderedCitations` for S15-22, which gets its own key.

### M-6 · major · Brief inventory: load rows skip `PVFormLoadArea`; a View moves into Platform
**Answer:** Fixed — brief § 6: one "Record area load state · `PVFormLoadArea`" row; "Formatted citation text" is the Platform formatter drawn through `PVTitleText`.

### M-7 · minor · Codebase fit leaves out the closest existing code
**Answer:** Fixed — § 6 Codebase fit names `PVFormLoadState`, `QueryRead.formLoadState`, `ConclusionDetailPresentation`, `NameDisplay.styled`, `PVTitleText.italicizingEmphasis` and `evict(_:ids:)`'s guard.

### X-1 · blocker · Blocked on a board that does not exist
**Answer:** Declined as a plan defect — the status is `Blocked — on board S15-D9` on purpose (plan-pr step 3: "Brief written, board not agreed → Blocked"). The plan is refreshed with the board link and frames before it moves to Planned; the stop condition applies then.

### X-2 · blocker · T-2 cannot set the reply's inputs
**Answer:** Fixed — STEP-1's FakeStore gains `renderCitationsInputs`; T-2 builds the write as `CatalogWriteEffects(reads: [CatalogWriteEffectsRead(read: .sourceRecords, ids: ["s1"])])`.

### X-3 · blocker · T-9's helper cannot produce `.failed`
**Answer:** Fixed by M-2 — the helper is gone; T-9 checks `QueryRead.formLoadState` through the session (loading, failed, ready).

### X-4 · major · Release rules unspecified
**Answer:** Fixed — D-4 names `.task(id:)`, `.onChange(of: key) { old, _ in release(old) }`, `.onDisappear`, the nil-handle state and the environment inheritance.

### X-5 · major · D-10 breaks `ReconciledValueDisplayTests`
**Answer:** Fixed — STEP-8 lists the file, the dropped case and the renamed test; D-10 says an empty title is not handled.

### X-6 · major · STEP-8's `rg` searches the wrong paths
**Answer:** Fixed — `rg … macos/App macos/ProvenenciaTests`, expected hits named.

### X-7 · major · Row layout choices open
**Answer:** Fixed — D-9 names the container, the first slot, the spoken label, the fallback id, the font through `italicizingEmphasis`, and why the first-line guide holds.

### X-8 · major · The table's rule logic across runs
**Answer:** Fixed — D-9 **Rules (table)** states the condition and the `ForEach` identities.

### X-9 · major · The RTF stop condition has no test
**Answer:** Fixed — T-7b round-trips `rtfData` through `NSAttributedString(rtf:)`.

### X-10 · minor · GoStore mapping and dictionary build
**Answer:** Fixed — STEP-1 says the mapping is checked by the manual check, as for `renderCitationPreview`; D-2 builds the dictionary with `uniquingKeysWith`, T-2 covers a duplicate.

### X-11 · minor · Model and key gaps
**Answer:** Fixed — `Sendable, Equatable` on the new types; STEP-2 adds `.provenanceSheet` to tests that list every kind; T-3 covers an in-flight release; STEP-9 gives full paths and the `catalog-caches.md` wording; the scope entry is corrected in this planning PR.

### X-12 · minor · `PersonDetailTests` lines
**Answer:** Fixed — STEP-8 deletes the whole untitled block (236–240) and line 228.

### X-13 · minor · The Review link is dead
**Answer:** Fixed — this log.
