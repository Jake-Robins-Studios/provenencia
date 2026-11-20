# Ship log — S15-16 Citations render through their type's formats

**Plan:** [`S15-16-citations-render.md`](S15-16-citations-render.md) · **Branch:** `s15-16-citations-render` · **PR:** #914
**State:** fixing (user request)

## Round 0 — implement
Head `07676275d`. Gate PASS (orchestrator run, against `1f927d4b5`). Report: no deviations from Decisions, Scope or Out; test worlds built in `render_test.go` through the plan's writes, two crafted cases use `PRAGMA foreign_keys=OFF`.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. UX routed on `macos/App/Platform/CitationFormatVocabulary.swift` and `CitationForm.swift` (parity enums, no chrome); SEC+PRF on `api/ffi/**`, `core/database/**`, and stored formats loaded from the catalog.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Plan has no Landed note though code differs (T-9 chain keys, D-3 `List` scan, `labelTypes`, `TestRenderCensus`) | Fix now → F-1 | verified: plan diff changes only the Status line; DoD requires the note |
| MNT-1 | MNT | major | `citationrender.fillValues` groups metadata rows by owner its own way (`ownerKey`, `seen`) beside the board's `Owner.key()` + `rowsByField` | Fix now → F-2 | verified: `load.go:109-160` vs `sourcemetadata.go:1015-1021`; D-11's one resolver needs one grouping |
| MNT-2 | MNT | major | Alias-prefixed column list hand-written in three packages; no skill line | Fix now → F-3 (same-pass cleanup) | verified: `citations.go:103`, `sourcetypes.go:52` (new), `metadatafields.go:480`; supersedes D-3's "shaped like `metadatafields.Columns`" per-package copies |
| CON-2 / MNT-3 / SEC note | CON, MNT | minor | `sources.GetManyTx` inserted between `getOne` and its doc comment | Fix now → F-4 | verified: `sources.go:671-675` |
| MNT-4 | MNT | minor | Built-in targets spelled as string literals in `citationrender` and `sourcemetadata` | Fix now → F-5 | minor in code this PR adds/changes |
| MNT-5 | MNT | minor | "citation options" parity row lists Go options by hand | Fix now → F-6 | verified: no `citationformat.Options()`; row names two constants |
| MNT-6 | MNT | minor | Field key→id lookup in handler tests is a third copy | Fix now → F-7 (same-pass cleanup) | verified: `citation_render_test.go:36`, `metadata_test.go:453`, `source_defs_test.go:469` |
| CON-3 | CON | minor | New handler tests skip `runRPC`; `TestRender` is not a table | Fix now → F-8 | files this PR adds; `add-ffi-handler` step 4 and `go-tests.mdc` |
| UX-1 | UX | minor | Preview of a deleted Citation returns `citations.invalid` ("That citation isn't valid.") while a deleted Source returns `sources.not_found` | To user → Fix now → F-9 | D-9 says a missing Citation target → `citations.ErrInvalid`; user (2026-11-19) accepted the recommendation: add `citations.not_found`, supersede that clause of D-9, record it in the Landed note |
| SEC note (ToStored) | CON | minor | An unsaved format near 4,096 bytes can exceed `MaxFormatBytes` after `ToStored` rewrites keys to `#<uuid>`; preview renders nothing with no diagnostic | Follow-up | pre-existing in `ToStored`/`RewriteFields` (save path has the same gap); this PR does not change them. Ask the user where it goes |

Nits (logged): `CON-4 · render_test.go "order, repeats and missing ids" · X via BenchID, not a UUIDv7; Sources recorded counted not named` · `MNT-7 · render.go:132 · size() recomputes len(Plain()) uncommented` · `MNT-8 · render.go:85-90 · repeats labelTypes' typeID loop` · `MNT-9 · citation_render_test.go:44 · setValues does one ListMetadataFields RPC per call` · `MNT-10 · render_test.go:167 / citation_render_test.go:20 · two page-locator JSON builders` · `UX-2 · preview.go:107-112 · per-chain seen map can repeat an option across missing entries`

### Fix plan 1

**F-2 — One owner grouping for boards and renders** (from MNT-1)
Files: `core/database/sourcemetadata/sourcemetadata.go`, `core/database/sourcemetadata/annotation.go`, `core/database/citationrender/load.go`.
Failing test first: `TestGroupByOwner` (sourcemetadata) — rows for two owners at different levels sharing an id, and two fields on one owner, come back under `Of(owner)` keyed by field id; an owner with no rows gives an empty map.
Do: add exported `type OwnerRows` with `GroupByOwner(rows []Row) OwnerRows` and `(OwnerRows) Of(o Owner) map[string]Row`, built on `Owner.key()` and `rowsByField`. Use it in `listWorkspaces` (replacing `valuesOf` + `rowsByField(valuesOf[...])`) and in `fillValues`. Delete `ownerKey`, the `seen` set and `byOwner` in `load.go`; `ListByOwnersTx` already removes repeated owners (`readByOwners` → `UniqueBlobIDs`).
Check: `grep -n "ownerKey" core/database/citationrender` prints nothing; board tests and `TestRender*` unchanged and green; `TestRenderScale` SELECT counts unchanged (9 and 11).

**F-3 — One alias-aware column-list helper** (from MNT-2; supersedes D-3's per-package copies — record in the Landed note)
Files: `core/database/` (new helper beside `UniqueBlobIDs`), `core/database/citations/citations.go`, `core/database/sourcetypes/sourcetypes.go`, `core/database/metadatafields/metadatafields.go`, `.agents/skills/add-catalog-query/SKILL.md`.
Failing test first: `TestColumns` (core/database) — table: empty alias leaves columns bare; alias `c` prefixes plain columns and the column inside `COALESCE(%s, '')`.
Do: add `database.Columns(alias string, cols ...string) string` where a col containing `%s` has the (prefixed) column name substituted and a bare col is prefixed. Rewrite `citations.columns`, `sourcetypes.columns` and `metadatafields.Columns` as one call each (keep their names and SQL output identical). Add one line to `add-catalog-query` covering the pattern: a column-list function on `database.Columns`, `scanX(row, extra ...any)`, and `GetManyTx` (`UniqueBlobIDs`, `sqlbatch.Query`, map keyed by `string(id)`, missing ids absent).
Check: `grep -rnE 'alias \+= "\."|= alias \+ "\."' core api` prints only lines inside `core/database`'s new helper (or nothing); every existing package test green.

**F-1 — Landed note** (from CON-1)
Files: `docs/deployment-plan/spike-15/prs/S15-16-citations-render.md`.
Do: add `## Landed` at the end listing: T-9's chain uses `{graph.meta.piece|source.meta.volume}` (why); D-3's `List` scans into a local `suggested` then assigns; unplanned helper `labelTypes`; unplanned `TestRenderCensus`; §10 manual check is none; and every change this fix round makes against the plan (F-2 `OwnerRows`, F-3 `database.Columns` superseding D-3's copies, F-5 exported built-in targets, F-6 `citationformat.Options()`, F-7 `fieldIDsByKey`). Write it last in the round.
Check: `scripts/check-plan-docs.py` on the plan OK.

**F-4 — Restore `getOne`'s doc comment** (from CON-2, MNT-3)
Files: `core/database/sources/sources.go`.
Do: move the two `getOne` comment lines from above `GetManyTx` to directly above `func getOne`.
Check: `go doc ./core/database/sources GetManyTx` starts with "GetManyTx".

**F-5 — Built-in targets from citationformat's table** (from MNT-4)
Files: `core/citationformat/builtins.go`, `core/database/citationrender/load.go`, `core/database/sourcemetadata/annotation.go`.
Do: export one `Target` value per built-in beside the table (e.g. `SourceTitle`, `SourceType`, `SourceDate`, `ArtifactLabel`, `GraphName`, `CitationPage`, `CitationImage`, `CitationLabel`); a test asserts each is in `Builtins()` and `Builtins()` has no other. Use them in `fillValues`; replace `dateHead` and `pageHead`; delete `builtin()`.
Check: `grep -rnE 'Builtin: *"' core --include='*.go' | grep -v _test | grep -v core/citationformat` prints nothing.

**F-6 — Options list from Go** (from MNT-5)
Files: `core/citationformat/form.go`, `api/ffi/swift_vocabulary_test.go`.
Do: add `citationformat.Options() []Option` beside `Forms()`; the "citation options" row uses it like the others.
Check: `TestSwiftVocabularyMatchesGo` green.

**F-7 — One field key→id test helper** (from MNT-6)
Files: `api/ffi/handlers/harness_test.go`, `citation_render_test.go`, `metadata_test.go`, `source_defs_test.go`.
Do: move `fieldIDs` to `harness_test.go` as `fieldIDsByKey`; call it from `lineLedgerSource` and the `source_defs_test.go:469` site. While there, MNT-9: look ids up once in `newRenderWorld` rather than per `setValues`.
Check: `grep -n "ListMetadataFields, &engine.ListMetadataFieldsRequest" api/ffi/handlers/*_test.go` prints only the `harness_test.go` line (plus any test that is about `ListMetadataFields` itself).

**F-8 — Test shape** (from CON-3)
Files: `api/ffi/handlers/citation_render_test.go`, `core/database/citationrender/render_test.go`.
Do: put the handler error cases (malformed id, no target, Source target with `full`, non-UUID target) into a `runRPC` table; fold `TestRender`'s cases that differ only by format and Citation (each built-in, image, no image, unknown, supplied blank, no short) into one case table. Coverage unchanged.
Check: tests green; `rg -n runRPC api/ffi/handlers/citation_render_test.go` finds it.

Order: F-2, F-3, F-4, F-5, F-6, F-7, F-8, then F-1 last. Gate: `scripts/check-pr.sh` PASS.

**F-9 — A preview of a deleted Citation says it no longer exists** (from UX-1; user decision 2026-11-19, supersedes D-9's "a Citation target that is not → `citations.ErrInvalid`")
Files: `core/database/citations/` (sentinel), the `apperr` code registry, `core/database/citationrender/preview.go`, `api/ffi/handlers/citation_render_test.go`, `macos/App/Platform/L10n.swift` + `Localizable.xcstrings` + the Swift engine-error-code mapping. Skills: `add-localized-string`.
Failing test first: `TestRenderPreview` case "deleted Citation" expects `citations.ErrNotFound`; the handler `runRPC` table gets a row expecting code `citations.not_found`.
Do: add `citations.ErrNotFound` as an apperr `KindNotFound` code `citations.not_found`, following how `sources.ErrNotFound` / `sources.not_found` is declared and mapped end to end. `RenderPreview` returns it when `loadCitations` finds no row. Do not change other `citations` paths that return `ErrInvalid` for a missing row. Swift: map the code to an `L10n.Errors` entry, copy "This Citation no longer exists." (match the casing and shape of the Source entry). Update the plan's Landed note (D-9 superseded by user decision) and the error list in `docs/citation-formats.md` § Rendering if it names the preview's errors.
Check: tests green; `scripts/check-pr.sh` PASS (localizable included).

## Round 1 — fix
Head `4d9fadf86`. F-1 – F-8 done (implementer gate PASS; orchestrator gate pending). Deviations: F-3 test written after the code; `database.Columns` takes `"name|expr"` for expression columns; F-7 left `source_defs_test.go:469` (it tests `ListMetadataFields` itself); F-8 keeps two crafted-SQL cases as subtests. F-9 added after the user's UX-1 answer.
F-9 head `eb291e062`. Gate PASS (orchestrator run, against `1f927d4b5`). F-9 deviations: copy is "This citation no longer exists." (lowercase, matching the sibling `citations.invalid` / `citations.in_use` entries); AC-2.6 and the plan's FFI error line still say `citations.invalid`, superseded in the Landed note. Checked the Landed note's T-9 reason: the census world gives the graph `item` ("Ada Robins"), so it holds.

## Round 2 — review
Scope `07676275d...eb291e062`. Reviewers: CON (CON-1 major), MNT (MNT-1, MNT-2 majors). Not sent back: UX (UX-1 minor; F-9 read by the orchestrator), SEC+PRF (no findings).

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | Landed note | Resolved | plan `## Landed` lists every difference, including the user's D-9 change |
| MNT-1 | MNT | major | Owner grouping | Resolved | `sourcemetadata.OwnerRows` used by `listWorkspaces` and `fillValues`; `TestGroupByOwner` |
| MNT-2 | MNT | major | Column-list helper | Resolved | `database.Columns`; grep prints only the helper; skill line added |
| CON-2 / MNT-3 | — | minor | `getOne` doc | Resolved (orchestrator) | `go doc` for `GetManyTx` reads as its own |
| MNT-4 | — | minor | Built-in targets | Resolved (orchestrator) | exported targets, `TestBuiltinTargets`; grep empty |
| MNT-5 | — | minor | Options list | Resolved (orchestrator) | `citationformat.Options()` at `form.go:46` |
| MNT-6 | — | minor | Test helper | Resolved (orchestrator) | `fieldIDsByKey` at `harness_test.go:452` |
| CON-3 | — | minor | Test shape | Resolved (CON round 2 confirmed) | `runRPC` tables in `citation_render_test.go` |
| UX-1 | — | minor | Deleted Citation preview | Resolved (orchestrator) | `citations.ErrNotFound` / `citations.not_found`, L10n + xcstrings, tests in core and handler |

No new blockers. Nits (logged): `MNT-11 · core/database/sqlin.go:31 · gofmt turned '' in the doc example into a typographic quote` · `MNT-12 · core/database/sqlin_columns_test.go · Columns lives in sqlin.go; a columns.go pair would be easier to find` · `ORC · preview.go RenderPreview doc · one rewrapped line runs long`

## Finish
`origin/main` unchanged since the branch was cut (`1f927d4b5`); gate PASS on `eb291e062` stands.

## Result
Gate PASS · CI green (test ×2, localizable) · open: none · follow-ups: ToStored rewrite can exceed `MaxFormatBytes` (home pending the user) · to user: UX-1 (answered 2026-11-19: add `citations.not_found`)

## User request after round 2 — two format limits (2026-11-19)
The follow-up (a format under the limit as typed can exceed it once `ToStored` swaps keys for `#<uuid>`) moved onto this PR at the user's request. User decisions: two limits; the one the researcher sees counts **characters**, not bytes; the parse limit is that plus margin sized from the seeds.
Sizing: the 72 seeded format strings hold at most 22 field placeholders (doubled: 44). Each placeholder grows by 37 − key length on save (seed keys 3–20, mean 8.4; worst 1-char key: +36). 44 × 36 = 1,584 bytes. A full 4,000-character format at up to ~1.6 bytes per character plus 1,584 fits in 8,192 bytes. Largest seeded stored format: 1,291 bytes; largest stored/typed ratio 2.2×.

**F-10 — Two format limits: characters typed, bytes parsed** (user request)
Files: `core/citationformat/parse.go`, `core/database/sourcetypes/formats.go`, `core/database/deleteimpact/formatrefs.go`, `macos/App/Platform/CitationFormatVocabulary.swift`, `api/ffi/swift_vocabulary_test.go`, `docs/citation-formats.md`, the plan's Landed note, `docs/deployment-plan/spike-15/deployment-plan.md` (S15-17 scope entry).
Failing tests first (`sourcetypes`, `citationrender`, `citationformat`):
- a format of many short-key placeholders under 4,000 characters typed but over 4,096 bytes once stored saves through `ToStored` and previews (renders, no diagnostic) — fails today with an empty preview;
- a format of 4,001 characters (ASCII) is refused by `ToStored` with `too_long` over the whole typed text; 4,000 characters of multi-byte text (e.g. `é`) is not refused for length;
- a typed format under 4,000 characters whose stored text exceeds 8,192 bytes (crafted: many one-character keys, or multi-byte literal text) is refused by `ToStored` with `too_long` over the whole typed text, never stored;
- `Parse` refuses text over 8,192 bytes with `too_long`.
Do:
- In `citationformat`: `MaxFormatChars = 4000` (the limit the researcher sees, counted in Unicode code points, `utf8.RuneCountInString`) and `MaxFormatBytes = 8 << 10` (the parse limit on any text, typed or stored). Doc comments say which is which and where the margin comes from (44 placeholders × 36 bytes, from the seeds). `Parse` keeps checking bytes, against the new value.
- In `sourcetypes.ToStored`: before anything else, each form whose typed text has more than `MaxFormatChars` characters gets `too_long` (span: the whole text) and the call returns diagnostics only, the same shape as today's. After the key→id rewrite, any form whose stored text is over `MaxFormatBytes` gets `too_long` over the whole typed text. Both go through the existing `sortByForm` diagnostic return.
- `deleteimpact/formatrefs.go` keeps using `citationformat.MaxFormatBytes` (now the stored limit); check its comment still reads true.
- Swift: add the limit the editor shows, `CitationFormatLimit.maxCharacters = 4000`, in `CitationFormatVocabulary.swift`, and a parity row in `TestSwiftVocabularyMatchesGo` reading `citationformat.MaxFormatChars`, so a change in Go fails a test, not a screen.
- `docs/citation-formats.md`: "A format holds at most 4,000 characters (stored, at most 8,192 bytes)…" and the `too_long` row: "More than 4,000 characters, or more than 8,192 bytes once its fields are stored by id".
- S15-17's map scope entry (no plan yet): add that the editor shows how many of the 4,000 characters are used, counting Unicode scalars (`unicodeScalars.count`, matching Go's code points), from `CitationFormatLimit.maxCharacters`.
- The plan's Landed note: the two limits, by user decision 2026-11-19.
Check: the four tests pass; `TestSwiftVocabularyMatchesGo` green; existing parse, fuzz, seed-install and delete-impact tests green; `scripts/check-pr.sh` PASS.
