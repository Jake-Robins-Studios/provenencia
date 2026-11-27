# Ship log — S16-82 The Family read sends sibling groups and each couple's marriages

**Plan:** [`S16-82-family-groups-and-marriages-read.md`](S16-82-family-groups-and-marriages-read.md) · **Branch:** `s16-82-family-groups-and-marriages-read` · **PR:** #1009
**State:** ready

## Round 0 — implement
Head `eb4e6987e`. Gate PASS (orchestrator run against `47935695b`). Report deviations: T-9 is a new test `TestDropUnreadGroupsAndCouples` rather than an extension of `TestDropUnread`; `spouseLink` split into `spouseLink` + `filedSpouseLink` so `core/kinship` holds no literal number (layer test); AC-1.2/AC-1.4 catalog tests file parents via a `filedParents` helper for deterministic order; AC-2.7 date-edit test adds a date to an undated marriage (a second date on an already-dated event did not change its dating). Implementer's first gate also tripped `promotealign` `TestLargeSourceBudgets/after_a_handle_commit` on timing under load; passed alone and on rerun; unrelated.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers.py; UX matched on `GenealogyStore.swift`, `GoStore.swift`, generated `engine.pb.swift`: model mapping only, no chrome).

UX: clean. SEC+PRF: clean (every crafted axis bounded; the marriage cap sits before the one batched `Nodes` load; `TestCraftedMarriages` 200 marriages within `capBudget`). Its Outside-my-lens note (T-7 landed as a new test) routed to CON and deduped into CON-2.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | `Couples`/`SiblingGroups` re-derive the person's spouses (dedup) and parent ids beside `partnerUnits`/`parentUnits` | Fix now → F-1 | verified: same-pass cleanup; parent-id loop at `families.go:181,378,449`; spouse first-wins dedup in `partnerUnits` (`at` map) and `Couples` (`seen` map) |
| MNT-2 | MNT | major | `Couples` skips self-loop links that load already drops | Fix now → F-2 | verified: `graphcache/load.go:369-372` drops a record-to-itself link; `eventLinks` skips same-person pairs. User ruling 2026-11-14 (self-loop links are crafted: refuse once at load, no reader handles them) supersedes D-5's "A pair is skipped when either end is the person"; recorded in the Landed note |
| MNT-3 | MNT | minor | `FamilyCouple.Marriages` holds pivots after `Families` and read events after `PersonFamily`; `marriageEvents` mutates its argument and returns rows | Fix now → F-3 | minor in a file this PR adds |
| MNT-4 | MNT | minor | Couple indexes: `Group.Couples` vs `Family.UnitCouples` parallel slice | Later PR (S16-81) | D-11 binds the parallel slice here; S16-81 rewrites the units, so its map scope entry now carries the move (commit `dcf9dbab1`) |
| CON-1 | CON | minor | AC-2.8's {Heinrich, Katharina} group clause untested | Fix now → F-4 | verified: fixture has no Heinrich–Katharina child |
| CON-2 (+SEC note) | CON | minor | Landed note omits T-7 landing as `TestCraftedMarriages` | Fix now → F-5 | verified in `caps_test.go` diff |
| MNT-5, MNT-6, MNT-7 | MNT | nit | duplicated `born`/`bornIn`, `parents`/`parentsOf` closures; `ParentSets` loop repeats `indexes` | Fix now → F-6 | same-pass cleanup: this PR adds each second copy |
| MNT-8 | MNT | nit | dead `bytes.Equal(c.B, f.Person)` half in `indexCouples` | Fix now → F-6 | code this PR adds; rides along |

Nits (logged): `CON-3 · core/database/persondetail/family_test.go (TestPersonFamilyGroups merged-parent) · compare the exact line "Anna: Margarethe, Johann" instead of HasSuffix/Contains` (folded into F-6).

Follow-up (not this PR's code): `promotealign` `TestLargeSourceBudgets/after_a_handle_commit` timed out under the gate's parallel load in the implementer's first run. A wall-clock budget that trips under load; ask the user where it goes.

### Fix plan 1

**F-1 — One helper each for the person's parent ids and spouse links** (from MNT-1)
Files: `core/kinship/families.go`. Skill: `add-match-rule` (kinship page functions).
Failing test first: none (refactor; behavior unchanged). Existing `TestSiblingGroups`, `TestCouples`, `TestFamilies*` stay green.
Do: add unexported `parentIDs(person []byte, kin Kin) [][]byte` and `spouseLinks(person []byte, kin Kin) []Link` (distinct by the other end, first link wins) beside `relativeOf`. `parentUnits`, `SiblingGroups` and `Couples` call `parentIDs`; `partnerUnits` and `Couples` call `spouseLinks`. No other copy of either loop stays.
Check: `grep -nE "l\.From\(person\)" core/kinship/families.go` prints only the helpers' lines (and `relativeOf` if it uses it); `grep -nE "seen\[string|at\[string\(r\.ID" core/kinship/families.go` prints at most the `spouseLinks` line; scripts/check-pr.sh PASS.

**F-2 — Drop the self-loop checks in `Couples`** (from MNT-2)
Files: `core/kinship/families.go`.
Do: delete `bytes.Equal(other, person)` in the partner loop and `bytes.Equal(ids[i], person) || bytes.Equal(ids[j], person)` in the parent-pair loop, and the doc sentence "A pair with the person at either end is skipped." Add no test for a self-loop. In the plan's Landed note: "D-5's self-pair skip was dropped: load refuses a link from a record to itself (user ruling 2026-11-14)."
Check: `grep -n "bytes.Equal(.*person)" core/kinship/families.go` shows no check in `Couples`; scripts/check-pr.sh PASS.

**F-3 — One meaning for `FamilyCouple.Marriages`** (from MNT-3)
Files: `core/database/persondetail/family.go`.
Do: `marriageEvents` stops rewriting `family.Couples[i].Marriages`; it returns the loaded events (cap applied before `in.Nodes`, as today). `PersonFamily` builds each couple's final `Marriages` from them once, earliest first, at most `maxMarriagesPerCouple`, which replaces the in-place cap and the `rank`/`rankOf` re-sort. If `Families` must still fill `Marriages` with pivots, the doc says so in one meaning per function; prefer `Families` carrying the pivots under a name that is not `Marriages` only if D-12's `FamilyCouple{A, B, Marriages}` shape stays as written for `PersonFamily`'s output. Do not change the proto or what is sent.
Check: `TestPersonFamilyCouples`, `TestCraftedMarriages`, `TestPersonFamilyQueryCount` pass unchanged; the type's doc states one meaning; scripts/check-pr.sh PASS.

**F-4 — Test AC-2.8's {Heinrich, Katharina} group** (from CON-1)
Files: `core/database/persondetail/family_test.go`.
Failing test first: `TestPersonFamilyCouples/AC-2.8` — add `filedParents(w, w.person("Christian"), 1823, heinrich, kath)` and extend `want` to `{"Heinrich+Anna;Heinrich+Katharina", "Heinrich+Anna", "Heinrich+Katharina"}` (it may pass at once; the code path exists; then say so).
Check: the subtest passes.

**F-5 — Landed note lists T-7 and this round's deviations** (from CON-2)
Files: `docs/deployment-plan/spike-16/prs/S16-82-family-groups-and-marriages-read.md`.
Do: add to the Landed note "T-7 is a new test, `TestCraftedMarriages`, beside `TestCraftedFamily`", F-2's D-5 line, and any F-3 shape change.
Check: scripts/check-pr.sh plan-docs PASS.

**F-6 — Test helper dedupe and the dead half** (from MNT-5, MNT-6, MNT-7, MNT-8, CON-3)
Files: `core/database/persondetail/family_test.go`, `core/kinship/families_test.go`, `api/ffi/handlers/person_detail.go`, `core/database/persondetail/family.go`.
Do: delete the `born` closure in `TestPersonFamilyOriginSiblings` and call `bornIn`; make `parents`/`parentsOf` one file-level helper beside `linkTo`; the `ParentSets` int32 loop uses the `indexes` closure; drop the `bytes.Equal(c.B, f.Person) && …` half in `indexCouples`; the merged-parent subtest compares the exact line `"Anna: Margarethe, Johann"`.
Check: `grep -n "born := func\|parentsOf := func\|parents := func" core/database/persondetail/family_test.go core/kinship/families_test.go` prints nothing; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `7f4a75fcd`. Gate PASS (orchestrator run). F-1 to F-6 done; F-4 passed at once (code path existed). Implementer deviations: `dropUnread` still filters marriages by summary, now redundant since `PersonFamily` builds only read events (kept so `TestDropUnreadGroupsAndCouples` stays); `partnerUnits` local `r` renamed `p`.
CON-1: **Resolved** (`260f1fef8` adds Christian of Heinrich and Katharina; `want` has the three groups). CON-2: **Resolved** (`7f4a75fcd` Landed note names T-7, the D-5 drop and the F-3 shape).

## Round 2 — review
Reviewers: MNT (the only lens with a Fix-now major). Scope `eb4e6987e...7f4a75fcd`.

MNT-1: **Resolved** (`parentIDs`, `spouseLinks` in `families.go`; no other copy). MNT-2: **Resolved** (both checks and the doc sentence gone; no self-loop test). New blockers: none. Verdict clean.
Minors read by the orchestrator: MNT-3 **Partly resolved**: `marriageEvents` no longer mutates, and the re-sort is gone, but the `FamilyCouple.Marriages` doc still gives one meaning for `Families` and one for `PersonFamily` (F-3's fallback clause). F-6: **Resolved**.

Below blocker, noted by the round-2 reviewer (no Fix plan 2: round 2 only fixes blockers), open for the user:
- `dropUnread`'s marriage-by-summary filter (`family.go:425-433`) is now dead after F-3; kept so `TestDropUnreadGroupsAndCouples` stays.
- `families_test.go:674-675`: `parentsOf` sits between `linkTo`'s doc comment and `func linkTo`.
- `FamilyCouple.Marriages` still has two meanings in its doc (MNT-3 remainder).
- `Couples` doc line at `families.go:442` runs long (cosmetic).

## Result
`origin/main` unchanged since `47935695b`; no merge needed. Gate PASS at `7f4a75fcd` · CI pending · open blockers/majors: none · later PR: MNT-4 (S16-81 scope entry) · open minors: the four above · follow-ups: `promotealign` `TestLargeSourceBudgets` wall-clock budget trips under gate load · to user: —

## Cost
Plan: 5,700 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 209k |
| 1 | CON | opus | 82k |
| 1 | MNT | opus | 107k |
| 1 | UX | opus | 43k |
| 1 | SEC+PRF | opus | 66k |
| 1 | implementer fix | sonnet | 98k |
| 2 | MNT | opus | 42k |
| | **Total** | | **647k** |
