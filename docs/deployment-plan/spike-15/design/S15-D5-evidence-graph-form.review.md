# Review — S15-D5 Evidence graph form and graph rows

**Verdict:** Fits with changes — Ready with changes (round 2's findings Fixed or Declined; no open blocker)
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **The form's body and scrolling (X-4).** A body that never scrolls cannot fit: the fixed parts reach about 980pt and the window can be 460pt tall. **Answered (user, 2026-11-14):** the whole body may scroll when everything does not fit; a long Artifact list must not be the cause. The checklist keeps its 264pt cap and the form uses the kit's scrolling body (EG-6).

- **The kit's scrolling body is capped at 560pt (X2-1).** With it the one-column form scrolls almost always. **Answered (user, 2026-11-14):** make the form two columns (880pt: fields and board left, Artifacts right), the app's first; if it works, the other sheets follow (`docs/ideas/wide-layout.md` "Two-column form sheets").

## Writer's own calls

- Two equal columns at 880pt; one 560pt column when the Source page pane is below 960pt, chosen when the form opens (EG-7).
- Graph values ride the Source page's read and the graph write replies answer the graph's rows (M-1); Edit reads the graph's board through `GetMetadataBoard` before the form opens, because `sourcemetadata.Apply` deletes any value a draft leaves out and each window has its own `WorkspaceSession` (`WorkspaceView.swift`), so a stale page cache could erase another window's values. The map's S15-11 entry is re-cut to match.
- "+n more" reads one owner-neutral string, "3 more details of <ref>", on both rows; the Artifact row loses the word "copy" (M2-3).

## Round 1

### X-1 · blocker · "The graph's saved values are already on the page" is false today
Nothing in Swift holds a graph's rows: `CatalogSourceWorkspace.metadataRows(for:)` answers nil for `.graph`; the graph writes send `metadata: nil`.
**Answer:** Fixed — §2 "Where the values come from": S15-11 makes the Source page's read carry each graph's values and the graph Save answer its rows. Same finding as M-1.

### X-2 · blocker · Frame 3 shows a row edit and the Add field row at once
`MetadataBoardModel.openAddRow()` ends a row edit first.
**Answer:** Fixed — frame 3 split into 3a (Line being edited) and 3b (Add field row open).

### X-3 · blocker · Cancel closes at once; only Escape and an outside click ask
`PVFormDialog` Cancel calls `onCancel`; S15-D14's Board line records the same.
**Answer:** Fixed — EG-3 and frame 5 (after Escape); §1 no longer says Cancel discards with a confirm.

### X-4 · blocker · The tallest case cannot fit a non-scrolling body
**Answer:** To user, answered — EG-6 rewritten: the lists keep their caps; the body scrolls with the kit's scrolling body only when the rest does not fit. Frames 7a and 7b.

### X-5 · major · Data and the "0, 3 and 7" frame disagree
**Answer:** Fixed — EG-8 draws 0, 4 and 7 (Ostrander, Robins, Hale); frame 3a is Robins before Family was saved.

### X-6 · major · The read-only view is Artifact-named
**Answer:** Fixed — inventory "Read-only values": one owner-neutral view that owns the 320 / 440pt width. Same as M-2.

### X-7 · major · "The two sections line up" cannot hold
**Answer:** Fixed — EG-W1 says the same width, not alignment.

### X-8 · major · Add becomes async; guard and banner unstated
**Answer:** Fixed — §2 "Opening the form": the same guard and page banner as Add artifact; inventory "Page error banner" names `SourcePageContext.showFailure` and no new copy. Same as M-6.

### X-9 · minor · Typeless Source, untouched suggestions
**Answer:** Fixed — §2 says a typeless Source has no suggestions (frame 4 covers it). An untouched suggestion writes nothing (`MetadataDraftHost`), as on the Artifact sheet; no brief change.

### X-10 · minor · S15-36 has no landed link
**Answer:** Fixed — header.

### M-1 · blocker · Graph values have no data path; the map's S15-11 entry plans another
**Answer:** Fixed — §2 "Where the values come from"; the map's S15-11 row and scope entry are re-cut (Go and Swift; no `getMetadataBoard` in Swift; no reload; the graph replies answer rows). The plan carries the engine detail.

### M-2 · major · The values view and its width are Artifact-named
**Answer:** Fixed — inventory; EG-9 reads the ref, as the Artifact row.

### M-3 · major · A third copy of "put an owner's rows on the page, then `.wroteMetadataBoard`"
**Answer:** Fixed in the plan (S15-11 extracts one helper on `SourcePageContext`); no brief change.

### M-4 · major · The open-field message is an Artifact-sheet key
**Answer:** Fixed — §2.1 calls it the board's open-field message; the plan renames the key.

### M-5 · minor · A per-form checklist cap
**Answer:** Fixed — moot after X-4: the cap stays 264 for every checklist; the brief adds no cap of its own.

### M-6 · minor · Reuse the Artifact add path's suggestion read
**Answer:** Fixed — §2; the plan calls `SourcePageContext.unsavedMetadataRows(level: .graph)`.

## Round 2

### X2-1 · blocker · The kit's scrolling body is capped at 560pt, not the window
`PVFormDialogContent.maxScrollingBodyHeight` is 560; a one-column form is about 800pt.
**Answer:** To user, answered — two columns (EG-1, EG-6, EG-7; frames 7a – 7c).

### X2-2 · major · Where "+n more" lands
**Answer:** Fixed — EG-8: scrolled to Evidence graph metadata when the body scrolls; the plan passes `scrollTarget`.

### X2-3 · minor · Frame 5 contradicts EG-4
**Answer:** Fixed — frame 5 is after a click outside.

### X2-4 · minor · Opening has no requirement
**Answer:** Fixed — EG-10.

### X2-5 · minor · The shared view's name and keys
**Answer:** Fixed — inventory names `MetadataDetailsColumn`; the plan's D-7 names the keys and ids.

### M2-1 · blocker · The workspace does not list the Source's graphs
**Answer:** Fixed — §2: membership stays with the graph list; the page read adds values keyed by graph. The plan's D-3 makes `setMetadataRows` write a graph's rows without a membership check. A deleted graph's entry is left: rows are read by the graph list's ids, which are never reused (Declined only for the cleanup, with that evidence).

### M2-2 · blocker · M-3 and M-4 rest on a plan that did not exist
**Answer:** Fixed — the plan exists (`prs/S15-11-graph-metadata.md` D-6, D-8) and the map's S15-11 entry names both. `MetadataBoardHost.didWrite` stays out of the helper: it applies the mutation only and never sets the page's rows (its live board owns them), so it is not a copy of the two lines.

### M2-3 · blocker · EG-9's text contradicts the shared view
The Artifact label reads "3 more copy details of ART-…".
**Answer:** Fixed — EG-9: one owner-neutral string for both rows; the Artifact row's label changes.
