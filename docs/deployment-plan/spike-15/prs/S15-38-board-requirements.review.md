# Review — S15-38 Boards carry their citation's requirements

Plan: [`S15-38-board-requirements.md`](S15-38-board-requirements.md)

## Before the reviewers (user, 2026-11-19)

Three product calls asked while planning, each answered with the recommendation:

1. The seeded census format puts `{artifact.meta.url}` in a group, so it is used; no seeded Artifact or graph field is needed. **Fix the Check**: bar 4, S15-38's and S15-39's Checks name a Source field (census Jurisdiction). The seed stays.
2. A chain's later options are used and appear on a board only where suggested or valued; only a chain's first option is emitted unsuggested.
3. A dismissed used field stays hidden; only needed fields refuse dismissal.

## Round 1

Maintainability (opus): **Fits with changes**. Executability (sonnet): **Ready with changes**.

### M-1 · blocker · `boardResolver` is a second catalog resolver beside S15-16's
**Answer:** Fixed. D-4: `sourcemetadata.CitationValue(Row, Field)` and `sources.CitationDate(Source)` are exported, the one mapping from a stored value to `citationformat.Value`; the board's `ownerValues` uses them. S15-16's map scope now starts from them.

### M-2 · blocker · `SourceRequirements` is a second path with its own read
**Answer:** Fixed. D-9: the `source`-level needs keep the chains headed by `source.date` and `citation.page`; `ListWorkspaces` returns `[]Board` whose Source board carries `Date` and `Page` from the same pass. `GetSourceWorkspace` reads them from its boards. `SourceRequirements` is gone.

### M-3 · major · Parsing stored formats in a second package
**Answer:** Fixed. D-13: `sourcetypes.Formats.Parse` and `sourcetypes.RequirementsTx`; `viewTx` calls `Parse`. T-10.

### M-4 · minor · Title and type resolver branches are unreachable
**Answer:** Fixed. D-4: always-set built-ins answer zero (their chains are used and never reach `Missing`); D-14 reads the Source for its date and mark only.

### M-5 · minor · `Requirement` names two concepts
**Answer:** Fixed. D-1: `sourcemetadata.Annotation`; the file is `annotation.go`.

### M-6 · minor · `typeRequirements` unused, `fieldOrder` undefined
**Answer:** Fixed. Both gone; `levelNeeds` (D-2) holds needs, emission order and headed chains.

### M-7 · minor · Split per-(type, level) needs from per-owner answers
**Answer:** Fixed. D-2 `needsAt` (pure, cached beside `suggested`), D-3 `annotate` per owner; `DismissSuggestion` uses `needsAt` only (D-8).

### M-8 · minor · Doc comments this PR makes false
**Answer:** Fixed. STEP-4 rewrites `ListWorkspace`, `ListWorkspaces`, `WorkspaceEntry`; STEP-5 `DismissSuggestion`; STEP-8 rewrites the § 5.4 Dismiss bullet.

### M-9 · minor · T-9's query counter does not fit · and X-2 · major · T-9 cannot count queries
**Answer:** Declined the counter in this PR, with evidence: `listWorkspaces` and `StoredFormatsTx` take `*sql.Tx`, and the repo's two counters are private (`core/database/effects/path_test.go` `countingQuerier`, `graphcache.Graph.SetQueryCounterForTest`). Choosing a shared mechanism (driver `ConnectHook` or a test hook) is a decision S15-16's Check ("a fixed number of queries") needs first; it is an Out line with S15-16 as home. T-9 now checks correctness at Scale; the one format read is held by D-13's structure (one `RequirementsTx` call per `listWorkspaces`).

### X-1 · blocker · Swift draws no unsuggested empty entry; manual check false
**Answer:** Fixed. Verified at `MetadataBoardModel.swift` `saved` / `suggested` / `moveSaved`. §4 gains a Swift board row, Reach says the entry is undrawn and dropped from the client copy by a reorder (no write sends it), the Brief line says so, and §10 checks only that the pages work as before. D-12 (no Swift change) stands.

### X-3 · major · The need for one owner in `DismissSuggestion` is unnamed; order unclear
**Answer:** Fixed. D-8 names `needOfTx` and the order (after `getPairTx`, before the layout read).

### X-4 · major · Fixtures for the custom type and a dangling id
**Answer:** Fixed. §8 "Fixtures": the line-number type through `sourcetypes.Create`, `AppendSuggestion`, `UpdateFormats`; the dangling id through one raw `UPDATE source_types`.

### X-5 · major · `testWorld` collides with `sourcevocabtest.Install`
**Answer:** Fixed. `seededWorld(t)` *(new)* without `seedBirthCertificate`; handler tests use `seededSourceOfType`.

### X-6 · minor · Shapes left open
**Answer:** Fixed. D-3 builds the tail needed and a one-option chain is not met; D-4 sets `Mark` and `UnknownText` and a key-named target answers zero; D-14 deduplicates Source owners and builds boards only for requested owners; D-15 names the fields loaded; D-10 allows `artifact` and `graph` only; a built-in as a later option is answered (T-2); the `(new)` markers are fixed.

### X-7 · minor · Wording
**Answer:** Fixed. AC-4.2 names `{citation.page|source.meta.page_range}`; seeded labels are "Line" and "Pages"; D-4 no longer answers `source.type`.

## Round 2

Fresh reviewers with the log. Maintainability (opus): **Fits with changes**, every round-1 answer holds (M-3 only half: see M-11). Executability (sonnet): **Not ready** on X-8 alone, Ready with changes once X-8 to X-11 are fixed; every round-1 answer verified.

### M-10 · blocker · Board rules change without the draft-board parity file
**Answer:** Fixed. Verified: `.cursor/rules/macos-client.mdc` names `draft_board_scenarios.json` as the record of the rules `MetadataDraftHost` mirrors, and `TestDraftBoardScenarios` runs on a format-less type. D-17: the file marks `document_number` needed (no existing scenario dismisses it empty), one new scenario pins the refused dismiss under a new `needed` divergence that `MetadataDraftHostParityTests.compared` skips; S15-39's map scope removes the skip. STEP-5, T-14, header and §4 updated.

### M-11 · blocker · `Formats.Parse` beside `ToStored`'s own loop
**Answer:** Fixed. Verified `ToStored`'s loop at `core/database/sourcetypes/formats.go`. D-13: `Parse` skips forms blank after `TrimSpace`; `ToStored` and `viewTx` both call it. STEP-1 files and check updated; Deletes names both loops.

### M-12 · blocker · `CitationRequirementOption` copies part of `MetadataField`
**Answer:** Fixed. D-16: `CitationRequirementOption { string level = 1; MetadataField field = 2; string builtin = 3; }` through `metadataFieldProto`.

### X-8 · blocker · `ListWorkspaces`' new return breaks `TestListWorkspacesExported`
**Answer:** Fixed. STEP-4 names the edit (`got[i].Entries`) as the one existing core test edit allowed.

### X-9 · major · Draft board error codes
**Answer:** Fixed. AC-3.3 and T-12 split `request.invalid_id` (malformed) from `sourcemetadata.invalid` (no Source, bad level).

### X-10 · major · `sources` imports `citationformat` transitively
**Answer:** Fixed. §4 Source row corrected; the stop condition is now any import cycle reported by `go build ./...`.

### X-11 · major · T-8's counts undefined
**Answer:** Fixed. T-8 states each count as a sum over types with its predicate and names the per-type table.

### X-12 · major · Proto and Xcode checks need macOS tooling
**Answer:** Fixed. §7 Toolchain line: run every Go check, report each skipped command by name; CI runs them. The Implementer block stays verbatim, as the template requires.

### X-13 · minor · Shapes left open
**Answer:** Fixed. D-2 names `builtinHeads` keyed by `Target` (page at `citation` level); D-10 names how the draft read gets type, rows and `ErrNotFound` → `ErrInvalid`; D-14 keeps the added Source owners out of extras, layout and output; D-13 says `viewTx` keeps its `Forms()` loop for `with`; T-13 names a `CreateSourceType` type for "no formats"; D-15 says a valued field answers whether or not its row loaded.

## Verdict

Two rounds run, the cap. Every blocker from both rounds is Fixed; no finding is open and nothing is To user. The round-2 fixes are the writer's and were not re-reviewed (the loop stops at two rounds). **Planned.**
