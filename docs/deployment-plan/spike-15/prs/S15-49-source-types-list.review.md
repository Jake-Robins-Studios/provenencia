# Review — S15-49 The Source types list is redesigned

Plan: [`S15-49-source-types-list.md`](S15-49-source-types-list.md). Brief: [`../design/archive/S15-D28-source-types-list.md`](../design/archive/S15-D28-source-types-list.md). Both reviewed together.

## Round 1 — 2026-11-15

Lint: `python3 scripts/check-plan-docs.py` on both, 0 errors (after adding AC-2.6 to the manual check).

**Maintainability** (fresh, strongest model) — verdict **Fits with changes**. No blocker.

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | major | The Used by cell and its sort would be copies of Associated fields' | **Fixed** — D-2 `countCell(_:)` and D-6 `compareCount(_:_:by:)`, both private, shared by the two count columns; Codebase fit rows; brief inventory "share one count cell" |
| M-2 | minor | Name the concept `usedBy` (the row field, the header), not `usage` (the page's sentence) | **Fixed** — `SortColumn.usedBy`, id `"usedBy"`, `usedByColumnWidth`, `L10n.SourceTypes.columnUsedBy` (`sourceTypes.list.columnUsedBy`) |
| M-3 | minor | `.sourceTypesList` reloads on Source writes while `.metadataFieldsList` follows a reported usage read: two freshness mechanisms for one kind of count | **Logged** — an Out row, not planned: about 30 rows reload; this PR adds no reload |
| M-4 | nit | Column ids come from `SortColumn` and one pane constant | **Logged** — D-1 adds the doc comment the reviewer suggested |

**Executability** (fresh) — verdict **Not ready** (the board) / otherwise Ready with changes.

| ID | Sev | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | blocker | The plan is blocked on an undrawn board | **To user** — expected: status stays `Blocked — on board S15-D28`; the board is the user's to draw and agree. "Planned:" in the header is the planning date and base, as every plan's |
| X-2 | blocker | `xcodebuild` and `check-pr.sh` cannot run on the review box | **Declined** — the implementer works on a Mac (every Swift plan in this spike); § 8 now says which checks need Xcode and which run anywhere |
| X-3 | major | T-2 reads members the plan left `private` | **Fixed** — D-1: `columns(_:)`, `usedByColumnWidth`, `descriptionColumnID` are internal |
| X-4 | major | STEP-2's `rg` sweep matches this plan | **Fixed** — scoped to `macos .agents .cursor docs/*.md`; xcstrings ordering stated |
| X-5 | major | The handle-nil spinner in `SourceTypesView.body` is outside the band | **Fixed** — D-4 says it stays outside: a centered spinner filling the pane sits in the same place banded or not |
| X-6 | major | STEP-4 file list lacks full paths, `design/README.md` and the archive move | **Fixed** — STEP-4 lists each path, the `git mv` and the README row |
| X-7 | minor | Cell styling and identifiers left open | **Fixed** — D-2 (one count cell; header identifier from `PVTable`) |
| X-8 | minor | Duplicate label and count order | **Fixed** — Edges says `sorted(by:)` decides, as for Fields today, untested |
| X-9 | minor | Version bump | No change needed |
| B-1 | major | Brief: loading and failed states not drawn | **Fixed** — TL-4 says only the empty project is drawn; the other two keep today's look |
| B-2 | minor | Brief: Label and Description competing at Wide not in the data | **Fixed** — frame 1a / 1b includes Grave memorial with its plugin pill and a long description |
| B-3 | minor | Brief: count cells name no kit type | **Fixed** — inventory names `PVFont.mono`, `PVTypeScale.micro` |

No round 2: round 1 raised no blocker on the plan's shape (X-1 is the board gate, X-2 the environment).

## Verdict

Fits with changes; Ready with changes. X-1 answered 2026-11-15: the user gave the board ([section 01 of the S2-03 Source Types Board](https://claude.ai/artifact/R94Wfp97eC9cBLaSNBQEga)). Checked against its frames and its *Source Types List* component: D-1 – D-4 hold as written (same ids, widths, count cell, band, Description unsortable and flexible at 562pt); D-3 gains the description's hover tooltip, the board's one addition. Status Planned.
