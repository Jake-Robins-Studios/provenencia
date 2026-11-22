# Review — S15-25 Move from an Artifact or a graph

**Plan:** [`S15-25-move-from-artifact-or-graph.md`](S15-25-move-from-artifact-or-graph.md) · **Brief:** [S15-D10](../design/S15-D10-move-confirm.md)
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet), fresh context, read-only.
**Verdict, round 1:** maintainability **Reshape**; executability **Not ready**. Every finding answered below. Three went to the user, who answered them on 2026-11-21.
**Round 2:** run after the board was agreed (2026-11-22); verdicts Fits with changes / Ready with changes; every finding answered below.

## Round 1 — executability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | blocker | STEP-9 archives S15-D1 and S15-D14 without handling the ~18 links into them, the D14 review log, or the README cells | **Fixed** — STEP-11 (was STEP-9): `git mv` of the three briefs and S15-D14's review log; rewrite every inbound link (`rg` command given); `check-plan-docs.py`'s `multi_pr_ok` matches by file name, so it needs no change; README Archived cells say what goes in each; the check now lints every plan and brief in the spike |
| X-2 | blocker | Plan (reply order) and brief MV-5 (seed first) disagree on bundle row order; `progress` indexed by position | **Fixed** — D-13: `bundleArtifacts` / `bundleGraphs` put the seed first, then the reply's order; progress matched by `graphId`. AC-2.1b, T-5 |
| X-3 | blocker | D-6 leaves a failed pick read, Read again's target, a cleared pick, a pick before the first reply, and a repeated pick open | **Fixed** — D-6 states each case; AC-3.5; T-10 extended |
| X-4 | major | `FakeStore.moveToSource` does not say how the fake's rows move; missing impact key behaviour | **Fixed** — D-4: re-buckets `artifactsBySource`, sets graphs' `sourceID`, `preconditionFailure` on a missing script, defaults for an absent target |
| X-5 | major | STEP-1 and STEP-2 disagree on who creates the test file; GoStore mapping untested | **Fixed** — the store step creates the file; GoStore gets no Swift test, as its precedent `getEvidenceGraphUnlinkImpact`; the manual check runs it |
| X-6 | major | ACs without a test (graph seed, card `isEnabled`, navigation, unread list, short `progress`) | **Fixed** — T-14 (graph seed), T-5 (short progress), T-7 (unread list), T-11/T-13 (`leave` called or not). The graph card's `isEnabled` helper and its T-3 were dropped when the board replaced the menu with buttons (2026-11-22); AC-1.1 – AC-1.4 are manual check step 2 |
| X-7 | major | Dialog details left open (spacing, ComboBox parameters, Callout ids, plural layout, unused keys) | **Fixed** — D-14 and D-13 name every call, parameter and identifier; D-12 names the plural layout precedent |
| X-8 | major | "Open" vs "Open evidence graph"; brief frame 1 contradicts itself; frame 6 data; no Wide menu frames | **Fixed** — "Open" in both (the card button's own key); frames 1a/1b and 2a/2b; frame 6 has its own Source |
| X-9 | major | Target not in the list at move time; apply order; `openMove` with no Source; history check | **Fixed** — `target` kept at the pick (D-6, D-8); `apply(_:leavingPage:)` (D-8); `openMove` guards `source` (D-5); history fixed by D-17 |
| X-10 | minor | `isEnabled` helper unnamed; stale doc comment; `(0,0)`; "never by `== 1`" wording; STEP-5 check; commit subjects | **Fixed** — the `isEnabled` helper went with the menu (board, 2026-11-22); doc comment in Deletes; `(0,0)` stated; wording; manual check; one subject per step |

## Round 1 — maintainability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | D-6 hand-rolls a reply sequence number beside `LatestCall`, against `docs/macos-client-patterns.md` | **Fixed** — D-6 reads through `LatestCall`; `settleReads()` for tests; FakeHold's oldest-first release is enough because `LatestCall` drops a superseded reply whenever it lands |
| M-2 | blocker | D-8 names both Sources' cache updates by hand, against the working rule "A move is the whole bundle" | **To user → answered (2026-11-21).** The writer offered: name both by hand (a rule bend), or have the page follow `source_records` (a reload after every Source edit). The user asked for a correct design that keeps patch-first performance. Writer's proposal, accepted and folded into S15-25: a narrow engine read `source_artifacts`, reported only when an Artifact joins or leaves a Source, which `.sourceWorkspace` follows; Artifact create and delete lose their hand-written reloads. D-15, D-16, D-8, US-5, T-0, T-15. **Rules this plan bends:** none |
| M-3 | blocker | D-11 copies the engine's "not assessed weighs as Standard" rule into Swift | **To user → answered (2026-11-21): the engine sends it.** D-11: three label fields on the preflight reply (`source_credibility_label`, `target_credibility_label`, `weighed_as_label`); Swift drops the grades lookup. T-0b, T-9 |
| M-4 | major | D-8 relies on update order to leave the page; `apply(_:_:leavingPage:)` exists | **Fixed** — D-8 `move(leavingPage:)` |
| M-5 | major | D-10's `targets` re-sorts 3,000 Sources outside the derived cache | **Fixed** — `DerivedValueID.sourcesByUpdated`; `.sourcesOfType` filters from it |
| M-6 | major | A canvas history entry keeps the old `sourceId` after a move | **To user → answered (2026-11-21): fix in this PR.** D-17: `WorkspaceLocation.correctingGraphSource(_:)` and `replaceCurrent(with:)` from the destination host for the canvas, composer and Promote. US-6, T-16 |
| M-7 | minor | Brief MV-5 hedges the caption style | **Fixed** — the brief names the kit SubsectionHeader only |
| M-8 | minor | Booleans and optionals in the model instead of a phase enum | **Declined** — with `LatestCall` the model holds `readState` (the kit's `PVFormLoadState`, what the load area draws), `impact`, `impactTarget` and two flags. `canMove` combines facts the view reads separately, and no state the plan names is impossible: `.ready` with `impact == nil` cannot arise because only a reply sets `.ready` |
| M-9 | nit | Brief § 1 says "between Edit… and Delete…" | **Fixed** — "just before Delete…" |
| M-10 | nit | 560 vs Copy Source's 520 | **Fixed** — 520, as Copy Source |

## To user (all answered)

- M-2: the cache design above (2026-11-21: fold the `source_artifacts` read into S15-25).
- M-3: the engine sends the grade labels (2026-11-21).
- M-6: fix the history entry in this PR (2026-11-21).

## Board (2026-11-22)

The user agreed the board with one change from the brief: no right-click menus; Move is a visible folder-input IconButton on Artifact rows and graph cards, and the Artifact row's existing menu goes. The plan's D-1, D-2, Deletes, STEP-6, STEP-7, T-2, T-3 and the brief's MV-1, MV-2 now say so. One board detail is not taken: the bundle's graph rows reuse the graph card's count line ("subjects · observations"), not the board's "people · citations" (D-13), so the dialog and the card read alike.

## Round 2 — executability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X2-1 | major | `reads_test.go:47` asserts one read on `artifacts`; `Reads` order unstated | **Fixed** — D-15 names the `want` entry, the line-47 change and the position before `ReadSourceRecords`; `registry_completeness_test.go` needs nothing |
| X2-2 | major | STEP-6 and STEP-11 `rg` checks cannot pass (plan history hits; multi-line declarations; catalog keys) | **Fixed** — scoped to `macos`, `.agents`, `docs/*.md`; `rg verbatimTitle` over the ContextMenu folder and README; the catalog checked by key; the doc comments named |
| X2-3 | major | No named test file for T-16; host wiring untested; where the modifier attaches | **Fixed** — `WorkspaceNavigationTests.swift`; one `.onChange` on the host's body; AC-6.1 and AC-6.2 host wiring by manual check step 5 |
| X2-4 | major | T-2 would drop the two width assertions | **Fixed** — delete the five lines, keep the widths, rename the test |
| X2-5 | major | Log X-6 and X-10 named `GraphCardAction.isEnabled`, which the board removed | **Fixed** — log corrected; AC-1.1 – AC-1.4 manual; T-2 and T-3 no longer overlap |
| X2-6 | minor | Stale "Frames in words" / "Blocked" text; brief's enhancement paragraph; manual step order | **Fixed** |
| X2-7 | minor | Open choices: the fallback glyph's drawing, `showsWhy`, how `.sourcesOfType` derives, `followsOwnId`'s type, a flash after D-17 | **Fixed** — each stated in D-2, D-13, D-10 or § 11; `followsOwnId` takes a `CatalogQueryFollows`, which `.reads(.sourceArtifacts)` is (`CatalogLastUpdated.swift:359`) |
| X2-8 | nit | STEP-4 is large; count-line wording | Logged; the count line is D-13's |

## Round 2 — maintainability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M2-1 | blocker | The Sources list rows stop following Artifact create and delete once `refreshCoverFromStore` goes, and never follow a move | **Fixed** — D-16 (b): `.sourcesList` follows the read with a per-id merged re-read (`.evidenceGraphsList`'s shape); `ListSources` gains `source_ids`, `sources.ListByIDs`; AC-5.3 – AC-5.5, T-0c, T-17 |
| M2-2 | blocker | The read misses graphs, which the workspace also holds; the fake reported it where the engine would not | **Fixed** — renamed `source_holdings`, also on `evidence_graphs` (D-15); the fake's move effects are scripted per test (D-4). Cost stated: a graph create or delete reloads the visible page once |
| M2-3 | blocker | `replaceCurrent` does not remount the place, so the canvas keeps the old Source | **Fixed** — D-17: `sourceId` joins the three places' identities in `PlaceRegistry`, `CitationComposerEntry.identityKey`, `PromoteEntry.identityKey`; T-16 asserts it |
| M2-4 | blocker | Hand re-reads after an ingest beside the declared reload | **Fixed** in part — the read also fires on an Artifact's `file_id` change; `refreshCoverFromStore` and its three calls go. **Declined** in part: the create's and attach's in-place patch through `SourceArtifactsSection.show` stays. It draws the reply's own row at once and is what `docs/macos-client-patterns.md` rule 2 asks of a write (patch the moved rows, then the declared refreshes follow); removing it would make the new row wait for the reload |
| M2-5 | nit | Brief Kind line says "menu items" | **Fixed** |
| M2-6 | nit | Grades unique on (key, origin) | **Fixed** — D-11 reads each Source's label through its assessment's grade id, and the default by `Lookup(DefaultKey, provenencia)`; T-0b row |

**Stop.** Round 2 was the last round (`review-plan`: two rounds, then the user). No blocker is open: each was Fixed, M2-4's remaining part Declined with the rule that sets it. The fixes add scope the user has not seen: the Sources list re-reads changed rows by id (a `ListSources` id filter), and a graph create or delete now reloads the visible Source page. Both are reported to the user with the plan.
