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

## Round 2

See below.
