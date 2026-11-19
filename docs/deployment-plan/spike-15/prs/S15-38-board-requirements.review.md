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

## Verdict

Round 1 answered: every blocker Fixed. Round 2 pending (round 1 had blockers).
