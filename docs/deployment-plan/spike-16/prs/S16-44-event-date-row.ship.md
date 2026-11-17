# Ship log — S16-44 The Event page's Date row shows as-ofs

**Plan:** [`S16-44-event-date-row.md`](S16-44-event-date-row.md) · **Branch:** `s16-44-event-date-row` · **PR:** #881
**State:** ready

## Round 0 — implement
Base `6d497220e` (`main`).
Head `2f07f98d6`. Gate PASS (orchestrator run, against `6d497220e`). PR #881 (draft).
Report deviations: version 0.22.0 → 0.23.0 (`main` was already 0.22.0); T-1 rows re-chosen where the reconciler folds or drops inputs (phrase-only as-of row dropped; single-valued `date` second value kept as mixed); `PersonDetailTests.aMixedRowDisclosesItsOtherValues` expects `propertyKey: "x"`; new L10n `rowAsOfFormat`/`rowFromFormat`/`rowUntilFormat`; unused T-1 struct fields left in; §10 manual check not run. T-2 `ForEntity` median 118.8 → 128.2 ms (1.08×).

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none (UX: `macos/App/**`, `Localizable.xcstrings`; SEC: `api/ffi/**`; PRF: `core/database/**`, `macos/App/Features/**`).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | major | VoiceOver never reaches lines past the 20th, even after Show more; Place Names with > 20 names regress | Fix now → F-2 | verified: `ReconciledValueRow.summary` ignores children and reads `model.accessibilityLabel`, built once from `shown.listedValues.prefix(listFold.limit)`; `folded.shown` never reaches it. AC-4.1's first label (20) stays; the label grows with the pages revealed |
| MNT-1 | MNT | major | Date row's `lines` repeats `Shown(field:)`'s listing and gates on the role, not the field's state | Fix now → F-1 | verified: `EventDetailContent.lines` gates `role == .asOf`; D-3 says "every displayed value of a `multiple` field, or the first displayed value of a single-valued field". Same-pass cleanup of `Shown(field:)`'s map/drop-empty |
| MNT-3 | MNT | major | `DatingRole` sent to the wire by numeric cast; neighbours use maps | Fix now → F-3 | verified `conclusion_summaries.go:252`. Contradicts D-1's "values equal the proto enum's"; **user 2026-11-17: use a map** |
| MNT-4 | MNT | major | Row-level fold departs from the fold pattern `macos-client-patterns.md:105` documents | Fix now → F-4 | verified: D-5 chose the row-level `@State`; the doc must name it. Doc update, code shape stays |
| CON-1 | CON | major | Archived S16-D6 brief's relative links all break | Fix now → F-7 | verified: moved with 0 line changes; S16-D4's archive commit `b994dadf2` fixed the same links |
| CON-2 | CON | major | §10 manual check not run | Rejected | ship-pr step 8: the user runs the manual check; it goes in the report. The VoiceOver gap it points at is UX-1 |
| MNT-2 | MNT | major | Two Swift role enums with a translating switch | Rejected | D-3 names `DateRowDisplay.Role` (wording roles apart from wire roles); **user 2026-11-17: keep D-3** |
| UX-2 | UX | minor | Last Show more press strands keyboard focus | Fix now → F-5 | verified: button drawn only `if folded.hidden > 0`, `revealed: nil`, `focusedLine` never bound. Departs from D-5's `revealed: nil`; **user 2026-11-17: claim the row's disclosure** |
| UX-3 | UX | minor | Any value change (a Source count) re-folds an opened list | Fix now → F-6 | verified: `.onChange(of: model.shown.listedValues)` compares `support`. Departs from D-5's expression; **user 2026-11-17: reset on line ids** |
| MNT-5 | MNT | minor | Role line's plain text filled through a second format path | Fix now → F-8 | verified `DateRowDisplay.swift:47-53`; precedent `NameDisplayRun.plainText` |
| MNT-6 | MNT | minor | `Value.styled` generic name; `spokenValue` keys off it | Rejected | D-3 names `styled` "as `NameDisplay { text, styled }`"; D-6 names the styled single-line exception |
| MNT-7 | MNT | minor | T-1 table carries unread fields (dup CON-3) | Fix now → F-9 | verified: `wantFst`, `rec.key`, `rec.name` unread; `field` column always `"as_of"` |

Nits (logged): `CON-3 · conclusiondetails_test.go · unused T-1 fields (folded into MNT-7)` · `MNT-8 · compose.go:252 · datingProperties only forwards a map lookup` · `MNT-9 · ReconciledValueRowModel.swift:89 · relabeled's field could be non-optional` · `MNT-10 · EventDetailTests.swift:64-70 · year/day helpers repeat DateRowDisplayTests.point` · `UX-4 · ReconciledValueRow.swift:46 · Show more speaks no row name`
SEC+PRF: no findings (ForEntity 125.0 / 122.8 / 124.7 ms at 10,000 records, 900 kept).

### Fix plan 1
Plan deviations this fix plan makes (record in the plan's Landed note): D-1's cast → a map (MNT-3, user); D-5's `revealed: nil` → the last page claims the row's disclosure (UX-2, user); D-5's reset on `listedValues` → reset on their ids (UX-3, user); D-6's spoken label grows with the pages revealed (UX-1; the first label is still 20, AC-4.1).

**F-1 — One listing rule for a field's lines** (from MNT-1)
Files: `macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift`, `macos/App/Features/Conclusions/EventDetailContent.swift`, `macos/ProvenenciaTests/EventDetailTests.swift`. Skill: `add-ui-component`.
Failing test first: `EventDetailTests.anAsOfFieldThatIsNotMultipleListsItsFirstValue` — an as-of dating whose `as_of` field is `.mixed` (or any non-`multiple` state) with two displayed values lists one `as of` line, per D-3.
Do: extract the listing in `Shown(field:locale:orders:)` (`field.displayedValues` → `PVProvenanceSheetContent.value(…)` → drop empty `text`) into one static on `PVProvenanceSheetContent` (e.g. `listed(_ values:, propertyKey:, role: DateRowDisplay.Role = .plain, locale:, orders:)`); `Shown(field:)` calls it for a `multiple` field. `EventDetailContent.lines` keeps only the role switch and calls it: every displayed value when `field.state == .multiple`, else `field.displayedValues.prefix(1)`. No other copy of the map + empty-drop remains.
Check: `grep -rn "text.isEmpty" macos/App/Features/Conclusions/EventDetailContent.swift macos/App/DesignSystem/Recipes/ProvenanceSheet/PVProvenanceSheetContent.swift` shows the empty-drop once; the test passes; existing Date row tests pass.

**F-2 — The spoken label follows the pages revealed** (from UX-1)
Files: `macos/App/Features/Conclusions/ReconciledValueRowModel.swift`, `macos/App/Features/Conclusions/ReconciledValueRow.swift`, `macos/ProvenenciaTests/EventDetailTests.swift` (and the Place names tests).
Failing test first: `EventDetailTests.theSpokenLabelGrowsWithEachPage` — a 900-line row speaks 20 lines at 0 pages and 70 at 1 page; a Place Names row of 25 names speaks 20 at 0 pages and 25 at 1 page.
Do: `spokenValue` takes the number of lines shown (default `listFold.limit`); the model gains `accessibilityLabel(pages:)` (or equivalent) that returns the stored label at 0 pages and otherwise rebuilds it through `ReconciledValueDisplay.accessibilityLabel` / `relabeled`'s path over `listFold.shown(…, pages:).shown`. `ReconciledValueRow.summary` uses it with `folds.pages(model.id)`. One path builds the label; `relabeled` must keep its label (a relabeled row speaks its own label at every page count).
Check: the test passes; T-10 still passes.

**F-3 — Roles go to the wire through a map** (from MNT-3)
Files: `api/ffi/handlers/conclusion_summaries.go`, `core/database/conclusionsummaries/events.go`.
Do: `var eventDatingRoles = map[conclusionsummaries.DatingRole]engine.EventDatingRole{…}` beside `eventDatingKinds`; `eventDatingPropertiesProto` uses it. Drop "values equal the wire's" from both doc comments.
Check: `rg -n "engine\.EventDatingRole\(" api/ffi/handlers --glob '!*_test.go'` prints nothing; T-11 passes.

**F-4 — The patterns doc names the row's fold** (from MNT-4)
Files: `docs/macos-client-patterns.md`.
Do: after the sentence at line 105 on section folds, add that a `ReconciledValueRow` with more than 21 listed lines folds itself (`ReconciledValueRowModel.listFold`), keeps its pages in its own `ConclusionFoldState`, resets when its lines' ids change, speaks the lines revealed, and on the press that reveals the last page claims the row's disclosure.
Check: plan-docs PASS.

**F-5 — The last page claims the row's disclosure** (from UX-2)
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`.
Do: replace `@FocusState focusedLine: Int?` with a focus state bound to the row's first disclosure stop (the Why `PVDisclosureButton` in `.why` mode, the provenance button in `.sheet` mode, else the other-values disclosure). Pass it to `ConclusionShowMoreRow` as `revealed` only when the press reveals the last page (`folded.hidden <= listFold`'s next page count); earlier presses pass nil and focus stays on Show more. Reuse `FocusClaim`.
Check: builds; gate PASS. (Behaviour joins the user's manual check.)

**F-6 — Reset the fold on the lines' ids** (from UX-3)
Files: `macos/App/Features/Conclusions/ReconciledValueRow.swift`.
Do: `.onChange(of: model.shown.listedValues.map(\.id))`.
Check: gate PASS.

**F-7 — The archived brief's links resolve** (from CON-1)
Files: `docs/deployment-plan/spike-16/design/archive/S16-D6-event-date-row.md`.
Do: add one `../` to each relative link; `archive/S16-D4-event-date-line.md` → `S16-D4-event-date-line.md`, as `b994dadf2` did for S16-D4.
Check: every relative `](…)` target in the file resolves from `design/archive/` (script it), except the `README.md` link already broken in S16-D4.

**F-8 — A role line's text comes from its styled copy** (from MNT-5)
Files: `macos/App/Platform/DateRowDisplay.swift`, `macos/App/Platform/L10n.swift`.
Do: `text = String(styled.characters)`; delete `L10n.Dates.rowFrom` and `rowUntil` (keep the `…Format` resources; `rowAsOf` stays if the header still calls it).
Check: `rg "rowFrom\(|rowUntil\(" macos` prints nothing; `DateRowDisplayTests.lineWordsADatesRole` passes unchanged.

**F-9 — T-1's table holds only what it reads** (from MNT-7, CON-3)
Files: `core/database/conclusiondetails/conclusiondetails_test.go`.
Do: delete `wantFst`, `rec.key`, `rec.name` and the always-`"as_of"` `field` column.
Check: `TestForEntityMultipleDatesInDateOrder` passes.

## Round 1 — fix
Head `1ac26a753`. Gate PASS (orchestrator run). F-1 – F-9 done (commits `2bd311258`, `5bbb287d4`, `5bc75092a`, `22fae3d89`, `4cf702700`, `1ac26a753`). Report deviations: F-9's table became `dates []*datevalue.Value`; F-2 added a private `Voice` enum on `ReconciledValueRowModel` so field-backed and spanning rows rebuild the label on one path; the plan's Landed note and `completed.md` record the four Fix plan 1 deviations.

## Round 2 — review
Reviewers: CON (CON-1), MNT (MNT-1, MNT-3, MNT-4), UX (UX-1). Not sent: SEC+PRF (no findings in round 1). Scope: `2f07f98d6...1ac26a753`.

Round-1 findings: UX-1 **Resolved** (UX) except one case: at 21 lines and 0 pages the fold shows all 21 (`minimumHidden: 2`) but `accessibilityLabel(pages: 0)` speaks `listFold.limit` (20), so line 21 has no way to be heard (orchestrator, from the round-1 fix report; base `namesRow` spoke every name) — **Not resolved**, carried into F-10. MNT-1, MNT-3, MNT-4 **Resolved** (MNT). CON-1 **Resolved** (CON). Minors read by the orchestrator: UX-2 **Resolved** (`revealsLastPage` gates `revealed`), UX-3 **Resolved** (`.onChange(of: model.shown.listedValues.map(\.id))`), MNT-5 **Resolved** (`rg "rowFrom\(|rowUntil\(" macos` empty), MNT-7 **Resolved** (unread fields gone).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-5 (= MNT-11, CON-4) | UX, MNT, CON | blocker | Mixed derived rows (Person Born/Died, Event Place) stop saying "Mixed" to VoiceOver | Fix now → F-10 | verified: `derived(...)` stores `spokenJoin([label, lead, badgeMixed])` but sets `voice: .joined`; the view now speaks `accessibilityLabel(pages:)`, whose `.joined` case is `spokenJoin(label, lead)`. Three lenses independently |

### Fix plan 2
**F-10 — One builder for every row's spoken label, from what the fold shows** (from UX-5, MNT-11, CON-4; UX-1's 21-line case)
Files: `macos/App/Features/Conclusions/ReconciledValueRowModel.swift`, `macos/ProvenenciaTests/EventDetailTests.swift` (and a Person derived-row test where the existing Person tests build one).
Failing tests first:
- `EventDetailTests.aMixedDerivedRowSpeaksTheSameLabelAtNoPages` — the Event Place row with places York and Toronto (as `summarySuppliesSubjectsAndPlace`): `shown.badge == .mixed` and `accessibilityLabel(pages: 0) == accessibilityLabel`, which ends with `L10n.ProvenanceSheet.badgeMixed`.
- Extend `theSpokenLabelGrowsWithEachPage`: a 21-line row speaks 21 lines at 0 pages; a 900-line row still speaks 20 at 0 pages (AC-4.1); `accessibilityLabel(pages: 0) == accessibilityLabel` for a field row, a spanning row, a derived row and an empty row.
Do: `accessibilityLabel(pages:)` is the one builder. Its line count is `listFold.shown(shown.listedValues, pages: pages).shown.count` at every page count (no `listFold.limit` special case). The `.joined` voice appends `L10n.ProvenanceSheet.badgeMixed` when `shown.badge == .mixed` and the lead is not nil (or give `Voice` a case that carries it). `derived(...)`, `spanning`, `empty` and `relabeled` all set the stored `accessibilityLabel = row.accessibilityLabel(pages: 0)`; delete `derived`'s own `spoken` build. Keep `spokenValue`'s styled single-line rule (D-6).
Check: the tests pass; `grep -n "badgeMixed" macos/App/Features/Conclusions/ReconciledValueRowModel.swift` shows it once; scripts/check-pr.sh PASS.

## Round 2 — fix
Head `3f9841e27`. Gate PASS (orchestrator run; `origin/main` unchanged at `6d497220e`). F-10 done: tests red first, then green. Orchestrator read the diff: `accessibilityLabel(pages:)` is the one builder (line count from the fold at every page count; `.joined` appends `badgeMixed` once); `derived`, `empty`, `spanning`, `relabeled` store its pages-0 result. UX-5 / MNT-11 / CON-4 **Resolved**; UX-1's 21-line case **Resolved**.
Nits (logged): `ORC · ReconciledValueRowModel.swift:106 · doc comment still says "At no pages, the first 20" (now: the lines the fold shows)`.

## Result
Gate PASS · CI green · open: none · follow-ups: none · to user: MNT-2, MNT-3, UX-2, UX-3 (answered 2026-11-17)
