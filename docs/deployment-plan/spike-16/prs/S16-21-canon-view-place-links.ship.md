# Ship log — S16-21 Promote's alignment reads a canon view and the place entries

**Plan:** [`S16-21-canon-view-place-links.md`](S16-21-canon-view-place-links.md) · **Branch:** `s16-21-canon-view-place-links` · **PR:** #836
**State:** fixing 1

## Round 0 — implement
Head `68754cdee` (base `43fd47e79`). PR #836 (draft). Gate PASS (orchestrator run). Report deviations:
1. A link move drops both the page and the succession entry for a place (an input key names a bridge end, not a term), where the plan said only the page drops; over-drop, not under-drop. `TestPlaceEntryFollowLinkMoves` asserts it; Landed note records it.
2. Page inputs include the `{id, place_relationship, from}` key; `TestPlaceEntryInputsMatchReads` compares as a sorted set.
3. Temporary build bridges between steps (removed by STEP-5).
4. Base benchmarks run from a `git archive ba2d35a` extract, not a worktree.
5. `main` moved past `ba2d35a`; no Current-state file changed.

D-13 medians (3 runs, base `ba2d35a` vs head, implementer's machine): LargeSourcePropose warm 4,000 persons 169.9 → 166.3 ms, 16,000 persons 194.4 → 182.4 ms; ProposeWarmCity 270 → 260 ms; `placeSuccession-B` 56 KB (51 keys); `placePages-B` 44 → 36 KB. The SEC+PRF reviewer's own runs (loaded machine, load 12–15) show warm allocs −13% (554,936 → 482,816), B/op +6%, times within noise; heap held after a proposal unchanged.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (core/graphalign, core/kinship, core/database/**). Skipped: UX (no `macos/App/**`, strings, `core/apperr` or error codes).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | The three place fills each build the same inputs by hand | Fix now → F-1 | verified: `placeentries.go:208`, `:230-238`, `:259-267`; `rg 'FollowKeys\(' core` outside graphcache prints exactly these three. Same-pass cleanup: this PR adds the third copy |
| MNT-2 | MNT | major | "Each distinct end of a link" written out in three places | Fix now → F-2 | verified: `rg 'bytes.Equal\(\w+\.A, \w+\.B\)' core` prints `recordlinks.go:125`, `types.go:209`, `align.go:126`. Same-pass cleanup: this PR adds two copies; the `recordlinks` copy moves too |
| MNT-2b | MNT | — | `recordlinks.addLink` reads a self-loop through `Edge.From(end)` (only `KeyA`), unlike D-16's layer reading | Follow-up | older than this PR; changes what record-link pages read for a self-loop, so not a same-pass cleanup |
| MNT-3 | MNT | minor | New cache named singular beside plural siblings | Fix now → F-3 | minor in code this PR adds |
| CON-1 | CON | minor | D-13 medians missing from the ship log | Fixed (orchestrator) | copied into Round 0 above |
| CON-2 | CON | minor | Plan §10 manual check not run | To user (routine) | the user runs §10 at hand-off (ship-pr step 8); no Swift or strings change |

Nits (logged): `MNT-4 · core/graphalign/connections.go:646-669 · name the reader closure in NewFiled's open` · `MNT-5 · core/connectrules/filing.go:30 · "both decide through it" has no referent; name Filed.Decide` (stale comment in a changed file → rides F-3) · `CON-3 · connections_test.go · reader cases shipped as standalone tests, not TestConnections rows` · `CON-4 · invariants_test.go · TestPlacePartOfItselfPlaces cannot tell D-16's KeyB reading from the old one`

SEC+PRF: no findings (lazy and eager loop checks agree on ~120,000 random checks; no new panic path).

### Fix plan 1

**F-1 — One inputs rule for the place fills** (from MNT-1)
Files: `core/database/conclusionsummaries/placeentries.go`.
Failing test first: none (refactor); `TestPlaceEntryInputsMatchReads` and `TestPlaceEntries*` must stay green, with `PROVENENCIA_GRAPH_VERIFY=1` too.
Do: compute a place's inputs once in `followPlaces` (a `followedPlace.inputs` field, or a helper `placeInputs(id, f, hopList)` returning `[NodeKey(id)]` when `f` is nil): `NodeKey(id)` plus `FollowKeys(id, hop, f.links[i])` for each hop, through `UniqueInputKeys`. `fillPlaceEntries`, `fillPlacePages` and `fillPlaceSuccessions` read it; their own key-building lines go.
Check: `rg -n 'FollowKeys\(' core | grep -v graphcache/` prints one line, in the shared helper or `followPlaces`. scripts/check-pr.sh PASS.

**F-2 — `kinship.Edge.Ends`** (from MNT-2)
Files: `core/kinship/kinship.go`, `core/kinship/kinship_test.go`, `core/graphalign/types.go`, `core/graphalign/align.go`, `core/recordlinks/recordlinks.go`.
Failing test first: `TestEdgeReadings` (or a sibling table test) gains cases for `Ends`: a link between two handles yields A then B; a self-loop yields A once.
Do: add `func (e Edge) Ends() iter.Seq[[]byte]` beside `Readings`. Move `Canon.View` (`types.go:208-211`), `newState` (`align.go:125-132`) and `recordlinks.NewGraph` (`recordlinks.go:123-127`) onto it. Do not change `recordlinks.addLink`'s `From` reading (a Follow-up).
Check: `rg -n 'bytes.Equal\(\w+\.A, \w+\.B\)' core` prints only the line inside `Ends`. Goldens and `go test ./core/recordlinks/... ./core/graphalign/... ./core/kinship/...` pass. scripts/check-pr.sh PASS.

**F-3 — Plural name for the succession cache; comment referent** (from MNT-3, MNT-5)
Files: `core/database/conclusionsummaries/placeentries.go`, `placechains.go`, `docs/catalog-caches.md`, `core/database/promotealign/bench_test.go`, `core/connectrules/filing.go`, and any test or doc naming the old key (the plan's Landed note, `completed.md`).
Do: rename the registered cache `conclusionsummaries.placeSuccession` → `conclusionsummaries.placeSuccessions`, field `placeGraph.succession` → `successions`, the bench measure `placeSuccession` → `placeSuccessions`, and the doc row. In `filing.go:30` name `Filed.Decide` in place of "it".
Check: `rg -n 'placeSuccession\b|"placeSuccession"|\.succession\b' core docs` prints nothing but the type name `placeSuccession` (the per-key value type stays singular). scripts/check-pr.sh PASS.
