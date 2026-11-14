# Review — S15-D5 Evidence graph form and graph rows

**Verdict:** Fits with changes — Not ready → fixed in round 1 (round 2 below)
**Rounds:** 1. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user

- **The form's body and scrolling (X-4).** A body that never scrolls cannot fit: the fixed parts reach about 980pt and the window can be 460pt tall. **Answered (user, 2026-11-14):** the whole body may scroll when everything does not fit; a long Artifact list must not be the cause. The checklist keeps its 264pt cap and the form uses the kit's scrolling body (EG-6).

## Writer's own calls

- The form is 560pt wide, as the Artifact sheet (EG-7).
- Graph values ride the Source page's read and the graph write replies answer the graph's rows (M-1); the edit form opens from the page's values, with no store read of its own. The map's S15-11 entry is re-cut to match.
- "+n more" on a graph row reads the graph's ref, as the Artifact row reads its ref (M-2).

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
