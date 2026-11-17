# Ship log — S15-15 Source types store citation formats

**Plan:** [`S15-15-type-stores-citation-formats.md`](S15-15-type-stores-citation-formats.md) · **Branch:** `s15-15-type-stores-citation-formats` · **PR:** #871
**State:** ready

Base: `main` @ `dbc946cf6` (plan planned against `754d8f6`). `VERSION` on main is already 0.18.0, so the bump is 0.18.0 → 0.19.0 per the plan's Version bump line.

## Round 0 — implement
Head `5962a9a7f`. Gate PASS (orchestrator run). Report deviations:
1. `metadatafields_test.go` moved to external package `metadatafields_test` to break a test import cycle (`sourcetypes` now imports `metadatafields`); no test changed.
2. Version 0.18.0 → 0.19.0 (main already at 0.18.0).
3. T-9 landed as a separate `TestQueryBindsStringKeysAsText` instead of a case in `TestQueryReadsPastTheBindLimit`.
4. T-5 is one `TestDelete` case covering AC-3.1–3.5.
5. `UpdateCitationFormats` / `GetCitationFormats` follow `UpdateSourceType`: `writes.Op` carries no `UserID`.
Manual check (§10) not run by implementer.

## Round 1 — review
Reviewers: CON, MNT, UX, SEC+PRF. Skipped: none. UX for `macos/App/**` and `Localizable.xcstrings`; SEC+PRF for migration `000066`, `api/ffi/**`, `core/database/**`, and stored format text parsed from the catalog.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| UX-1 | UX | major | A choice for a since-deleted field fails the whole save as "Invalid source type." | To user → answered: keep D-5 (user, 2026-11-16: "No need to handle the case of a second window."); Edges line aligned → F-5 | `checkChoices` (`formats.go:349`) returns `ErrInvalid` before parse, exactly as D-5/AC-2.7 say; contradicts the plan's own Edges "Removed inputs" line (`unknown_field` at the key). Plan Decision, so the user decides |
| SEC-1 | SEC | major | Format-ref scan has no length bound on stored text | Fix now → F-2 | verified: `formatrefs.go` `totals` runs `strings.Contains` per field over every stored text with no length filter; one cap at `MaxFormatBytes` (memory rule: one high cap for crafted-only costs) |
| MNT-1 | MNT | major | Fourth copy of the editable-origin check; `Update`/`UpdateFormats` opening steps duplicated | Fix now → F-1 | verified: `rg` finds 4 copies (`metadatafields.go:193`, `sourcetypes.go:260`, `formats.go:373`, `properties.go:207`); same-pass cleanup |
| MNT-2 | MNT | minor | Form→column pairing written separately in `UpdateFormats` and `Delete` | Fix now → F-3 | minor in a file this PR adds |
| UX-2 | UX | minor | Toast "…that uses it keeps it" | To user → Fix now → F-6 (user, 2026-11-16, chose "…are unchanged") | wording is D-12's; user amended it |
| CON-1 | CON | minor | AC-4.2 resave asserts nothing | Fix now → F-4 | verified: test checks only `err`, diagnostics return with `err == nil` |
| UX-oml | UX→CON | minor | Manual check step 2 says "Its count is 1" but the Metadata page shows no count | Fix now → F-5 | verified: no `usedBy` read in `macos/App/Features/Metadata/` |

Nits (logged): `MNT-3 · formats.go:30-50 · explicit List case instead of default` · `MNT-4 · source_defs.go citationFormatsProto · doc comment` · `MNT-5 · effects/registry.go:455 · name searchindex.ReprojectSource/ReprojectSourceType` · `UX-3 · Localizable.xcstrings:2737,2761 · serial comma "events, or places"` · `UX-4 · L10n.swift:8521 · toastRemovedBody doc comment` · `CON-2 · docs/citation-formats.md ambiguous_field row · "more than one field holds the key"` · `CON-3 · metadatafields_test.go:236 · direct one-type AC-3.3 assertion`

### Fix plan 1

**F-1 — One editable-origin rule, one type lookup for `sourcetypes` writes** (from MNT-1)
Files: `core/vocabkey/vocabkey.go`, `core/database/sourcetypes/sourcetypes.go`, `core/database/sourcetypes/formats.go`, `core/database/metadatafields/metadatafields.go`, `core/database/properties/properties.go`.
Failing test first: none needed for the extraction; add a table test for `vocabkey.Editable` (user, provenencia → true; `plugin:x`, unknown → false) in the existing vocabkey test file.
Do: add `vocabkey.Editable(origin string) bool` beside `IsPluginOrigin`; move all four callers onto it. In `sourcetypes`, add an unexported `editableTx(tx, id)` that does the id-length check, `getByIDTx`, and the origin check (returning `ErrLocked`), used by both `Update` and `UpdateFormats`. Keep each caller's current not-found error (`Update` returns `sql.ErrNoRows`, `UpdateFormats` returns `ErrInvalid` per D-13): `editableTx` returns `sql.ErrNoRows` and `UpdateFormats` maps it, with a one-line comment saying why the two differ. No behavior change.
Check: `rg -n "Origin != vocabkey.OriginUser" core` prints nothing; `rg -nE "OriginUser &&|OriginProvenencia &&|!= vocabkey.OriginProvenencia" core --glob '!*_test.go'` prints nothing; existing `TestUpdate`/`TestUpdateFormats`/metadatafields/properties tests pass; scripts/check-pr.sh PASS.

**F-2 — Cap stored format text at `MaxFormatBytes` in the format-reference scan** (from SEC-1)
Files: `core/database/deleteimpact/formatrefs.go`, its test.
Failing test first: a `deleteimpact` (or `metadatafields` `TestDelete`) case where a type's `citation_full` is a raw-written text longer than `citationformat.MaxFormatBytes` that contains `#<field id>`: the field is not counted as named (UsedBy 0, delete not refused). Today it counts.
Do: both queries (`sqlFormatTypesNaming` and the one `totals` reads) select only texts with `length(citation_x) <= ?`, bound to `citationformat.MaxFormatBytes`, so a text that can never parse (D-6) contributes no field. One cap; no other bound.
Check: the new case passes; scripts/check-pr.sh PASS.

**F-3 — One form↔column pairing in `sourcetypes`** (from MNT-2, with nit MNT-3)
Files: `core/database/sourcetypes/formats.go`, `core/database/sourcetypes/sourcetypes.go`.
Do: one unexported table (`[]struct{Form citationformat.Form; Column string}` or `formColumn(form) string`) used by `UpdateFormats` and `Delete`, iterated with `Formats.text(form)`. Give `List` an explicit case in `text`/`with` and make an unknown form panic or return an error rather than fall to `default`.
Check: `rg -n "\"citation_(full|short|list)\"" core/database/sourcetypes --glob '!*_test.go'` prints only the table's lines (and the `SELECT` column lists); tests pass.

**F-4 — AC-4.2 resave asserts its result** (from CON-1)
Files: `core/database/sourcetypes/formats_test.go` (~line 408).
Do: assert `view.Diagnostics` equals `[diag("full", CodeUnknownField, 13, 50)]` (adjust spans to the real fixture), `res.Revision == 0`, and raw `citation_full` unchanged.
Check: the case passes; break it locally by expecting no diagnostics and see it fail.

**F-5 — Plan doc corrections** (from UX outside-lens note, UX-1 answer)
Files: `docs/deployment-plan/spike-15/prs/S15-15-type-stores-citation-formats.md`.
Do: § 10 step 2: drop "Its count is 1." (the Metadata page draws no count). § Edges "Removed inputs": make it match D-5 — a choice whose field was deleted is `sourcetypes.invalid` (user, 2026-11-16: a second-window delete need not be handled); a key with no choice whose field is gone reports `unknown_field`. Add one line to the Landed note naming these.
Check: scripts/check-pr.sh PASS (plan-docs).

**F-6 — Toast ending "…are unchanged"** (from UX-2; user amended D-12 on 2026-11-16)
Files: `macos/App/Resources/Localizable.xcstrings`, `macos/App/Platform/L10n.swift`, and D-12's quoted wording in the plan if it spells the copy.
Do: the `records` substitution becomes one "%arg Source, Artifact, graph or Source type that uses it is unchanged" / other "%arg Sources, Artifacts, graphs and Source types that use it are unchanged", and the base string no longer appends " it". Update the `toastRemovedBody` doc comment (nit UX-4) to say the count includes Source types that name the field in a format.
Check: localizable check PASS; scripts/check-pr.sh PASS.

**Nits riding along (only if trivial in files already touched):** MNT-4 doc comment on `citationFormatsProto`; MNT-5 comment naming `searchindex.ReprojectSource`/`ReprojectSourceType`; UX-3 serial comma "people, events, or places" in the two new headings; CON-2 `docs/citation-formats.md` `ambiguous_field` row "more than one field holds the key".

## Round 1 — fix
Head `9e9c2461b`. Gate PASS (orchestrator run). F-1 through F-6 done; nits MNT-3/4/5, UX-3/4, CON-2 done; CON-3 not done (nit). Deviations: F-1's broad `rg` still prints user-only and provenencia-only origin checks (`propertyterms.go:204`, `properties.go:220`, …), which are not the user-or-provenencia rule (verified). F-2 caps in SQL with `length(CAST(col AS BLOB)) <= ?` to count bytes like `Parse`. The push failed: github.com did not resolve, so the head is local only.
Minors checked by orchestrator: CON-1 (F-4) **Resolved**: the resave asserts diagnostics, revision 0, raw text unchanged. UX-2 (F-6) **Resolved**: toast and xcstrings end "…are unchanged". UX outside-lens (F-5) **Resolved**: § 10 step 2 and Edges corrected. MNT-2 (F-3) goes to round 2 with MNT-1.

## Round 2 — review
Reviewers: MNT (MNT-1 major), SEC+PRF (SEC-1 major). Scope `5962a9a7f...9e9c2461b`.

| ID | Lens | Severity | Title | Decision | Evidence / reason |
| --- | --- | --- | --- | --- | --- |
| MNT-1 | MNT | major | (round 1) editable-origin copies | Resolved | reviewer: `vocabkey.Editable` + `editableTx`; four callers moved |
| MNT-2 | MNT | minor | (round 1) form↔column pairing | Resolved | reviewer: one `formColumns` table |
| SEC-1 | SEC | major | (round 1) uncapped format-ref scan | Resolved | reviewer: `formatText` caps at `MaxFormatBytes` in bytes; test `a format text past the format cap names no field` |

No new findings. Nits: none.

## Result
Gate PASS · CI not run yet (github.com unreachable from this Mac; branch not pushed) · open: none · follow-ups: none · to user: UX-1 (answered: keep D-5), UX-2 (answered: "…are unchanged") · nit not done: CON-3
