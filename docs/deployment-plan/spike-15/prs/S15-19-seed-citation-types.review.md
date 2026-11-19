# Review — S15-19 Seed the citation types, fields, suggestions and formats

Plan: [`S15-19-seed-citation-types.md`](S15-19-seed-citation-types.md). Lint: `scripts/check-plan-docs.py` clean once this log exists.

## Round 1 (2026-11-17)

Maintainability: **Fits with changes**. Executability: **Not ready** (X-1). The plan is Blocked on S15-52, so no step could run.

### Maintainability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M-1 | blocker | D-8 wrote the format columns a second way in `sqlUpsert`, beside `UpdateFormats`, and its `Formats{}` zero value would wipe a seeded type's formats from test fixtures that upsert `book` | **Fixed.** D-8: `UpsertTx(…, formats *Formats)`, nil keeps; the write goes through `writeStoredTx`, pulled out of `UpdateFormats`, which calls it. STEP-1, Go core, Codebase fit, T-9 updated |
| M-2 | major | `metadatafields.UpsertTx` would copy `Update`'s unknown-text trim, NULL and diff rule | **Fixed** in the preparatory PR: S15-52's map scope entry now says `UpsertTx`'s update branch and `Update` share one per-column diff; D-8 passes `UnknownText` through it |
| M-3 | major | D-10 wrote each seed list twice (ensure, then reorder), with a transient duplicate order; Codebase fit missed `subjectvocab.ReorderBindings` | **Fixed.** D-10: one `seedListTx` reads once, inserts missing seed rows at their place, updates moved rows; follows `ReorderBindings`. `EnsureSuggestion` keeps its test callers |
| M-4 | major | The certificate formats written three times, the journal formats twice | **Fixed.** D-6: `certificateFormats(word, plural)` and `journalArticleFormats`; D-5, STEP-3 updated |
| M-5 | minor | STEP-9 missed skill lines this PR makes false, and `render_test.go`'s comment naming the corpus | **Fixed.** STEP-9 names each skill line; D-13 rewords the comment |
| M-6 | minor | `FuzzParse` loses realistic seeds when the corpus goes | **Fixed.** D-13: `FuzzParse` adds `censusFull` and `censusShort` |

### Executability

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| X-1 | blocker | T-2's "every seeded field is read" cannot pass: no seeded format reads `database_title` or `record_id` | **Fixed.** Both stay (map § 6.8 lists them in the 63); T-2 names them in `unreadFields`; D-3 says why |
| X-2 | major | Named `TestInstall` cases did not exist; unclear which old cases stay | **Fixed.** STEP-5 names the two replaced and the four kept, with the one edited assertion |
| X-3 | major | Current state miscounted `sourcemetadata_test.go`; `harness_test.go` `sourceFixture` takes `Types[0]`, which becomes Archived manuscript | **Fixed.** § 4 row corrected; D-11 and STEP-8 make `sourceFixture` pick `birth_certificate` by key |
| X-4 | major | S15-52's helper names, `Op.Action` and the formats argument left open | **Fixed.** D-8: uses S15-52's names as landed, § 4 redone then (Stop condition stands); helpers pass nil, so callers do not change |
| X-5 | major | Fixture wiring (id → key, italics) open; fallbacks never rendered | **Fixed.** D-9 says how; a `court_report` `nopage` case shows the `page_range` fallback; the bare fixture shows `source.title` fallbacks |
| X-6 | minor | Position of a field read at two levels | **Fixed.** § 6 Suggestion rule: first appearance at any level |
| X-7 | minor | Corpus lines not mapped to type keys | **Fixed.** STEP-3 maps each line range |
| X-8 | minor | Which subtest the timing check means | **Fixed.** STEP-5 and § 6 Scale name the subtest |
| X-9 | minor | Tie order of non-seed rows | **Fixed.** D-10: ties broken by `field_id` |
| X-10 | minor | The plan's own lint fails until this log exists | **Fixed** by this log |

## Round 2 (2026-11-17)

Maintainability: **Fits with changes**. Executability: **Ready with changes**. Every round-1 answer holds (M-3 in part, closed by M2-2 below).

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| M2-1 | blocker | A re-run on an old catalog kept `record_date` and `issue_date` suggested, against the map ("stops suggesting") | **To user → answered** (2026-11-17): "dont worry about dogfood projects, I will take care of them manually. Just make sure that new projects get the correct stuff." D-10 drops the re-run ordering; D-12, US-4, Out, Edges, STEP-5, STEP-9 rewritten; AC-4.2, AC-4.3, T-5, T-6 removed. Map rule "The seed is the product default", bar 6, the S15-19 and S15-20 entries and citation map § 6.4 say the dogfood projects are updated by hand |
| M2-2 | blocker | `seedListTx` would add insert and update statements beside `sqlEnsureSuggestion`; S15-52's transactional ensure would go dead | **Fixed**, then made moot by M2-1: `seedListTx` is gone, and Install writes through S15-52's transactional ensure, its one production caller |
| M-1 caveat | minor | `sourcetypes.Create` still writes formats in `sqlInsert`; the three fixture files need `nil` if S15-52 has them call `UpsertTx` | **Logged** for `Create` (existing, unchanged by this PR). STEP-1 names the three fixture files |
| X2-1 | minor | Other `Types[0]` handler tests not named | **Fixed.** D-11 names them and when they switch |
| X2-2 | minor | S15-52's helper names fixed only when it lands | **Logged.** The § 4 redo records them; the Stop condition stands |

## Verdict

**Fits / Ready.** No blocker open; nothing To user open. Status stays **Blocked — on S15-52**, and § 4 is redone when S15-52 lands.

## Refresh round (2026-11-19, after S15-52 landed in #891)

§ 4 redone against `main` @ `809833a`; every row verified by the executability reviewer. Maintainability: **Fits with changes**. Executability: **Ready with changes**.

| ID | Severity | Finding | Answer |
| --- | --- | --- | --- |
| R-M1 | major | A formats-only re-upsert would need a third hand-built `source_type` update change (`updateChange` returns nil; `UpdateFormats` builds its own) | **Fixed.** D-8: `updateChange(prev, next, formats)` merges format diffs; `Update` passes nil; `UpdateFormats` builds through it; `UpsertTx` computes the format diffs first, then the change, then `sqlUpdate` only for row columns |
| R-X4 | minor | Same gap: no change to merge into when only formats differ | **Fixed** by R-M1's answer |
| R-M2 / R-X1 | major / blocker | Direct `UpsertTx` callers S15-52 added (`effects/source_type_search_test.go`, `sourcetypes_test.go` `TestUpsertTx`'s `run`) would not compile | **Fixed.** D-8 and STEP-1 name both (pass nil); STEP-1's check runs `./core/database/effects/...`; a formats-only case pins "no search reprojection" |
| R-M3 / R-X7 | minor | Text described suggestion work S15-52 already did; `UpsertTx`'s doc comment not named | **Fixed.** § 3 row, Go core row and STEP-5 title say "unchanged"; D-8 names the doc comment |
| R-X2 | minor | 29 → 33 lines in `sourcemetadata_test.go` | **Fixed** |
| R-X3 | major | STEP-9 quoted skill text S15-52 rewrote; skill's date-key line and two docs mentions | **Fixed.** STEP-9 quotes the current sentence, drops the date-key sentence, and says the two `docs/*.md` `issue_date` examples stay |
| R-X5 | minor | D-10's reason half true: a re-run is a no-op only because `writes.Run` rolls back an empty change list | **Fixed.** D-10's reason says so; T-4's revision count is the assertion |
| R-X6 | minor | Fixture mechanics (value map, transaction, `usualLevel`) | **Fixed.** § 6: a 63-entry map in the test, `db.Begin()` on `c.DB()`, `usualLevel` built from the two group lists |
| R-X8 | minor | `metadataSetFixture`, seed-twin user keys, a handler comment | **Fixed.** D-11 says they stay; the comment changes only if its test fails |

## Verdict (refresh)

**Planned.** No blocker open; nothing To user open.
