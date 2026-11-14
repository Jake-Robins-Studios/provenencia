# Ship log — S16-24 Person, Event and Place reads report their inputs

**Plan:** [`S16-24-reads-report-inputs.md`](S16-24-reads-report-inputs.md) · **Branch:** `s16-24-reads-report-inputs` · **PR:** #839
**State:** ready

## Round 0 — implement
Base `main` @ `1255b24f7` (plan written against `43fd47e`).
Head `e48ba67d3` · draft PR #839. Gate PASS (orchestrator run). Report deviations: S16-21 landed after the Planned commit and split place succession into `placeSuccession`, so `AttachPlaceRelationships` also records that entry's inputs (AC-1.3); handler recorder named `inputs` (not `in`, taken by the request bytes); T-10 Place case asserts the handle only, ids covered in core; test helper `datedBirth` added. Implementer saw one `TestLargeSourceBudgets` timing miss (2.517s vs 2.5s) while xcodebuild ran concurrently; passes on rerun and in this gate.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. UX: diff touches `macos/App/**`. SEC+PRF: `api/ffi/**`, `core/database/**` (graph and cache code).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | Place page does not record a child it hides (Contains filtered by `ImmediateParts`/`linkHolds`), so a write to that child's dates misses the page | Fix now → F-1 | verified: `placechains.go` Contains loop calls `AddHandles` only for ids `ImmediateParts` returns; `linkHolds` reads the child's period; reviewer's scratch test fails at head. Recording more than D-4's "every place it lists" changes no value and follows §6 Edges "Neighbors" (read-but-not-shown is recorded); noted in the Landed note |
| CON-2 | CON | minor | AC-1.11 "inputs equal the first's" compared for Family only | Fix now → F-2 | test-only gap in tests this PR changes |
| MNT-1 | MNT | minor | `PageInputs.off` duplicates `InputScope.off` | Fix now → F-3 | verified: `pageinputs.go:19-32`; same package, `p.scope.off` visible; D-1 needs only "return before Add", not a second field |
| MNT-2 | MNT | minor | `PersonFamily` re-adds relatives `shownKin` already recorded | Rejected | D-3 and D-7 name this `Add` explicitly ("`PersonFamily` adds every id it reads a summary of"); it ties recording to the summaries the read loads, not to `shownKin`'s filter |
| UX | UX | — | No findings | — | — |
| SEC+PRF | SEC+PRF | — | No findings | — | — |

Nits (logged): `MNT-3 · .agents/skills/add-ffi-handler/SKILL.md:57 · in → inputs` (stale doc in a changed file: rides on F-3) · `MNT-4 · placechains.go:422-436 · use self` (rides on F-1, same lines) · `MNT-5 · GoStore.swift mapPersonRecordLinks · Self.mapPageInputs` · `CON-3 · test helpers pass PageInputs() not NoPageInputs(); mention in Landed note` (rides on F-1) · `CON-4 · T-3 lives in placerecords_test.go; expected ids from returned rows` · `CON-5 · handler Place case checks own id only`

### Fix plan 1

**F-1 — Place page records every part it reads, shown or hidden** (from CON-1; MNT-4, CON-3 ride along)
Files: `core/database/conclusionsummaries/placechains.go`, `core/database/conclusionsummaries/placechains_test.go`, plan Landed note.
Failing test first: `TestAttachPlaceRelationshipsRecordsHiddenParts` — Town contains Village whose own period ends in 1900, so Contains is empty but `in.Lists()` handles hold Village (test body in CON-1).
Do: in `AttachPlaceRelationships`, next to the three `AddKeys` calls, `for _, l := range g.pages[self].partTo { in.AddHandles(l.from) }`, and drop the per-listed-child `in.AddHandles` in the Contains loop. Use `self` in place of `string(h.Entity.ID)` in that function (MNT-4). Update the function doc ("…and the id of every place it reads a part link to or lists"). In the plan's Landed note add: D-4 now records every part the page reads, not only the ones it lists (CON-1); test helpers pass `PageInputs()` where D-2 says `NoPageInputs()`, which changes no value (CON-3).
Check: the test is red before, green after; `TestAttachPlaceRelationshipsRecordsInputs` still passes; scripts/check-pr.sh PASS.

**F-2 — Warm reads report the same inputs as cold** (from CON-2)
Files: `core/database/persondetail/claims_test.go` (`TestClaimsWarmReadIssuesNoQuery`), `core/database/persondetail/timeline_test.go` (`TestPersonEventsQueryCount`), `core/database/conclusiondetails/conclusiondetails_test.go` (`TestForEntityQueryCountIsConstant`).
Do: keep each read's recorder and compare the two `Lists()` results as `TestPersonFamilyQueryCount` does.
Check: tests pass; scripts/check-pr.sh PASS.

**F-3 — One "records nothing" flag** (from MNT-1; MNT-3 rides along)
Files: `core/database/graphcache/pageinputs.go`, `.agents/skills/add-ffi-handler/SKILL.md`.
Do: delete `PageInputs.off`; read `p.scope.off` in `Cached`, `AddHandles`, `AddKeys`, `AddEvidenceGraphs`, `AddSources`, `Lists`. In the skill, `Inputs: pageInputsProto(inputs)` with the recorder named `inputs` (MNT-3).
Check: `rg -n "p\.off\b" core/database/graphcache` prints nothing; `TestPageInputs` passes; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `25b4fbf9a`. Gate PASS (orchestrator run). F-1 done: `TestAttachPlaceRelationshipsRecordsHiddenParts` red before, green after. F-2 done. F-3 done. No deviations.
Read by the orchestrator: F-2 (CON-2) **Resolved**: the claims, timeline and detail warm-read tests compare `Lists()` across the two reads. F-3 (MNT-1, MNT-3) **Resolved**: `off` field gone, every method reads `p.scope.off`; skill reads `pageInputsProto(inputs)`.

## Round 2 — review
Reviewers: CON (CON-1 blocker). Not sent: MNT (minors only, read above), UX and SEC+PRF (no findings). Scope `e48ba67d3...25b4fbf9a`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | blocker | (round 1) hidden child not recorded | Resolved | `placechains.go:428-430` records every `partTo` link's `from` before filtering; `TestAttachPlaceRelationshipsRecordsHiddenParts` |
| CON-6 | CON | blocker | Place page does not record a parent its period hides | Rejected | verifier Refuted end to end: a place's summary row walks every `partFrom` link without a period check (`closure`/`reach`, `placechains.go:65-95`; `finishPlaces` `compose.go:1216`), so a write to the hidden parent names the child in `SummaryDeps` (`searchindex.ReprojectChanged`), which the app follows as `touchedHandles` (`CatalogMutation.swift:135`) — the route D-4 names. Probe: deleting County's `start_date` put Village in the write's `SummaryDeps` and Village's PartOf went 0 → 1. A hidden child has no such route (empty `SummaryDeps`), which is why F-1's direct record is needed there and not here |

No Fix plan 2: no confirmed round-2 blocker.

## Finish
Merged `origin/main` @ `8245d2d35` (docs only); gate PASS (orchestrator run).

## Result
Gate PASS · CI pending · open: none · follow-ups: none · to user: —
