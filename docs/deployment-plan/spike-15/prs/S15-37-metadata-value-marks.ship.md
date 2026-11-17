# Ship log — S15-37 Metadata values can be marked unknown or supplied

**Plan:** [`S15-37-metadata-value-marks.md`](S15-37-metadata-value-marks.md) · **Branch:** `s15-37-metadata-value-marks` · **PR:** #879
**State:** ready

## Round 0 — implement
Base `origin/main` @ `2bcfd1fbd` (plan written against `b4c77df`). `main`'s `VERSION` is already 0.21.0, so the plan's own rule makes the bump 0.22.0.
Head `6ac9e215d`. Gate PASS (orchestrator run: all nine checks). Report deviations: AC-1.4 — `urlshape.Canonical` keeps a scheme-less url, so a supplied "ancestry.com/x" is stored as typed and only `open_href` gains `https://` (the AC says the stored text gains it); version 0.22.0; T-12 fixtures delete the Artifact before the Source; the handler passes `nil` unknown text until the wire commit; the § 10 manual check not run.

## Round 1 — review
Reviewers: CON, MNT, UX (`L10n.swift`, `Localizable.xcstrings`, new `valuemark.invalid` code), SEC+PRF (`api/ffi/**`, migration `000067.sql`, `core/database/**`). Skipped: none.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | Owner-generic test helpers sit beside Source-only copies | Fix now → F-1 | verified: `readDraft` (`sourcemetadata_test.go:1258`) is `readOwnerDraft` (1240) with `sourceOwner` hard-coded; `runSet`/`runClear` (695, 703) repeat `ownerOps.set`/`clear`'s `writes.Run` wrapper (2306, 2318). Same-pass cleanup |
| CON-2 | CON | minor | New mark tests are scripts, not tables (`.cursor/rules/go-tests.mdc`) | Fix now → F-2 | verified: no `[]struct` table in `TestValueMarks`, `TestValueMarkChanges`, `TestMetadataValueMarks`; the binding rule asks for tables and F-1 already edits the file |
| CON-1 | CON | minor | No wire test that a board entry's `field` carries `unknown_text` | Fix now → F-3 | verified: `rg UnknownText api -g '*_test.go'` hits only `source_defs_test.go`; AC-3.1 says "every board entry's `field`" |
| MNT-2 | MNT | minor | `Set` and `Apply` doc comments say every refusal is `sourcemetadata.ErrInvalid` | Fix now → F-4 | verified: `sourcemetadata.go:93`, `:339-340`; `normalizeFor` returns `valuemark.ErrInvalid` (977-984) |
| SEC-1 | SEC | minor | Supplied CHECK lets blank text through | Rejected | D-1 fixes the DDL text (`value_text IS NOT NULL`) and binds. Only a crafted catalog reaches it, and the result (Copy Source and a later save refuse that row with `valuemark.invalid`; the render omits it) is what an unmarked `''` row already does today (`value_text TEXT` has no check; `normalizeFor` refuses `""`). SQLite's `trim()` strips only spaces while Go's `TrimSpace` strips all whitespace, so the proposed CHECK still would not mirror Go exactly. Plan's D-1 Why overstates "refuses what Go refuses"; noted, not changed |
| UX-1 | UX | minor | Refusal copy leads with the cause the control cannot produce, says "text" | Later PR → S15-41 | D-12 fixes this sentence verbatim; S15-41 places the message on the row and is gated by S15-D22, so the rewording is written into S15-41's map scope entry ("Also (S15-37 review, UX-1)", commit `2c482c609`) |

Nits (logged): `CON-3 · sourcemetadata_test.go TestValueMarks · "Clearing an unknown value deletes its row." sits above a set, move to o.clear` (rides along in F-2) · `MNT-3 · metadatafields.go:456-463 · build Columns from a slice` · `UX-2 · L10n.swift:7354,7385,8221 · plugin "Supplied" vs the mark's "supplied" on the Metadata page; for S15-D22/D25`

### Fix plan 1

**F-1 — Source-only test helpers delegate to the owner-generic ones** (from MNT-1)
Files: `core/database/sourcemetadata/sourcemetadata_test.go`.
Do: `readDraft` becomes `return readOwnerDraft(t, c, sourceOwner(sourceID))`. Give the package one owner-generic runner for each write that returns `(Row, []rowchange.Change, error)` (or `([]rowchange.Change, error)` for clear) — e.g. `runSetOwner(c, userID, owner, in)` and `runClearOwner(c, userID, owner, fieldID)`, the shape `runUpdateUnknown` has in `metadatafields_test.go:893-909`. `runSet`, `runClear`, `ownerOps.set` and `ownerOps.clear` call them; callers keep their signatures.
Check: `grep -n 'writes.Run' core/database/sourcemetadata/sourcemetadata_test.go` shows one `update_metadata` call around `Set` and one around `Clear` (other actions, e.g. dismiss and apply, unchanged); `grep -n 'ReadDraftTx(tx, ' core/database/sourcemetadata/sourcemetadata_test.go` shows one call inside a helper body; `go test ./core/database/sourcemetadata/` passes; scripts/check-pr.sh PASS.

**F-2 — The new mark tests are table-driven** (from CON-2, CON-3)
Files: `core/database/sourcemetadata/sourcemetadata_test.go` (`TestValueMarks`, `TestValueMarkChanges`), `api/ffi/handlers/metadata_test.go` (`TestMetadataValueMarks`).
Do: turn independent cases into `[]struct{name …}` rows run with `t.Run`, per `.cursor/rules/go-tests.mdc`: the refused-mark inputs (unknown with text, both, supplied blank, empty with no mark), the url cases, the crafted-INSERT cases, and the create/update/delete change shapes (prior state, input, wanted keys/diffs). Keep `TestValueMarks`'s outer loop over the three levels. Dependent sequences (repeat → no changes; text over unknown; clear; dismiss; delete-in-use) stay as named `t.Run` subtests. Every case T-1, T-2 and T-8 list keeps an assertion; no case is dropped. Move CON-3's comment to the `clear` call.
Check: each of the three functions has a `[]struct` table; `go test -run 'TestValueMarks|TestValueMarkChanges|TestMetadataValueMarks' -v` lists the case names; scripts/check-pr.sh PASS.

**F-3 — Wire test: a board entry's field carries unknown text** (from CON-1)
Files: `api/ffi/handlers/metadata_test.go` (`TestMetadataValueMarks`).
Failing test first: none possible against the current code (it is right); this is coverage. Add a row/subtest: `UpdateMetadataField` on `m.suggested` with `UnknownText: proto.String("n.p.")`, then a `SetMetadata`, then assert `metadataByField(out.GetMetadata(), m.suggested).GetField().GetUnknownText() == "n.p."`. Prove it bites: temporarily build the entry's field inline without `UnknownText` and see it fail, then restore.
Check: the case passes; scripts/check-pr.sh PASS.

**F-4 — `Set` and `Apply` comments name both refusals** (from MNT-2)
Files: `core/database/sourcemetadata/sourcemetadata.go` lines ~93 and ~339.
Do: say a refused mark is `valuemark.ErrInvalid` and any other refused value `ErrInvalid`, each naming its field (Apply: the first in draft order), matching `normalizeFor`'s comment.
Check: scripts/check-pr.sh PASS.

## Round 1 — fix
Head `dcd07cc5f`. Gate PASS (orchestrator run: all nine checks). F-1, F-2, F-3, F-4 done. Deviations: `TestMetadataValueMarks` is a sequential step table (each step sets over the last); F-3 is its own subtest. F-3 shown to bite: dropping `UnknownText` from `source_defs.go:539` fails it with `entry field unknown_text = ""`.
Minors read by the orchestrator: CON-1 **Resolved** (subtest present, bites); CON-2 **Resolved** (`[]struct` tables: 3 in `TestValueMarks`, 1 in `TestValueMarkChanges`, 1 in `TestMetadataValueMarks`); MNT-2 **Resolved** (both comments name `valuemark.ErrInvalid` and `ErrInvalid`).

## Round 2 — review
Reviewers: MNT (MNT-1 major). Not sent: CON, UX, SEC+PRF (no Fix-now blocker or major).
Head `dcd07cc5f`. MNT-1 **Resolved**: `readDraft` delegates to `readOwnerDraft`; `runSetOwner`/`runClearOwner` hold the only `writes.Run` around `Set`/`Clear`, and `runSet`, `runClear`, `ownerOps.set`, `ownerOps.clear` call them. No new blockers.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-4 | MNT | minor (note) | An inline owner-generic `apply` closure (`sourcemetadata_test.go:1600-1608`, added in this PR) sits beside the Source-only `runApply` (:1245) | Follow-up → dropped | Same shape as MNT-1, but round 2 can only add blockers and a Fix plan 2 exists only for them. User dropped it (2026-11-17) |

## Result
Branch up to date with `origin/main` @ `2bcfd1fbd` (no merge needed). Gate PASS · CI green · open: none · follow-ups: none (MNT-4 dropped by the user) · later PR: UX-1 → S15-41 · rejected: SEC-1 · to user: —
