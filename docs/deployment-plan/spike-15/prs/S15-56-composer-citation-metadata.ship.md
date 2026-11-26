# Ship log — S15-56 The composer edits a Citation's metadata

**Plan:** [`S15-56-composer-citation-metadata.md`](S15-56-composer-citation-metadata.md) · **Branch:** `s15-56-composer-citation-metadata` · **PR:** #982
**State:** ready

Base: `main` @ `b42ec2c` (plan written against `620ddaa`).

## Round 0 — implement
Head `8f2ae7d66`. Gate PASS (orchestrator run). Report deviations: `citationFixture` skips seed install (project already seeded); registry and place tests updated for D-17/D-8 keys; `pageLabelLoadsSavesAndResets` removed with its input; old names left only in historical plan docs; T-3 empties seeded formats by SQL before deleting `page`; leave summary reads "the citation" when only the sheet changed (no new copy); T-4 builds its own owners; place spec is `.sourceCitationComposer` not `.citationComposer`; sheet subtitle reads `description` (holds the label); `ComposerPresented.metadata` model Equatable by Citation id. Manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF (route-reviewers: all four RUN). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Layout-only sheet save (reorder, dismiss) never reaches the composer's list | Fix now → F-1 | verified: `registry.go` has no `citation_metadata_layout` entry; `metadataEffects` adds no Reads for layout; carries a failing test |
| MNT-1 | MNT | blocker→major | Handler picks the own page itself, a copy of `CitationPages`' selection; page id read outside the boards' tx | Fix now → F-2 (same-pass cleanup) | verified `citations.go:233-264` vs `annotation.go`. Supersedes D-6's "resolves `PageFieldID` once on `c.DB()`" wording; D-6's rationale (same rows, no second `readByOwners`) holds. Rated major: the catalog session is exclusive, so the two-snapshot read cannot diverge in practice |
| UX-1 | UX | major | Typed-but-unconfirmed text is not dirty: sheet closes without asking, Save stays off | Fix now → F-3 | verified `CitationMetadataSheetModel.swift:48-49` uses `host.isChanged`; `MetadataBoardModel.hasUnsavedChanges` exists and the Artifact sheet and graph form use it. AC-1.5 ("a value typed in the sheet … the confirm asks") fails as written; D-9's `isDirty: host.isChanged` wording yields to the AC and its own "as `ArtifactSheetModel.save` does"; recorded in the Landed note |
| UX-2 | UX | major | Save error drawn at the top of a scrolling body, no scroll to it | Fix now → F-3 | verified: model has no `scrollTarget`/`scrollRequest`; `ArtifactSheetModel.scrollToTop` is the precedent |
| MNT-3 | MNT | major | `listedCitationsValue` repeats `listedCitations` | Fix now → F-4 | verified `CitationComposerModel+Metadata.swift:10-16` vs `CitationComposerModel.swift:157-163` |
| MNT-4, CON-4 | MNT, CON | major | `add-workspace-place` line attaches the Source page's parenthetical to the composer | Fix now → F-5 | verified `SKILL.md:175` |
| MNT-2 | MNT | major | Sheet drops the board its write returns and reloads the list instead of patching | Rejected | contradicted by the plan: Precedent ("the write's `citation_boards` read … reloads that list, so no patch is added"), D-5, D-7 (the return shape). The reload is the decided design; CON-1 closes its one gap |
| CON-2 | CON | major | AC-1.3's after-first-save half and D-12's in-flight rule have no test | Fix now → F-6 | verified: `newCitationMetadataLine` never starts a create and never asserts `metadataLineError` |
| UX-3 | UX | minor | AC-1.5 / manual step 6 say Cancel asks; the kit's Cancel closes at once | To user → amend the AC (user, 2026-11-26) | verified `PVSheet.swift:6`, `PVSheetDismiss.swift:3`, DesignSystem README:262. Meeting the AC needs a kit-wide Cancel change; amending it changes an AC |
| UX-5 | UX | minor | A failed list read leaves the line off with no message | Fix now → F-4 | minor in a file this PR adds |
| PRF-1 | PRF | minor | Artifact switch sends a draft-board read whose answer is dropped | Fix now → F-4 | verified order in `selectArtifactAndLoad` |
| UX-4 | UX | minor | VoiceOver reads the count twice | Fix now → F-3 | caption has no `.accessibilityHidden`; confirm in the manual pass |
| CON-3 | CON | minor | T-7 reloads the list itself | Fix now → F-6 | test calls `reloadListedCitations()` before asserting |
| MNT-5 | MNT | minor | `catalog-caches.md` does not name the Citation list's signals | Fix now → F-5 | file untouched by the PR |

Nits (logged): `MNT-6 · CitationComposerContext.swift:89 · key spelled twice (metadataFieldsKey)` · `MNT-7 · sourcevocab/registry_test.go:267 · hand-kept vocabkey list` · `UX-6 · Localizable.xcstrings citationComposer.metadataInheritsNew · "Inherits 0 values" zero form` · `UX-7 · CitationMetadataSheet.swift:677 · "Metadata" label under "Citation metadata" title`

### Fix plan 1

**F-1 — A Citation layout write reloads the composer's list** (from CON-1)
Files: `core/database/effects/registry.go`, `core/database/effects/reads_resolve_test.go`, `core/database/effects/reads_test.go`.
Failing test first: `TestCitationLayoutNamesCitationGraph` — the test in CON-1 (a layout-only `sourcemetadata.Apply` at the Citation level; `set.IDsOf(effects.ReadCitationBoards)` names the graph).
Do: add a `citation_metadata_layout` registry entry with `Reads: []ReadPath{{ReadCitationBoards, up("citation_id", "graph_id")}}`, filled by `metadataEffects` as the values tables are; add `citation_metadata_layout` to `TestReadsDeclare`'s want for `ReadCitationBoards`. Landed note: D-5 gains the layout table.
Check: the test passes; scripts/check-pr.sh PASS.

**F-2 — One `sourcemetadata` entry point decides a listed Citation's printed page** (from MNT-1)
Files: `core/database/sourcemetadata/annotation.go` (and/or `sourcemetadata.go`), `api/ffi/handlers/citations.go`, their tests.
Failing test first: none (refactor); `TestListCitationsByArtifactBoards`, `TestCitationPages`, `TestListCitationsByArtifactScale` stay green.
Do: add one exported `sourcemetadata` function for the list (for example `ListCitationWorkspaces(c, citationIDs) ([]Board, []string, error)`) that resolves `PageFieldID` inside the same transaction as `listWorkspaces` and picks each own page through one private selector that `CitationPages` also uses (own row, field id equals the page field, `PageText` non-empty). The handler only maps to proto and drops its `bytes` import. Landed note: D-6's "resolves `PageFieldID` once on `c.DB()`" is superseded (same-pass cleanup); D-6's same-rows rule holds.
Check: `grep -n "PageFieldID\|bytes.Equal" api/ffi/handlers/citations.go` prints nothing; scripts/check-pr.sh PASS.

**F-3 — The sheet counts typed text as a change and shows its save error** (from UX-1, UX-2, UX-4)
Files: `macos/App/Features/CitationComposer/CitationMetadataSheetModel.swift`, `CitationMetadataSheet.swift`, `CitationComposerModel+Metadata.swift`, `CitationComposerEvidenceColumn.swift`, `macos/ProvenenciaTests/CitationComposerModelTests.swift`.
Failing test first: `metadataSheetUnconfirmedInput` (new) — a value typed into a board row and not confirmed (`board.setTyped`) → sheet `isDirty` true, `canSave` true, `metadataSheetIsChanged` true; `save()` sets `saveError` to `board.unconfirmedInputMessage` and bumps `scrollRequest` with `scrollTarget == .top`.
Do: `isDirty` = `board.hasUnsavedChanges`; `canSave` = `board.hasUnsavedChanges && !isSaving`; `metadataSheetIsChanged` reads `board.hasUnsavedChanges`. Add `scrollTarget`/`scrollRequest` and a `scrollToTop()` wherever `saveError` is set, pass both to `pvFormDialog`, `.id` the form's top — copy `ArtifactSheetModel`/`ArtifactSheet`. Add `.accessibilityHidden(true)` to the count caption while the button carries it as a hint. Landed note: D-9's `isDirty`/`confirmDisabled` read `board.hasUnsavedChanges` (AC-1.5).
Check: the test passes; scripts/check-pr.sh PASS.

**F-4 — One cached-list accessor; the line reports a failed list; no dropped draft read** (from MNT-3, UX-5, PRF-1)
Files: `CitationComposerModel.swift`, `CitationComposerModel+Metadata.swift`, tests.
Failing test first: `metadataLineListFailure` (new) — FakeStore's `listCitationsByArtifact` throws → `metadataLineError` is `L10n.Errors.message(for:)` of that error. And in `selectArtifactSkipsDraftReadWhenACitationOpens` (new), switching to an Artifact with Citations makes no `getDraftMetadataBoard` call (count the FakeStore's calls).
Do: keep one optional accessor (`listedCitationsValue`); `listedCitations` = `listedCitationsValue ?? []`; `metadataRows` = `listedCitation(id)?.metadata` gated on the list being loaded. `metadataLineError` reads the list handle's `failure` when it has no value. In `selectArtifactAndLoad`, call `refreshDraftMetadata()` only when no first Citation opens (the `else` of `if let first = ordered.first`).
Check: the tests pass; scripts/check-pr.sh PASS.

**F-5 — Docs: the skill line and the cache table** (from MNT-4, CON-4, MNT-5)
Files: `.agents/skills/add-workspace-place/SKILL.md:175`, `docs/catalog-caches.md:53`.
Do: move the parenthetical back after `applySavedMetadata(_:owner:effects:)` and put the composer sentence after it as its own clause. In the Swift caches "Updated by" cell add: the composer's Citation lists revalidate on `citation_boards` (values and layout, from F-1) and go stale on `CatalogMutationKind.boardVocabulary`.
Check: scripts/check-pr.sh PASS.

**F-6 — Tests prove the after-save line and the write's own reload** (from CON-2, CON-3)
Files: `macos/ProvenenciaTests/CitationComposerModelTests.swift`, FakeStore if a gate is needed.
Failing test first: `newCitationLineAfterFirstSave` (CON-2's sketch) — after `fields.saveCitation()` on a new Citation, `metadataLineError == nil`, the count reads `metadataCountInherited(4)`, `canEditMetadata` true; and with `createCitationWithObservations` gated, `metadataLineError == nil` and the button off while it is in flight. Delete the `|| context.isCreatingCitation` guard locally to see the in-flight assertion go red, then restore it.
Do: in `metadataSheetSavesOnItsOwn`, replace the explicit `reloadListedCitations()` with settling the write (`session.settleWrites()` or the composer's equivalent) so the count follows the write's own `citation_boards` read.
Check: the tests pass; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `5a00542b8` (implementer), then `d0adc2c14` (orchestrator: AC-1.5 and manual step 6 amended per the user's UX-3 answer, Landed note updated). Gate PASS at `d0adc2c14`. F-1 – F-6 done, each with its failing test red first. Deviations: FakeStore gained `listCitationsByArtifactError`, `createCitationHold`, `listCitationsHold`, and seeds a created Citation's board from `draftMetadataBoardEntries`; `metadataLineListFailure` covers a first-load failure only (a failed refetch keeps the cached value); a `showComposerPlace` test helper puts the composer place on screen so the list reloads on write.
PRF-1 (minor): Resolved — read `selectArtifactAndLoad`; `refreshDraftMetadata()` now runs only in the `else` of `if let first`.

## Round 2 — review
Reviewers: CON, MNT, UX (each had a Fix-now blocker or major). Not sent: SEC+PRF (minor only). Scope `8f2ae7d66...d0adc2c14`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1, CON-2, CON-4 | CON | — | Round-1 items | Resolved | `TestCitationLayoutNamesCitationGraph`, `TestReadsDeclare`, `newCitationLineAfterFirstSave`; SKILL.md:175 |
| MNT-1, MNT-3, MNT-4 | MNT | — | Round-1 items | Resolved | `ListCitationWorkspaces` + shared `ownPage`; one list accessor chain; SKILL.md:175 |
| UX-1, UX-2 | UX | — | Round-1 items | Resolved | `board.hasUnsavedChanges`; `scrollTarget`/`scrollRequest` passed to `pvFormDialog` |
| CON-5 | CON | minor | F-4: a failed first-Citation load on an Artifact switch leaves a blank Citation with no draft-board read (count missing or the previous Artifact's) | To user → Fix now → F-7 (user, 2026-11-26) | below the round-2 bar; one-line fix; the user asked for it on this PR |

Nits (logged): `MNT-8 · sourcemetadata.go:821-848 · ListCitationWorkspaces repeats ListWorkspaces' open-tx wrapper`

No new blockers; no Fix plan 2. Merged `origin/main` (`0a5784aa6`, docs only) at `e63dec33e`; gate PASS.

### Fix plan 2
Not a round-2 blocker: the user asked for CON-5 on this PR (2026-11-26). No re-review; the orchestrator reads the fix.

**F-7 — A failed first-Citation load on an Artifact switch still reads the draft board** (from CON-5)
Files: `macos/App/Features/CitationComposer/CitationComposerModel.swift` (`selectArtifactAndLoad`), `macos/ProvenenciaTests/CitationComposerModelTests.swift`, FakeStore if it needs a per-id `getCitation` error.
Failing test first: `selectArtifactDraftReadAfterFailedLoad` (new) — switch to an Artifact whose listed first Citation's `loadCitation` throws (FakeStore `getCitation` error for that id, graph handle without a value so the load reaches the store) → `activeCitationID == nil`, `citationLoadError != nil`, one `getDraftMetadataBoard` call for the new Artifact, and `metadataCount` reads that Artifact's draft board (not the previous Artifact's).
Do: in `selectArtifactAndLoad`, when `showingLoadFailure(...)` returns nil, call `refreshDraftMetadata()` as the `else` branch does, e.g. `if await showingLoadFailure(...) == nil { refreshDraftMetadata() }`. Add a clause to the plan's Landed note.
Check: the test fails before the change and passes after; scripts/check-pr.sh PASS.

## Round 2 — fix
Head `7ce5a4ed0`. Gate PASS (orchestrator run). F-7 done: `selectArtifactDraftReadAfterFailedLoad` red first, green after; FakeStore gained `getCitationErrorsByID`. CON-5: Resolved — read `selectArtifactAndLoad`: a nil `showingLoadFailure` now calls `refreshDraftMetadata()`.

## Result
Gate PASS · CI pending · open: none blocker/major · follow-ups: — · to user: CON-5 → fixed (F-7)

## Cost
Plan: 6,425 words (check-plan-docs info line).

| Round | Agent | Model | Tokens |
| --- | --- | --- | --- |
| 0 | implementer | sonnet | 439k |
| 1 | CON | opus | 130k |
| 1 | MNT | opus | 109k |
| 1 | UX | opus | 101k |
| 1 | SEC+PRF | opus | 63k |
| 1 | implementer | sonnet | 176k |
| 2 | CON | opus | 59k |
| 2 | MNT | opus | 51k |
| 2 | UX | opus | 32k |
| 2 | implementer | sonnet | 98k |
| | **Total** | | **1,258k** |
