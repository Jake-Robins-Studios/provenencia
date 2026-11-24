# Review — S16-71 The Sources list is a native table

**Verdict:** Fits with changes — Ready with changes
**Rounds:** 2. **Reviewers:** maintainability (Opus), executability (Sonnet)

## To user
- Answered 2026-11-24: column widths are fixed per width class (the brief had draggable edges); every outlined badge takes the on-selection ink on a selected row (M-3).

## Writer's own calls
- A first press on a Source, then a second on the row that moved under it, opens the first (D-15); the fallback waits out the double-click time.
- Added sorts by id, as today; its words come from the create audit transaction.
- An old stored sort reads as Added, newest first.
- The skeletons are rows of the same table (D-8).
- `PVListBody` folds back into `PVList`.
- The table's 150 ms second scroll is shared with the lists.

## Round 1

| ID | Severity | Title | Answer |
| --- | --- | --- | --- |
| M-1, X-1 | blocker | `created_at` misses new and copied Sources, and unrelated reads pay | Fixed — D-1: `fillListed` and `enrichSourceProto`; T-2 covers create and copy |
| M-2 | blocker | A second way to read "when this was created" | Fixed — D-1: `audit.Created`; the note reads move onto it |
| M-3 | blocker | The badge ink changes Persons rows | To user — answered: every outlined badge; D-17, Rules bent, §10, §11 |
| M-4 | major | Sort and comparator are one value twice | Fixed — D-2, D-4 |
| M-5 | major | One-caller Bool with a sleep | Fixed — D-10: one request path, a named constant, no parameter |
| M-6 | major | Third event helper and a double optional | Fixed — D-14 `SourcesOutlineAction`, D-15 `SourcesPointer` |
| M-7 | major | Deletes and callers incomplete | Fixed — Deletes, D-2 (`updatedOrder`), D-11, STEP-9, STEP-10 |
| M-8 | minor | `showsIcon` not needed | Fixed — D-16 `PVListDetail.relative` |
| M-9 | minor | Platform numbers scattered | Fixed — D-6 |
| M-10 | minor | Badge keeps its own micro-caps numbers | Fixed — D-5; the nine other sites logged in STEP-10 |
| M-11 | nit | D-19 not a decision | Folded into D-8 |
| X-2 | major | `FakeStore` has no clock | Fixed — STEP-1 `createdAtStamp` |
| X-3 | major | Tie orders | Fixed — D-2, T-3 |
| X-4 | major | `onActivate` and `menu` signatures | Fixed — D-10 |
| X-5 | major | STEP-3 breaks the old list's slot | Fixed — `minWidth` is used from STEP-7 |
| X-6 | major | Three L10n keys with no step | Fixed — STEP-5; `addedUnknown` in D-18 |
| X-7 | major | No way to render previews | Fixed — STEP-7; the test command heads §7 |
| X-8 | major | Header ink cannot be read | Fixed — T-12 reads `headerCell.attributedStringValue` |
| X-9 | minor | Where the `GeometryReader` sits | Fixed — D-6 |
| X-10 | minor | Separator code before S16-66 | Fixed — D-11 |
| X-11 | minor | Private types, derived `extra` | Fixed — STEP-6, STEP-7 |
| X-12 | minor | No benchmark | Fixed — Scale `BenchmarkList` |
| X-13 | minor | Smaller choices | Fixed — D-2, D-8, D-15, D-16 |

## Round 2
Every round-1 blocker and major resolved.

| ID | Severity | Title | Answer |
| --- | --- | --- | --- |
| M-12, X-14 | blocker | STEP-4 conforms `SourcesSort` to a type STEP-7 adds | Fixed — the conformance is an extension in `SourcesTable.swift`, STEP-7 (D-2, D-4) |
| — | minor | STEP-5 omits `SourcesOutlineRows.swift` | Fixed |
| — | minor | `audit.Created`'s map key | Fixed — D-1 |
