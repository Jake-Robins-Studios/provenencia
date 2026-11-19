# Ship log — S15-19 Seed the citation types, fields, suggestions and formats

**Plan:** [`S15-19-seed-citation-types.md`](S15-19-seed-citation-types.md) · **Branch:** `s15-19-seed-citation-types` · **PR:** #897
**State:** ready

Base: `main` @ `2d48e41`.

## Round 0 — implement
Head `67a44fa83`. Gate PASS (orchestrator re-run). PR #897 (draft). Report deviations:
- D-11 named fewer test fixes than the new seed needs (birth certificate now suggests Artifact and graph fields): `graphFixture` gains `clearBoardSuggestions`; `TestUpdateSourceType` expects 4 + 10 + 2 + 1; `TestSearchCatalogHandleKinds` queries "James Kenneth" (seeded `item` description contains "Ada Robins").
- `render_test.go` reads type ids before opening its read transaction; § 6's `db.Begin()`-first order deadlocked `sourcetypes.Lookup` on the single connection.
- Implementer observations on the plan's formats (not changed): `book` list "2nd ed.." double period; bare renders leave stray punctuation (`census` "1880 census, ."); `church_register` full has no `creator` fallback so the bare form begins ", "; `statute` bare has two spaces.

## Round 1 — review
Reviewers: CON, MNT, SEC+PRF (`core/database/**` → performance). Skipped: UX — no `macos/App/**` (only `project.pbxproj` version lines), no `Localizable.xcstrings`, no `core/apperr` or error codes; the seed's labels and descriptions are catalog data, which CON and MNT read against the plan.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | No test checks the installed suggestion lists or their sort orders | Fix now → F-1 | verified: base `TestInstall` checked `SortOrder == i` (base line 68); head `sourcevocab_test.go` has no such check; plan § 6 Edges names T-12 for it |
| CON-2 | CON | major | `edition` and `holder` descriptions disagree with the formats: book list "2nd ed..", eight list formats start a sentence with lowercase "held in 2025 by" | To user → answered → Fix now → F-2 | verified in the golden (`book full list`, `family_bible full list` and seven more). Contradicts D-3/D-5 text, so asked. **User (2026-11-19):** "Formats write 'ed.'" and "Formats write 'held by'" |
| MNT-1 | MNT | major | Three copies of the form → format text switch (two new, in `sourcevocab` tests) | Fix now → F-3 | same-pass cleanup; `git grep "case citationformat.FormShort"` shows `formatText`, `seedType.text`, `Formats.text` |
| MNT-2 | MNT | major | Stored-formats read helper copied: `storedFormats`, `copyFixture.formats`, inline in `render_test.go`; `stored` closure plus inline read in `sourcetypes_test.go` | Fix now → F-4 | same-pass cleanup; `git grep StoredFormatsTx -- core` lists five sites |
| MNT-3 | MNT | minor | `UpsertTx` builds `updateChange` twice to gate `sqlUpdate` | Fix now → F-5 | minor in code this PR changes; `sourcetypes.go` update branch |
| SEC-note / impl. obs. | CON (routed) | — | Bare renders start with stray punctuation (`cemetery_marker` ", Grave of…", ". . Grave markers."; `church_register` ", *Baptisms…*"; `statute` ",  1880."; `government_file` "; .") | Rejected | Fields outside `[…]` are required by design (map § 6.3; requirements shown on the boards, S15-38); the bare fixture deliberately omits required fields to show which groups drop (D-9). A researcher sees this only while a required field is unfilled |

Nits (logged): `MNT-4 · api/ffi/handlers/evidence_graphs_test.go:41 · typeID from Types[0] vs the Source's type read by clearBoardSuggestions — comment or unify` · `MNT-5 · sourcevocab/render_test.go fieldValues · say the values mirror registry_fields.go description examples` · `CON-3 · evidence_graphs_test.go:42 · graphFixture could use the birth_certificate lookup sourceFixture uses`

### Fix plan 1

**F-1 — Install writes every suggestion list in registry order** (from CON-1)
Files: `core/database/sourcevocab/sourcevocab_test.go`.
Failing test first: in `TestInstall` "empty catalog gets the seed", for every `seedSuggestions` entry, `ListSuggestions(c, typeID, level)` returns exactly `FieldKeys` in order, each `Origin == provenencia`, `SortOrder == i`; and every (type, level) pair with no `seedSuggestions` entry has no rows. Prove it bites: temporarily make Install's sort order a constant 0, see it fail, revert.
Do: test only.
Check: the test passes; scripts/check-pr.sh PASS.

**F-2 — `edition` and `holder`: the formats write "ed." and "held by"** (from CON-2; user decision 2026-11-19)
Files: `core/database/sourcevocab/registry_fields.go`, `core/database/sourcevocab/registry.go`, `core/database/sourcevocab/testdata/seed-citations.txt`, `core/database/sourcevocab/render_test.go`, plus any doc that quotes these descriptions or formats (`docs/seeded-vocabulary.md`, the plan's Fields table and formats, map § 6.8 corpus lines if they hold these formats).
Failing test first: in `TestSeedCitations`, assert no `full`-fixture line contains `..` and no `full`-fixture line contains ". held" (lowercase sentence start after a period).
Do:
- `edition` description example becomes "2nd" (e.g. "The edition, as it should appear before \"ed.\" in a citation (2nd)."); book Full `[, {source.meta.edition} ed.]`, book List `[ {source.meta.edition} ed.]`. Any other format that reads `edition` gets the same.
- `holder` description example becomes "Clara Venn, Port Ellis, 2025" (who holds it, where, and the year). Every Full form that reads it writes `[; held by {source.meta.holder}]`; every List form writes `[ Held by {source.meta.holder}.]`. All eight types (`family_bible`, `photograph`, `private_papers`, `dna_match_report`, `gedcom_file`, `interview`, `oral_testimony`, `correspondence`) and any other reader `grep -n "source.meta.holder" core` finds.
- Update the full fixture value for `holder` to the new example shape and the `edition` value to "2nd"; regenerate the golden with `-update`, read the changed lines.
- Record the user's decision in the plan's Landed note (supersedes D-3's two descriptions and D-5's text for these formats).
Check: `grep -n "held in 2025 by\|ed\.\." core/database/sourcevocab` empty; T-1/T-2 still pass; scripts/check-pr.sh PASS.

**F-3 — One form → text switch** (from MNT-1)
Files: `core/database/sourcetypes/formats.go`, `core/database/sourcevocab/{sourcevocab_test.go,registry_test.go,render_test.go}`.
Do: export `sourcetypes.Formats.Text(form)` (rename `text`, keep its panic on an unknown form; update its in-package callers). Delete `formatText` and `seedType.text`; call `Formats.Text`.
Check: `grep -rnE "case citationformat\.FormShort" core` prints only `formats.go` (`Text` and `with`); scripts/check-pr.sh PASS.

**F-4 — One stored-formats read helper per package** (from MNT-2)
Files: `core/database/sourcevocab/{sourcevocab_test.go,copy_test.go,render_test.go}`, `core/database/sourcetypes/sourcetypes_test.go`.
Do: in `sourcevocab`, one package-level `storedFormats(t, c, id)` built on `dbtest.MustDB`; `copyFixture.formats` calls it (or is removed for it); `render_test.go` calls it per type instead of its own `Begin`/`StoredFormatsTx` (mind the single-connection deadlock: do not hold a tx while calling it). In `sourcetypes`, lift the `TestUpsertTx` `stored` closure to a file-level helper and use it for the inline read at ~`sourcetypes_test.go:385-397`.
Check: `git grep -n StoredFormatsTx -- 'core/**/*_test.go'` prints exactly one line in `sourcevocab` and one in `sourcetypes` (the helpers); scripts/check-pr.sh PASS.

**F-5 — Gate `sqlUpdate` on one row diff** (from MNT-3)
Files: `core/database/sourcetypes/sourcetypes.go`.
Do: in `UpsertTx`'s update branch compute `rowDiff := updateChange(existing, next, nil)` once, gate `sqlUpdate` on `rowDiff != nil`, then build the audited change with the diffs.
Check: `TestUpsertTx` and the effects test pass; scripts/check-pr.sh PASS.

## Round 1 — fix
Head `0230dc3ca`. Gate PASS (orchestrator re-run). F-1 – F-5 done. F-1 mutation (constant sort order) failed the new check, reverted. F-2 failing check hit 9 lines first; plan Fields table, formats, map § 6.8 corpus and Landed note updated. Deviation: F-4's grep also prints `sourcetypes/formats_test.go:452,466`, the dedicated `StoredFormatsTx` test — accepted, it exercises that function directly.
MNT-3 (minor): **Resolved** — read `0230dc3ca`; `sqlUpdate` gated on one `rowDiff`.

## Round 2 — review
Reviewers: CON (CON-1, CON-2 majors), MNT (MNT-1, MNT-2 majors). Not sent: SEC+PRF (no findings in round 1). Scope: `3e9f3ab17...0230dc3ca`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| CON-1 | CON | major | (round 1) suggestion lists unchecked | Resolved | `TestInstall` checks every list's keys, origin, `SortOrder == i`, and empty unlisted (type, level) pairs |
| CON-2 | CON | major | (round 1) `edition`/`holder` wording | Resolved | descriptions and nine formats changed per the user; golden regenerated; `TestSeedCitations` guards `..` and `. held` |
| MNT-1 | MNT | major | (round 1) form → text switch copies | Resolved | only `formats.go` `Text` and `with` switch on `FormShort` |
| MNT-2 | MNT | major | (round 1) stored-formats read copies | Resolved | one `storedFormats` per test package; `formats_test.go` keeps its direct `StoredFormatsTx` test |

No new findings. Nits (logged): `MNT-6 · sourcevocab/copy_test.go:109 · copyFixture.formats only forwards to storedFormats; call sites could call it directly`

## Finish
Merged `origin/main` @ `04e916c` (S16-48 plan docs only). Gate PASS after merge.

## Result
Gate PASS · CI see PR #897 · open: none · follow-ups: none · to user: CON-2 (answered 2026-11-19: formats write "ed." and "held by")
